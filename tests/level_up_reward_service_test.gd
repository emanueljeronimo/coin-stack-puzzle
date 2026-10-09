extends SceneTree

const LevelUpRewardServiceScript = preload("res://level_up_reward_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== level_up_reward_service test ===")
	_test_grant_from_level_five()
	_test_claim_amounts()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_grant_from_level_five() -> void:
	if LevelUpRewardServiceScript.should_grant(4):
		_fail("locked_before_5")
		return
	if not LevelUpRewardServiceScript.should_grant(5):
		_fail("unlocked_at_5")
		return
	if not LevelUpRewardServiceScript.should_grant(14):
		_fail("unlocked_after_5")
		return
	if LevelUpRewardServiceScript.base_stars(4) != 0:
		_fail("no_stars_before_5")
		return
	if LevelUpRewardServiceScript.base_stars(5) != 10:
		_fail("ten_at_5")
		return
	_ok("grant_from_level_five")

func _test_claim_amounts() -> void:
	if LevelUpRewardServiceScript.claim_stars(4, true) != 0:
		_fail("no_double_before_5")
		return
	if LevelUpRewardServiceScript.claim_stars(5, false) != 10:
		_fail("claim_base")
		return
	if LevelUpRewardServiceScript.claim_stars(5, true) != 20:
		_fail("claim_doubled")
		return
	if LevelUpRewardServiceScript.claim_stars(9, true) != 20:
		_fail("claim_later_doubled")
		return
	_ok("claim_amounts")
