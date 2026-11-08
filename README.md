# Music Machine starter code

Starter code for our IXD 360 Music Machine. Grab it, get sound coming out of your laptop, then make it your own instrument.

**How it works:** you press, touch or turn something → your ESP32 (HUZZAH32) reads it → sends a word over USB → Processing on your laptop plays the sound. Every instrument is its own loop, no networking between us.

**Goal for Nov 11:** your machine makes sound on your own laptop.

## What's in here

- **board/starter_board** – 4 buttons + 2 knobs. Start here if you're not sure.
- **board/touch_board** – turns fruit, foil, water, spoons, whatever, into keys (7 touch pins, no extra parts)
- **board/led_starter** – LED that lights on a button, dims with a knob, and flashes on the beat from Processing
- **processing/starter_sketch** – plays drum samples on buttons, notes in our shared key on touches, knobs do volume + pitch. Runs with no board too, keyboard test mode.
- **instruments/** – put your own copy here

## Set up once

**Arduino IDE**
- Download Arduino IDE 2 from arduino.cc
- Settings → Additional boards manager URLs → paste `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
- Boards Manager → search `esp32` → install **esp32 by Espressif**
- Tools → Board → esp32 → **Adafruit ESP32 Feather**

**Processing**
- Download Processing 4 from processing.org
- Sketch → Import Library → Manage Libraries → search **Sound** → install

## Try it with no board

- Open `processing/starter_sketch/starter_sketch.pde` and hit Run
- Keys **1 2 3 4** = drums, **a s d f g h j** = notes, arrows = knobs, **c** = click track
- If you hear sound, your laptop's ready

## Hook up your board

- Plug in the HUZZAH32, open one of the board sketches, pick the port under Tools → Port (usually has `usbserial` in the name), Upload
- Open Serial Monitor at **115200** and press stuff. You should see `btn1`, `knob1:57`, etc.
- **Close Serial Monitor**, then run starter_sketch. Only one app can use the port at a time.
- Wiring notes are at the top of each board file

## Make it yours

- Copy a board folder and the sketch folder into `instruments/your-name/`
- Rename the folder AND the file inside to match (Arduino and Processing both need that), like `enzo_bass/enzo_bass.ino`
- Swap the sounds: drop your own .wav files in the sketch's `data` folder and change `SAMPLE_FILES`
- Add your own words: look for `ADD YOUR OWN HERE` in both files

## Message format

Board sends one line per thing that happened, at 115200:
- **Button / touch:** a word, like `btn1` or `touch3`. Let go sends `btn1_up`.
- **Knob / sensor:** `name:value`, 0 to 100, like `knob1:57`
- **More than one value:** comma separated, like `LR:40,UD:80`
- **Laptop → board:** the sketch sends `beat` every beat (led_starter uses it)

## Shared settings

- **Tempo:** 120 bpm
- **Key:** A minor
- Already set at the top of starter_sketch (`BPM`, `ROOT_NOTE`, `SCALE`)
- Touch notes use A minor pentatonic (A C D E G), which always sounds right in A minor. There's a line under it if you want all 7 notes.
- Don't change tempo or key on your own, ask in Discord so we all stay together

## Stuck?

- **No sound:** check the Sound library is installed and your laptop volume is up
- **"Couldn't open port":** Serial Monitor is still open, close it
- **Wrong port picked:** look at the list in the Processing console, set `PORT_INDEX` to that number
- **Upload fails:** try a different USB cable (some are charge only), or hold the board's button while it says Connecting
- **Touch keys too jumpy / not working:** change `SENSITIVITY` in touch_board, or turn on `DEBUG_RAW` to see the numbers
- Still stuck: ask in Discord, someone from the code team will pair with you
