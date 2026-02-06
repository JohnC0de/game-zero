extends CharacterBody2D
class_name Player
## Player entity with movement, health, i-frames, and weapon mounting

signal health_changed(current: int, maximum: int)

@export var max_hp: int = 100
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var invincibility_duration: float = 1.0

var _base_max_hp: int = 100

var current_hp: int
var is_invincible: bool = false
var weapons: Array[Node2D] = []

@onready var weapon_mount: Node2D = $WeaponMount
@onready var pickup_area: Area2D = $PickupArea
@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Polygon2D = $Sprite
@onready var invincibility_timer: Timer = $InvincibilityTimer


func _ready() -> void:
	var cfg: PlayerConfig = Balance.get_player_config()
	_base_max_hp = cfg.base_max_hp
	max_hp = cfg.base_max_hp
	move_speed = cfg.base_move_speed
	acceleration = cfg.base_acceleration
	friction = cfg.base_friction
	invincibility_duration = cfg.base_invincibility_duration

	current_hp = max_hp
	Stats.changed.connect(_apply_stats)
	_apply_stats()
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_ended)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	pickup_area.area_entered.connect(_on_pickup_collected)

	# Equip starting weapon
	var start_weapon: PackedScene = WeaponCatalog.get_scene("Blaster")
	if start_weapon:
		add_weapon(start_weapon)
	else:
		Log.error("Player", "missing_start_weapon", {weapon = "Blaster"})

	Events.player_spawned.emit(self)
	Log.info("Player", "spawned", {hp = current_hp, pos = global_position})


func _physics_process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return

	var input: Vector2 = _get_input_direction()
	_apply_movement(input, delta)
	move_and_slide()

	# Rotate to face movement direction
	if velocity.length_squared() > 100:
		sprite.rotation = velocity.angle() + PI / 2


func _get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _apply_movement(input: Vector2, delta: float) -> void:
	if input != Vector2.ZERO:
		var speed: float = move_speed * Stats.get_mul(Stats.Stat.PLAYER_MOVE_SPEED_MUL)
		velocity = velocity.move_toward(input * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func take_damage(amount: int) -> void:
	if is_invincible:
		return

	var reduction: float = Stats.get_mul(Stats.Stat.PLAYER_DAMAGE_REDUCTION_MUL)
	var final_amount: int = maxi(1, int(float(amount) * reduction))
	current_hp = max(0, current_hp - final_amount)
	Log.info("Player", "damaged", {damage = amount, hp = current_hp, max = max_hp})
	Events.player_damaged.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_die()
	else:
		_start_invincibility()


func heal(amount: int) -> void:
	var old_hp: int = current_hp
	current_hp = min(max_hp, current_hp + amount)
	if current_hp != old_hp:
		Log.debug("Player", "healed", {amount = current_hp - old_hp, hp = current_hp})
		Events.player_healed.emit(current_hp, max_hp)
		health_changed.emit(current_hp, max_hp)


func collect_xp(amount: int) -> void:
	Game.add_xp(amount)


func add_weapon(weapon_scene: PackedScene) -> Node2D:
	var weapon: Node2D = weapon_scene.instantiate()
	weapon_mount.add_child(weapon)
	weapons.append(weapon)
	Log.info("Player", "weapon_added", {weapon = weapon.name, total = weapons.size()})
	Events.weapon_added.emit(weapon)

	# Re-emit weapon upgrades to the global event bus.
	var weapon_node: WeaponNode = weapon as WeaponNode
	if weapon_node:
		weapon_node.upgraded.connect(
			func(new_level: int) -> void: Events.weapon_upgraded.emit(weapon_node, new_level)
		)

	return weapon


func get_weapon_by_name(weapon_name: String) -> Node2D:
	for weapon: Node2D in weapons:
		var wn: Variant = weapon.get("weapon_name")
		if wn != null and (wn as String) == weapon_name:
			return weapon
	return null


func has_weapon(weapon_name: String) -> bool:
	return get_weapon_by_name(weapon_name) != null


func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer.start()
	_flash_invincibility()


func _on_invincibility_ended() -> void:
	is_invincible = false
	sprite.modulate.a = 1.0


func _flash_invincibility() -> void:
	if not is_invincible:
		return
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	invincibility_timer.timeout.connect(func() -> void: tween.kill(), CONNECT_ONE_SHOT)


func _die() -> void:
	Log.info("Player", "died", {xp = Game.current_xp})
	Events.player_died.emit()
	# Don't queue_free - let game manager handle scene transition


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var parent: Node = area.get_parent()
		var raw: Variant = parent.get("contact_damage") if parent and is_instance_valid(parent) else null
		var damage: int = raw as int if raw != null else 10
		take_damage(damage)


func _on_pickup_collected(area: Area2D) -> void:
	if area.is_in_group("pickup"):
		var pickup: Node = area.get_parent()
		if pickup.has_method("collect"):
			pickup.collect(self)


func _apply_stats() -> void:
	max_hp = _base_max_hp + int(Stats.get_add(Stats.Stat.PLAYER_MAX_HP_ADD))
	current_hp = mini(max_hp, current_hp)
	Events.player_healed.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
