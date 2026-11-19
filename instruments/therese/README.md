# Therese's instrument

**Part:** Pad chords (held)

**Instrument idea:** food instrument, touch bananas or fruit to play notes

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

4 held chords, one per bar, then it loops: G+C · G+D · G+C+Eb · G+Bb+D. Each chord rings for the whole bar.

```js
// 4. PAD CHORDS
note("<[g3,c4] [g3,d4] [g3,c4,d#4] [g3,a#3,d4]>").s("triangle").gain(0.5)
```

## Your files

- **therese_board/therese_board.ino** – open in Arduino IDE, upload to your board
- **therese_sketch/therese_sketch.pde** – open in Processing, hit Run
- **therese_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
