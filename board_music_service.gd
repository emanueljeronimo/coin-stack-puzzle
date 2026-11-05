extends RefCounted

const TRACK_1 := "1"
const TRACK_2 := "2"
const TRACK_OFF := "off"
const DEFAULT_TRACK := TRACK_1

const TRACK_1_PATH := "res://musica/musica tablero.mp3"
const TRACK_2_PATH := "res://musica/musica-tablero2.mp3"

static func normalize(track_id: String) -> String:
	if track_id == TRACK_2:
		return TRACK_2
	if track_id == TRACK_OFF:
		return TRACK_OFF
	return TRACK_1

static func is_enabled(track_id: String) -> bool:
	return normalize(track_id) != TRACK_OFF

static func path_for(track_id: String) -> String:
	var id := normalize(track_id)
	if id == TRACK_2:
		return TRACK_2_PATH
	if id == TRACK_OFF:
		return ""
	return TRACK_1_PATH

static func button_label(track_id: String) -> String:
	var id := normalize(track_id)
	if id == TRACK_2:
		return "Forest"
	if id == TRACK_OFF:
		return "OFF"
	return "Chill"

static func next_track(track_id: String) -> String:
	var id := normalize(track_id)
	if id == TRACK_1:
		return TRACK_2
	if id == TRACK_2:
		return TRACK_OFF
	return TRACK_1

static func resolve_track(saved_track: String, music_enabled: bool) -> String:
	if not saved_track.is_empty():
		return normalize(saved_track)
	if music_enabled:
		return TRACK_1
	return TRACK_OFF
