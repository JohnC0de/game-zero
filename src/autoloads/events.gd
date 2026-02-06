extends Node
## Global event bus for decoupled communication

# Player events
signal player_spawned(player: Node2D)
signal player_damaged(current_hp: int, max_hp: int)
signal player_died
signal player_healed(current_hp: int, max_hp: int)

# XP & Leveling
signal xp_collected(amount: int, total: int)
signal level_up(new_level: int)
signal upgrade_selected(upgrade: UpgradeData)

# Combat
signal enemy_spawned(enemy: Node2D)
signal enemy_killed(enemy: Node2D, position: Vector2)
signal weapon_added(weapon: Node2D)
signal weapon_upgraded(weapon: Node2D, new_level: int)

# Game state
signal game_started
signal game_paused
signal game_resumed
signal game_over(stats: Dictionary)

# Wave system
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)


func _ready() -> void:
	Log.info("Events", "signal_bus_ready")
