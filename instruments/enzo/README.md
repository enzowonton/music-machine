# Enzo's instrument

**Part:** bass

**Instrument idea:** little synth piano: 4 button keys play the bass, a slider sets volume, an LED lights while a key is held

**Controls:** 4 buttons (pins 14, 32, 15, 33) play the bass notes for our chords, 1 slide pot on A2 = volume, LED on pin 21 (220 ohm). Keyboard to test: 1 2 3 4 for bass, a–l for higher notes

**Sounds:** held bass notes on A, F, C, G (our chords are Am F C G)

## What I changed from the starter

This is the example, so here's what making it yours looks like. Search the sketch for `CHANGED`.

- **Buttons play bass instead of drums:** button 1 = A, 2 = F, 3 = C, 4 = G. The note holds as long as you hold the button, so you can play one per bar along with the chords.
- **The chord name shows big on screen** while you hold it
- **NOTE_OCTAVE** from 0 to -1, so the a–l notes are an octave lower
- **One slider instead of two knobs**, and an **LED on pin 21** that lights while you hold a key and blinks on "flash"
- **Note length:** longer, fuller notes so they ring out instead of plinking

Small changes are fine. Change a setting, hit Run, listen.

## Your files

- **enzo_board/enzo_board.ino** – open in Arduino IDE, upload to your board
- **enzo_sketch/enzo_sketch.pde** – open in Processing, hit Run
- **enzo_sketch/data/** – sound files go here
