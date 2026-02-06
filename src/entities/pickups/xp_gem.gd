extends Node2D
class_name XPGem
## Collectible XP gem that flies toward player when in range

@export var xp_value: int = 1
@export var magnet_speed: float = 400.0
@export var initial_scatter_speed: float = 100.0

var _being_collected: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _target: Node2D = null

@onready var area: Area2D = $Area
@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	area.add_to_group("pickup")
	# Random initial scatter
	_velocity = Vector2.from_angle(randf() * TAU) * initial_scatter_speed


func _process(delta: float) -> void:
	if _being_collected and is_instance_valid(_target):
		# Fly toward player
		var direction: Vector2 = global_position.direction_to(_target.global_position)
		_velocity = direction * magnet_speed
		global_position += _velocity * delta

		# Check if reached player
		if global_position.distance_to(_target.global_position) < 20:
			_complete_collection()
	else:
		# Initial scatter then slow down
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, 200 * delta)

	# Gentle bob animation
	sprite.position.y = sin(Time.get_ticks_msec() * 0.01) * 2


func collect(collector: Node2D) -> void:
	if _being_collected:
		return

	_being_collected = true
	_target = collector


func _complete_collection() -> void:
	if _target.has_method("collect_xp"):
		_target.collect_xp(xp_value)
	queue_free()
