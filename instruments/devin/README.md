# Devin's instrument

**Part:** Bass pulse (plays the whole song)

**Instrument idea:** TBD

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

8th notes, 2 bars, loops. Bar 1: Bb C C C Bb C Eb C · Bar 2: F G G G F G Bb G

```js
// 1. BASS PULSE
note("<[a#1 c2 c2 c2 a#1 c2 d#2 c2] [f1 g1 g1 g1 f1 g1 a#1 g1]>")
  .s("sawtooth").lpf(700).decay(0.15).sustain(0.3)
```

## Your files

- **devin_board/devin_board.ino** – open in Arduino IDE, upload to your board
- **devin_sketch/devin_sketch.pde** – open in Processing, hit Run
- **devin_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
