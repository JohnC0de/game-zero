extends Node

var config: BalanceConfig = BalanceConfig.new()


func get_xp_for_level(level: int) -> int:
	return config.progression.get_xp_for_level(level)


func get_spawn_interval(run_time: float) -> float:
	return config.spawn.get_spawn_interval(run_time)


func get_spawn_count(run_time: float) -> int:
	return config.spawn.get_spawn_count(run_time)


func get_enemy_hp_multiplier(run_time: float) -> float:
	return config.enemy_scaling.get_hp_multiplier(run_time)


func get_enemy_speed_multiplier(run_time: float) -> float:
	return config.enemy_scaling.get_speed_multiplier(run_time)


func get_player_config() -> PlayerConfig:
	return config.player


func get_weapon_scaling_config() -> WeaponScalingConfig:
	return config.weapon_scaling


func get_fog_config() -> FogConfig:
	return config.fog
