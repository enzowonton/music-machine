// ─────────────────────────────────────────────
// z_sketch.pde
// Music Machine: shared Processing starter
//
// RECEIVE messages from your board over USB (serial, 115200)
// USE them to play sound and draw visuals on your laptop
//
// Works with any of the board starters:
//   btn1 .. btn4        ->  drum samples (data folder)
//   touch1 .. touch9    ->  notes in our shared key
//   knob1:0..100        ->  volume
//   knob2:0..100        ->  pitch (samples) and octave (notes)
//
// No board yet? It still runs. Use the keyboard:
//   1 2 3 4             ->  btn1 .. btn4
//   a s d f g h j k l   ->  touch1 .. touch9
//   up / down arrows    ->  knob1      left / right arrows -> knob2
//
// Every time a sound plays it also sends "flash" back to the board
// (led_starter flashes its LED on it).
//
// Needs the Sound library: Sketch > Import Library > Manage Libraries > "Sound"
// ─────────────────────────────────────────────

import processing.sound.*;
import processing.serial.*;
import java.util.concurrent.ConcurrentLinkedQueue;


// ── SHARED SETTINGS ──────────────────────────
// these keep all our instruments playing together.
// our tempo is 125 bpm and our key is C minor (same as "Chase" by Giorgio Moroder).
// don't change them on your own, ask in Discord first.
// (to practice at 125, use a metronome app. the show needs one shared click, still being figured out.)

final int BPM       = 125;
final int ROOT_NOTE = 48;                       // 48 = C3 (MIDI note number)
final int[] SCALE   = {0, 3, 5, 7, 10, 12, 15, 17, 19}; // C minor pentatonic: C Eb F G Bb C Eb F G
// want all 7 notes of C minor instead? use {0, 2, 3, 5, 7, 8, 10, 12, 14}


// ── YOUR SETTINGS ────────────────────────────

// leave as -1 to auto-find the board. if it picks the wrong port,
// look at the list printed in the console and put the number here.
final int PORT_INDEX = -1;

// sounds for btn1..btn4, files live in the data folder
final String[] SAMPLE_FILES = {"kick.wav", "snare.wav", "hat.wav", "clap.wav"};

final int NOTE_OCTAVE = 0;   // -1 = lower (bass), 0 = middle, 1 = higher


// ── SOUND ────────────────────────────────────

Sound master;
SoundFile[] samples = new SoundFile[4];
TriOsc[] voices = new TriOsc[SCALE.length];
Env[] envs = new Env[SCALE.length];

float volume = 0.8;      // knob1
float pitch = 1.0;       // knob2, for samples
int octaveShift = 0;     // knob2, for notes


// ── SERIAL ───────────────────────────────────

Serial port;
String portName = "";
// serialEvent runs on its own thread, so messages wait here until draw()
ConcurrentLinkedQueue<String> inbox = new ConcurrentLinkedQueue<String>();


// ── VISUALS ──────────────────────────────────

ArrayList<Ring> rings = new ArrayList<Ring>();
ArrayList<String> recent = new ArrayList<String>();
float knob1Shown = 80, knob2Shown = 50;
boolean[] keysDown = new boolean[256];


void setup() {
  size(800, 600);
  textFont(createFont("Menlo", 12));
  noStroke();

  master = new Sound(this);
  master.volume(volume);

  for (int i = 0; i < SAMPLE_FILES.length; i++) {
    samples[i] = new SoundFile(this, SAMPLE_FILES[i]);
  }
  for (int i = 0; i < voices.length; i++) {
    voices[i] = new TriOsc(this);
    envs[i] = new Env(this);
  }

  connectToBoard();
}


void draw() {
  // RECEIVE: handle everything that came in since last frame
  String msg;
  while ((msg = inbox.poll()) != null) {
    handleMessage(msg);
  }

  // background with a soft trail
  fill(15, 15, 20, 50);
  rect(0, 0, width, height);

  for (int i = rings.size() - 1; i >= 0; i--) {
    Ring r = rings.get(i);
    r.update();
    r.display();
    if (r.isDead()) rings.remove(i);
  }

  drawStatus();
}


// ── RECEIVE ──────────────────────────────────

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() > 0) inbox.add(line);
}


// a line can be one word ("btn1"), one value ("knob1:57"),
// or several values ("LR:40,UD:80")
void handleMessage(String msg) {
  addToLog(msg);
  String[] parts = split(msg, ',');
  for (String part : parts) {
    part = trim(part);
    if (part.indexOf(':') > 0) {
      String[] nv = split(part, ':');
      handleValue(nv[0], float(nv[1]));
    } else {
      handleWord(part);
    }
  }
}


// ── USE: WORDS (buttons, touches) ────────────

void handleWord(String word) {
  if (word.startsWith("btn") && !word.endsWith("_up")) {
    int i = int(word.substring(3)) - 1;
    if (i >= 0 && i < samples.length) playSample(i);
  }
  else if (word.startsWith("touch") && !word.endsWith("_up")) {
    int i = int(word.substring(5)) - 1;
    if (i >= 0 && i < SCALE.length) playNote(i);
  }

  // ADD YOUR OWN HERE, for example:
  // else if (word.equals("shake")) { playSample(2); }
}


// ── USE: VALUES (knobs, sensors) ─────────────

