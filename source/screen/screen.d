module screen.screen;

import std.conv;
import std.stdio;

import input;
import screen.menu;
import screen.game;

private string buffer;
Screen currentScreen;

class Screen {
	abstract void render(TermSize size);

	void input(Input input) {
	}
}

void initScreen() {
	currentScreen = new MenuScreen();
}

void renderScreen() {
	buffer = "";

	TermSize size = getSize();
	currentScreen.render(size);

	buffer ~= pos(0, 0);
	buffer ~= "\n";
	writeln(buffer);
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

int[] fontWidths = [
	2, 3, 3, 4, 3, 4, 3, 4, 4, 4, 2, 3
];

string[] fontParts = [
	r"   __  __        __  __  ___  __   __   __     ()/ ",
	r"/|  _)  _) |__| |_  /__    / (__) (__\ /  \     /  ", 
	r" | /__ __)    | __) \__)  /  (__)  __/ \__/ () /() ",
];

void drawBigString(string s, uint x, uint y) {
	foreach (char c; s) {
		x += drawBigChar(c, x, y) + 1;
	}
}

int drawBigChar(char c, uint x, uint y) {
	int[char] indices = [
		'1': 0,
		'2': 1,
		'3': 2,
		'4': 3,
		'5': 4,
		'6': 5,
		'7': 6,
		'8': 7,
		'9': 8,
		'0': 9,
		'.': 10,
		'%': 11,
	];
	int index = indices[c];
	int start = 0;
	for (int i = 0; i < index; i++) {
		start += 1 + fontWidths[i];
	}
	int width = fontWidths[index];
	buffer ~= pos(x, y + 0) ~ fontParts[0][start..start + width];
	buffer ~= pos(x, y + 1) ~ fontParts[1][start..start + width];
	buffer ~= pos(x, y + 2) ~ fontParts[2][start..start + width];
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
