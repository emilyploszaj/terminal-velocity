import std.string;

import bindbc.sdl;

import parser;
import settings;

Mix_Music* music;

void initSDL() {
	loadSDL();
	loadSDLMixer();
	SDL_Init(SDL_INIT_AUDIO);
	Mix_Init(MIX_INIT_MP3);
	Mix_OpenAudio(44100, AUDIO_S16SYS, 2, 4096);
}

void deinitSDL() {
	Mix_FreeMusic(music);
	Mix_CloseAudio();
	SDL_Quit();
}

void initMusic(Song song) {
	Mix_FreeMusic(music);
	music = Mix_LoadMUS(song.audioFile.toStringz());
}

void playMusic() {
	Mix_VolumeMusic(MIX_MAX_VOLUME * Settings.volume / 15);
	Mix_PlayMusic(music, 0);
}

void stopMusic() {
	Mix_HaltMusic();
}

bool pollSDL() {
	SDL_Event e;
	while (SDL_PollEvent(&e) != 0){
		if (e.type == SDL_QUIT) {
			return true;
		}
	}
	return false;
}