void handleValue(String name, float value) {
  if (Float.isNaN(value)) return;   // ignore garbled lines

  if (name.equals("knob1")) {
    knob1Shown = value;
    volume = value / 100.0;
    master.volume(volume);
  }
  else if (name.equals("knob2")) {
    knob2Shown = value;
    pitch = map(value, 0, 100, 0.5, 1.5);
    octaveShift = value < 33 ? -1 : (value > 66 ? 1 : 0);
  }

  // ADD YOUR OWN HERE, for example a distance sensor:
  // else if (name.equals("dist")) { pitch = map(value, 0, 100, 0.5, 2.0); }
}


// ── SOUND ────────────────────────────────────

void playSample(int i) {
  samples[i].stop();
  samples[i].rate(pitch);
  samples[i].play();
  rings.add(new Ring(random(100, width - 100), random(80, height - 160), colorFor(i)));
  sendToBoard("flash");
}


void playNote(int i) {
  int midi = ROOT_NOTE + SCALE[i] + 12 * (NOTE_OCTAVE + octaveShift);
  voices[i].freq(midiToFreq(midi));
  // attack, sustain time, sustain level, release (seconds)
  envs[i].play(voices[i], 0.01, 0.15, 0.5, 0.4);
  float x = map(i, 0, SCALE.length - 1, 120, width - 120);
  rings.add(new Ring(x, height / 2 - 40, colorFor(4 + i)));
  sendToBoard("flash");
}


float midiToFreq(int midi) {
  return 440 * pow(2, (midi - 69) / 12.0);
}


// ── SEND (laptop -> board) ───────────────────
// send any word you want, then handle it in the board's RECEIVE section

void sendToBoard(String word) {
  if (port != null) port.write(word + "\n");
}


// ── CONNECT ──────────────────────────────────

void connectToBoard() {
  String[] ports = Serial.list();
  println("Serial ports:");
  printArray(ports);

  int pick = PORT_INDEX;
  if (pick < 0) {
    // look for the usual names a HUZZAH32 shows up as
    for (int i = 0; i < ports.length; i++) {
      String n = ports[i].toLowerCase();
      if (n.contains("cu.usbserial") || n.contains("cu.slab") ||
          n.contains("cu.wchusbserial") || n.contains("cu.usbmodem")) {
        pick = i;
        break;
      }
    }
    // windows: take the last COM port
    if (pick < 0 && ports.length > 0 && ports[ports.length - 1].startsWith("COM")) {
      pick = ports.length - 1;
    }
  }

  if (pick < 0 || pick >= ports.length) {
    println("No board found, running in keyboard test mode.");
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


// ── KEYBOARD TEST MODE ───────────────────────

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP)    handleMessage("knob1:" + int(constrain(knob1Shown + 5, 0, 100)));
    if (keyCode == DOWN)  handleMessage("knob1:" + int(constrain(knob1Shown - 5, 0, 100)));
    if (keyCode == RIGHT) handleMessage("knob2:" + int(constrain(knob2Shown + 5, 0, 100)));
    if (keyCode == LEFT)  handleMessage("knob2:" + int(constrain(knob2Shown - 5, 0, 100)));
    return;
  }
  if (key >= 256 || keysDown[key]) return;   // ignore key repeat while held
  keysDown[key] = true;

  String w = keyToWord(key);
  if (w != null) handleMessage(w);
}


void keyReleased() {
  if (key == CODED || key >= 256) return;
  keysDown[key] = false;
  String w = keyToWord(key);
  if (w != null) handleMessage(w + "_up");
}


String keyToWord(char k) {
  if (k >= '1' && k <= '4') return "btn" + k;
  int t = "asdfghjkl".indexOf(k);
  if (t >= 0) return "touch" + (t + 1);
  return null;
}


// ── SCREEN ───────────────────────────────────

color colorFor(int i) {
  color[] palette = {
    color(232, 89, 60),  color(127, 119, 221), color(29, 158, 117), color(239, 159, 39),
    color(90, 170, 230), color(220, 100, 170), color(160, 200, 80), color(240, 220, 110),
    color(120, 210, 200), color(250, 140, 110), color(180, 140, 240)
  };
  return palette[i % palette.length];
}


void addToLog(String msg) {
  recent.add(msg);
  if (recent.size() > 8) recent.remove(0);
}


void drawStatus() {
  fill(0, 0, 0, 160);
  rect(0, height - 110, width, 110);

  // connection
  fill(255, 200);
  textAlign(LEFT);
  String status = port != null ? "board: " + portName : "no board: keyboard test mode";
  text(status, 20, height - 85);
  text(BPM + " bpm   C minor", 20, height - 65);

  // knobs
  text("knob1 volume", 20, height - 40);
  text("knob2 pitch", 20, height - 18);
  fill(127, 119, 221, 220);
  rect(130, height - 50, knob1Shown * 1.5, 10, 3);
  fill(29, 158, 117, 220);
  rect(130, height - 28, knob2Shown * 1.5, 10, 3);

  // last messages from the board, newest at the bottom
  fill(255, 150);
  textAlign(RIGHT);
  for (int i = 0; i < recent.size(); i++) {
    text(recent.get(i), width - 20, height - 100 + i * 12);
  }
}


// ── RING (one per sound) ─────────────────────

class Ring {
  float x, y, size = 10, life = 255;
  color c;

  Ring(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.c = c;
  }

  void update() {
    size += 6;
    life -= 6;
  }

  void display() {
    noFill();
    stroke(red(c), green(c), blue(c), life);
    strokeWeight(4);
    ellipse(x, y, size, size);
    noStroke();
  }

  boolean isDead() {
    return life <= 0;
  }
}
