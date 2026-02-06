extends Resource
class_name WeaponScalingConfig

@export var damage_per_level: float = 0.2
@export var cooldown_reduction_per_level: float = 0.1
@export var cooldown_min: float = 0.15

@export var extra_projectile_every_levels: int = 2


func get_damage_multiplier(level: int) -> float:
	return 1.0 + float(level - 1) * damage_per_level


func get_cooldown_multiplier(level: int) -> float:
	return 1.0 - float(level - 1) * cooldown_reduction_per_level


func get_extra_projectiles(level: int) -> int:
	if extra_projectile_every_levels <= 0:
		return 0
	return int((level - 1) / extra_projectile_every_levels)
