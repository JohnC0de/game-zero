extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _current_suite: String = ""


func _init() -> void:
	_run_all_tests()
	_print_summary()
	quit(_failed)


func _run_all_tests() -> void:
	print("\n=== Running Tests ===\n")
	
	_run_suite("Game XP Scaling", _test_xp_scaling)
	_run_suite("Save Data Logic", _test_save_logic)


func _run_suite(name: String, tests: Callable) -> void:
	_current_suite = name
	print("[%s]" % name)
	tests.call()
	print("")


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % test_name)
	else:
		_failed += 1
		print("  ✗ %s" % test_name)


func _assert_eq(a: Variant, b: Variant, test_name: String) -> void:
	_assert(a == b, "%s (got %s, expected %s)" % [test_name, a, b])


func _assert_gt(a: Variant, b: Variant, test_name: String) -> void:
	_assert(a > b, "%s (%s > %s)" % [test_name, a, b])


func _print_summary() -> void:
	var total: int = _passed + _failed
	print("=== Results: %d/%d passed ===" % [_passed, total])
	if _failed > 0:
		print("❌ %d tests failed" % _failed)
	else:
		print("✅ All tests passed!")


func _test_xp_scaling() -> void:
	var xp_1: int = _calc_xp(1)
	var xp_5: int = _calc_xp(5)
	var xp_10: int = _calc_xp(10)
	
	_assert_eq(xp_1, 10, "Level 1 XP is 10")
	_assert_gt(xp_5, xp_1, "Level 5 XP > Level 1")
	_assert_gt(xp_10, xp_5, "Level 10 XP > Level 5")
	
	var prev: int = 0
	var increasing: bool = true
	for lvl in range(1, 15):
		var xp: int = _calc_xp(lvl)
		if xp <= prev:
			increasing = false
			break
		prev = xp
	_assert(increasing, "XP requirements always increase")


func _calc_xp(level: int) -> int:
	return int(10 + (level - 1) * 5 + pow(level - 1, 1.5) * 2)


func _test_save_logic() -> void:
	var thresholds: Dictionary = {
		"Orbit": 50,
		"Nova": 150,
		"Missiles": 300,
	}
	
	_assert(_is_unlocked("Blaster", 0, thresholds), "Blaster always unlocked")
	_assert(not _is_unlocked("Orbit", 0, thresholds), "Orbit locked at 0 kills")
	_assert(_is_unlocked("Orbit", 50, thresholds), "Orbit unlocked at 50 kills")
	_assert(not _is_unlocked("Nova", 100, thresholds), "Nova locked at 100 kills")
	_assert(_is_unlocked("Nova", 150, thresholds), "Nova unlocked at 150 kills")
	
	var progress: float = _unlock_progress("Orbit", 25, thresholds)
	_assert_eq(progress, 0.5, "Orbit 50% at 25 kills")


func _is_unlocked(weapon: String, kills: int, thresholds: Dictionary) -> bool:
	if weapon == "Blaster":
		return true
	if weapon in thresholds:
		return kills >= thresholds[weapon]
	return false


func _unlock_progress(weapon: String, kills: int, thresholds: Dictionary) -> float:
	if weapon == "Blaster":
		return 1.0
	if weapon in thresholds:
		return float(kills) / thresholds[weapon]
	return 0.0
