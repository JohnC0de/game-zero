extends WeaponNode
## Nova weapon - periodic AoE damage pulse

@export var weapon_name: String = "Nova"
@export var base_damage: int = 15
@export var base_cooldown: float = 3.0
@export var base_radius: float = 100.0

var _cooldown_timer: float = 0.0

# Calculated stats
var damage: int:
	get:
		return int(base_damage * (1.0 + (level - 1) * 0.2))
var cooldown: float:
	get:
		return maxf(1.0, base_cooldown - (level - 1) * 0.3)
var radius: float:
	get:
		return base_radius + (level - 1) * 20.0


func _ready() -> void:
	Log.debug("Weapon", "equipped", {name = weapon_name, level = level})


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0:
		_pulse()
		_cooldown_timer = cooldown


func upgrade() -> void:
	super.upgrade()


func _pulse() -> void:
	# Find all enemies in radius
	var enemy_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_hitbox")
	var hit_count: int = 0

	for node: Node in enemy_nodes:
		var enemy_area: Area2D = node as Area2D
		if not enemy_area:
			continue
		var enemy: Node2D = enemy_area.get_parent() as Node2D
		if not enemy or not is_instance_valid(enemy):
			continue

		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_count += 1

	# Visual effect
	_spawn_pulse_visual()

	if hit_count > 0:
		Log.debug("Weapon", "nova_pulse", {hits = hit_count, radius = radius})


func _spawn_pulse_visual() -> void:
	# Create expanding ring visual
	var ring: Line2D = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.5, 0.8, 0.8)
	ring.closed = true

	# Create circle points
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	for i: int in segments + 1:
		var angle: float = (float(i) / segments) * TAU
		points.append(Vector2.from_angle(angle) * 10.0)
	ring.points = points

	add_child(ring)

	# Animate expansion and fade
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * (radius / 10.0), 0.3)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(ring.queue_free)
