extends "res://src/entities/enemies/enemy_base.gd"
## Small enemy spawned by Splitter - faster but weaker

var _initial_velocity: Vector2 = Vector2.ZERO
var _scatter_time: float = 0.3


func set_initial_velocity(vel: Vector2) -> void:
	_initial_velocity = vel


func _update_behavior(delta: float) -> void:
	if _scatter_time > 0:
		# Initial scatter phase
		velocity = _initial_velocity
		_scatter_time -= delta
		_initial_velocity = _initial_velocity.move_toward(Vector2.ZERO, 500 * delta)
	else:
		# Normal chase
		var direction: Vector2 = get_direction_to_target()
		velocity = direction * move_speed

	if velocity.length_squared() > 0:
		sprite.rotation = velocity.angle() + PI / 2
