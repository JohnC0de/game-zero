extends Resource
class_name ProgressionConfig

@export var base_xp: int = 10
@export var linear_per_level: int = 6
@export var exp_power: float = 1.7
@export var exp_scale: float = 2.8


func get_xp_for_level(level: int) -> int:
	if level <= 1:
		return base_xp
	var l: int = level - 1
	return int(base_xp + l * linear_per_level + pow(float(l), exp_power) * exp_scale)
