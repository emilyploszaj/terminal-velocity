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
	Thread thread =new Thread({
		inputLoop();
	});
	thread.isDaemon = true;
	thread.start();
	import core.sys.posix.fcntl;
	import std.stdio;
	fcntl(stdin.fileno, F_SETFL, fcntl(stdin.fileno, F_GETFL) | O_NONBLOCK);
}

Input[] getInput() {
	inputMutex.lock();
	Input[] ret = cast(Input[]) input[];
	input.length = 0;
	inputMutex.unlock();
	return ret;
}

void inputLoop() {
	ulong escStart = 0;
	string esc;
	char[1] buf;
	while (!shouldQuit) {
		if (escStart != 0 && curMsecs > escStart + 50) {
			if (esc == "\033") {
				addInput(Input.Type.Char, '\033');
			}
			parseEsc(esc);
			esc.length = 0;
			escStart = 0;
		}

		import core.stdc.stdio;
		if (fread(buf.ptr, 1, 1, stdin) == 0) {
			continue;
		}
		char c = buf[0];

		if (esc.length != 0 || c == '\033') {
			if (c == '\033') {
				escStart = curMsecs();
			}
			esc ~= c;
			if (parseEsc(esc)) {
				esc.length = 0;
				escStart = 0;
			}
		} else {
			addInput(Input.Type.Char, c);
		}
	}
}

bool parseEsc(string esc) {
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
		return false;
	}
	return true;
}

void addInput(Input.Type type, char c) {
	inputMutex.lock();
	input ~= Input(type, c, curMsecs());
	inputMutex.unlock();
}
