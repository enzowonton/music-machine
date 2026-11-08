// ─────────────────────────────────────────────
// touch_board.ino
// Music Machine: touch starter (Adafruit HUZZAH32 / ESP32 Feather)
//
// Turns any conductive thing into a key: fruit, foil, water, wire,
// a spoon, a pumpkin. Run a wire from the pin to the object. That's it.
//
// READ the ESP32's built-in touch sensing
// SEND to Processing over USB (serial, 115200):
//   touched   ->  touch1
//   let go    ->  touch1_up
//
// Starter_sketch plays touch1..touch7 as notes in our shared key.
// ─────────────────────────────────────────────


// ── TOUCH PINS ───────────────────────────────
// these are the HUZZAH32 pins that can sense touch
// (GPIO 4 is the pin labeled A5)

const int NUM_TOUCH = 7;
const int TOUCH_PINS[NUM_TOUCH]       = {4, 15, 12, 14, 27, 33, 32};
const char* TOUCH_NAMES[NUM_TOUCH]    = {"touch1", "touch2", "touch3", "touch4",
                                         "touch5", "touch6", "touch7"};


// ── SETTINGS ─────────────────────────────────

// a touch counts when the reading drops below this share of its resting value.
// too jumpy? make it smaller (0.6). not picking up touches? make it bigger (0.85).
const float SENSITIVITY = 0.75;

// print raw readings instead of messages, to help you tune SENSITIVITY.
// turn on, open Serial Monitor, touch things, then turn back off.
const bool DEBUG_RAW = false;


// ── STATE ────────────────────────────────────

int baseline[NUM_TOUCH];
bool touched[NUM_TOUCH];


void setup() {
  Serial.begin(115200);
  delay(500);

  // don't touch anything for the first second: this learns the resting values
  for (int i = 0; i < NUM_TOUCH; i++) {
    long total = 0;
    for (int s = 0; s < 20; s++) {
      total += touchRead(TOUCH_PINS[i]);
      delay(5);
    }
    baseline[i] = total / 20;
    touched[i] = false;
  }
}


void loop() {
  for (int i = 0; i < NUM_TOUCH; i++) {
    // READ: lower number = being touched
    int reading = touchRead(TOUCH_PINS[i]);

    if (DEBUG_RAW) {
      Serial.print(reading);
      Serial.print(i < NUM_TOUCH - 1 ? "\t" : "\n");
      continue;
    }

    bool isTouched = reading < baseline[i] * SENSITIVITY;

    // SEND only when it changes
    if (isTouched && !touched[i]) {
      Serial.println(TOUCH_NAMES[i]);
    } else if (!isTouched && touched[i]) {
      Serial.print(TOUCH_NAMES[i]);
      Serial.println("_up");
    }
    touched[i] = isTouched;
  }

  delay(10);
}
