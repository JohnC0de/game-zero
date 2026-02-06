extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

var master_volume: float = 1.0
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply()


func apply() -> void:
	_apply_audio()
	_apply_display()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	save_settings()


func _apply_audio() -> void:
	var idx: int = AudioServer.get_bus_index("Master")
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, master_volume)))
	AudioServer.set_bus_mute(idx, master_volume <= 0.0001)


func _apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(SETTINGS_PATH)
	if err != OK:
		return

	master_volume = cfg.get_value("audio", "master_volume", 1.0) as float
	fullscreen = cfg.get_value("display", "fullscreen", false) as bool
