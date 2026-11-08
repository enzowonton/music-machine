// ─────────────────────────────────────────────
// visuals_starter.pde
// Music Machine: visuals starter for the big screen
//
// Built from the visual direction in our pitch deck:
//   - a grid of glowing dots, like the Ferranti Mark 1's display
//   - a wave that goes from a smooth sine (analog) to a square (digital)
//   - everything centered and symmetrical
//   - the show opens on a single point of light (the spotlight)
//
// Try it with the keyboard:
//   up / down       ->  open the light from one dot to the full grid
//   left / right    ->  analog (smooth wave) <-> digital (square wave)
//   1 2 3 4         ->  a hit: a ring of light ripples out from the center
//   a s d f g h j k l -> same, smaller ripples
//
// It also listens to a board, same messages as starter_sketch:
//   btn / touch words -> ripples     knob1 -> light open     knob2 -> analog/digital
// Heads up: only one sketch can use a board's port at a time. To make an
// instrument drive these visuals, copy the parts you like into its sketch.
// ─────────────────────────────────────────────

import processing.serial.*;
import java.util.concurrent.ConcurrentLinkedQueue;


// ── LOOK ─────────────────────────────────────

final int COLS = 32;            // dots across
final int ROWS = 18;            // dots down
final color BG      = color(12, 12, 14);
final color ANALOG  = color(245, 232, 210);   // warm white
final color DIGITAL = color(80, 230, 140);    // phosphor green

final int PORT_INDEX = -1;      // -1 = auto-find the board


// ── STATE ────────────────────────────────────

float open = 0.0;        // 0 = one dot, 1 = full grid
float openShown = 0.0;   // eased version, so changes glide
float mix = 0.0;         // 0 = analog, 1 = digital
float mixShown = 0.0;

ArrayList<Ripple> ripples = new ArrayList<Ripple>();
boolean[] keysDown = new boolean[256];

Serial port;
ConcurrentLinkedQueue<String> inbox = new ConcurrentLinkedQueue<String>();


void setup() {
  size(1280, 720);       // projector shape. fullScreen() for the show.
  noStroke();
  connectToBoard();
}


void draw() {
  String msg;
  while ((msg = inbox.poll()) != null) handleMessage(msg);

  openShown += (open - openShown) * 0.05;
  mixShown  += (mix - mixShown) * 0.05;

  background(BG);
  drawDots();
  drawWave();

  for (int i = ripples.size() - 1; i >= 0; i--) {
    ripples.get(i).update();
    if (ripples.get(i).isDead()) ripples.remove(i);
  }
}


// ── DOT GRID ─────────────────────────────────

void drawDots() {
  float gap = width / (float) COLS;
  float cx = width / 2.0, cy = height / 2.0;
  float maxDist = dist(0, 0, cx, cy);
  color c = lerpColor(ANALOG, DIGITAL, mixShown);

  for (int col = 0; col < COLS; col++) {
    for (int row = 0; row < ROWS; row++) {
      float x = gap * (col + 0.5);
      float y = gap * (row + 0.5);
      float d = dist(x, y, cx, cy);

      // the spotlight: how far out the light has opened
      float reach = openShown * maxDist + gap * 0.7;
      float glow = constrain(1 - (d - reach) / (gap * 2), 0, 1) * 0.35;

      // ripples add light where their ring passes
      for (Ripple r : ripples) glow += r.lightAt(d, gap);

      glow = constrain(glow, 0, 1);
      if (glow < 0.02) continue;

      float size = gap * 0.25 + gap * 0.35 * glow;
      fill(c, 40 * glow);
      ellipse(x, y, size * 2.2, size * 2.2);   // soft halo
      fill(c, 255 * glow);
      ellipse(x, y, size, size);
    }
  }
}


// ── WAVE: sine (analog) to square (digital) ──
// a square wave is a sine plus smaller sines stacked on top.
// more stacked sines = more digital.

void drawWave() {
  float harmonics = 1 + mixShown * mixShown * 15;   // how many sines are stacked
  float amp = height * 0.12 * (0.3 + 0.7 * openShown);
  float speed = frameCount * 0.03;
  color c = lerpColor(ANALOG, DIGITAL, mixShown);

  noFill();
  stroke(c, 220);
  strokeWeight(3);
  beginShape();
  for (int x = 0; x <= width; x += 3) {
    float t = map(x, 0, width, 0, TWO_PI * 3) - speed;
    float y = 0;
    for (int k = 0; k < ceil(harmonics); k++) {
      int n = 2 * k + 1;                              // 1, 3, 5, 7...
      float fade = constrain(harmonics - k, 0, 1);    // new sines fade in smoothly
      y += fade * sin(n * t) / n;
    }
    vertex(x, height / 2.0 - y * amp);
  }
  endShape();
  noStroke();
}


// ── RIPPLE (one per hit) ─────────────────────

class Ripple {
  float radius = 0, speed, strength;

  Ripple(float strength) {
    this.strength = strength;
    speed = 8 + 6 * strength;
  }

  void update() {
    radius += speed;
    strength *= 0.975;
  }

  float lightAt(float d, float gap) {
    float band = gap * 1.2;
    return strength * constrain(1 - abs(d - radius) / band, 0, 1);
  }

  boolean isDead() {
    return strength < 0.03 || radius > width;
  }
}


// ── MESSAGES (board or keyboard) ─────────────

void handleMessage(String msg) {
  for (String part : split(msg, ',')) {
    part = trim(part);
    if (part.indexOf(':') > 0) {
      String[] nv = split(part, ':');
      float v = float(nv[1]);
      if (Float.isNaN(v)) continue;
      if (nv[0].equals("knob1")) open = v / 100.0;
      if (nv[0].equals("knob2")) mix = v / 100.0;
    }
    else if (part.endsWith("_up")) {
      // nothing on release
    }
    else if (part.startsWith("btn"))   ripples.add(new Ripple(1.0));
    else if (part.startsWith("touch")) ripples.add(new Ripple(0.6));
  }
}


void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP)    open = constrain(open + 0.1, 0, 1);
    if (keyCode == DOWN)  open = constrain(open - 0.1, 0, 1);
    if (keyCode == RIGHT) mix  = constrain(mix + 0.1, 0, 1);
    if (keyCode == LEFT)  mix  = constrain(mix - 0.1, 0, 1);
    return;
  }
  if (key >= 256 || keysDown[key]) return;
  keysDown[key] = true;
  if (key >= '1' && key <= '4') handleMessage("btn" + key);
  if ("asdfghjkl".indexOf(key) >= 0) handleMessage("touch1");
}


void keyReleased() {
  if (key != CODED && key < 256) keysDown[key] = false;
}


// ── BOARD ────────────────────────────────────

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line != null && trim(line).length() > 0) inbox.add(trim(line));
}


void connectToBoard() {
  String[] ports = Serial.list();
  int pick = PORT_INDEX;
  for (int i = 0; pick < 0 && i < ports.length; i++) {
    String n = ports[i].toLowerCase();
    if (n.contains("cu.usbserial") || n.contains("cu.slab") ||
        n.contains("cu.wchusbserial") || n.contains("cu.usbmodem")) pick = i;
  }
  if (pick < 0 || pick >= ports.length) {
    println("No board found, keyboard only.");
    return;
  }
  try {
    port = new Serial(this, ports[pick], 115200);
    port.bufferUntil('\n');
    println("Connected to " + ports[pick]);
  }
  catch (Exception e) {
    port = null;
    println("Couldn't open " + ports[pick] + " (another sketch or Serial Monitor is using it).");
  }
}
