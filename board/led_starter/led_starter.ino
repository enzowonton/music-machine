// ─────────────────────────────────────────────
// led_starter.ino
// Music Machine: LED starter (Adafruit HUZZAH32 / ESP32 Feather)
//
// Three ways to light an LED, pick what you need:
//   1. press a button       -> LED turns on (no laptop needed)
//   2. turn a knob          -> LED gets brighter / dimmer
//   3. RECEIVE from Processing -> LED flashes every time a sound plays
//      (starter_sketch sends "flash", or any word you tell it to)
//
// It also SENDS btn1 / knob1:57 like starter_board, so sound still works.
// ─────────────────────────────────────────────


// ── PINS ─────────────────────────────────────
// LED: long leg -> 220 ohm resistor -> pin 21, short leg -> GND
// button: one leg to pin 14, other leg to GND
// knob: outer legs to 3V and GND, middle leg to A2

const int LED_PIN    = 21;
const int BUTTON_PIN = 14;
const int KNOB_PIN   = A2;

// set to false if you don't have a knob plugged in yet
const bool USE_KNOB  = true;


// ── SETTINGS ─────────────────────────────────

const int FLASH_MS = 80;   // how long a flash lasts


// ── STATE ────────────────────────────────────

int brightness = 255;            // 0 to 255, set by the knob
bool buttonDown = false;
unsigned long flashUntil = 0;
int lastKnobSent = -100;
String incoming = "";


void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
}


void loop() {
  readButton();
  if (USE_KNOB) readKnob();
  receiveFromProcessing();
  updateLed();
  delay(5);
}


// ── 1. BUTTON ────────────────────────────────

void readButton() {
  bool pressed = digitalRead(BUTTON_PIN) == LOW;
  if (pressed != buttonDown) {
    buttonDown = pressed;
    Serial.println(pressed ? "btn1" : "btn1_up");
    delay(20);  // simple debounce
  }
}


// ── 2. KNOB ──────────────────────────────────

void readKnob() {
  int raw = analogRead(KNOB_PIN);           // 0 to 4095
  brightness = map(raw, 0, 4095, 0, 255);

  int value = map(raw, 0, 4095, 0, 100);
  if (abs(value - lastKnobSent) >= 2) {
    lastKnobSent = value;
    Serial.print("knob1:");
    Serial.println(value);
  }
}


// ── 3. RECEIVE ───────────────────────────────

void receiveFromProcessing() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '\n') {
      incoming.trim();
      // USE: add your own words here, e.g. if (incoming == "drop") { ... }
      if (incoming == "flash") {
        flashUntil = millis() + FLASH_MS;
      }
      incoming = "";
    } else {
      incoming += c;
    }
  }
}


// ── LIGHT IT ─────────────────────────────────

void updateLed() {
  bool on = buttonDown || millis() < flashUntil;
  analogWrite(LED_PIN, on ? brightness : 0);
}
