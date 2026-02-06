extends GdUnitTestSuite
## Unit tests for core game logic


func test_xp_for_level_1() -> void:
	var xp: int = Game.get_xp_for_level(1)
	assert_int(xp).is_equal(10)


func test_xp_increases_each_level() -> void:
	var prev: int = 0
	for level: int in range(1, 15):
		var xp: int = Game.get_xp_for_level(level)
		assert_int(xp).is_greater(prev)
		prev = xp


func test_xp_scaling_values() -> void:
	assert_int(Game.get_xp_for_level(5)).is_greater(Game.get_xp_for_level(1))
	assert_int(Game.get_xp_for_level(10)).is_greater(Game.get_xp_for_level(5))


func test_upgrade_selected_resumes_game() -> void:
	# Setup: put game in LEVEL_UP state
	Game.state = Game.State.LEVEL_UP
	assert_int(Game.state).is_equal(Game.State.LEVEL_UP)

	# Act: emit upgrade_selected signal (simulates player picking an upgrade)
	var fake_upgrade: UpgradeData = UpgradeData.new()
	fake_upgrade.type = UpgradeData.Type.STAT_BOOST
	fake_upgrade.display_name = "Test"
	Events.upgrade_selected.emit(fake_upgrade)

	# Assert: game should resume to PLAYING state
	assert_int(Game.state).is_equal(Game.State.PLAYING)


func test_xp_overflow_chains_multiple_level_ups() -> void:
	# Arrange
	Game.start_game()
	assert_int(Game.state).is_equal(Game.State.PLAYING)

	# Act: Add a large amount of XP to force multiple level-ups.
	Game.add_xp(1000)

	# Consume level-ups by simulating selecting an upgrade repeatedly.
	var safety: int = 0
	while Game.state == Game.State.LEVEL_UP and safety < 50:
		var fake_upgrade: UpgradeData = UpgradeData.new()
		fake_upgrade.type = UpgradeData.Type.STAT_BOOST
		fake_upgrade.display_name = "Test"
		Events.upgrade_selected.emit(fake_upgrade)
		safety += 1

	# Assert
	assert_int(safety).is_less_equal(50)
	assert_int(Game.state).is_equal(Game.State.PLAYING)
	assert_int(Game.current_level).is_greater(1)
	assert_int(Game.current_xp).is_less(Game.xp_to_next_level)
