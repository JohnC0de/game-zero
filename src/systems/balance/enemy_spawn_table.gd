extends Resource
class_name EnemySpawnTable

@export var phases: Array[EnemySpawnPhase] = []


func pick_scene(run_time: float) -> PackedScene:
	var phase: EnemySpawnPhase = _get_phase(run_time)
	if not phase:
		return null
	if phase.entries.is_empty():
		return null

	var total: float = 0.0
	for e: EnemySpawnEntry in phase.entries:
		total += maxf(0.0, e.weight)

	if total <= 0.0:
		var idx: int = randi_range(0, phase.entries.size() - 1)
		return phase.entries[idx].enemy_scene

	var roll: float = randf() * total
	var acc: float = 0.0
	for e: EnemySpawnEntry in phase.entries:
		acc += maxf(0.0, e.weight)
		if roll <= acc:
			return e.enemy_scene
	return phase.entries[phase.entries.size() - 1].enemy_scene


func _get_phase(run_time: float) -> EnemySpawnPhase:
	for p: EnemySpawnPhase in phases:
		if p and p.contains_time(run_time):
			return p
	if phases.is_empty():
		return null
	return phases[phases.size() - 1]
