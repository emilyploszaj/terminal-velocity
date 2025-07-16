import core.sync.mutex;
import core.thread;
import core.time;

import app;

struct Input {
	enum Type {
		Char,
		Move,
		Key,
	}
	Type type;
	char c;
	ulong time;

	int getXOff() {
		if (type == Type.Move) {
			if (c == 'a') {
				return -1;
			} else if (c == 'd') {
				return 1;
			}
		}
		return 0;
	}

	int getYOff() {
		if (type == Type.Move) {
			if (c == 'w') {
				return -1;
			} else if (c == 's') {
				return 1;
			}
		}
		return 0;
	}
}

private shared Mutex inputMutex;
private shared Input[] input;

void initInput() {
	inputMutex = new shared Mutex();
	new Thread({
		inputLoop();
	}).start();
}

Input[] getInput() {
	inputMutex.lock();
	Input[] ret = cast(Input[]) input[];
	input.length = 0;
	inputMutex.unlock();
	return ret;
}

void inputLoop() {
	import std.stdio;
	string esc;
	char[1] buf;
	while (true) {
		char[] slice = stdin.rawRead(buf);
		char c = slice[0];
		if (esc.length != 0 || c == '\033') {
			esc ~= c;
			if (esc == "\033[A") {
				addInput(Input.Type.Move, 'w');
			} else if (esc == "\033[B") {
				addInput(Input.Type.Move, 's');
			} else if (esc == "\033[C") {
				addInput(Input.Type.Move, 'd');
			} else if (esc == "\033[D") {
				addInput(Input.Type.Move, 'a');
			} else if (esc == "\033[E") {
				addInput(Input.Type.Key, 'e');
			} else {
				continue;
			}
			esc.length = 0;
		} else {
			addInput(Input.Type.Char, c);
		}
	}
}

void addInput(Input.Type type, char c) {
	inputMutex.lock();
	input ~= Input(type, c, MonoTime.currTime.ticks.ticksToNSecs() / 1_000_000);
	inputMutex.unlock();
}
