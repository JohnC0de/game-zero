extends Node2D
class_name DamageNumber
## Floating damage number that rises and fades

const FLOAT_SPEED: float = 80.0
const FLOAT_DURATION: float = 0.6
const SPREAD: float = 20.0

const POOL_LIMIT: int = 128
static var _pool: Array[DamageNumber] = []

var amount: int = 0
var color: Color = Color.WHITE

var _tween: Tween = null

@onready var label: Label


func _ready() -> void:
	_ensure_label()
	hide()


func _ensure_label() -> void:
	if label:
		return
	label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Center the label
	label.position = Vector2(-20, -10)
	label.custom_minimum_size = Vector2(40, 20)

	add_child(label)


func _play() -> void:
	_ensure_label()
	show()

	if _tween:
		_tween.kill()
		_tween = null

	label.text = str(amount)
	label.add_theme_color_override("font_color", color)
	label.modulate.a = 1.0

	scale = Vector2.ONE
	position.x += randf_range(-SPREAD, SPREAD)

	_tween = create_tween().set_ignore_time_scale(true)
	_tween.set_parallel(true)

	# Float upward
	_tween.tween_property(self, "position:y", position.y - FLOAT_SPEED * FLOAT_DURATION, FLOAT_DURATION)

	# Scale up then down (pop effect)
	_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	_tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	# Fade out in second half
	_tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION * 0.5).set_delay(FLOAT_DURATION * 0.5)

	# Cleanup
	_tween.chain().tween_callback(_recycle)


func _recycle() -> void:
	if _tween:
		_tween.kill()
		_tween = null

	hide()
	if is_inside_tree() and get_parent():
		get_parent().remove_child(self)

	if _pool.size() < POOL_LIMIT:
		_pool.append(self)
	else:
		queue_free()


static func clear_pool() -> void:
	for dn: DamageNumber in _pool:
		if is_instance_valid(dn):
			dn.free()
	_pool.clear()


## Factory method to spawn a damage number
static func spawn(
	parent: Node, pos: Vector2, dmg: int, dmg_color: Color = Color.WHITE
) -> DamageNumber:
	var instance: DamageNumber = _pool.pop_back() if not _pool.is_empty() else DamageNumber.new()
	instance.amount = dmg
	instance.color = dmg_color
	instance.global_position = pos
	parent.add_child(instance)
	instance._play()
	return instance
