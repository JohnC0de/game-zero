extends Node
## Core game state manager

enum State { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER }

var state: State = State.MENU:
	set(value):
		var old: State = state
		state = value
		Log.info("Game", "state_changed", {from = State.keys()[old], to = State.keys()[state]})
		_apply_state()

var player: Node2D = null
var run_time: float = 0.0
var kills: int = 0
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 10


func _ready() -> void:
	Log.info("Game", "manager_ready")
	Events.player_spawned.connect(_on_player_spawned)
	Events.player_died.connect(_on_player_died)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.upgrade_selected.connect(_on_upgrade_selected)


func _process(delta: float) -> void:
	if state == State.PLAYING:
		run_time += delta


func start_game() -> void:
	Log.info("Game", "starting_new_run")
	_reset_run_stats()
	state = State.PLAYING
	Events.game_started.emit()


func pause_for_level_up() -> void:
	state = State.LEVEL_UP


func resume_from_level_up() -> void:
	state = State.PLAYING


func end_game() -> void:
	state = State.GAME_OVER
	var stats: Dictionary = {time = run_time, kills = kills, level = current_level}
	Log.info("Game", "run_ended", stats)
	Events.game_over.emit(stats)


func add_xp(amount: int) -> void:
	# XP is tracked by Game (authoritative) so HUD/UI stay consistent.
	# Note: pick-ups should not grant XP while paused, but guard anyway.
	if amount <= 0:
		return
	if state != State.PLAYING:
		return

	current_xp += amount
	Events.xp_collected.emit(amount, current_xp)
	_maybe_level_up()


func get_xp_for_level(level: int) -> int:
	return Balance.get_xp_for_level(level)


func _reset_run_stats() -> void:
	run_time = 0.0
	kills = 0
	current_level = 1
	current_xp = 0
	xp_to_next_level = get_xp_for_level(1)
	Log.debug("Game", "stats_reset", {xp_needed = xp_to_next_level})


func _apply_state() -> void:
	match state:
		State.PLAYING:
			get_tree().paused = false
		State.PAUSED, State.LEVEL_UP, State.GAME_OVER:
			get_tree().paused = true
		State.MENU:
			get_tree().paused = false


func _on_player_spawned(p: Node2D) -> void:
	player = p
	Log.debug("Game", "player_registered", {pos = p.global_position})


func _on_player_died() -> void:
	Log.info("Game", "player_died", {time = run_time, kills = kills})
	end_game()


func _on_enemy_killed(_enemy: Node2D, _pos: Vector2) -> void:
	kills += 1
	if kills % 50 == 0:
		Log.info("Game", "kill_milestone", {kills = kills, time = run_time})


func _maybe_level_up() -> void:
	# Only trigger a single level-up at a time (we pause for upgrade UI).
	if state != State.PLAYING:
		return
	if current_xp >= xp_to_next_level:
		_level_up()


func _level_up() -> void:
	current_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = get_xp_for_level(current_level)
	Log.info("Game", "level_up", {level = current_level, next_xp = xp_to_next_level})
	Events.level_up.emit(current_level)
	pause_for_level_up()


func _on_upgrade_selected(_upgrade: UpgradeData) -> void:
	resume_from_level_up()
	# If we had XP overflow (big pickup), chain another level-up immediately.
	_maybe_level_up()


func _exit_tree() -> void:
	# Ensure pooled FX don't show as leaked instances on exit.
	DamageNumber.clear_pool()
	DeathParticles.clear_pool()
