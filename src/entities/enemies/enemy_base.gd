extends CharacterBody2D
class_name EnemyBase
## Base class for all enemies with health, movement, and death handling

signal died(enemy: EnemyBase)

@export var max_hp: int = 10
@export var move_speed: float = 100.0
@export var contact_damage: int = 10
@export var xp_value: int = 1
@export var enemy_color: Color = Color(1.0, 0.3, 0.3)

var current_hp: int
var target: Node2D = null

@onready var sprite: Polygon2D = $Sprite
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	current_hp = max_hp
	target = Game.player
	hitbox.add_to_group("enemy_hitbox")

	# Apply color
	if sprite:
		sprite.color = enemy_color

	Events.enemy_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_update_behavior(delta)
	move_and_slide()


func _update_behavior(_delta: float) -> void:
	## Override in subclasses for different movement patterns
	pass


func take_damage(amount: int) -> void:
	current_hp -= amount
	_on_damaged(amount)

	if current_hp <= 0:
		_die()


func _on_damaged(amount: int) -> void:
	## Visual feedback - flash white + hit stop + damage number
	ScreenFX.hitstop_small()

	# Spawn damage number
	DamageNumber.spawn(get_tree().current_scene, global_position, amount, Color.WHITE)

	if sprite:
		var tween: Tween = create_tween().set_ignore_time_scale(true)
		var base_color: Color = sprite.color
		tween.tween_property(sprite, "color", Color.WHITE, 0.05)
		tween.tween_property(sprite, "color", base_color, 0.08)


func _die() -> void:
	_spawn_death_effect()
	Events.enemy_killed.emit(self, global_position)
	died.emit(self)
	queue_free()


func _spawn_death_effect() -> void:
	DeathParticles.spawn(get_tree().current_scene, global_position, enemy_color)


func get_direction_to_target() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	return global_position.direction_to(target.global_position)


func get_distance_to_target() -> float:
	if not is_instance_valid(target):
		return INF
	return global_position.distance_to(target.global_position)
