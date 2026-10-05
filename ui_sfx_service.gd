extends RefCounted

const BUTTON_SFX_PATH := "res://musica/sonido-boton.mp3"
const COIN_SFX_PATH := "res://musica/sonido-ficha-2.mp3"
const COIN_PITCH_MIN := 0.62
const COIN_STRETCH_PER_EXTRA := 0.10

static func should_play_button(sounds_enabled: bool, has_player: bool) -> bool:
	return sounds_enabled and has_player

static func apply_oneshot_stream(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false

static func coin_sfx_pitch(coin_count: int) -> float:
	var n: int = maxi(1, coin_count)
	var stretch: float = 1.0 + float(n - 1) * COIN_STRETCH_PER_EXTRA
	return clampf(1.0 / stretch, COIN_PITCH_MIN, 1.0)


