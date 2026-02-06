extends Node2D
class_name GameArena
## Main game arena - manages entity containers and game start

const XP_GEM_SCENE: PackedScene = preload("res://src/entities/pickups/xp_gem.tscn")

@export var base_zoom: float = 1.0
@export var min_zoom: float = 0.7
@export var zoom_per_enemy: float = 0.02
@export var zoom_speed: float = 2.0

var _target_zoom: float = 1.0
var _camera: Camera2D = null

@onready var player: CharacterBody2D = $Player
@onready var enemies_container: Node2D = $Enemies
@onready var projectiles_container: Node2D = $Projectiles
@onready var pickups_container: Node2D = $Pickups


func _ready() -> void:
	add_to_group("arena")
	Log.info("Arena", "initialized")
	Events.enemy_killed.connect(_on_enemy_killed)

	# Get camera reference
	_camera = player.get_node_or_null("Camera2D") as Camera2D

	# Auto-start game
	call_deferred("_start_game")


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_update_camera_zoom(delta)


func _update_camera_zoom(delta: float) -> void:
	if not _camera:
		return

	# Count nearby enemies
	var nearby_count: int = 0
	var danger_radius: float = 300.0

	for child: Node in enemies_container.get_children():
		var enemy: Node2D = child as Node2D
		if not enemy:
			continue
		if player.global_position.distance_to(enemy.global_position) < danger_radius:
			nearby_count += 1

	# Calculate target zoom (zoom out when more enemies nearby)
	_target_zoom = maxf(min_zoom, base_zoom - nearby_count * zoom_per_enemy)

	# Smooth zoom
	var current: float = _camera.zoom.x
	var new_zoom: float = lerpf(current, _target_zoom, zoom_speed * delta)
	_camera.zoom = Vector2(new_zoom, new_zoom)


func _start_game() -> void:
	Game.start_game()


func spawn_enemy(enemy_scene: PackedScene, pos: Vector2) -> Node2D:
	var enemy: Node2D = enemy_scene.instantiate()
	enemy.global_position = pos
	enemies_container.add_child(enemy)
	return enemy


func spawn_enemy_direct(enemy: Node2D) -> void:
	## Spawn an already-instantiated enemy (used by splitters etc)
	enemies_container.add_child(enemy)


func spawn_projectile(projectile: Node2D) -> void:
	projectiles_container.add_child(projectile)


func spawn_pickup(pickup: Node2D, pos: Vector2) -> void:
	# Spawning pickups during a physics callback (e.g. projectile hit) can
	# trigger "Can't change this state while flushing queries".
	# Defer adding the Area2D to the scene tree.
	call_deferred("_spawn_pickup_deferred", pickup, pos)


func _spawn_pickup_deferred(pickup: Node2D, pos: Vector2) -> void:
	if not pickup:
		return
	pickup.global_position = pos
	pickups_container.add_child(pickup)


func get_enemy_count() -> int:
	return enemies_container.get_child_count()


func get_random_spawn_position(min_distance: float = 400.0, max_distance: float = 600.0) -> Vector2:
	var angle: float = randf() * TAU
	var distance: float = randf_range(min_distance, max_distance)
	return player.global_position + Vector2.from_angle(angle) * distance


func _on_enemy_killed(enemy: Node2D, pos: Vector2) -> void:
	var xp_value: int = 1
	var e: EnemyBase = enemy as EnemyBase
	if e:
		xp_value = e.xp_value
	else:
		var raw: Variant = enemy.get("xp_value")
		if raw != null:
			xp_value = raw as int

	_spawn_xp_gems(pos, xp_value)


func _spawn_xp_gems(pos: Vector2, value: int) -> void:
	# Spawn multiple small gems for visual flair
	var safe_value: int = maxi(1, value)
	var gem_count: int = mini(safe_value, 5)  # Cap at 5 gems
	var value_per_gem: int = maxi(1, safe_value / gem_count)

	for i: int in gem_count:
		var gem: XPGem = XP_GEM_SCENE.instantiate()
		gem.xp_value = value_per_gem
		spawn_pickup(gem, pos)
