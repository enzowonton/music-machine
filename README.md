# Music Machine starter code

Starter code for our IXD 360 Music Machine. Grab it, get sound coming out of your laptop, then make it your own instrument.

**How it works:** you press, touch or turn something → your ESP32 (HUZZAH32) reads it → sends a word over USB → Processing on your laptop plays the sound. Every instrument is its own loop, no networking between us.

**The show:** Analog / Digital. Liana's real guitar opens, Turing's 1951 computer music turns it digital, the two sides face off, then Rafael's AI robot brings them together.

**Goal for Tue Nov 10 (Code Checkpoint):** every player has a control making sound on their own laptop.

## New to GitHub? Start here

**What this page is:** a shared folder for our code, like a Google Drive folder. You're reading the README, the instructions for the folder. The list of folders and files is above this.

**Get the code:**
1. Click the green **Code** button near the top of this page
2. Click **Download ZIP**
3. Unzip it (double-click it on a Mac)

**What to open:** only your own folder, `instruments/your-name/`. You'll get everyone's folders in the ZIP, and that's normal. Ignore the rest, and don't worry, changing your copy can't mess up anyone else's.

**What's in your folder:**
- `your-name_sketch/your-name_sketch.pde` – the laptop part. Open it in Processing and hit Run. No board needed to try it.
- `your-name_board/your-name_board.ino` – the board part. Open it in Arduino IDE and upload it to your HUZZAH32.
- `README.md` – fill in your instrument idea

**Sending your code back:** send your files to Enzo on Discord. You don't need a GitHub account.

**Getting updates:** if we post that the starter changed, download the ZIP again. Copy your own files out first so you don't lose your changes.

**Just want to look?** Click any folder or file on this page to open it. Nothing you click here changes anything.

## What's in here

- **board/starter_board** – 4 buttons + 2 knobs. Start here if you're not sure.
- **board/touch_board** – turns fruit, foil, water, spoons, whatever, into keys (7 touch pins, no extra parts)
- **board/led_starter** – LED that lights on a button, dims with a knob, and flashes when Processing plays a sound
- **processing/starter_sketch** – plays drum samples on buttons, notes in our shared key on touches, knobs do volume + pitch. Runs with no board too, keyboard test mode.
- **processing/visuals_starter** – big screen visuals from our deck: glowing dot grid, a wave that goes from smooth (analog) to square (digital), ripples on every hit
- **instruments/** – everyone's own folder, already set up. **Start here.**

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
- Keys **1 2 3 4** = drums, **a s d f g h j k l** = notes, arrows = knobs
- If you hear sound, your laptop's ready

## Hook up your board

- Plug in the HUZZAH32, open one of the board sketches, pick the port under Tools → Port (usually has `usbserial` in the name), Upload
- Open Serial Monitor at **115200** and press stuff. You should see `btn1`, `knob1:57`, etc.
- **Close Serial Monitor**, then run starter_sketch. Only one app can use the port at a time.
- Wiring notes are at the top of each board file

## Make it yours

- **Your folder is already made:** `instruments/your-name/` has your own board file and sketch, ready to open
- **See `instruments/enzo`** for an example of changing the starter
- Swap the sounds: drop your own .wav files in your sketch's `data` folder and change `SAMPLE_FILES`
- Add your own words: look for `ADD YOUR OWN HERE` in both files
- How to get your code back on GitHub is in `instruments/README.md`

## Message format

Board sends one line per thing that happened, at 115200:
- **Button / touch:** a word, like `btn1` or `touch3`. Let go sends `btn1_up`.
- **Knob / sensor:** `name:value`, 0 to 100, like `knob1:57`
- **More than one value:** comma separated, like `LR:40,UD:80`
- **Laptop → board:** the sketch sends `flash` every time a sound plays (led_starter uses it)

## Shared settings

- **Tempo:** 120 bpm
- **Key:** A minor
- **Chords:** Am, F, C, G, one chord per bar. Calm parts use half-time drums.
- Already set at the top of starter_sketch (`BPM`, `ROOT_NOTE`, `SCALE`)
- To practice at 120, use a metronome app. For the show we'll need one shared click everyone hears, still figuring that out.
- Touch notes use A minor pentatonic (A C D E G), which always sounds right in A minor. There's a line under it if you want all 7 notes.
- Don't change tempo or key on your own, ask in Discord so we all stay together

## Sensors

- **Flex sensor, light sensor (photoresistor), pressure pad:** wire like a knob, with a 10k resistor. One leg to 3V, other leg to the pin (A2, A3 or A4), and a 10k resistor from that same pin to GND. starter_board reads it as a knob, so name it something like `flex` in `KNOB_NAMES`.
- **Distance sensors and anything else:** depends on the exact part. Ask Eli (sensors and lights).

## Code team

- **Enzo** – board code and wiring
- **Devin** – Processing sound
- **Eli** – sensors and lights
- **Daniel** – performance setup (laptops, cables, sound check)

## Stuck?

- **No sound:** check the Sound library is installed and your laptop volume is up
- **"Couldn't open port":** Serial Monitor is still open, close it
- **Wrong port picked:** look at the list in the Processing console, set `PORT_INDEX` to that number
- **Cable:** the HUZZAH32 has a micro-USB port. Newer Macs need a USB-C to micro-USB cable, and it has to be a data cable (charge-only cables won't upload)
- **Upload fails:** try a different USB cable (some are charge only), or hold the board's button while it says Connecting
- **Touch keys too jumpy / not working:** change `SENSITIVITY` in touch_board, or turn on `DEBUG_RAW` to see the numbers
- Still stuck: ask in Discord, someone from the code team will pair with you
