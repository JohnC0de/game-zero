extends Node2D
class_name WeaponNode
## Minimal shared weapon base (level + upgrade signaling).

signal upgraded(new_level: int)

var level: int = 1


func upgrade() -> void:
	level += 1
	var wn: Variant = get("weapon_name")
	var name: String = wn as String if wn != null else "Weapon"
	Log.info("Weapon", "upgraded", {name = name, level = level})
	upgraded.emit(level)
