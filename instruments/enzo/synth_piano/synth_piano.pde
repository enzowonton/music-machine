// ─────────────────────────────────────────────
// synth_piano.pde
// Music Machine: Enzo's synth piano (bass part)
//
// RECEIVE messages from enzo_board over USB (serial, 115200)
// USE them to play a warm synth bass and draw a glowing piano on screen
//
// From the board:
//   btn1 .. btn4     ->  bass notes A, F, C, G (our chords Am F C G)
//   btn5 .. btn8     ->  higher melody notes A, C, D, E
//                        every note holds as long as you hold the key
//   knob1:0..100     ->  volume (the slider)
//   knob2:0..100     ->  pitch (the dial): middle = in tune,
//                        turn left = lower, right = higher (up to 1 octave)
// To the board:
//   flash            ->  LED blinks on every new note
//
// No board plugged in? It still runs. Use the keyboard:
//   1 .. 8           ->  the 8 keys
//   up / down        ->  volume      left / right  ->  pitch dial
//
// Needs the Sound library: Sketch > Import Library > Manage Libraries > "Sound"
// ─────────────────────────────────────────────

import processing.sound.*;
import processing.serial.*;
import java.util.concurrent.ConcurrentLinkedQueue;


// ── SHARED SETTINGS (ask in Discord before changing) ──

final int BPM = 125;   // our tempo (key is C minor, these bass notes are still the old A minor ones)


// ── YOUR SETTINGS ────────────────────────────

// the 8 keys, left to right.
// 1-4 bass, MIDI numbers: 45 = A2, 41 = F2, 48 = C3, 43 = G2
// 5-8 melody (A minor pentatonic, an octave up): 57 = A3, 60 = C4, 62 = D4, 64 = E4
final int NUM_KEYS = 8;
final int[]    KEY_NOTES  = {45, 41, 48, 43, 57, 60, 62, 64};
final String[] KEY_LABELS = {"A", "F", "C", "G", "A", "C", "D", "E"};
final String[] KEY_CHORDS = {"Am", "F", "C", "G", "", "", "", ""};   // chord names show for bass keys

// pitch dial: how far it bends at each end, in semitones (12 = one octave)
final float BEND_RANGE = 12;
// around the middle the dial snaps to perfectly in tune, so you can find "normal" easily
final float DIAL_DEADZONE = 6;     // in dial units (0-100)

// how bright the synth sounds: lower = darker / rounder, higher = buzzier
final float FILTER_CUTOFF = 900;   // try 400 to 3000

// how loud the sub (one octave lower, smooth) is under the main buzz
final float SUB_LEVEL = 0.6;       // 0 = off, 1 = loud

// how fast notes fade in / out: bigger = snappier, smaller = softer
final float FADE_SPEED = 0.3;      // try 0.05 to 0.6

// leave as -1 to auto-find the board. if it picks the wrong port,
// look at the list printed in the console and put that number here.
final int PORT_INDEX = -1;


// ── SOUND ────────────────────────────────────

Sound master;
SawOsc buzz;        // main synth tone
SawOsc buzz2;       // same note, slightly detuned, makes it thick
SinOsc sub;         // smooth tone one octave down
LowPass filter;

float volume = 0.8;     // slider
float amp = 0;          // how loud the note is right now
float ampTarget = 0;    // where it's fading to
float currentFreq = 110;
int currentMidi = 45;
float bend = 0;          // semitones from the pitch dial
float bendSmooth = 0;    // eases toward bend so turning sounds smooth

boolean[] held = new boolean[NUM_KEYS];   // which keys are down
int playing = -1;                   // which key is sounding, -1 = none


// ── SERIAL ───────────────────────────────────

Serial port;
String portName = "";
ConcurrentLinkedQueue<String> inbox = new ConcurrentLinkedQueue<String>();


// ── VISUALS ──────────────────────────────────

float[] glow = new float[NUM_KEYS];       // each key's light, fades out after you let go
float volumeShown = 80;
float dialShown = 50;
float wavePhase = 0;
ArrayList<Ripple> ripples = new ArrayList<Ripple>();
color[] keyColors;


