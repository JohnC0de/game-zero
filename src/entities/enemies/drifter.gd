extends "res://src/entities/enemies/enemy_base.gd"
## Slow enemy with erratic, drifting movement

@export var drift_change_interval: float = 2.0
@export var drift_strength: float = 0.5

var _drift_timer: float = 0.0
var _drift_offset: Vector2 = Vector2.ZERO


func _update_behavior(delta: float) -> void:
	# Update drift direction periodically
	_drift_timer -= delta
	if _drift_timer <= 0:
		_drift_offset = (
			Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * drift_strength
		)
		_drift_timer = drift_change_interval

	# Move toward player with drift
	var to_player: Vector2 = get_direction_to_target()
	var direction: Vector2 = (to_player + _drift_offset).normalized()
	velocity = direction * move_speed

	# Gentle rotation based on velocity
	if velocity.length_squared() > 0:
		sprite.rotation = lerp_angle(sprite.rotation, velocity.angle(), 0.1)
