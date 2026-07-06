extends Node

## Cola de destino para la escena Loading.tscn (cambios de escena con barra de progreso).
const LOADING_SCENE_PATH := "res://Loading.tscn"
const DEFAULT_BOOT_SCENE_PATH := "res://Home.tscn"

var pending_scene_path: String = ""
var pending_message: String = "Cargando"


func go_to(scene_path: String, message: String = "Cargando") -> void:
	pending_scene_path = scene_path
	pending_message = message
	get_tree().change_scene_to_file(LOADING_SCENE_PATH)


func consume_pending_scene() -> String:
	var path: String = pending_scene_path if not pending_scene_path.is_empty() else DEFAULT_BOOT_SCENE_PATH
	pending_scene_path = ""
	return path


func consume_pending_message() -> String:
	var msg: String = pending_message
	pending_message = "Cargando"
	return msg
