extends Node

signal changed

enum Stat {
	PLAYER_DAMAGE_MUL,
	PLAYER_COOLDOWN_MUL,
	PLAYER_MOVE_SPEED_MUL,
	PLAYER_PICKUP_RANGE_MUL,
	PLAYER_MAX_HP_ADD,
	PLAYER_DAMAGE_REDUCTION_MUL,
	WEAPON_PROJECTILE_ADD,
	BLASTER_SPREAD_MUL,
	MISSILE_TURN_RATE_MUL,
}

var _mul: Array[float] = []
var _add: Array[float] = []


func _ready() -> void:
	Events.game_started.connect(reset_run)
	reset_run()


func reset_run() -> void:
	_mul = []
	_add = []
	for i: int in Stat.size():
		_mul.append(1.0)
		_add.append(0.0)
	changed.emit()


func apply_mul(stat: Stat, factor: float) -> void:
	_mul[stat] *= factor
	changed.emit()


func apply_add(stat: Stat, value: float) -> void:
	_add[stat] += value
	changed.emit()


func get_mul(stat: Stat) -> float:
	return _mul[stat]


func get_add(stat: Stat) -> float:
	return _add[stat]
