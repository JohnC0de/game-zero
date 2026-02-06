extends Resource
class_name WeaponDef

@export var weapon_name: String = ""
@export var weapon_scene: PackedScene
@export var unlock_total_kills: int = 0


func is_default_unlocked() -> bool:
	return unlock_total_kills <= 0
