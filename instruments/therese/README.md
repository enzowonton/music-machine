# Therese's instrument

**Part:** Lead melody, bars 7–8 (the ending)

**Instrument idea:** food instrument, touch bananas or fruit to play notes

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

The last line of the lead. Starts with two quick notes (C D) at the very end of bar 6, right after Zitlali, then: Eb D C D C Bb, then C G F.

```js
// 5. LEAD CALL + ANSWER (bars 7–8, the pickup "c6 d6" ends bar 6)
note("<[d#6@5 ~ d6 c6 d6@5 ~ c6 a#5] [c6 ~ g5@2 ~ ~ f5@7 ~ ~ ~]>").s("sawtooth").lpf(2500).gain(0.6)
```

## Your files

- **therese_board/therese_board.ino** – open in Arduino IDE, upload to your board
- **therese_sketch/therese_sketch.pde** – open in Processing, hit Run
- **therese_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