void setup() {
  size(1000, 620);
  pixelDensity(displayDensity());
  textFont(createFont("Helvetica-Bold", 20));

  keyColors = new color[] {
    color(255, 160, 40),   // A  amber
    color(40, 200, 130),   // F  green
    color(80, 140, 255),   // C  blue
    color(220, 90, 220),   // G  pink
    color(255, 110, 90),   // melody A  coral
    color(120, 220, 230),  // melody C  aqua
    color(250, 220, 90),   // melody D  yellow
    color(170, 140, 255)   // melody E  lavender
  };

  master = new Sound(this);
  master.volume(volume);

  buzz  = new SawOsc(this);
  buzz2 = new SawOsc(this);
  sub   = new SinOsc(this);
  buzz.amp(0);  buzz2.amp(0);  sub.amp(0);
  buzz.play();  buzz2.play();  sub.play();

  filter = new LowPass(this);
  filter.process(buzz, FILTER_CUTOFF);
  // (buzz2 stays unfiltered but quiet, it adds a little edge)

  connectToBoard();
}


void draw() {
  // RECEIVE: everything that came in since last frame
  String msg;
  while ((msg = inbox.poll()) != null) handleMessage(msg);

  // fade the note in / out so it never clicks
  amp += (ampTarget - amp) * FADE_SPEED;
  buzz.amp(amp * 0.45);
  buzz2.amp(amp * 0.12);
  sub.amp(amp * SUB_LEVEL * 0.5);

  // pitch dial: glide toward the dial's bend and retune the note
  bendSmooth += (bend - bendSmooth) * 0.25;
  setPitch();

  for (int i = 0; i < NUM_KEYS; i++) {
    if (held[i]) glow[i] = 1;
    else glow[i] *= 0.9;
  }

  background(12, 12, 18);
  drawWave();
  drawRipples();
  drawChordRow();
  drawKeys();
  drawStatus();
}


// ── RECEIVE ──────────────────────────────────

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() > 0) inbox.add(line);
}


void handleMessage(String msg) {
  // values look like "knob1:57", words look like "btn1" or "btn1_up"
  if (msg.indexOf(':') > 0) {
    String[] nv = split(msg, ':');
    handleValue(nv[0], float(nv[1]));
  } else {
    handleWord(msg);
  }
}


// ── USE: KEYS ────────────────────────────────

void handleWord(String word) {
  if (!word.startsWith("btn")) return;

  boolean up = word.endsWith("_up");
  String num = up ? word.substring(3, word.length() - 3) : word.substring(3);
  int i = int(num) - 1;
  if (i < 0 || i >= NUM_KEYS) return;

  if (!up) {
    held[i] = true;
    noteOn(i);
  } else {
    held[i] = false;
    if (i == playing) {
      // like a real synth: if you're still holding another key, go back to it
      int other = lastHeldKey();
      if (other >= 0) noteOn(other);
      else noteOff();
    }
  }
}


int lastHeldKey() {
  for (int i = NUM_KEYS - 1; i >= 0; i--) if (held[i]) return i;
  return -1;
}


// ── USE: SLIDER + DIAL ───────────────────────

void handleValue(String name, float value) {
  if (Float.isNaN(value)) return;
  if (name.equals("knob1")) {
    volumeShown = value;
    volume = value / 100.0;
    master.volume(volume);
  }
  else if (name.equals("knob2")) {
    dialShown = value;
    float off = value - 50;
    if (abs(off) <= DIAL_DEADZONE) bend = 0;
    else bend = map(abs(off), DIAL_DEADZONE, 50, 0, BEND_RANGE) * (off < 0 ? -1 : 1);
  }
}


// ── SOUND ────────────────────────────────────

void noteOn(int i) {
  currentMidi = KEY_NOTES[i];
  setPitch();
  ampTarget = 1;
  playing = i;

  ripples.add(new Ripple(keyCenterX(i), keyTopY(), keyColors[i]));
  sendToBoard("flash");   // SEND: LED blinks
}


void noteOff() {
  ampTarget = 0;
  playing = -1;
}


