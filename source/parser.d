import std.algorithm;
import std.conv;
import std.string;
import std.file;

struct Song {
	Note[] notes;
	string audioFile;
	string name;
	string artist;
	ulong skip;
}

abstract class Note {

	abstract @property ulong getStart();

	abstract @property ulong getEnd();
}

class NormalNote : Note {
	ulong time;
	uint col;

	this(ulong time, uint col) {
		this.time = time;
		this.col = col;
	}

	override @property ulong getStart() {
		return time;
	}

	override @property ulong getEnd() {
		return time;
	}
}

class BlockingNote: Note {
	ulong start, end;
	uint col;

	this(ulong start, ulong end, uint col) {
		this.start = start;
		this.end = end;
		this.col = col;
	}

	override @property ulong getStart() {
		return start;
	}

	override @property ulong getEnd() {
		return end;
	}
}

Song parseSong(string file, long offset) {
	string song = cast(string) read(file);
	string audioFile = file[0..$-4] ~ ".mp3";
	uint[char] colMap = [
		'd': 0,
		'f': 1,
		'j': 2,
		'k': 3,
	];

	ulong start = 0;
	ulong anchor = 0;
	ulong skip = 0;
	if (offset == 0) {
		start += 1000;
	}
	uint bpm = 120;
	uint measure = 0;
	uint measureSplit = 4;
	Note[] notes;
	string name = "";
	string artist = "";
	BlockingNote[4] currentBlocks;
	foreach (string line; song.split("\n")) {
		line = line.strip();
		if (line.countUntil(";") != -1) {
			line = line.split(";")[0].strip();
		}
		if (line.length == 0) {
			continue;
		}
		if (line.startsWith("name=")) {
			name = line.split("=")[1];
		} else if (line.startsWith("artist=")) {
			artist = line.split("=")[1];
		} else if (line.startsWith("bpm=")) {
			bpm = line.split("=")[1].to!int;
		} else if (line.startsWith("start=")) {
			start += line.split("=")[1].to!int;
			anchor = start;
		} else if (line.startsWith("skip=")) {
			skip = line.split("=")[1].to!int;
		} else if (line.startsWith("tempo=")) {
			anchor = getTime(anchor, bpm, measure, measureSplit, 0);
			bpm = line.split("=")[1].to!int;
			measure = 0;
		} else if (line.startsWith("/")) {
			measureSplit = line[1..$].to!int;
		} else if (line.startsWith("m=")) {
			string[] parts = line[2..$].split(",");
			if (parts.length != measureSplit) {
				throw new Exception("Expected " ~ measureSplit.to!string ~ " notes, found " ~ parts.length.to!string);
			}
			for (size_t i = 0; i < parts.length; i++) {
				string part = parts[i];
				ulong time = getTime(anchor, bpm, measure, measureSplit, i);
				if (time < offset) {
					break;
				}
				time -= offset;
				uint mode = 0;
				Note[] batch;
				foreach (char c; part.strip()) {
					if (c == '[') {
						mode = 1;
					} else if (c == ']') {
						mode = 2;
					}
					if (c in colMap) {
						int col = colMap[c];
						if (mode == 0) {
							batch ~= new NormalNote(time, col);
						} else if (mode == 1) {
							if (currentBlocks[col] !is null) {
								throw new Exception("Blocker in col " ~ col.to!string ~ " already exists and hasn't been ended");
							}
							BlockingNote bn = new BlockingNote(time, time, col);
							currentBlocks[col] = bn;
							batch = bn ~ batch;
						} else if (mode == 2) {
							if (currentBlocks[col] is null) {
								throw new Exception("No blocker exists in col " ~ col.to!string ~ " to end");
							}
							currentBlocks[col].end = time;
							currentBlocks[col] = null;
						}
					}
				}
				notes ~= batch;
			}
			measure++;
		}
	}
	for (int i = 0; i < 4; i++) {
		if (currentBlocks[i] !is null) {
			throw new Exception("Blocker in col " ~ i.to!string ~ " was never ended");
		}
	}
	return Song(notes, audioFile, name, artist, skip);
}

ulong getTime(ulong anchor, ulong bpm, ulong measure, ulong measureSplit, ulong note) {
	return anchor + (measure * measureSplit + note) * 1000L * 60 / bpm * 4 / measureSplit;
}
