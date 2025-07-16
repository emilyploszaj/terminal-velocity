import std.string;

import bindbc.sdl;

import parser;

Mix_Music* music;

void initSDL() {
	loadSDL();
	loadSDLMixer();
	SDL_Init(SDL_INIT_AUDIO);
	Mix_Init(MIX_INIT_MP3);
	Mix_OpenAudio(44100, AUDIO_S16SYS, 2, 4096);
}

void initMusic(Song song) {
	Mix_FreeMusic(music);
	music = Mix_LoadMUS(song.audioFile.toStringz());
}

void playMusic() {
	Mix_VolumeMusic(MIX_MAX_VOLUME / 2);
	Mix_PlayMusic(music, 0);
}

bool pollSDL() {
	SDL_Event e;
	while (SDL_PollEvent(&e) != 0){
		if (e.type == SDL_QUIT) {
			Mix_FreeMusic(music);
			SDL_Quit();
			return true;
		}
	}
	return false;
}
