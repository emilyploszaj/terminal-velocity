module screen.game;

import std.conv;
import std.math;
import std.traits;

import app;
import input;
import parser;
import screen.screen;
import settings;
import sound;

ulong[4] lastPress;
long lastJudgement = 0;
ulong[5] judgementCounts;

long cumulativeAccuracy = 0;
long objectsHit = 0;
long totalScore = 0;
long maxScore = 0;
enum ulong SCROLL_TIME = 700;

struct Judgement {
	size_t index;
	ulong timing;
	ulong score;
	uint color;
	string name;
}

enum ulong MAX_JUDGEMENT = 200;
enum Judgements : Judgement {
	Perfect = Judgement(0, 20,  100, 123, "Perfect"),
	Great   = Judgement(1, 50,  95,  27,  " Great "),
	Good    = Judgement(2, 100, 70,  69,  "  Good "),
	Bad     = Judgement(3, 150, 40,  214, "  Bad  "),
	Miss    = Judgement(4, 200, 0,   125, "  Miss "),
}

class LiveNote {
	Note note;
	bool alive = true;

	this(Note note) {
		this.note = note;
	}
}

class GameScreen : Screen {
	ulong start;
	Song song;
	LiveNote[] liveNotes;
	size_t nextProcess = 0;
	bool musicStarted = false;

	this(Song song) {
		this.song = song;
		initMusic(song);
		start = curMsecs();
	}

	override void render(TermSize size) {
		updateLive();
		if (!musicStarted && curMsecs() - start > 1000) {
			start = curMsecs() - 1000;
			playMusic();
			musicStarted = true;
		}

		int width = size.cols;
		int height = size.rows;
		print("\033[2J"); // Erase screen
		ulong time = curMsecs() - start;
		print(color(32) ~ "terminal ~ velocity" ~ reset(), width / 2 - 9, Settings.downscroll ? 0 : height - 1);

		print("\033[1;34m" ~ song.name ~ reset(), width / 2 - 48, 3);
		print("\033[2;32m" ~ song.artist ~ reset(), width / 2 - 48, 5);

		uint c0x = width / 2 - 10 * 2 + 3;

		int[] rowColors = [
			26, 51, 45, 33
		];

		double acc = 100;
		long avgErr = 0;
		if (maxScore > 0) {
			acc = totalScore * 10_000 / maxScore / 100.0;
		}
		if (objectsHit > 0) {
			avgErr = (cumulativeAccuracy / objectsHit);
		}

		print("\033[1m" ~ "Accuracy" ~ reset(), width / 2 + 22, height - 11);
		drawBigString(acc.to!string ~ "%", width / 2 + 23, height - 10);
		print("\033[1m" ~ "Score" ~ reset(), width / 2 + 22, height - 6);
		drawBigString(totalScore.to!string, width / 2 + 23, height - 5);
 		print("Avg Error: " ~ avgErr.to!string, 0, 9);

		for (int i = 0; i < 4; i++) {
			int x = i * 10 + c0x - 1;
			if (time - lastPress[i] < 100) {
				string text = bg(61) ~ "       " ~ reset();
				for (int y = 1; y < height - 1; y++) {
					print(text, x, y);
				}
			} else {
				string text = bg(60) ~ "       " ~ reset();
				for (int y = 1; y < height - 1; y++) {
					print(text, x, y);
				}
			}
		}

		foreach (LiveNote live; liveNotes) {
			Note note = live.note;
			int x = note.col * 10 + c0x;
			long diff;
			if (time > note.time) {
				continue;
			} else {
				diff = cast(long) (note.time - time);
			}
			int y = cast(int) (diff * height / SCROLL_TIME);
			if (Settings.downscroll) {
				y = height - y;
			}
			if (y >= 0 && y < height) {
				print(bg(255) ~ fg(rowColors[note.col]));
				if (!live.alive) {
					print("  *  ", x, y);
				} else {
					print("[---]", x, y);
				}
				print(reset());
			}
		}

		for (int i = 0; i < 4; i++) {
			int x = i * 10 + c0x - 1;
			int y = Settings.downscroll ? height - 1 : 0;
			string text = "[     ]";
			if (time - lastPress[i] < 100) {
				text = "[xxxxx]";
			}
			print(text, x, y);
		}

		foreach (Judgement j; EnumMembers!Judgements) {
			if (abs(lastJudgement) <= j.timing || j == Judgements.Miss) {
				int y = Settings.downscroll ? 12 : height - 13;
				print(bg(j.color) ~ fg(232), width / 2 - 3, y);
				print(lastJudgement.to!string.padTo(7));
				print(j.name.padTo(9) ~ reset(), width / 2 - 4, y - 2);
				break;
			}
		}

		for (int i = 0; i < 5; i++) {
			Judgement[] judgements = [Judgements.Perfect, Judgements.Great, Judgements.Good, Judgements.Bad, Judgements.Miss];
			Judgement j = judgements[i];
			print(bg(j.color) ~ fg(232) ~ j.name ~ reset(), width / 2 - 50, height - 10 + i * 2);
			print(judgementCounts[i].to!string, width / 2 - 42, height - 10 + i * 2);
		}
	}

	void updateLive() {
		ulong time = curMsecs() - start;
		while (nextProcess < song.notes.length) {
			Note note = song.notes[nextProcess];
			if (note.time - time < 2_000) {
				liveNotes ~= new LiveNote(note);
				nextProcess++;
				continue;
			}
			break;
		}
		size_t firstValid = 0;
		while (firstValid < liveNotes.length) {
			LiveNote live = liveNotes[firstValid];
			if (time > live.note.time && time - live.note.time > MAX_JUDGEMENT) {
				if (live.alive) {
					score(live, Judgements.Miss, 9999);
				}
				firstValid++;
				continue;
			}
			break;
		}
		if (firstValid > 0) {
			liveNotes = liveNotes[firstValid..$];
		}
	}

	override void input(Input input) {
		int[char] cols = [
			'd': 0,
			'f': 1,
			'j': 2,
			'k': 3,
		];
		if (input.type == Input.Type.Char) {
			if (input.c in cols) {
				int c = cols[input.c];
				ulong time = input.time - start;
				lastPress[c] = time;
				press(c, time);
			}
		}
	}

	void press(uint col, ulong time) {
		lastJudgement = 999;
		LiveNote closest = null;
		long closestDiff = 9999999999;
		foreach (LiveNote live; liveNotes) {
			if (live.note.col == col && live.alive) {
				long diff = longDiff(live.note.time, time);
				if (abs(diff) < abs(closestDiff)) {
					closest = live;
					closestDiff = diff;
				}
			}
		}
		if (closest !is null) {
			if (abs(closestDiff) < MAX_JUDGEMENT) {
				closest.alive = false;
				lastJudgement = closestDiff;
				long absDiff = abs(closestDiff);
				foreach (Judgement j; EnumMembers!Judgements) {
					if (absDiff <= j.timing) {
						score(closest, j, closestDiff);
						return;
					}
				}
				score(closest, Judgements.Miss, closestDiff);
			}
		}
	}

	void score(LiveNote note, Judgement j, long acc) {
		note.alive = false;
		if (abs(acc) < 9999) {
			cumulativeAccuracy += acc;
			objectsHit++;
		}
		totalScore += j.score;
		judgementCounts[j.index]++;
		maxScore += 100;
	}
}
