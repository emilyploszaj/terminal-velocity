module screen.screen;

import std.conv;
import std.stdio;
import std.string;
import std.uni;

import input;
import screen.menu;
import screen.game;

private string buffer;
Screen currentScreen;

BigLetter[char] bigFont;

class Screen {
	abstract void render(TermSize size);

	void input(Input input) {
	}
}

void initScreen() {
	constructBigFont;
	currentScreen = new MenuScreen();
}

void renderScreen() {
	buffer = "";

	TermSize size = getSize();
	currentScreen.render(size);

	buffer ~= pos(0, 0);
	buffer ~= "\n";
	import core.stdc.stdio;
	printf(toStringz(buffer));
}

void print(string text) {
	buffer ~= text;
}

void print(string text, uint x, uint y) {
	print(pos(x, y) ~ text);
}

string pos(uint x, uint y) {
	x++;
	y++;
	return "\033[" ~ y.to!string ~ ";" ~ x.to!string ~ "H";
}

string color(int c) {
	return "\033[1;" ~ c.to!string ~ "m";
}

string fg(int c) {
	return "\033[38;5;" ~ c.to!string ~ "m";
}

string bg(int c) {
	return "\033[48;5;" ~ c.to!string ~ "m";
}

string reset() {
	return "\033[0m";
}

void constructBigFont() {

	void addMap(string[] lines, string map) {
		if (lines.length != 3 || lines[0].length != lines[1].length || lines[1].length != lines[2].length) {
			throw new Exception("Improper fontmap format!");
		}
		int currentLetter = 0;
		int start = 0;
		for (int x = 0; x < lines[0].length; x++) {
			if (lines[0][x] == ' ' && lines[1][x] == ' ' && lines[2][x] == ' ') {
				char c = map[currentLetter];
				int width = x - start;
				if (width > 0) {
					BigLetter letter = BigLetter(c, [lines[0][start..x], lines[1][start..x], lines[2][start..x]], width);
					bigFont[c] = letter;
					start = x + 1;
					currentLetter++;
				} else {
					start++;
				}
			}
		}
		if (currentLetter != map.length) {
			throw new Exception("Improper fontmap format!");
		}
	}

	bigFont[' '] = BigLetter(' ', ["  ", "  ", "  "], 2);

	addMap(
		[
			r"  _    __   __  __   __  __  __      ___ ___                      __   __   __   __   __  ___                             ___ ",
			r" /_\  |__) /   |  \ |_  |_  / _ |__|  |   |  |_/ |   |\  /| |\ | /  \ |__) /  \ |__) (__   |  |   | \  / \  /\  / \_/ \_/  _/ ",
			r"/   \ |__) \__ |__/ |__ |   \_/ |  | _|_ \/  | \ |__ | \/ | | \| \__/ |    \__\ |  \  __)  |  |__/   \/   \/  \/  / \  |  /__ ",
		],
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	);
	addMap(
		[
			r"   __  __        __  __  ___  __   __   __  ",
			r"/|  _)  _) |__| |_  /__    / (__) (__\ /  \ ",
			r" | /__ __)    | __) \__)  /  (__)  __/ \__/ ",
		],
		"1234567890"
	);
	addMap(
		[
			r"|\ /|    ()/         ",
			r"| ? |     /  ___ /\/ ",
			r"|/ \| () /()         ",
		],
		"\0.%-~"
	);
	/* 
	addMap(
		[
			r" _       _      _   _  _                _                  _   _        _                           __ ",
			r" _| |_  /   _| /_) /_ (_) |_  _^  _^ |/  |   _ _   _   _  |_) (_|  |/\ (_  |- |  | |  | |   | \/ \/  / ",
			r"(_) |_) \_ (_| \__ |   _/ | |  |_ _/ |\  |_ | | | | | (_) |     |_ |    _) \_ |_/   \/  \_|_| /\ /  /_ ",
		],
		"abcdefghijklmnopqrstuvwxyz"
	);
	*/
}

struct BigLetter {
	char c;
	string[] rows;
	int width;
}

int measureBigString(string s) {
	s = s.toUpper();
	int width = cast(int) s.length - 1;
	foreach (char c; s) {
		if (c !in bigFont) {
			c = '\0';
		}
		width += bigFont[c].width;
	}
	return width;
}

void printTitledBigString(string title, string text, uint x, uint y) {
	print("\033[1m" ~ title ~ reset(), x, y);
	printBigString(text, x + 1, y + 1);
}

void printCenteredBigString(string s, uint x, uint y, string style = "") {
	printBigString(s, x - measureBigString(s) / 2, y, style);
}

void printBigString(string s, uint x, uint y, string style = "") {
	s = s.toUpper();
	foreach (char c; s) {
		x += printBigChar(c, x, y, style) + 1;
	}
}

int printBigChar(char c, uint x, uint y, string style) {
	if (c !in bigFont) {
		c = '\0';
	}
	BigLetter letter = bigFont[c];
	int width = letter.width;
	buffer ~= "\033[1;37m" ~ style;
	buffer ~= pos(x, y + 0) ~ letter.rows[0] ~ " ";
	buffer ~= pos(x, y + 1) ~ letter.rows[1] ~ " ";
	buffer ~= pos(x, y + 2) ~ letter.rows[2] ~ " ";
	buffer ~= reset();
	return width;
}

string padTo(string s, uint size) {
	while (s.length < size) {
		s = " " ~ s ~ " ";
	}
	if (s.length > size) {
		s = s[0..size];
	}
	return s;
}

struct winsize {

	ushort ws_row;
	ushort ws_col;
	ushort ws_xpixel;
	ushort ws_ypixel;

}

enum uint TIOCGWINSZ = 0x5413;
extern(C) int ioctl(int, int, ...);

TermSize getSize() {

	winsize ws;
	ioctl(stdout.fileno, TIOCGWINSZ, &ws);
	return TermSize(ws.ws_col, ws.ws_row);
}

struct TermSize {
	uint cols, rows;
}
