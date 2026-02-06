extends Node
## Persistent save data manager for meta progression

const SAVE_PATH: String = "user://save_data.json"

# Persistent stats
var total_kills: int = 0
var total_runs: int = 0
var best_time: float = 0.0
var best_level: int = 1

# Unlocks
var unlocked_weapons: Array[String] = []


func _ready() -> void:
	load_data()
	_ensure_defaults()
	Events.game_over.connect(_on_game_over)
	Log.info(
		"SaveData",
		"loaded",
		{kills = total_kills, runs = total_runs, weapons = unlocked_weapons.size()}
	)


func _on_game_over(stats: Dictionary) -> void:
	total_runs += 1
	total_kills += stats.get("kills", 0) as int

	var time: float = stats.get("time", 0.0) as float
	if time > best_time:
		best_time = time

	var level: int = stats.get("level", 1) as int
	if level > best_level:
		best_level = level

	_check_unlocks()
	save_data()

	Log.info(
		"SaveData",
		"run_recorded",
		{total_kills = total_kills, total_runs = total_runs, best_time = best_time}
	)


func _check_unlocks() -> void:
	for w: WeaponDef in WeaponCatalog.get_all():
		if w.weapon_name == "":
			continue
		if w.weapon_name in unlocked_weapons:
			continue
		if total_kills >= w.unlock_total_kills:
			unlocked_weapons.append(w.weapon_name)
			Log.info("SaveData", "weapon_unlocked", {weapon = w.weapon_name})


func is_weapon_unlocked(weapon_name: String) -> bool:
	return weapon_name in unlocked_weapons


func get_unlock_progress(weapon_name: String) -> float:
	if weapon_name in unlocked_weapons:
		return 1.0
	var w: WeaponDef = WeaponCatalog.get_by_name(weapon_name)
	if w and w.unlock_total_kills > 0:
		return float(total_kills) / float(w.unlock_total_kills)
	return 0.0


func _ensure_defaults() -> void:
	if not unlocked_weapons.is_empty():
		return
	unlocked_weapons = WeaponCatalog.get_default_unlocked()
	if unlocked_weapons.is_empty():
		unlocked_weapons.append("Blaster")


func save_data() -> void:
	var data: Dictionary = {
		"total_kills": total_kills,
		"total_runs": total_runs,
		"best_time": best_time,
		"best_level": best_level,
		"unlocked_weapons": unlocked_weapons,
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		Log.debug("SaveData", "saved")


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json: JSON = JSON.new()
	var error: Error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		Log.error("SaveData", "parse_error", {error = error})
		return

	var data: Variant = json.data
	if not data is Dictionary:
		return

	var d: Dictionary = data as Dictionary
	total_kills = d.get("total_kills", 0) as int
	total_runs = d.get("total_runs", 0) as int
	best_time = d.get("best_time", 0.0) as float
	best_level = d.get("best_level", 1) as int

	var weapons: Array = d.get("unlocked_weapons", []) as Array
	unlocked_weapons.clear()
	for w: Variant in weapons:
		unlocked_weapons.append(str(w))


func reset_data() -> void:
	total_kills = 0
	total_runs = 0
	best_time = 0.0
	best_level = 1
	unlocked_weapons = WeaponCatalog.get_default_unlocked()
	if unlocked_weapons.is_empty():
		unlocked_weapons.append("Blaster")
	save_data()
	Log.info("SaveData", "reset")
