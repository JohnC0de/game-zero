extends RefCounted
class_name WeaponCatalog

const _WEAPONS_DIR: String = "res://src/data/weapons"

static var _loaded: bool = false
static var _cache: Array[WeaponDef] = []


static func get_all() -> Array[WeaponDef]:
	_ensure_loaded()
	return _cache.duplicate()


static func get_by_name(weapon_name: String) -> WeaponDef:
	_ensure_loaded()
	for w: WeaponDef in _cache:
		if w.weapon_name == weapon_name:
			return w
	return null


static func get_scene(weapon_name: String) -> PackedScene:
	var w: WeaponDef = get_by_name(weapon_name)
	return w.weapon_scene if w else null


static func get_default_unlocked() -> Array[String]:
	_ensure_loaded()
	var out: Array[String] = []
	for w: WeaponDef in _cache:
		if w.is_default_unlocked():
			out.append(w.weapon_name)
	return out


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_cache = []

	var dir: DirAccess = DirAccess.open(_WEAPONS_DIR)
	if not dir:
		Log.warn("WeaponCatalog", "missing_dir", {dir = _WEAPONS_DIR})
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var normalized: String = file_name
		if normalized.ends_with(".remap"):
			normalized = normalized.trim_suffix(".remap")

		if not dir.current_is_dir() and normalized.ends_with(".tres"):
			var res_path: String = "%s/%s" % [_WEAPONS_DIR, normalized]
			var res: Resource = load(res_path)
			var w: WeaponDef = res as WeaponDef
			if w and w.weapon_name != "" and w.weapon_scene:
				_cache.append(w)
		file_name = dir.get_next()
	dir.list_dir_end()
