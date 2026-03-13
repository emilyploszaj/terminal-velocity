# `Terminal ~ Velocity`
`Terminal ~ Velocity` is a relatively simple, terminal-based, 4 key rhythm game.

As a 4 key rhythm game, gameplay consists of simple notes that appear in one of 4 columns that need to be hit with the corresponding `d`, `f`, `j`, or `k` key. `Terminal ~ Velocity`'s "unique" twists (other than the obvious) are note blockers and board flipping. Segments may appear in songs that prevent notes under them from being actuated. The player is also able to press `space` at any time to flip the board horizontally, which in turn mirrors all of the notes but leaves note blockers in place. For instance, a note in column `d` after being flipped would be in the `k` column and to score points, `k` would have to be pressed unless the board was flipped back.

## Compatibility
Right now, `Terminal ~ Velocity` is mainly targeting Linux.

Hypothetically, any terminal with reasonable feature support should run `Terminal ~ Velocity` just fine, but the game is tested in KDE's [Konsole](https://apps.kde.org/konsole/), so strong results can be expected there.

`Terminal ~ Velocity` is a [D](https://dlang.org/) application built with [DUB](https://dub.pm/). SDL2 and SDL2 Mixer are used to play audio.

## Contributions
Contributions are welcome!
`Terminal ~ Velocity` is a toy project and is definitely lacking simple features, wide compatibility, and more. And, of course, you can make your own charts for songs!

## Challenges
* A terminal is one of the worst places to implement a rhythm game that, despite this, doesn't have to compromise on core functionality.
  * A smooth framerate, complex charts and mechanics, and consistent performance is able to underly standard 4 key gameplay with normal timing windows (... on certain terminals with certain configurations. Your mileage may vary)
* Input releasing is not possible to detect, meaning standard features like hold notes are impossible to implement, and `Terminal ~ Velocity` needs to focus on only mechanics actuated with a key press.
* Terminals do not generally prioritize things like vsync, low input latency, and smooth framerates.
  * Precise input timing is achieved via believing really hard and frequently polling.

## Charting
`Terminal ~ Velocity`'s charting format is designed to be edited in a text editor manually because that seemed like the simplest viable option. Instead of boring documentation, here's an example. Of course, all of the songs in the game by default are also reasonable examples.

`my-cool-song.tvs`:
```
; Anything after a semicolon is a comment and ignored

; Terminal ~ Velocity looks for an mp3 file with the same name in the same folder as the provided .tvs

; --- Header ---

	; Song display name
name=My Cool Song
	; Song artist name
artist=My Favorite Artist
	; Millisecond offset for the start of music
start=1460
	; Initial BPM of your song
bpm=120

	; Optionally, skip to a millisecond offset in the song
	; Useful while creating a song, but not recommended for finished songs
skip=1000

; --- Body ---

	; A line with "/[number]" sets the amount of notes per measure
	; In this case, 4 beats per measure
/4

	; "m=" defines a comma separated list of notes in the measure
	; Spaces and placeholder characters like "-" are ignored
	; A note is one of d, f, j, or k
m= d, -, f, -

	; Chords are simply defining multiple notes together
	; Order doesn't matter, each note this measure is the same thing
m= df, fd, d-f, -fd-

	; "tempo=" defines a new bpm starting where a new measure would begin
bpm=150

	; /8 means that twice the notes will now happen in the same span of time and need to be defined
	; This measure is the same as the first but at a higher bpm
/8
m= d, -, -, -,   f, -, -, -

	; Column blockers are started with `[` and ended with `]`
	; `d [fj` would have a normal d note and start blockers in the f and j columns
	; `[f ]j` would start a blocker in the f column and end a blocker in the j column
m= d [fj, -, d, ]f,   d, -, -, ]j
```