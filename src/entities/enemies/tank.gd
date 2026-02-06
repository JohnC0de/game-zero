extends "res://src/entities/enemies/enemy_base.gd"
## Slow, heavily armored enemy


func _update_behavior(_delta: float) -> void:
	var direction: Vector2 = get_direction_to_target()
	velocity = direction * move_speed

	# Tanks don't rotate much - they're bulky
	if velocity.length_squared() > 0:
		sprite.rotation = lerp_angle(sprite.rotation, velocity.angle() + PI / 2, 0.05)
