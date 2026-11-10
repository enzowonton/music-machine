// ─────────────────────────────────────────────
// synth_piano.pde
// Music Machine: Enzo's synth piano (bass part)
//
// RECEIVE messages from enzo_board over USB (serial, 115200)
// USE them to play a warm synth bass and draw a glowing piano on screen
//
// From the board:
//   btn1 .. btn4     ->  bass notes A, F, C, G (our chords Am F C G)
//                        the note holds as long as you hold the key
//   knob1:0..100     ->  volume (the slider)
// To the board:
//   flash            ->  LED blinks on every new note
//
// No board plugged in? It still runs. Use the keyboard:
//   1 2 3 4          ->  the 4 keys
//   up / down        ->  volume
//
// Needs the Sound library: Sketch > Import Library > Manage Libraries > "Sound"
// ─────────────────────────────────────────────

import processing.sound.*;
import processing.serial.*;
import java.util.concurrent.ConcurrentLinkedQueue;


// ── SHARED SETTINGS (ask in Discord before changing) ──

final int BPM = 120;   // our tempo, A minor


// ── YOUR SETTINGS ────────────────────────────

// the 4 keys, left to right. MIDI numbers: 45 = A2, 41 = F2, 48 = C3, 43 = G2
final int[]    KEY_NOTES  = {45, 41, 48, 43};
final String[] KEY_LABELS = {"A", "F", "C", "G"};
final String[] KEY_CHORDS = {"Am", "F", "C", "G"};

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

boolean[] held = new boolean[4];   // which keys are down
int playing = -1;                   // which key is sounding, -1 = none


// ── SERIAL ───────────────────────────────────

Serial port;
String portName = "";
ConcurrentLinkedQueue<String> inbox = new ConcurrentLinkedQueue<String>();


// ── VISUALS ──────────────────────────────────

float[] glow = new float[4];       // each key's light, fades out after you let go
float volumeShown = 80;
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
    color(220, 90, 220)    // G  pink
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

  for (int i = 0; i < 4; i++) {
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
  if (i < 0 || i >= 4) return;

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
  for (int i = 3; i >= 0; i--) if (held[i]) return i;
  return -1;
}


// ── USE: SLIDER ──────────────────────────────

void handleValue(String name, float value) {
  if (Float.isNaN(value)) return;
  if (name.equals("knob1")) {
    volumeShown = value;
    volume = value / 100.0;
    master.volume(volume);
  }
}


// ── SOUND ────────────────────────────────────

void noteOn(int i) {
  currentFreq = midiToFreq(KEY_NOTES[i]);
  buzz.freq(currentFreq);
  buzz2.freq(currentFreq * 1.006);   // slight detune = thicker sound
  sub.freq(currentFreq / 2);
  ampTarget = 1;
  playing = i;

  ripples.add(new Ripple(keyCenterX(i), keyTopY(), keyColors[i]));
  sendToBoard("flash");   // SEND: LED blinks
}


void noteOff() {
  ampTarget = 0;
  playing = -1;
}


float midiToFreq(int midi) {
  return 440 * pow(2, (midi - 69) / 12.0);
}


// ── SEND (laptop -> board) ───────────────────

void sendToBoard(String word) {
  if (port != null) port.write(word + "\n");
}


// ── SCREEN ───────────────────────────────────

// layout of the 4 big keys
float keysLeft()     { return 140; }
float keyWidth()     { return (width - 280) / 4.0; }
float keyTopY()      { return 300; }
float keyHeight()    { return 230; }
float keyCenterX(int i) { return keysLeft() + keyWidth() * i + keyWidth() / 2; }


// the sound wave across the top, moves with the note
void drawWave() {
  color c = playing >= 0 ? keyColors[playing] : color(90, 90, 110);
  float level = max(amp, 0.04);
  float cycles = map(currentFreq, 80, 140, 3, 6);   // higher note = tighter wave
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
  for (int i = 0; i < 4; i++) {
    float x = keyCenterX(i);
    boolean on = (i == playing);
    fill(on ? keyColors[i] : color(255, 40));
    textSize(on ? 46 : 28);
    text(KEY_CHORDS[i], x, 255);
  }
}


void drawKeys() {
  for (int i = 0; i < 4; i++) {
    float x = keysLeft() + keyWidth() * i + 8;
    float w = keyWidth() - 16;
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
    textSize(54);
    text(KEY_LABELS[i], x + w / 2, y + h / 2 - 10 + press);
    textSize(14);
    fill(lerpColor(color(110), color(255, 220), g));
    text("key " + (i + 1), x + w / 2, y + h - 32 + press);
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
  String status = port != null ? "board: " + portName : "no board, keyboard mode (1-4 keys, up/down volume)";
  text(status, 40, height - 40);
  text(BPM + " bpm  ·  A minor  ·  hold one key per bar", 40, height - 20);

  // volume slider readout
  textAlign(RIGHT, CENTER);
  text("volume", width - 250, height - 30);
  fill(255, 30);
  rect(width - 230, height - 36, 190, 12, 6);
  fill(255, 200);
  rect(width - 230, height - 36, 190 * volumeShown / 100.0, 12, 6);
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
    return;
  }
  if (key >= 256 || keysDown[key]) return;   // ignore key repeat
  keysDown[key] = true;
  if (key >= '1' && key <= '4') handleMessage("btn" + key);
}

void keyReleased() {
  if (key == CODED || key >= 256) return;
  keysDown[key] = false;
  if (key >= '1' && key <= '4') handleMessage("btn" + key + "_up");
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
