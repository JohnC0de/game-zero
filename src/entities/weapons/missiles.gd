extends WeaponNode
## Missiles weapon - fires homing projectiles

const MISSILE_SCENE: PackedScene = preload("res://src/entities/weapons/missile_projectile.tscn")

@export var weapon_name: String = "Missiles"
@export var base_damage: int = 12
@export var base_cooldown: float = 1.5
@export var base_missile_count: int = 1

var _cooldown_timer: float = 0.0

# Calculated stats
var damage: int:
	get:
		return int(base_damage * (1.0 + (level - 1) * 0.15))
var cooldown: float:
	get:
		return maxf(0.5, base_cooldown - (level - 1) * 0.15)
var missile_count: int:
	get:
		return base_missile_count + int((level - 1) / 2)


func _ready() -> void:
	Log.debug("Weapon", "equipped", {name = weapon_name, level = level})


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0:
		var targets: Array[Node2D] = _find_targets()
		if targets.size() > 0:
			_fire(targets)
			_cooldown_timer = cooldown


func upgrade() -> void:
	super.upgrade()


func _find_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var candidates: Array[Node2D] = []
	var enemy_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_hitbox")
	for node: Node in enemy_nodes:
		var enemy_area: Area2D = node as Area2D
		if not enemy_area:
			continue
		var enemy: Node2D = enemy_area.get_parent() as Node2D
		if not enemy or not is_instance_valid(enemy):
			continue
		candidates.append(enemy)

	# Sort by distance (closest first)
	candidates.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			return (
				global_position.distance_squared_to(a.global_position)
				< global_position.distance_squared_to(b.global_position)
			)
	)

	# Take closest N
	for i: int in mini(missile_count, candidates.size()):
		targets.append(candidates[i])

	return targets


func _fire(targets: Array[Node2D]) -> void:
	for target: Node2D in targets:
		var missile: Node2D = MISSILE_SCENE.instantiate()
		missile.damage = damage
		missile.target = target
		missile.global_position = global_position

		# Add to projectiles container
		var arena: Node = get_tree().get_first_node_in_group("arena")
		if arena and arena.has_method("spawn_projectile"):
			arena.spawn_projectile(missile)
		else:
			get_tree().current_scene.add_child(missile)
