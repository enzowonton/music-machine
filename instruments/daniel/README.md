# Daniel's instrument

**Part:** Drums: hi-hats

**Instrument idea:** beat machine on a table, pads or buttons trigger beats

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

Fast 16th-note closed hats, with an open hat at the end of bar 2. 2 bars, loops.

```js
// 2. DRUMS (hi-hat layer)
s("<[hh*16] [hh*14 oh ~]>")
```

## Your files

- **daniel_board/daniel_board.ino** – open in Arduino IDE, upload to your board
- **daniel_sketch/daniel_sketch.pde** – open in Processing, hit Run
- **daniel_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
