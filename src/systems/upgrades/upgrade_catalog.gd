extends RefCounted
class_name UpgradeCatalog

const _UPGRADES_DIR: String = "res://src/data/upgrades"

static var _cache: Array[UpgradeData] = []
static var _loaded: bool = false


static func get_all() -> Array[UpgradeData]:
	if _loaded:
		return _cache.duplicate()
	_loaded = true
	_cache = []

	var dir: DirAccess = DirAccess.open(_UPGRADES_DIR)
	if not dir:
		Log.warn("UpgradeCatalog", "missing_dir", {dir = _UPGRADES_DIR})
		return []

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var normalized: String = file_name
		if normalized.ends_with(".remap"):
			normalized = normalized.trim_suffix(".remap")

		if not dir.current_is_dir() and normalized.ends_with(".tres"):
			var res_path: String = "%s/%s" % [_UPGRADES_DIR, normalized]
			var res: Resource = load(res_path)
			var u: UpgradeData = res as UpgradeData
			if u:
				_cache.append(u)
		file_name = dir.get_next()
	dir.list_dir_end()

	return _cache.duplicate()
