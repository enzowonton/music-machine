# Sunni's instrument

**Part:** Lead melody, bars 1–2 (call + first answer)

**Instrument idea:** mini harp, held upright

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

You open the lead. The call, then the first answer: Eb C D Bb C D Eb F, then G, high D, Bb. Zitlali plays these same notes later (bars 5–6) with a different sound.

```js
// 5. LEAD CALL + ANSWER (bars 1–2)
note("<[d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ d6@3 ~ a#5@7 ~ ~ ~]>").s("sawtooth").lpf(2500).gain(0.6)
```

## Your files

- **sunni_board/sunni_board.ino** – open in Arduino IDE, upload to your board
- **sunni_sketch/sunni_sketch.pde** – open in Processing, hit Run
- **sunni_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
