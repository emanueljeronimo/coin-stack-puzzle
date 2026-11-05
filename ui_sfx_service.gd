extends RefCounted

const BUTTON_SFX_PATH := "res://musica/sonido-boton.mp3"
const COIN_SELECT_SFX_PATH := "res://musica/sonido-giro.wav"
const COIN_PLACE_SFX_PATH := "res://musica/sonido-colocar.wav"
const COIN_SFX_PATH := COIN_PLACE_SFX_PATH
const FUSION_SFX_PATH := "res://musica/sonido-clin.wav"
const LEVEL_UP_SFX_PATH := "res://musica/subir-nivel.mp3"
const CARD_FLICK_GAP_SEC := 0.045
const CARD_FLICK_MAX := 10

static func should_play_button(sounds_enabled: bool, has_player: bool) -> bool:
	return sounds_enabled and has_player

static func apply_oneshot_stream(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

static func card_flick_count(coin_count: int) -> int:
	return clampi(coin_count, 1, CARD_FLICK_MAX)

static func card_flick_delay(index: int) -> float:
	return maxf(float(index), 0.0) * CARD_FLICK_GAP_SEC
