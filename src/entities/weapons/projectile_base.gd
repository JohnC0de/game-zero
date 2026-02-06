extends Area2D
class_name ProjectileBase
## Base class for all projectiles

@export var speed: float = 500.0
@export var damage: int = 5
@export var lifetime: float = 3.0
@export var pierce: int = 1  # How many enemies to hit before destroying

var direction: Vector2 = Vector2.RIGHT
var _hits_remaining: int

@onready var sprite: Node2D = $Sprite


func _ready() -> void:
	_hits_remaining = pierce
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	global_position += direction * speed * delta

	# Rotate sprite to face direction
	if sprite:
		sprite.rotation = direction.angle()


func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()


func _on_body_entered(body: Node2D) -> void:
	_try_damage(body)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var target: Node2D = area.get_parent() as Node2D
		if target:
			_try_damage(target)


func _try_damage(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
		_hits_remaining -= 1

		if _hits_remaining <= 0:
			_on_destroyed()


func _on_destroyed() -> void:
	# Override for death effects
	queue_free()
