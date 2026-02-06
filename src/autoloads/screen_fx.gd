extends Node
## Screen effects manager - shake, flash, slowmo, hit stop

var _camera: Camera2D = null
var _shake_amount: float = 0.0
var _shake_decay: float = 5.0
var _hitstop_active: bool = false


func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.player_damaged.connect(_on_player_damaged)
	Log.debug("ScreenFX", "ready")


## Hit stop - brief time freeze for impact feel
func hitstop(duration: float = 0.05) -> void:
	if _hitstop_active:
		return

	_hitstop_active = true
	var old_time_scale: float = Engine.time_scale
	Engine.time_scale = 0.0

	# Use a real timer (unaffected by time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout

	Engine.time_scale = old_time_scale
	_hitstop_active = false


func hitstop_small() -> void:
	hitstop(0.03)


func hitstop_medium() -> void:
	hitstop(0.06)


func hitstop_large() -> void:
	hitstop(0.1)


func _process(delta: float) -> void:
	if _shake_amount > 0:
		_shake_amount = maxf(0, _shake_amount - _shake_decay * delta)
		_apply_shake()
	elif _camera and _camera.offset != Vector2.ZERO:
		# Ensure we don't leave the camera permanently offset.
		_camera.offset = Vector2.ZERO


func shake(amount: float, decay: float = 5.0) -> void:
	_shake_amount = maxf(_shake_amount, amount)
	_shake_decay = decay


func shake_small() -> void:
	shake(3.0, 8.0)


func shake_medium() -> void:
	shake(6.0, 6.0)


func shake_large() -> void:
	shake(12.0, 4.0)


func _apply_shake() -> void:
	if not _camera:
		_camera = get_viewport().get_camera_2d()

	if _camera:
		_camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount)
		)


func _on_enemy_killed(_enemy: Node2D, _pos: Vector2) -> void:
	shake_small()


func _on_player_damaged(_current: int, _max: int) -> void:
	shake_medium()
