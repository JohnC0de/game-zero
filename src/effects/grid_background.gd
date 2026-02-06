extends ColorRect
class_name GridBackground
## Infinite scrolling grid background that follows camera

@export var parallax_factor: float = 0.5
@export var grid_size: float = 50.0

var _shader_material: ShaderMaterial


func _ready() -> void:
	# Ensure we cover the full screen
	set_anchors_preset(Control.PRESET_FULL_RECT)

	if material is ShaderMaterial:
		_shader_material = material as ShaderMaterial
		_shader_material.set_shader_parameter("grid_size", grid_size)


func _process(_delta: float) -> void:
	if not _shader_material:
		return

	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		var offset: Vector2 = camera.global_position * parallax_factor
		_shader_material.set_shader_parameter("offset", offset)