// the note's pitch plus whatever the dial adds
void setPitch() {
  currentFreq = 440 * pow(2, (currentMidi + bendSmooth - 69) / 12.0);
  buzz.freq(currentFreq);
  buzz2.freq(currentFreq * 1.006);   // slight detune = thicker sound
  sub.freq(currentFreq / 2);
}


// ── SEND (laptop -> board) ───────────────────

void sendToBoard(String word) {
  if (port != null) port.write(word + "\n");
}


// ── SCREEN ───────────────────────────────────

// layout of the 4 big keys
float keysLeft()     { return 60; }
float keyWidth()     { return (width - 120) / (float) NUM_KEYS; }
float keyTopY()      { return 300; }
float keyHeight()    { return 230; }
float keyCenterX(int i) { return keysLeft() + keyWidth() * i + keyWidth() / 2; }


// the sound wave across the top, moves with the note
void drawWave() {
  color c = playing >= 0 ? keyColors[playing] : color(90, 90, 110);
  float level = max(amp, 0.04);
  float cycles = constrain(map(currentFreq, 50, 400, 2.5, 9), 2, 10);   // higher note = tighter wave
  wavePhase += 0.04 + amp * 0.06;

  noFill();
  strokeWeight(3);
  stroke(red(c), green(c), blue(c), 60 + 195 * amp);
  beginShape();
  for (float x = 40; x <= width - 40; x += 4) {
    float t = (x - 40) / (width - 80) * cycles + wavePhase;
    float saw = 2 * (t - floor(t + 0.5));          // sawtooth: the buzz
    float smooth = sin(t * TWO_PI);                 // sine: the sub
    float y = lerp(smooth, saw, 0.55) * 70 * level;
    vertex(x, 150 + y);
  }
  endShape();
  noStroke();
}


// the chord progression, current chord lit up
void drawChordRow() {
  textAlign(CENTER, CENTER);
  for (int i = 0; i < NUM_KEYS; i++) {
    if (KEY_CHORDS[i].length() == 0) continue;
    float x = keyCenterX(i);
    boolean on = (i == playing);
    fill(on ? keyColors[i] : color(255, 40));
    textSize(on ? 46 : 28);
    text(KEY_CHORDS[i], x, 255);
  }
}


void drawKeys() {
  // labels over the two groups
  textAlign(CENTER, CENTER);
  textSize(12);
  fill(255, 90);
  text("BASS", keysLeft() + keyWidth() * 2, keyTopY() - 18);
  text("MELODY", keysLeft() + keyWidth() * 6, keyTopY() - 18);

  for (int i = 0; i < NUM_KEYS; i++) {
    float gap = (i == 4) ? 18 : 0;   // small gap between bass and melody keys
    float x = keysLeft() + keyWidth() * i + 6 + gap * 0.5;
    float w = keyWidth() - 12 - gap * 0.5;
    float y = keyTopY();
    float h = keyHeight();
    float g = glow[i];
    float press = held[i] ? 6 : 0;   // key dips when pressed
    color c = keyColors[i];

    // glow behind the key
    for (int r = 4; r > 0; r--) {
      fill(red(c), green(c), blue(c), 18 * g);
      rect(x - r * 6, y - r * 6 + press, w + r * 12, h + r * 12, 18 + r * 4);
    }

    // the key itself: ivory that tints toward its color when lit
    fill(lerpColor(color(235, 232, 222), c, 0.7 * g));
    rect(x, y + press, w, h, 14);

    // a thin shadow line at the bottom like a real key
    fill(0, 60);
    rect(x, y + h - 10 + press, w, 10, 0, 0, 14, 14);

    // label
    fill(lerpColor(color(40, 40, 50), color(255), g));
    textAlign(CENTER, CENTER);
    textSize(44);
    text(KEY_LABELS[i], x + w / 2, y + h / 2 - 10 + press);
    textSize(14);
    fill(lerpColor(color(110), color(255, 220), g));
    text("" + (i + 1), x + w / 2, y + h - 32 + press);
  }
}


