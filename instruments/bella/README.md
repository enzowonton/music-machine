# Bella's instrument

**Part:** Drums: kick + snare

**Instrument idea:** TBD

**Controls:**

**Sounds:**

## Your part in the song

From `score/chase_strudel.js` (125 bpm, C minor).

Kick on 1, 3 and the "and" of 3, snare on 2 and 4. 2 bars, loops.

```js
// 2. DRUMS (kick + snare layers)
s("<[bd ~ ~ ~ bd bd ~ ~] [bd ~ ~ ~ bd bd ~ ~]>, ~ ~ sd ~ ~ ~ sd ~")
```

## Your files

- **bella_board/bella_board.ino** – open in Arduino IDE, upload to your board
- **bella_sketch/bella_sketch.pde** – open in Processing, hit Run
- **bella_sketch/data/** – your sound files go here

These start as copies of the starter code. Change whatever you want, it's yours. Want touch keys or an LED instead? Copy the code from `board/touch_board` or `board/led_starter` into your board file.

See `instruments/enzo` for an example.
