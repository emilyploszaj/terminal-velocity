module screen.game;

import std.algorithm;
import std.conv;
import std.math;
import std.traits;
import std.uni;

import app;
import input;
import parser;
import screen.screen;
import settings;
import sound;

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

class SongTime {
	private long[] progressHistory;
	ulong start;
	long musicOffset = 0;

	public @property ulong now() {
		return curMsecs() - start + musicOffset;
	}

	public void addSoundOffset(long progress) {
		if (curMsecs() - start < 1000) {
			return;
		}
		enum PERIOD = 10;
		if (progress > 0) {
			progressHistory ~= progress - now;
			if (progressHistory.length > PERIOD) {
				progressHistory = progressHistory[1..$];
				long sum;
				foreach (p; progressHistory) {
					sum += p;
				}
				musicOffset = 1000 + sum / PERIOD;
			}
		}
	}
}

class GameScreen : Screen {
	SongTime songTime = new SongTime();
	Screen previousScreen;
	Song song;
	LiveNote[] liveNotes;
	size_t nextProcess = 0;
	bool musicStarted = false;

	bool flipped = false;
	long lastFlip = -9999;
	ulong[4] lastPress;
	long lastJudgement = 0;
	ulong[5] judgementCounts;

	long cumulativeAccuracy = 0;
	long objectsHit = 0;
	long totalScore = 0;
	long maxScore = 0;
	enum ulong SCROLL_TIME = 700;

	this(Screen previousScreen, Song song) {
		this.previousScreen = previousScreen;
		this.song = song;
		initMusic(song);
		songTime.start = curMsecs();
	}

