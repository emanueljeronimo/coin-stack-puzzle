extends SceneTree

## Stress test headless de caminos que históricamente crasheaban.
## Uso:
##   "Godot_v4.6.1-stable_win64.exe" --headless --path . --script res://tests/crash_stress_test.gd

const StackScript = preload("res://stack.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== CoinStackPuzzle crash stress test ===")
	_test_checkpoint_descriptions()
	_test_buggy_percent_format()
	_test_stack_empty_selection()
	await _test_stack_move_and_fuse_spam()
	await _test_multi_coin_flight()
	_test_level_up_queue_logic()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _checkpoint_description(level: int) -> String:
	const CHECKPOINT_BASE_VALUE := 5
	if level <= 1:
		return ""
	var steps := level - 2
	var v := CHECKPOINT_BASE_VALUE + int(steps / 2)
	if steps % 2 == 0:
		if steps == 0:
			return "Creaste la pila %d" % v
		return "Completaste la pila %d" % (v - 1)
	return "Pila %d: más de la mitad" % v

func _test_checkpoint_descriptions() -> void:
	for level in range(1, 21):
		var text := _checkpoint_description(level)
		var combined := "Nivel %d\n%s" % [level, text]
		if level == 3 and combined.find("Pila 5") < 0:
			_fail("checkpoint_desc_level_3", combined)
			return
	_ok("checkpoint_descriptions_1_to_20")

func _test_buggy_percent_format() -> void:
	## Documenta el formato viejo "50%%" y valida el reemplazo seguro.
	var v := 5
	var safe := "Pila %d: más de la mitad" % v
	var shown := "Nivel %d\n%s" % [3, safe]
	if shown != "Nivel 3\nPila 5: más de la mitad":
		_fail("safe_percent_format", shown)
		return
	# El patrón viejo: si %% no escapa bien, el segundo % rompe el formateo.
	var old_ok := true
	var old_text := ""
	old_text = "Pila %d: más del 50%%" % v
	if old_text.find("%d") >= 0 or old_text.find("%") < 0:
		# Si quedó un %d sin resolver, el format falló.
		old_ok = old_text.find("%d") < 0
	print("  note: old 50%% format => '", old_text, "'")
	if not old_ok:
		_fail("old_percent_format_behavior", old_text)
		return
	_ok("percent_format_safe_and_old_checked")

func _test_stack_empty_selection() -> void:
	var stack: Node = StackScript.new()
	root.add_child(stack)
	stack.set_selected(true)
	stack.set_selected(false)
	stack.set_selected(true, false)
	stack.set_selected(false, false)
	stack.queue_free()
	_ok("empty_stack_selection")

func _test_stack_move_and_fuse_spam() -> void:
	var board := Node2D.new()
	root.add_child(board)
	var a: Node = StackScript.new()
	var b: Node = StackScript.new()
	board.add_child(a)
	board.add_child(b)
	for _i in range(10):
		a.push(3, false)
	if not a.is_ready_to_fuse():
		_fail("fuse_ready", "se esperaba pila homogénea llena")
		board.queue_free()
		return
	a.play_fusion_animation()
	var fused: int = a.remove_all_and_fuse()
	if fused != 4:
		_fail("fuse_value", "esperado 4, got %d" % fused)
		board.queue_free()
		return
	a.push(fused, false)
	for value in range(1, 8):
		for _j in range(6):
			if not a.is_full():
				a.push(value, false)
		while not a.is_empty():
			a.pop()
	for _k in range(5):
		a.push(2, false)
	var moved: int = a.move_top_block_to(b)
	if moved <= 0:
		_fail("move_block", "no movió fichas")
		board.queue_free()
		return
	await create_timer(0.4).timeout
	if a.has_method("kill_all_tweens"):
		a.kill_all_tweens()
		b.kill_all_tweens()
	board.queue_free()
	_ok("move_and_fuse_spam")

func _test_multi_coin_flight() -> void:
	var board := Node2D.new()
	root.add_child(board)
	var src: Node = StackScript.new()
	var dst: Node = StackScript.new()
	board.add_child(src)
	board.add_child(dst)
	for _i in range(8):
		src.push(4, false)
	var moved: int = src.move_top_block_to(dst)
	if moved != 8:
		_fail("multi_flight_count", "movidas=%d" % moved)
		board.queue_free()
		return
	await create_timer(0.7).timeout
	var pending: int = int(dst.pending_incoming_values.size())
	var coins: int = int(dst.coins.size())
	if pending > 0 or coins != 8:
		_fail("multi_flight_settle", "pending=%d coins=%d" % [pending, coins])
		board.queue_free()
		return
	dst.kill_all_tweens()
	src.kill_all_tweens()
	board.queue_free()
	_ok("multi_coin_flight")

func _test_level_up_queue_logic() -> void:
	var pending: Array = []
	var previous := 1
	var checkpoint_level := 7
	for alert_lvl in range(previous + 1, checkpoint_level + 1):
		pending.append(alert_lvl)
	if pending != [2, 3, 4, 5, 6, 7]:
		_fail("level_queue", str(pending))
		return
	var desc3 := _checkpoint_description(3)
	var shown := "Nivel %d\n%s" % [3, desc3]
	if shown.find("Pila 5") < 0:
		_fail("level3_text", shown)
		return
	_ok("level_up_queue_and_level3_text")
