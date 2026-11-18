// Prebake script
//
// This is code that is loaded before your pattern is run.
// You can use it to define custom functions to use in any pattern.
// 
// This is an initial example script. You can edit it to add 
// your own funtions.
//
// To use a script shared by some other user you can use
// the import-button or paste the script in this editor.

const ratchet = register('ratchet', (pat) => pat.sometimes(ply(2)))

// "Chase" (Giorgio Moroder) — loop sketch for the Analog / Digital show
// Pulled from the fan MIDI at onlinesequencer.net/3839945 (that file is set to 130 BPM).
// Here everything runs at 125 BPM in C minor. Octaves are shifted to playable ranges.
// Paste into strudel.cc and press Ctrl+Enter. Comment parts in and out to hear each loop alone.

setcpm(125 / 4) // 125 BPM, 4 beats per bar (1 cycle = 1 bar)

stack(
  // 1. BASS PULSE — 2 bars, plays the whole song (e-piano doubles it in the MIDI)
  note("<[a#1 c2 c2 c2 a#1 c2 d#2 c2] [f1 g1 g1 g1 f1 g1 a#1 g1]>")
    .s("sawtooth").lpf(700).decay(0.15).sustain(0.3),

  // 2. DRUMS — 2 bars: kick on 1, 3 and the "and" of 3; snare on 2 and 4;
  //    16th-note closed hats; open hat at the end of bar 2
  s("<[bd ~ ~ ~ bd bd ~ ~] [bd ~ ~ ~ bd bd ~ ~]>, ~ ~ sd ~ ~ ~ sd ~, <[hh*16] [hh*14 oh ~]>"),

  // 3. PLUCK ARP — 4 bars: one note per bar repeated in 16ths (C, D, Eb, D)
  note("<[c5*16] [d5*16] [d#5*16] [d5*16]>").s("square").lpf(2000).decay(0.08).sustain(0),

  // 4. PAD CHORDS — 4 bars of held chords
  note("<[g3,c4] [g3,d4] [g3,c4,d#4] [g3,a#3,d4]>").s("triangle").gain(0.5),

  // 5. LEAD CALL + ANSWER — 8 bars: the same call three times, with a different answer each time
  note(`<
    [d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ d6@3 ~ a#5@7 ~ ~ ~]
    [d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ a#5@3 ~ f5@7 ~ ~ ~]
    [d#5 ~ c5 ~ d5 ~ a#4 c5@3 d5@2 d#5 ~ f5 ~] [g5 ~ d6@3 ~ a#5@5 ~ ~ c6 d6]
    [d#6@5 ~ d6 c6 d6@5 ~ c6 a#5] [c6 ~ g5@2 ~ ~ f5@7 ~ ~ ~]
  >`).s("sawtooth").lpf(2500).gain(0.6)
)
