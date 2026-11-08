# Enzo's instrument

**Part:** bass

**Instrument idea:** synth keys or beat box on a table, pads or buttons trigger sound (undecided)

**Controls:** 4 buttons play the bass notes for our chords, 2 knobs. Keyboard to test: 1 2 3 4 for bass, a–l for higher notes

**Sounds:** held bass notes on A, F, C, G (our chords are Am F C G)

## What I changed from the starter

This is the example, so here's what making it yours looks like. Search the sketch for `CHANGED`.

- **Buttons play bass instead of drums:** button 1 = A, 2 = F, 3 = C, 4 = G. The note holds as long as you hold the button, so you can play one per bar along with the chords.
- **The chord name shows big on screen** while you hold it
- **NOTE_OCTAVE** from 0 to -1, so the a–l notes are an octave lower
- **Note length:** longer, fuller notes so they ring out instead of plinking

Small changes are fine. Change a setting, hit Run, listen.

## Your files

- **enzo_board/enzo_board.ino** – open in Arduino IDE, upload to your board
- **enzo_sketch/enzo_sketch.pde** – open in Processing, hit Run
- **enzo_sketch/data/** – sound files go here
