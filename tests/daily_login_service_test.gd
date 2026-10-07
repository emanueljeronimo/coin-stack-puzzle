extends SceneTree

const DailyLoginServiceScript = preload("res://daily_login_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== daily_login_service test ===")
	_test_day_reset()
	_test_claim_chain()
	_test_slots_and_rotation()
	_test_level_unlock()
	_test_unlocked_rotation()
	_test_pending_grants()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_day_reset() -> void:
	var same: Dictionary = DailyLoginServiceScript.synced_progress("2026-10-05", 3, "2026-10-05")
	if str(same.get("day", "")) != "2026-10-05" or int(same.get("claimed", -1)) != 3:
		_fail("keep_same_day", str(same))
		return
	var reset: Dictionary = DailyLoginServiceScript.synced_progress("2026-10-05", 3, "2026-10-06")
	if str(reset.get("day", "")) != "2026-10-06" or int(reset.get("claimed", -1)) != 0:
		_fail("reset_next_day", str(reset))
		return
	if DailyLoginServiceScript.day_key_from_dict({"year": 2026, "month": 10, "day": 5}) != "2026-10-05":
		_fail("day_key_format")
		return
	_ok("day_reset")

func _test_claim_chain() -> void:
	if DailyLoginServiceScript.slot_status(0, 0) != "available":
		_fail("first_available")
		return
	if DailyLoginServiceScript.slot_status(1, 0) != "locked":
		_fail("second_locked")
		return
	if not DailyLoginServiceScript.can_claim(0, 0):
		_fail("can_claim_free")
		return
	if DailyLoginServiceScript.can_claim(1, 0):
		_fail("cannot_skip")
		return
	var first: Dictionary = DailyLoginServiceScript.claim(0, 0)
	if not bool(first.get("ok", false)) or int(first.get("claimed", 0)) != 1:
		_fail("claim_free", str(first))
		return
	if DailyLoginServiceScript.slot_status(0, 1) != "claimed":
		_fail("first_claimed")
		return
	if DailyLoginServiceScript.slot_status(1, 1) != "available":
		_fail("second_unlocked")
		return
	var skip: Dictionary = DailyLoginServiceScript.claim(2, 1)
	if bool(skip.get("ok", true)):
		_fail("skip_blocked", str(skip))
		return
	var second: Dictionary = DailyLoginServiceScript.claim(1, 1)
	if not bool(second.get("ok", false)) or int(second.get("claimed", 0)) != 2:
		_fail("claim_second", str(second))
		return
	var last: Dictionary = DailyLoginServiceScript.claim(3, 3)
	if not bool(last.get("ok", false)) or int(last.get("claimed", 0)) != 4:
		_fail("claim_last", str(last))
		return
	if DailyLoginServiceScript.can_claim(0, 4):
		_fail("all_done")
		return
	_ok("claim_chain")

func _test_slots_and_rotation() -> void:
	var slots: Array = DailyLoginServiceScript.slot_defs("2026-10-05")
	if slots.size() != 4:
		_fail("slot_count", str(slots.size()))
		return
	var free_slot: Dictionary = slots[0] as Dictionary
	if int(free_slot.get("amount", 0)) != 70 or bool(free_slot.get("requires_ad", true)):
		_fail("free_slot", str(free_slot))
		return
	if DailyLoginServiceScript.slot_label(free_slot) != "70":
		_fail("free_label", DailyLoginServiceScript.slot_label(free_slot))
		return
	var ad_stars: Dictionary = slots[1] as Dictionary
	if int(ad_stars.get("amount", 0)) != 100 or not bool(ad_stars.get("requires_ad", false)):
		_fail("ad_stars", str(ad_stars))
		return
	var lives: Dictionary = slots[3] as Dictionary
	if int(lives.get("seconds", 0)) != 900:
		_fail("lives_sec", str(lives))
		return
	if DailyLoginServiceScript.slot_label(lives) != "15 min":
		_fail("lives_label", DailyLoginServiceScript.slot_label(lives))
		return
	var a: String = DailyLoginServiceScript.wildcard_for_day("2026-10-05")
	var b: String = DailyLoginServiceScript.wildcard_for_day("2026-10-06")
	if a == b:
		_fail("wildcard_rotates", "%s %s" % [a, b])
		return
	if DailyLoginServiceScript.WILDCARD_TYPES.find(a) < 0:
		_fail("wildcard_type", a)
		return
	var wc: Dictionary = slots[2] as Dictionary
	if str(wc.get("wildcard_type", "")) != a:
		_fail("wildcard_slot", str(wc))
		return
	if DailyLoginServiceScript.wildcard_title("hammer") != "Martillo":
		_fail("wildcard_title")
		return
	_ok("slots_and_rotation")

func _test_level_unlock() -> void:
	if DailyLoginServiceScript.unlock_level() != 5:
		_fail("unlock_level", str(DailyLoginServiceScript.unlock_level()))
		return
	if DailyLoginServiceScript.is_unlocked(4):
		_fail("locked_at_4")
		return
	if not DailyLoginServiceScript.is_unlocked(5):
		_fail("unlocked_at_5")
		return
	if not DailyLoginServiceScript.is_unlocked(6):
		_fail("unlocked_after_5")
		return
	_ok("level_unlock")

func _test_unlocked_rotation() -> void:
	if DailyLoginServiceScript.wildcard_for_day("2026-10-05", 5) != "mix":
		_fail("level5_mix_a")
		return
	if DailyLoginServiceScript.wildcard_for_day("2026-10-06", 5) != "mix":
		_fail("level5_mix_b")
		return
	var at_ten_a: String = DailyLoginServiceScript.wildcard_for_day("2026-10-05", 10)
	var at_ten_b: String = DailyLoginServiceScript.wildcard_for_day("2026-10-06", 10)
	if at_ten_a == at_ten_b:
		_fail("level10_rotates", "%s %s" % [at_ten_a, at_ten_b])
		return
	if DailyLoginServiceScript.WILDCARD_TYPES.find(at_ten_a) < 0 or at_ten_a == "glove":
		_fail("level10_pool", at_ten_a)
		return
	if DailyLoginServiceScript.wildcard_for_day("2026-10-07", 6) != "mix":
		_fail("level6_not_glove")
		return
	_ok("unlocked_rotation")

func _test_pending_grants() -> void:
	var all_pending: Array = DailyLoginServiceScript.pending_grant_indexes(4, 0)
	if all_pending.size() != 4:
		_fail("pending_all", str(all_pending))
		return
	if not DailyLoginServiceScript.pending_grant_indexes(4, 4).is_empty():
		_fail("pending_none")
		return
	var mid: Array = DailyLoginServiceScript.pending_grant_indexes(3, 1)
	if mid.size() != 2 or int(mid[0]) != 1 or int(mid[1]) != 2:
		_fail("pending_mid", str(mid))
		return
	_ok("pending_grants")
