# Z's instrument

**Part:** Lead melody, bars 5–6 (call + third answer)

**Instrument idea:** TBD

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

Same notes as Sunni's bars 1–2, played with a different sound: Eb C D Bb C D Eb F, then G, high D, Bb. Your last Bb is cut a little short because the ending (bars 7–8) starts with two quick notes (C D) at the very end of bar 6.

```js
// 5. LEAD CALL + ANSWER (same notes as Sunni, played in bars 5–6)
note("<[d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ d6@3 ~ a#5@7 ~ ~ ~]>").s("sawtooth").lpf(2500).gain(0.6)
```

## Your files

- **z_board/z_board.ino** – open in Arduino IDE, upload to your board
- **z_sketch/z_sketch.pde** – open in Processing, hit Run
- **z_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
