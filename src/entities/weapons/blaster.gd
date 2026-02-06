extends WeaponBase
class_name WeaponBlaster
## Basic projectile weapon - fires toward nearest enemy

@export var spread_angle: float = 15.0  # Degrees between multi-shots


func _fire(target: Node2D) -> void:
	var base_direction: Vector2 = global_position.direction_to(target.global_position)
	var count: int = projectile_count
	var spread: float = spread_angle * Stats.get_mul(Stats.Stat.BLASTER_SPREAD_MUL)

	if count == 1:
		_spawn_projectile(base_direction)
	else:
		# Spread shots evenly
		var total_spread: float = deg_to_rad(spread * (count - 1))
		var start_angle: float = base_direction.angle() - total_spread / 2

		for i: int in count:
			var angle: float = start_angle + deg_to_rad(spread * i)
			var dir: Vector2 = Vector2.from_angle(angle)
			_spawn_projectile(dir)
