import core.sys.posix.termios;
import core.sys.posix.unistd;
import core.thread;
import core.time;

import std.algorithm;
import std.conv;
import std.math;
import std.stdio;
import std.traits;

import input;
import parser;
import screen.screen;
import settings;
import sound;

bool shouldQuit = false;

int main() {
	readSettings();
	initScreen();
	initSDL();
	initInput();
	
	termios raw;
	tcgetattr(STDIN_FILENO, &raw);
	auto old_c_lflag = raw.c_lflag;
	raw.c_lflag &= ~(ECHO | ICANON);
	//raw.c_cc[VMIN] = 1;
	//raw.c_cc[VTIME] = 0;
	tcsetattr(STDIN_FILENO, TCSANOW, &raw);
	writeln("\u001B[?1049h"); // Alt screen
	writeln("\033[?25l"); // Hide cursor

	while(shouldQuit == false) {
		if (pollSDL()) {
			break;
		}
		runInput();
		renderScreen();
		Thread.sleep(dur!"msecs"(Settings.frameDuration));
	}
	write("\033[?25h"); // Show cursor
	write("\u001B[?1049l\n"); // Restore screen
	foreach (t; Thread.getAll()) {
		t.isDaemon = true;
	}
	deinitSDL();
	raw.c_lflag = old_c_lflag;
	tcsetattr(STDIN_FILENO, TCSANOW, &raw);
	return 0;
}

ulong curMsecs() {
	return MonoTime.currTime.ticks.ticksToNSecs() / 1_000_000;
}

void runInput() {
	import input;
	Input[] inputs = getInput();
	foreach (Input i; inputs) {
		currentScreen.input(i);
	}
}

long longDiff(ulong a, ulong b) {
	if (b > a) {
		return -(cast(long) (b - a));
	} else {
		return cast(long) (a - b);
	}
}
