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

		for (int i = 0; i < options.length; i++) {
			Song song = options[i];
			bool selected = i == selectedOption;
			string style = "";
			if (selected) {
				style = color(34);
			}
			int y = i * 7 + 2;
			int x = width / 2;
			printCenteredBigString(song.name, x, y, style);
			print(style ~ song.artist, x - 20, y + 4);
			print(reset());
		}
	}

	override void input(Input input) {
		if (input.type == Input.Type.Move) {
			selectedOption = clamp(selectedOption + input.getYOff(), 0, cast(int) options.length - 1);
		} else if (input.type == Input.Type.Char) {
			if (input.c == ' ' || input.c == '\n') {
				currentScreen = new GameScreen(this, options[selectedOption]);
			} else if (input.c == '\033') {
				currentScreen = new MenuScreen();
			}
		}
	}
}
