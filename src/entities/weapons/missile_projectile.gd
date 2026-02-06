extends Area2D
## Homing missile projectile

@export var speed: float = 350.0
@export var turn_rate: float = 5.0  # Radians per second
@export var damage: int = 12
@export var lifetime: float = 4.0

var target: Node2D = null
var direction: Vector2 = Vector2.UP

@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	area_entered.connect(_on_area_entered)

	# Random initial direction if no target
	if not target:
		direction = Vector2.from_angle(randf() * TAU)
	else:
		direction = global_position.direction_to(target.global_position)

	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	# Home toward target if valid
	if is_instance_valid(target):
		var target_dir: Vector2 = global_position.direction_to(target.global_position)
		var angle_diff: float = direction.angle_to(target_dir)
		var tr: float = turn_rate * Stats.get_mul(Stats.Stat.MISSILE_TURN_RATE_MUL)
		var max_turn: float = tr * delta
		angle_diff = clampf(angle_diff, -max_turn, max_turn)
		direction = direction.rotated(angle_diff)

	global_position += direction * speed * delta

	# Rotate sprite to face direction
	if sprite:
		sprite.rotation = direction.angle() + PI / 2


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy: Node2D = area.get_parent() as Node2D
		if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		queue_free()
