extends RefCounted

const STEP_NONE := ""
const STEP_MERGE := "merge"
const STEP_ROLL := "roll"
const STEP_DONE := "done"

const MERGE_ORIGIN := 0
const MERGE_DEST := 1

static func should_start(tutorial_done: bool, checkpoint_level: int) -> bool:
	return not tutorial_done and checkpoint_level <= 1

static func should_skip_for_progress(checkpoint_level: int) -> bool:
	return checkpoint_level > 1

static func is_active(step: String) -> bool:
	return step == STEP_MERGE or step == STEP_ROLL

static func tutorial_stack_count() -> int:
	return 5

static func initial_stack_rows() -> Array:
	return [
		[1, 1, 1, 1],
		[1, 1, 1],
		[2, 2],
		[2],
		[],
	]

static func is_merge_layout(rows: Array) -> bool:
	var expected: Array = initial_stack_rows()
	if rows.size() < expected.size():
		return false
	for i in range(expected.size()):
		var got: Array = rows[i] as Array
		var want: Array = expected[i] as Array
		if got.size() != want.size():
			return false
		for j in range(want.size()):
			if int(got[j]) != int(want[j]):
				return false
	return true

static func speech_for_step(step: String) -> String:
	match step:
		STEP_MERGE:
			return "Junta las fichas iguales en una ranura."
		STEP_ROLL:
			return "Toca Repartir para sumar fichas."
		_:
			return ""

static func can_select_stack(step: String, stack_index: int) -> bool:
	if step == STEP_MERGE:
		return stack_index == MERGE_ORIGIN or stack_index == MERGE_DEST
	return false

static func can_move(step: String, from_index: int, to_index: int) -> bool:
	if step != STEP_MERGE:
		return false
	if from_index == to_index:
		return false
	var a_ok := from_index == MERGE_ORIGIN or from_index == MERGE_DEST
	var b_ok := to_index == MERGE_ORIGIN or to_index == MERGE_DEST
	return a_ok and b_ok

static func blocks_roll(step: String) -> bool:
	return step == STEP_MERGE

static func uses_scripted_roll(step: String) -> bool:
	return step == STEP_ROLL

static func blocks_tools(step: String) -> bool:
	return is_active(step)

static func roll_values() -> Array:
	return [1, 1, 1, 1, 2, 2, 2, 2]

static func next_after_merge(step: String) -> String:
	if step == STEP_MERGE:
		return STEP_ROLL
	return step

static func next_after_roll(step: String) -> String:
	if step == STEP_ROLL:
		return STEP_DONE
	return step

static func pointer_is_stack(step: String) -> bool:
	return step == STEP_MERGE
