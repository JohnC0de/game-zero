extends WeaponNode
class_name WeaponBase
## Base class for all weapons - handles targeting and firing

signal fired

@export var weapon_name: String = "Weapon"
@export var base_damage: int = 5
@export var base_cooldown: float = 1.0
@export var base_projectile_count: int = 1
@export var projectile_scene: PackedScene

var _cooldown_timer: float = 0.0

# Calculated stats (modified by level)
var damage: int:
	get:
		return _calculate_damage()
var cooldown: float:
	get:
		return _calculate_cooldown()
var projectile_count: int:
	get:
		return _calculate_projectile_count()


func _ready() -> void:
	Log.debug("Weapon", "equipped", {name = weapon_name, level = level})


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0:
		var target: Node2D = _find_target()
		if target:
			_fire(target)
			_cooldown_timer = cooldown


func _find_target() -> Node2D:
	## Override for different targeting behavior. Default: nearest enemy.
	var enemy_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_hitbox")
	if enemy_nodes.is_empty():
		return null

	var nearest: Node2D = null
	var nearest_dist: float = INF

	for node: Node in enemy_nodes:
		var enemy_area: Area2D = node as Area2D
		if not enemy_area:
			continue
		var enemy: Node2D = enemy_area.get_parent() as Node2D
		if not enemy or not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func _fire(_target: Node2D) -> void:
	## Override in subclasses for weapon-specific firing logic
	pass


func _spawn_projectile(direction: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	if not projectile_scene:
		return null

	var projectile: Node2D = projectile_scene.instantiate()
	var base: ProjectileBase = projectile as ProjectileBase
	if base:
		base.damage = damage
	projectile.global_position = global_position + offset

	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

	# Add to projectiles container via arena
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena and arena.has_method("spawn_projectile"):
		arena.spawn_projectile(projectile)
	else:
		get_tree().current_scene.add_child(projectile)

	fired.emit()
	return projectile


func _calculate_damage() -> int:
	var scaling: WeaponScalingConfig = Balance.get_weapon_scaling_config()
	var base: float = float(base_damage) * scaling.get_damage_multiplier(level)
	base *= Stats.get_mul(Stats.Stat.PLAYER_DAMAGE_MUL)
	return int(base)


func _calculate_cooldown() -> float:
	var scaling: WeaponScalingConfig = Balance.get_weapon_scaling_config()
	var cd: float = base_cooldown * scaling.get_cooldown_multiplier(level)
	cd *= Stats.get_mul(Stats.Stat.PLAYER_COOLDOWN_MUL)
	return maxf(scaling.cooldown_min, cd)


func _calculate_projectile_count() -> int:
	var scaling: WeaponScalingConfig = Balance.get_weapon_scaling_config()
	var count: int = base_projectile_count + scaling.get_extra_projectiles(level)
	count += int(Stats.get_add(Stats.Stat.WEAPON_PROJECTILE_ADD))
	return maxi(1, count)
