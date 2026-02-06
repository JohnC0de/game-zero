extends Node
class_name WaveSpawner
## Spawns enemies at increasing rates based on game time

@export var max_enemies: int = 100

@export var enemy_spawn_table: EnemySpawnTable = preload("res://src/data/spawns/enemy_spawn_table.tres")

var _spawn_timer: float = 0.0
var _arena: GameArena = null
var _director: EncounterDirector = EncounterDirector.new()


func _ready() -> void:
	Events.game_started.connect(_on_game_started)
	Log.info("WaveSpawner", "initialized")


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	if not _arena:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_wave()
		_spawn_timer = _get_current_spawn_interval()


func _on_game_started() -> void:
	_arena = get_tree().get_first_node_in_group("arena") as GameArena
	_spawn_timer = 0.5  # Quick first spawn
	Log.debug("WaveSpawner", "game_started", {arena = _arena != null})


func _get_current_spawn_interval() -> float:
	var base: float = Balance.get_spawn_interval(Game.run_time)
	var mult: float = _director.get_spawn_interval_multiplier(Metrics.get_kills_per_minute())
	return base * mult


func _get_spawn_count() -> int:
	return Balance.get_spawn_count(Game.run_time)


func _spawn_wave() -> void:
	if not _arena:
		return

	var current_count: int = _arena.get_enemy_count()
	var max_dynamic: int = int(float(max_enemies) * _director.get_max_enemies_multiplier(Metrics.get_kills_per_minute()))
	max_dynamic = maxi(10, max_dynamic)
	if current_count >= max_dynamic:
		return

	var spawn_count: int = _get_spawn_count()
	spawn_count = mini(spawn_count, max_dynamic - current_count)

	for i: int in spawn_count:
		_spawn_enemy()

	if spawn_count > 0 and Game.run_time > 0:
		Log.debug(
			"WaveSpawner",
			"spawned",
			{
				count = spawn_count,
				total = _arena.get_enemy_count(),
				interval = "%.2f" % _get_current_spawn_interval()
			}
		)


func _spawn_enemy() -> void:
	var pos: Vector2 = _arena.get_random_spawn_position()
	var scene: PackedScene = _get_enemy_scene()
	if not scene:
		return
	var enemy: Node2D = _arena.spawn_enemy(scene, pos)

	# Scale enemy stats based on time
	_apply_difficulty_scaling(enemy)


func _get_enemy_scene() -> PackedScene:
	if not enemy_spawn_table:
		return null
	return enemy_spawn_table.pick_scene(Game.run_time)


func _apply_difficulty_scaling(enemy: Node2D) -> void:
	var e: EnemyBase = enemy as EnemyBase
	if not e:
		return

	var hp_multiplier: float = Balance.get_enemy_hp_multiplier(Game.run_time)
	e.max_hp = int(e.max_hp * hp_multiplier)
	e.current_hp = e.max_hp

	var speed_multiplier: float = Balance.get_enemy_speed_multiplier(Game.run_time)
	e.move_speed *= speed_multiplier
