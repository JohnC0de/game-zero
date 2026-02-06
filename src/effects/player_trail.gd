extends Line2D
## Motion trail effect for the player

@export var max_points: int = 15
@export var point_interval: float = 0.02

var _timer: float = 0.0
var _target: Node2D = null


func _ready() -> void:
	width = 8.0
	default_color = Color(0.2, 0.9, 1.0, 0.5)
	width_curve = Curve.new()
	width_curve.add_point(Vector2(0, 1))
	width_curve.add_point(Vector2(1, 0))

	# Wait for player to be available
	call_deferred("_setup_target")


func _setup_target() -> void:
	_target = Game.player


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_timer -= delta
	if _timer <= 0:
		_timer = point_interval
		_add_point(_target.global_position)

	# Remove old points
	while get_point_count() > max_points:
		remove_point(0)


func _add_point(pos: Vector2) -> void:
	add_point(pos)
