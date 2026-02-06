extends WeaponNode
## Orbit weapon - rotating damage shields around the player

@export var weapon_name: String = "Orbit"
@export var base_damage: int = 8
@export var base_orb_count: int = 2
@export var orbit_radius: float = 60.0
@export var rotation_speed: float = 3.0  # Radians per second

var _orbs: Array[Area2D] = []
var _angle: float = 0.0

# Calculated stats
var damage: int:
	get:
		return int(base_damage * (1.0 + (level - 1) * 0.25))
var orb_count: int:
	get:
		return base_orb_count + int((level - 1) / 2)


func _ready() -> void:
	_create_orbs()
	Log.debug("Weapon", "equipped", {name = weapon_name, level = level})


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_angle += rotation_speed * delta
	_update_orb_positions()


func upgrade() -> void:
	super.upgrade()
	_create_orbs()  # Recreate with new count


func _create_orbs() -> void:
	# Clear existing orbs
	for orb: Area2D in _orbs:
		orb.queue_free()
	_orbs.clear()

	# Create new orbs
	for i: int in orb_count:
		var orb: Area2D = _create_single_orb()
		add_child(orb)
		_orbs.append(orb)

	_update_orb_positions()


func _create_single_orb() -> Area2D:
	var orb: Area2D = Area2D.new()
	orb.collision_layer = 4  # Player projectile
	orb.collision_mask = 2  # Enemy

	# Visual
	var sprite: Polygon2D = Polygon2D.new()
	sprite.color = Color(0.2, 0.8, 1.0)
	sprite.polygon = PackedVector2Array(
		[Vector2(0, -10), Vector2(-8, 0), Vector2(0, 10), Vector2(8, 0)]
	)
	orb.add_child(sprite)

	# Collision
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	orb.add_child(shape)

	# Damage on contact
	orb.area_entered.connect(_on_orb_hit.bind(orb))

	return orb


func _update_orb_positions() -> void:
	var count: int = _orbs.size()
	if count == 0:
		return

	var angle_step: float = TAU / count
	for i: int in count:
		var orb_angle: float = _angle + (angle_step * i)
		_orbs[i].position = Vector2.from_angle(orb_angle) * orbit_radius


func _on_orb_hit(area: Area2D, _orb: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy: Node2D = area.get_parent() as Node2D
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
