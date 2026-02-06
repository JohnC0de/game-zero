extends RefCounted
class_name EncounterDirector

const MIN_KILLS_PER_MIN: float = 10.0
const TARGET_KILLS_PER_MIN: float = 25.0
const MAX_KILLS_PER_MIN: float = 60.0


func get_spawn_interval_multiplier(kills_per_min: float) -> float:
	# If the player is under-performing, slow spawns down (less pressure).
	# If over-performing, speed spawns up slightly.
	var kpm: float = clampf(kills_per_min, MIN_KILLS_PER_MIN, MAX_KILLS_PER_MIN)
	var t: float = inverse_lerp(TARGET_KILLS_PER_MIN, MAX_KILLS_PER_MIN, kpm)
	if kpm < TARGET_KILLS_PER_MIN:
		var t2: float = inverse_lerp(TARGET_KILLS_PER_MIN, MIN_KILLS_PER_MIN, kpm)
		return lerpf(1.0, 1.35, t2)
	return lerpf(1.0, 0.85, t)


func get_max_enemies_multiplier(kills_per_min: float) -> float:
	var kpm: float = clampf(kills_per_min, MIN_KILLS_PER_MIN, MAX_KILLS_PER_MIN)
	if kpm < TARGET_KILLS_PER_MIN:
		var t: float = inverse_lerp(TARGET_KILLS_PER_MIN, MIN_KILLS_PER_MIN, kpm)
		return lerpf(1.0, 0.75, t)
	var t2: float = inverse_lerp(TARGET_KILLS_PER_MIN, MAX_KILLS_PER_MIN, kpm)
	return lerpf(1.0, 1.15, t2)
