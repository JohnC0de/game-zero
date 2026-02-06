extends Resource
class_name EnemyScalingConfig

@export var hp_per_minute: float = 0.08
@export var speed_per_minute: float = 0.04
@export var speed_cap_multiplier: float = 1.4


func get_hp_multiplier(run_time: float) -> float:
	return 1.0 + (run_time / 60.0) * hp_per_minute


func get_speed_multiplier(run_time: float) -> float:
	return minf(speed_cap_multiplier, 1.0 + (run_time / 60.0) * speed_per_minute)
