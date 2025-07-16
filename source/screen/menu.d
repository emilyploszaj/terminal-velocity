module screen.menu;

import std.algorithm;
import std.conv;
import std.math;
import std.traits;

import app;
import input;
import parser;
import screen.screen;
import screen.game;
import screen.songselect;
import settings;

class MenuScreen : Screen {
	Option[] options;
	int selectedOption = 0;

	this() {
		options ~= Option((s) => "Play", (i) {
			if (i == 0) {
				currentScreen = new SongSelectScreen();
			}
		});
		options ~= Option((s) {
			if (s) {
				return ("==============="[0..Settings.volume] ~ "               ")[0..15];
			} else {
				return "Volume";
			}
		}, (i) {
			Settings.volume = clamp(Settings.volume + i, 0, 15);
		});
		options ~= Option((s) {
			return Settings.downscroll ? "Downscroll" : "Upscroll";
		}, (i) {
			Settings.downscroll = !Settings.downscroll;
		});
		options ~= Option((s) => "Quit", (i) {
		});
	}

	override void render(TermSize size) {
		int width = size.cols;
		int height = size.rows;
		print("\033[2J"); // Erase screen
		
		print(color(32) ~ "terminal ~ velocity" ~ reset(), width / 2 - 9, 0);

		for (int i = 0; i < options.length; i++) {
			bool selected = i == selectedOption;
			string text = padTo(options[i].name(selected), 15);
			if (selected) {
				text = "\033[1;34m" ~"[" ~ text ~ "]" ~ reset();
			} else {
				text = " " ~ text ~ " ";
			}
			print(text, width / 2 - 8, i * 2 + 2);
		}
	}

	override void input(Input input) {
		if (input.type == Input.Type.Move) {
			selectedOption = clamp(selectedOption + input.getYOff(), 0, cast(int) options.length - 1);
			int xOff = input.getXOff();
			if (xOff != 0) {
				options[selectedOption].callback(xOff);
			}
		} else if (input.type == Input.Type.Char && (input.c == '\n' || input.c == ' ')) {
			options[selectedOption].callback(0);
		}
	}
}

struct Option {
	string function(bool) name;
	void function(int) callback;
}