	override void render(TermSize size) {
		updateLive();
		if (!musicStarted && curMsecs() - songTime.start > 1000) {
			songTime.start = curMsecs() - 1000 - song.skip;
			playMusic(song.skip);
			musicStarted = true;
		}

		int width = size.cols;
		int height = size.rows;
		print("\033[2J"); // Erase screen
		ulong time = curMsecs() - songTime.start;
		print(color(32) ~ "terminal ~ velocity" ~ reset(), width / 2 - 9, Settings.downscroll ? 0 : height - 1);

		string minutes = ("0" ~ ((time / 1000) / 60).to!string)[$ - 2..$];
		string seconds = ("0" ~ ((time / 1000) % 60).to!string)[$ - 2..$];
		print("Time: " ~ minutes ~ ":" ~ seconds, 0, 0);

		printTitledBigString("Song", song.name.toUpper(), width / 2 + 22, 5);
		printTitledBigString("Artist", song.artist.toUpper(),  width / 2 + 22, 10);

		int[] bgRowColors = [
			231, 231, 231, 231
		];
		int[] rowColors = [
			99, 99, 79, 79
		];
		int squish = flipSquish();
		int colWidth = 7;

		if (squish < 5) {
			colWidth = 7;
		} else if (squish < 35) {
			colWidth = 6;
		} else if (squish < 55) {
			colWidth = 5;
		} else if (squish < 70) {
			colWidth = 4;
		} else if (squish < 80) {
			colWidth = 3;
		} else if (squish < 90) {
			colWidth = 2;
		} else {
			colWidth = 1;
		}

		int[int] colOccupation;

		double acc = 100;
		long avgErr = 0;
		if (maxScore > 0) {
			acc = totalScore * 10_000 / maxScore / 100.0;
		}
		if (objectsHit > 0) {
			avgErr = (cumulativeAccuracy / objectsHit);
		}

		printTitledBigString("Accuracy", acc.to!string ~ "%", width / 2 + 22, height - 16);
		printTitledBigString("Score", totalScore.to!string, width / 2 + 22, height - 11);
		printTitledBigString("Average Error", avgErr.to!string, width / 2 + 22, height - 6);

		for (int i = 0; i < 4; i++) {
			int x = colX(size, i) - colWidth / 2;
			int col = i;
			if (flipped) {
				col = 3 - col;
			}
			string text = "";
			int color;
			if (lastPress[col] > 0 && time - lastPress[col] < 100) {
				text = bg(61);
				color = 61;
			} else {
				text = bg(60);
				color = 60;
			}
			text ~= "       "[0..colWidth];
			text ~= reset();
			for (int y = 1; y < height - 1; y++) {
				print(text, x, y);
			}
			for (int xo = 0; xo < colWidth; xo++) {
				colOccupation[x + xo] = color;
			}
		}

		foreach (LiveNote live; liveNotes) {
			if (time > live.note.getEnd()) {
				continue;
			}
			if (cast(NormalNote) live.note !is null) {
				NormalNote note = cast(NormalNote) live.note;
				int x = colX(size, note.col);
				int y = getPosFromTime(time, height, note.time);
				if (y >= 0 && y < height) {
					print(bg(bgRowColors[note.col]) ~ fg(rowColors[note.col]));
					if (!live.alive) {
						int pad = (colWidth - 2) / 2;
						if (pad < 0) {
							pad = 0;
						}
						string padding = "   "[0..pad];
						print(padding ~ "*" ~ padding, x - pad, y);
					} else {
						int xo = x - colWidth / 2;
						if (colWidth >= 2) {
							print("█" ~ "🬋🬋🬋🬋🬋"[0..(colWidth - 2) * 4] ~ "█", xo, y);
						} else if (colWidth >= 6) {
							print("|", x, y);
						}
					}
					print(reset());
				}
			} else if (cast(BlockingNote) live.note !is null) {
				BlockingNote note = cast(BlockingNote) live.note;
				int x = rawColX(size, note.col, false);
				int startY = getPosFromTime(time, height, note.start).clamp(0, height);
				int endY = getPosFromTime(time, height, note.end).clamp(0, height);
				if (endY < startY) {
					int temp = startY;
					startY = endY;
					endY = temp;
				} else if (startY == endY) {
					continue;
				}
				startY = (startY - 1).clamp(0, height);
				endY = (endY + 1).clamp(0, height);
				for (int y = startY; y <= endY; y++) {
					print("", x - 4, y);
					for (int xo = 0; xo < 9; xo++) {
						int rx = x - 4 + xo;
						if (rx in colOccupation && colOccupation[rx] != 0) {
							print(bg(colOccupation[rx]) ~ fg(217) ~ "░");
						} else {
							print(reset() ~ fg(217) ~ "░");
						}
					}
				}
			}
		}

		print(reset());

		for (int i = 0; i < 4; i++) {
			int col = i;
			if (flipped) {
				col = 3 - col;
			}
			int x = rawColX(size, col, true) - 3;
			int y = Settings.downscroll ? height - 1 : 0;
			string text = "[     ]";
			if (lastPress[i] > 0 && time - lastPress[i] < 100) {
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

	int getPosFromTime(ulong time, int height, ulong noteTime) {
		long diff = cast(long) (noteTime - time);
		int y = cast(int) (diff * height / SCROLL_TIME);
		if (Settings.downscroll) {
			y = height - y;
		}
		return y;
	}

	bool isFlipped() {
		enum HALF_FLIP_TIME = 50;
		ulong time = curMsecs() - songTime.start;
		if (time - lastFlip < HALF_FLIP_TIME) {
			return !flipped;
		}
		return flipped;
	}

	int flipSquish() {
		enum HALF_FLIP_TIME = 50;
		ulong time = curMsecs() - songTime.start;
		long off = time - lastFlip;
		if (off < HALF_FLIP_TIME * 2) {
			off = abs(off - HALF_FLIP_TIME);
			return cast(int) (100 - (off * 100 / HALF_FLIP_TIME));
		}
		return 0;
	}

	int colX(TermSize size, int col) {
		if (isFlipped()) {
			col = 3 - col;
		}
		int cx = size.cols / 2;
		int space = 10;
		int squish = flipSquish();
		if (squish < 5) {
			space = 10;
		} else if (squish < 30) {
			space = 9;
		} else if (squish < 50) {
			space = 8;
		} else if (squish < 60) {
			space = 7;
		} else if (squish < 70) {
			space = 6;
		} else if (squish < 78) {
			space = 5;
		} else if (squish < 84) {
			space = 4;
		} else if (squish < 90) {
			space = 3;
		} else {
			space = 1;
		}
		if (col < 2) {
			return cx - (space / 2) - space * (1 - col);
		} else {
			return cx + (space / 2) + space * (col - 2);
		}
	}

	int rawColX(TermSize size, int col, bool doFlip) {
		if (doFlip && isFlipped()) {
			col = 3 - col;
		}
		int cx = size.cols / 2;
		int space = 10;
		if (col < 2) {
			return cx - (space / 2) - space * (1 - col);
		} else {
			return cx + (space / 2) + space * (col - 2);
		}
	}

	void updateLive() {
		ulong time = curMsecs() - songTime.start;
		while (nextProcess < song.notes.length) {
			Note note = song.notes[nextProcess];
			if (time > note.getStart() || note.getStart() - time < 2_000) {
				liveNotes ~= new LiveNote(note);
				nextProcess++;
				continue;
			}
			break;
		}
		size_t firstValid = 0;
		while (firstValid < liveNotes.length) {
			LiveNote live = liveNotes[firstValid];
			if (time > live.note.getEnd() && time - live.note.getEnd() > MAX_JUDGEMENT) {
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
				ulong time = input.time - songTime.start;
				lastPress[c] = time;
				press(c, time);
			} else if (input.c == '\033') {
				stopMusic();
				setScreen(previousScreen);
			} else if (input.c == ' ') {
				flipped = !flipped;
				lastFlip = curMsecs() - songTime.start;
			}
		}
	}

	void press(uint col, ulong time) {
		uint rawCol = col;
		if (flipped) {
			col = 3 - col;
		}
		lastJudgement = 999;
		LiveNote closest = null;
		long closestDiff = 9_999_999_999;
		foreach (LiveNote live; liveNotes) {
			if (cast(NormalNote) live.note !is null) {
				NormalNote note = cast(NormalNote) live.note;
				if (note.col == col && live.alive) {
					long diff = longDiff(note.time, time);
					if (abs(diff) < abs(closestDiff)) {
						closest = live;
						closestDiff = diff;
					}
				}
			}
		}
		if (closest !is null) {
			foreach (LiveNote live; liveNotes) {
				if (cast(BlockingNote) live.note !is null) {
					BlockingNote note = cast(BlockingNote) live.note;
					if (note.col == rawCol) {
						if (closest.note.getStart() >= note.getStart() && closest.note.getStart() <= note.getEnd()) {
							return;
						}
					}
				}
			}
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
		if (cast(NormalNote) note.note !is null) {
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
}
