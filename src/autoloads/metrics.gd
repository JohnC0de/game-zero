extends Node

var _kills_at_start: int = 0
var _time_at_start: float = 0.0


func _ready() -> void:
	Events.game_started.connect(_on_game_started)
	Events.enemy_killed.connect(_on_enemy_killed)


func _on_game_started() -> void:
	_kills_at_start = Game.kills
	_time_at_start = Game.run_time


func _on_enemy_killed(_enemy: Node2D, _pos: Vector2) -> void:
	pass


func get_kills_per_minute() -> float:
	var dt: float = maxf(0.001, Game.run_time - _time_at_start)
	var dk: int = Game.kills - _kills_at_start
	return (float(dk) / dt) * 60.0
