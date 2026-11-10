// ─────────────────────────────────────────────
// enzo_board.ino
// Music Machine: board starter (Adafruit HUZZAH32 / ESP32 Feather)
//
// READ your buttons and knobs
// SEND what happened to Processing over USB (serial, 115200)
//
// One message per line:
//   button pressed   ->  btn1
//   button let go    ->  btn1_up
//   knob turned      ->  knob1:57      (0 to 100)
//
// RECEIVE "flash" from Processing -> LED blinks   // CHANGED
//
// Processing (starter_sketch) RECEIVES these and USES them to play sound.
// ─────────────────────────────────────────────


// ── BUTTONS ──────────────────────────────────
// wire each button: one leg to the pin, the other leg to GND
// (no resistor needed, the board's built-in pullup handles it)

const int NUM_BUTTONS = 4;
const int BUTTON_PINS[NUM_BUTTONS]          = {14, 32, 15, 33};
const char* BUTTON_NAMES[NUM_BUTTONS]       = {"btn1", "btn2", "btn3", "btn4"};


// ── KNOBS ────────────────────────────────────
// wire each knob (potentiometer): outer legs to 3V and GND, middle leg to the pin
// A2 = GPIO 34, A3 = GPIO 39, A4 = GPIO 36
// heads up: a knob pin with nothing plugged in sends random numbers.
// if you don't have knobs yet, set NUM_KNOBS to 0.

// CHANGED: one slider (slide pot) on A2 = volume
const int NUM_KNOBS = 1;
const int KNOB_PINS[]                       = {A2};
const char* KNOB_NAMES[]                    = {"knob1"};


// ── LED ── CHANGED ───────────────────────────
// long leg -> 220 ohm resistor -> pin 21, short leg -> GND
// lights while you hold a key, and blinks when Processing sends "flash"

const int LED_PIN  = 21;
const int FLASH_MS = 80;


// ── SETTINGS ─────────────────────────────────

const int DEBOUNCE_MS  = 30;  // ignore button bounce shorter than this
const int KNOB_STEP    = 2;   // only send a knob when it moves at least this much


// ── STATE (you don't need to touch this) ─────

bool lastPressed[NUM_BUTTONS];
unsigned long lastChange[NUM_BUTTONS];
int lastKnob[8];
unsigned long flashUntil = 0;   // CHANGED
String incoming = "";           // CHANGED


void setup() {
  Serial.begin(115200);

  for (int i = 0; i < NUM_BUTTONS; i++) {
    pinMode(BUTTON_PINS[i], INPUT_PULLUP);
    lastPressed[i] = false;
    lastChange[i] = 0;
  }

  for (int i = 0; i < NUM_KNOBS; i++) {
    lastKnob[i] = -100;  // forces every knob to send once at startup
  }

  pinMode(LED_PIN, OUTPUT);  // CHANGED

  // CHANGED: LED blinks 3 times at startup so you know it's wired right
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH); delay(200);
    digitalWrite(LED_PIN, LOW);  delay(200);
  }
}


void loop() {
  readButtons();
  readKnobs();
  receiveFromProcessing();  // CHANGED
  updateLed();              // CHANGED
  delay(5);
}


// ── READ + SEND: BUTTONS ─────────────────────

void readButtons() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    // READ: pullup means LOW = pressed
    bool pressed = digitalRead(BUTTON_PINS[i]) == LOW;

    if (pressed != lastPressed[i] && millis() - lastChange[i] > DEBOUNCE_MS) {
      lastPressed[i] = pressed;
      lastChange[i] = millis();

      // SEND
      if (pressed) {
        Serial.println(BUTTON_NAMES[i]);
      } else {
        Serial.print(BUTTON_NAMES[i]);
        Serial.println("_up");
      }
    }
  }
}


// ── READ + SEND: KNOBS ───────────────────────

void readKnobs() {
  for (int i = 0; i < NUM_KNOBS; i++) {
    // READ: average a few readings so the number doesn't jitter
    long total = 0;
    for (int s = 0; s < 8; s++) total += analogRead(KNOB_PINS[i]);
    int raw = total / 8;                    // 0 to 4095
    int value = map(raw, 0, 4095, 0, 100);  // 0 to 100

    // SEND only when it really moved
    if (abs(value - lastKnob[i]) >= KNOB_STEP) {
      lastKnob[i] = value;
      Serial.print(KNOB_NAMES[i]);
      Serial.print(":");
      Serial.println(value);
    }
  }
}


// ── RECEIVE + LIGHT: LED ── CHANGED ──────────

void receiveFromProcessing() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '\n') {
      incoming.trim();
      if (incoming == "flash") flashUntil = millis() + FLASH_MS;
      incoming = "";
    } else {
      incoming += c;
    }
  }
}

void updateLed() {
  bool anyHeld = false;
  for (int i = 0; i < NUM_BUTTONS; i++) if (lastPressed[i]) anyHeld = true;
  digitalWrite(LED_PIN, (anyHeld || millis() < flashUntil) ? HIGH : LOW);
}
