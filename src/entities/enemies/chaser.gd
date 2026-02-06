extends EnemyBase
class_name EnemyChaser
## Simple enemy that relentlessly chases the player


func _update_behavior(_delta: float) -> void:
	var direction: Vector2 = get_direction_to_target()
	velocity = direction * move_speed

	# Rotate to face movement
	if velocity.length_squared() > 0:
		sprite.rotation = velocity.angle() + PI / 2
