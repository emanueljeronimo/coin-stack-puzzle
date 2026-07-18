extends SceneTree

const StackScript = preload("res://stack.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_stack_flow test ===")
	await _test_move_block_and_fuse_result()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _new_stack() -> Node:
	var s: Node = StackScript.new()
	root.add_child(s)
	return s

func _fill_stack(stack: Node, value: int, count: int) -> void:
	for _i in range(count):
		stack.push(value, false)

func _free_stacks(stacks: Array) -> void:
	for s in stacks:
		if s != null and is_instance_valid(s):
			s.queue_free()

func _test_move_block_and_fuse_result() -> void:
	var src := _new_stack()
	var dst := _new_stack()
	_fill_stack(src, 2, 10)

	var moved := int(src.move_top_block_to(dst))
	if moved != 10:
		_fail("move_full_homogeneous_block", str(moved))
		_free_stacks([src, dst])
		return

	await create_timer(0.8).timeout
	if int(dst.coins.size()) != 10 or not dst.is_ready_to_fuse():
		_fail("destination_ready_to_fuse", "coins=%d" % int(dst.coins.size()))
		_free_stacks([src, dst])
		return

	var fused := int(dst.remove_all_and_fuse())
	if fused != 3:
		_fail("fused_value", str(fused))
		_free_stacks([src, dst])
		return
	dst.push(fused, false)
	if int(dst.top_value()) != 3 or int(dst.coins.size()) != 1:
		_fail("post_fuse_state", str(dst.coins))
		_free_stacks([src, dst])
		return

	_ok("move_block_and_fuse_result")
	_free_stacks([src, dst])
