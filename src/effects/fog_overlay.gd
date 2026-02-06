extends CanvasLayer
class_name FogOverlay

@onready var _rect: ColorRect = $FogRect

var _player: Node2D = null
var _mat: ShaderMaterial = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_mat = _rect.material as ShaderMaterial
	_apply_config()
	_update_viewport_size()

	Events.player_spawned.connect(_on_player_spawned)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _process(_delta: float) -> void:
	if not _mat:
		return
	_mat.set_shader_parameter("player_screen_px", _get_player_screen_pos_px())


func _on_player_spawned(p: Node2D) -> void:
	_player = p


func _on_viewport_size_changed() -> void:
	_update_viewport_size()


func _apply_config() -> void:
	if not _mat:
		return

	var cfg: FogConfig = Balance.get_fog_config()
	_mat.set_shader_parameter("radius_px", cfg.visibility_radius_px)
	_mat.set_shader_parameter("softness_px", cfg.edge_softness_px)
	_mat.set_shader_parameter("darkness_alpha", cfg.darkness_alpha)
	_mat.set_shader_parameter("noise_strength", cfg.noise_strength)
	_mat.set_shader_parameter("noise_scale", cfg.noise_scale)


func _update_viewport_size() -> void:
	if not _mat:
		return
	var size: Vector2 = _get_viewport_size()
	_mat.set_shader_parameter("viewport_size_px", size)


func _get_player_screen_pos_px() -> Vector2:
	var fallback: Vector2 = _get_viewport_size() * 0.5
	if not _player or not is_instance_valid(_player):
		return fallback

	# get_canvas_transform converts world -> screen (includes Camera2D offset/shake).
	var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_xform * _player.global_position


func _get_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size
