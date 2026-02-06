extends GdUnitTestSuite

const WORLD_SCENE_PATH: String = "res://world.tscn"
const LEVEL_UP_UI_SCENE_PATH: String = "res://src/ui/level_up_ui.tscn"


func test_level_up_ui_scene_loads() -> void:
	# This catches .tscn parse errors that script compilation won't detect.
	var scene: PackedScene = load(LEVEL_UP_UI_SCENE_PATH) as PackedScene
	assert_bool(scene != null).is_true()
	if scene == null:
		return
	var ui_node: Node = scene.instantiate()
	assert_bool(ui_node != null).is_true()
	assert_bool(ui_node is LevelUpUI).is_true()
	ui_node.queue_free()


func test_world_scene_loads_and_includes_level_up_ui() -> void:
	var scene: PackedScene = load(WORLD_SCENE_PATH) as PackedScene
	assert_bool(scene != null).is_true()
	if scene == null:
		return
	var world: Node = scene.instantiate()
	assert_bool(world != null).is_true()
	world.queue_free()


func test_level_up_flow_shows_menu_and_resumes_game() -> void:
	var world_scene: PackedScene = load(WORLD_SCENE_PATH) as PackedScene
	assert_bool(world_scene != null).is_true()
	if world_scene == null:
		return
	var world: Node = world_scene.instantiate()
	assert_bool(world != null).is_true()
	if world == null:
		return

	# Mount the world so _ready() runs on children.
	get_tree().root.add_child(world)
	await await_idle_frame()
	await await_idle_frame()

	# Ensure player is registered (UpgradeManager.apply_upgrade requires it).
	assert_bool(Game.player != null).is_true()

	var ui: LevelUpUI = world.get_node_or_null("LevelUpUI") as LevelUpUI
	assert_bool(ui != null).is_true()

	# Trigger the level-up UI the same way the game does.
	Game.state = Game.State.PLAYING
	Events.level_up.emit(2)
	Game.pause_for_level_up()
	await await_idle_frame()

	assert_bool(ui.visible).is_true()
	assert_int(Game.state).is_equal(Game.State.LEVEL_UP)

	var grid: GridContainer = ui.get_node(
		"Panel/Card/Margin/VBox/Content/ChoicesPanel/ChoicesMargin/ChoicesVBox/ChoicesGrid"
	) as GridContainer
	assert_bool(grid != null).is_true()
	assert_int(grid.get_child_count()).is_equal(3)

	# Pick first upgrade and verify game resumes.
	ui._on_choice_selected(0)
	await await_idle_frame()

	assert_bool(ui.visible).is_false()
	assert_int(Game.state).is_equal(Game.State.PLAYING)

	world.queue_free()
	await await_idle_frame()
