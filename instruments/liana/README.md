# Liana's instrument

**Part:** Lead melody, bars 3–4 (call + second answer)

**Instrument idea:** real guitar, plus her own build (TBD)

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

Comes right after Sunni. Same call, different answer: Eb C D Bb C D Eb F, then G, Bb, F.

```js
// 5. LEAD CALL + ANSWER (bars 3–4)
note("<[d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ a#5@3 ~ f5@7 ~ ~ ~]>").s("sawtooth").lpf(2500).gain(0.6)
```

## Your files

- **liana_board/liana_board.ino** – open in Arduino IDE, upload to your board
- **liana_sketch/liana_sketch.pde** – open in Processing, hit Run
- **liana_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
