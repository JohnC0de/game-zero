extends Resource
class_name EnemySpawnPhase

@export var start_time: float = 0.0
@export var end_time: float = -1.0
@export var entries: Array[EnemySpawnEntry] = []


func contains_time(t: float) -> bool:
	if t < start_time:
		return false
	if end_time <= 0.0:
		return true
	return t < end_time
