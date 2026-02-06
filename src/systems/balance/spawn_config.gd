extends Resource
class_name SpawnConfig

@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.45
@export var spawn_acceleration: float = 0.016
@export var max_enemies: int = 90

@export var spawn_count_step_seconds: float = 35.0
@export var spawn_count_cap: int = 5


func get_spawn_interval(run_time: float) -> float:
	var time_factor: float = 1.0 - (run_time * spawn_acceleration)
	time_factor = clampf(time_factor, 0.0, 1.0)
	return lerpf(min_spawn_interval, base_spawn_interval, time_factor)


func get_spawn_count(run_time: float) -> int:
	var base: int = 1 + int(run_time / spawn_count_step_seconds)
	var variance: int = randi_range(0, maxi(1, base / 2))
	return mini(base + variance, spawn_count_cap)
