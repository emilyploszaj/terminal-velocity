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
import sound;

void main() {
	initScreen();
	initSDL();
	initInput();
	
	termios raw;
	tcgetattr(STDIN_FILENO, &raw);
	raw.c_lflag &= ~(ECHO | ICANON);
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

	while(true) {
		if (pollSDL()) {
			break;
		}
		runInput();
		renderScreen();
		Thread.sleep(dur!"msecs"(12));
	}
	import core.stdc.stdlib;
	exit(0);
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
