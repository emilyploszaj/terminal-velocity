import std.conv;
import std.string;
import std.file;

struct Song {
	Note[] notes;
	string audioFile;
	string name;
	string artist;
}

struct Note {
	ulong time;
	uint col;
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
	if (offset == 0) {
		start += 1000;
	}
	uint bpm = 120;
	uint measure = 0;
	uint measureSplit = 4;
	Note[] notes;
	string name = "";
	string artist = "";
	foreach (string line; song.split("\n")) {
		line = line.strip();
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
		} else if (line.startsWith("/")) {
			measureSplit = line[1..$].to!int;
		} else if (line.startsWith("m=")) {
			string[] parts = line[2..$].split(",");
			if (parts.length != measureSplit) {
				throw new Exception("Expected " ~ measureSplit.to!string ~ " notes, found " ~ parts.length.to!string);
			}
			for (size_t i = 0; i < parts.length; i++) {
				string part = parts[i];
				ulong time = getTime(start, bpm, measure, measureSplit, i);
				if (time < offset) {
					break;
				}
				time -= offset;
				foreach (char c; part.strip()) {
					if (c in colMap) {
						notes ~= Note(time, colMap[c]);
					}
				}
			}
			measure++;
		}
	}
	return Song(notes, audioFile, name, artist);
}

ulong getTime(ulong start, ulong bpm, ulong measure, ulong measureSplit, ulong note) {
	ulong time = start;
	return start + (measure * measureSplit + note) * 1000L * 60 / bpm * 4 / measureSplit;
}
