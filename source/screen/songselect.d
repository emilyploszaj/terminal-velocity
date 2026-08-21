module screen.songselect;

import std.algorithm;
import std.conv;
import std.file;
import std.math;
import std.string;
import std.traits;

import app;
import input;
import parser;
import screen.screen;
import screen.game;
import screen.menu;

class SongSelectScreen : Screen {
	Song[] options;
	int selectedOption = 0;

	this() {
		foreach (string name; dirEntries("songs", SpanMode.depth)) {
			if (name.endsWith(".tvs") && isFile(name)) {
				options ~= parseSong(name, 0);
			}
		}
	}

	override void render(TermSize size) {
		int width = size.cols;
		int height = size.rows;
		print("\033[2J"); // Erase screen
		
		print(color(32) ~ "terminal ~ velocity" ~ reset(), width / 2 - 9, 0);

		drawSongList(0, 0, width - 40, height);

		drawSongInfo(options[selectedOption], width - 40, 0, 40, height);
	}

	void drawSongList(int x, int y, int width, int height) {
		for (int i = 0; i < options.length; i++) {
			Song song = options[i];
			bool selected = i == selectedOption;
			string style = "";
			if (selected) {
				style = color(34);
			}
			int sy = y + i * 7 + 2;
			int sx = x + width / 2;
			printCenteredBigString(song.name, sx, sy, style);
			print(style ~ song.artist, sx - 20, sy + 4);
			print(reset());
		}
	}

	void drawSongInfo(Song song, int x, int y, int width, int height) {
		print(color(32) ~ "Song:     ", x + 1, y + 1);
		print(reset() ~ song.name);
		print(color(32) ~ "Artist:   ", x + 1, y + 3);
		print(reset() ~ song.artist);
		print(color(32) ~ "Charting: ", x + 1, y + 5);
		print(reset() ~ "Emi");
		print(color(32) ~ "Length:   ", x + 1, y + 9);
		ulong seconds = song.notes[$ - 1].getEnd() / 1000;
		string duration =
			("0" ~ (seconds / 60).to!string)[$ - 2..$] ~ ":" ~
			("0" ~ (seconds % 60).to!string)[$ - 2..$];
		print(reset() ~ duration);
		print(color(32) ~ "Notes:    ", x + 1, y + 11);
		print(reset() ~ song.notes.length.to!string);
	}

	override void input(Input input) {
		if (input.type == Input.Type.Move) {
			selectedOption = clamp(selectedOption + input.getYOff(), 0, cast(int) options.length - 1);
		} else if (input.type == Input.Type.Char) {
			if (input.c == ' ' || input.c == '\n') {
				setScreen(new GameScreen(this, options[selectedOption]));
			} else if (input.c == '\033') {
				setScreen(new MenuScreen());
			}
		}
	}
}
