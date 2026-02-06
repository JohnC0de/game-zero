extends RefCounted
class_name WeightedPicker


func pick_unique(items: Array[UpgradeData], count: int) -> Array[UpgradeData]:
	var picked: Array[UpgradeData] = []
	var pool: Array[UpgradeData] = items.duplicate()
	for i: int in mini(count, pool.size()):
		var idx: int = _pick_index(pool)
		picked.append(pool[idx])
		pool.remove_at(idx)
	return picked


func _pick_index(items: Array[UpgradeData]) -> int:
	var total: float = 0.0
	for u: UpgradeData in items:
		total += maxf(0.0, u.weight)
	if total <= 0.0:
		return randi_range(0, items.size() - 1)

	var roll: float = randf() * total
	var acc: float = 0.0
	for i: int in items.size():
		acc += maxf(0.0, items[i].weight)
		if roll <= acc:
			return i
	return items.size() - 1
