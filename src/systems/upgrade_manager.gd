extends Node
class_name UpgradeManager
## Manages available upgrades and generates choices on level-up

const MAX_WEAPON_LEVEL: int = 8

var _picked_counts: Dictionary = {}
var _picker: WeightedPicker = WeightedPicker.new()




func _ready() -> void:
	add_to_group("upgrade_manager")
	Events.game_started.connect(_on_game_started)
	Log.debug("UpgradeManager", "ready")


func _on_game_started() -> void:
	_picked_counts.clear()


func generate_choices(count: int = 3) -> Array[UpgradeData]:
	## Generate upgrade choices for level-up screen
	var choices: Array[UpgradeData] = []
	var available: Array[UpgradeData] = _get_available_upgrades()

	choices = _picker.pick_unique(available, count)

	Log.debug("UpgradeManager", "generated_choices", {count = choices.size()})
	return choices


func apply_upgrade(upgrade: UpgradeData) -> void:
	var player: Player = Game.player as Player
	if not player:
		Log.error("UpgradeManager", "no_player_for_upgrade")
		return

	match upgrade.type:
		UpgradeData.Type.NEW_WEAPON:
			if upgrade.weapon_scene:
				player.add_weapon(upgrade.weapon_scene)
				Log.info(
					"UpgradeManager",
					"applied_new_weapon",
					{weapon = upgrade.weapon_name}
				)
		UpgradeData.Type.UPGRADE_WEAPON:
			var weapon: Node2D = player.get_weapon_by_name(upgrade.weapon_name)
			if weapon and weapon.has_method("upgrade"):
				weapon.upgrade()
				var new_level: int = int(upgrade.stat_value)
				Log.info(
					"UpgradeManager",
					"applied_weapon_upgrade",
					{weapon = upgrade.weapon_name, level = new_level}
				)
		UpgradeData.Type.STAT_BOOST:
			_apply_stat_boost(player, upgrade)

	Events.upgrade_selected.emit(upgrade)
	_track_picked(upgrade)


func _get_available_upgrades() -> Array[UpgradeData]:
	var upgrades: Array[UpgradeData] = []
	var player: Player = Game.player as Player

	if not player:
		return upgrades

	# Check each weapon (only unlocked ones)
	for w: WeaponDef in WeaponCatalog.get_all():
		var weapon_name: String = w.weapon_name
		if weapon_name == "" or not w.weapon_scene:
			continue
		if not SaveData.is_weapon_unlocked(weapon_name):
			continue

		if player.has_weapon(weapon_name):
			# Offer upgrade if player has this weapon
			var weapon: Node2D = player.get_weapon_by_name(weapon_name)
			var level: int = 0
			var has_level: bool = false
			if weapon:
				var level_raw: Variant = weapon.get("level")
				has_level = level_raw != null
				if has_level:
					level = level_raw as int
			if weapon and has_level and level < MAX_WEAPON_LEVEL:
				upgrades.append(_make_weapon_upgrade(weapon_name, level + 1))
		else:
			upgrades.append(_make_new_weapon(weapon_name, w.weapon_scene))

	# Always include some stat boosts
	for u: UpgradeData in UpgradeCatalog.get_all():
		if _can_offer(u):
			upgrades.append(u)

	return upgrades


func _track_picked(upgrade: UpgradeData) -> void:
	var count: int = _picked_counts.get(upgrade.id, 0) as int
	_picked_counts[upgrade.id] = count + 1


func _can_offer(upgrade: UpgradeData) -> bool:
	var count: int = _picked_counts.get(upgrade.id, 0) as int
	return count < upgrade.max_stack


func _make_new_weapon(weapon_name: String, scene: PackedScene) -> UpgradeData:
	var u: UpgradeData = UpgradeData.new()
	u.id = "new_%s" % weapon_name
	u.display_name = "New: %s" % weapon_name
	u.description = "Acquire %s weapon" % weapon_name
	u.type = UpgradeData.Type.NEW_WEAPON
	u.icon_color = Color(1.0, 0.9, 0.2)
	u.weapon_scene = scene
	u.weapon_name = weapon_name
	return u


func _make_weapon_upgrade(weapon_name: String, new_level: int) -> UpgradeData:
	var u: UpgradeData = UpgradeData.new()
	u.id = "up_%s_%d" % [weapon_name, new_level]
	u.display_name = "%s Lv.%d" % [weapon_name, new_level]
	u.description = "Upgrade %s" % weapon_name
	u.type = UpgradeData.Type.UPGRADE_WEAPON
	u.icon_color = Color(0.3, 1.0, 0.5)
	u.weapon_name = weapon_name
	# stat_value is reused to carry the resulting level for display/logging.
	u.stat_value = float(new_level)
	return u


func _apply_stat_boost(_player: Player, upgrade: UpgradeData) -> void:
	var stat: Stats.Stat = upgrade.stat
	var value: float = upgrade.stat_value
	match upgrade.stat_op:
		UpgradeData.StatOp.MUL:
			Stats.apply_mul(stat, value)
		UpgradeData.StatOp.ADD:
			Stats.apply_add(stat, value)
