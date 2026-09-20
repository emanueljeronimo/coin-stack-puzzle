class_name MainFacade
extends RefCounted

var _owner: Node = null

func _init(owner: Node) -> void:
	_owner = owner

func save_and_print() -> void:
	if _owner == null:
		return
	if _owner.has_method("print_status"):
		_owner.call("print_status")
	if _owner.has_method("save_game"):
		_owner.call("save_game")