void drawRipples() {
  for (int i = ripples.size() - 1; i >= 0; i--) {
    Ripple r = ripples.get(i);
    r.update();
    r.display();
    if (r.isDead()) ripples.remove(i);
  }
}


void drawStatus() {
  textAlign(LEFT, CENTER);
  textSize(13);
  fill(255, 150);
  String status = port != null ? "board: " + portName : "no board, keyboard mode (1-8 keys, up/down volume, left/right pitch)";
  text(status, 40, height - 40);
  text(BPM + " bpm  ·  A minor  ·  hold one key per bar", 40, height - 20);

  // volume slider readout
  textAlign(RIGHT, CENTER);
  fill(255, 150);
  text("volume", width - 250, height - 46);
  fill(255, 30);
  rect(width - 230, height - 52, 190, 12, 6);
  fill(255, 200);
  rect(width - 230, height - 52, 190 * volumeShown / 100.0, 12, 6);

  // pitch dial readout: center line = in tune
  fill(255, 150);
  String b = abs(bend) < 0.05 ? "in tune" : nf(bend, 0, 1) + " st";
  text("pitch  " + b, width - 250, height - 22);
  fill(255, 30);
  rect(width - 230, height - 28, 190, 12, 6);
  fill(255, 120);
  rect(width - 136, height - 31, 2, 18);
  fill(abs(bend) < 0.05 ? color(120, 230, 160) : color(255, 200));
  ellipse(width - 230 + 190 * dialShown / 100.0, height - 22, 14, 14);
}


// ── CONNECT ──────────────────────────────────

void connectToBoard() {
  String[] ports = Serial.list();
  println("Serial ports:");
  printArray(ports);

  int pick = PORT_INDEX;
  if (pick < 0) {
    for (int i = 0; i < ports.length; i++) {
      String n = ports[i].toLowerCase();
      if (n.contains("cu.usbserial") || n.contains("cu.slab") ||
          n.contains("cu.wchusbserial") || n.contains("cu.usbmodem")) {
        pick = i;
        break;
      }
    }
    if (pick < 0 && ports.length > 0 && ports[ports.length - 1].startsWith("COM")) {
      pick = ports.length - 1;
    }
  }

  if (pick < 0 || pick >= ports.length) {
    println("No board found, running in keyboard mode.");
    return;
  }

  try {
    port = new Serial(this, ports[pick], 115200);
    port.bufferUntil('\n');
    portName = ports[pick];
    println("Connected to " + portName);
  }
  catch (Exception e) {
    port = null;
    println("Couldn't open " + ports[pick] + ". Is Arduino's Serial Monitor open? Close it and run again.");
  }
}


// ── KEYBOARD MODE ────────────────────────────

boolean[] keysDown = new boolean[256];

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP)   handleMessage("knob1:" + int(constrain(volumeShown + 5, 0, 100)));
    if (keyCode == DOWN) handleMessage("knob1:" + int(constrain(volumeShown - 5, 0, 100)));
    if (keyCode == RIGHT) handleMessage("knob2:" + int(constrain(dialShown + 5, 0, 100)));
    if (keyCode == LEFT)  handleMessage("knob2:" + int(constrain(dialShown - 5, 0, 100)));
    return;
  }
  if (key >= 256 || keysDown[key]) return;   // ignore key repeat
  keysDown[key] = true;
  if (key >= '1' && key <= '8') handleMessage("btn" + key);
}

void keyReleased() {
  if (key == CODED || key >= 256) return;
  keysDown[key] = false;
  if (key >= '1' && key <= '8') handleMessage("btn" + key + "_up");
}


// ── RIPPLE (one per new note) ────────────────

class Ripple {
  float x, y, size = 20, life = 220;
  color c;

  Ripple(float x, float y, color c) {
    this.x = x; this.y = y; this.c = c;
  }

  void update() { size += 9; life -= 5; }

  void display() {
    noFill();
    stroke(red(c), green(c), blue(c), life);
    strokeWeight(3);
    ellipse(x, y, size, size * 0.6);
    noStroke();
  }

  boolean isDead() { return life <= 0; }
}
