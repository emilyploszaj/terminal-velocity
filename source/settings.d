import std.conv;
import std.file;
import std.string;

private enum string SETTINGS_FILE = "settings.ini";

class Settings {
	static int frameDuration = 12;
	static int volume = 10;
	static bool downscroll = true;
}

void writeSettings() {
	string settings;
	settings ~= "[terminal-velocity]";
	settings ~= "frame-duration = " ~ Settings.frameDuration.to!string ~ "\n";
	settings ~= "volume = " ~ Settings.volume.to!string ~ "\n";
	settings ~= "downscroll = " ~ Settings.downscroll.to!string ~ "\n";
	write(SETTINGS_FILE, settings);
}

void readSettings() {
	try {
		if (exists(SETTINGS_FILE)) {
			foreach (string line; (cast(string) read(SETTINGS_FILE)).split('\n')) {
				try {
					string[] parts = line.split('=');
					if (parts.length <= 1) {
						continue;
					}
					string key = parts[0].strip();
					string value = parts[1].strip();
					if (key == "frame-duration") {
						Settings.frameDuration = value.to!int;
					} else if (key == "volume") {
						Settings.volume = value.to!int;
					} else if (key == "downscroll") {
						Settings.downscroll = value.to!bool;
					}
				} catch (Exception e) {
				}
			}
		}
	} catch (Exception e) {
	}
}
