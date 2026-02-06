extends CanvasLayer
class_name PauseMenu

const UIStyle: Script = preload("res://src/ui/ui_style.gd")
const UIFx: Script = preload("res://src/ui/ui_fx.gd")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://src/ui/settings_menu.tscn")

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var resume_button: Button = $Panel/VBox/Resume
@onready var settings_button: Button = $Panel/VBox/Settings
@onready var menu_button: Button = $Panel/VBox/Menu
@onready var quit_button: Button = $Panel/VBox/Quit

@onready var version_label: Label = $Panel/VBox/VersionLabel

var _settings_menu: CanvasLayer = null


func _ready() -> void:
	UIFx.allow_input_while_paused(self)
	UIStyle.apply_title(title_label, UIStyle.COLOR_WARN, 40)
	UIStyle.apply_button(resume_button, UIStyle.COLOR_GOOD)
	UIStyle.apply_button(settings_button, UIStyle.COLOR_ACCENT)
	UIStyle.apply_button(menu_button, UIStyle.COLOR_ACCENT)
	UIStyle.apply_button(quit_button, UIStyle.COLOR_BAD)
	UIStyle.apply_subtitle(version_label, UIStyle.COLOR_MUTED, 14)
	version_label.text = "Version: %s" % UpdateManager.get_current_version()

	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	menu_button.pressed.connect(_on_menu)
	quit_button.pressed.connect(_on_quit)

	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle()


func _toggle() -> void:
	if Game.state == Game.State.LEVEL_UP:
		return
	if Game.state == Game.State.GAME_OVER:
		return
	if Game.state == Game.State.MENU:
		return

	if visible:
		_on_resume()
		return

	if Game.state == Game.State.PLAYING:
		Game.state = Game.State.PAUSED
		show()
		UIFx.fade_in(panel as CanvasItem)
		UIFx.set_initial_focus(resume_button)
		Log.info("PauseMenu", "opened")


func _on_resume() -> void:
	if Game.state == Game.State.PAUSED:
		Game.state = Game.State.PLAYING
	hide()
	Log.info("PauseMenu", "resumed")


func _on_settings() -> void:
	if not _settings_menu:
		_settings_menu = SETTINGS_MENU_SCENE.instantiate() as CanvasLayer
		add_child(_settings_menu)
		if _settings_menu.has_signal("closed"):
			_settings_menu.connect(
				"closed",
				func() -> void:
					show()
					UIFx.set_initial_focus(resume_button)
			)
	hide()
	_settings_menu.call("open")


func _on_menu() -> void:
	Log.info("PauseMenu", "main_menu")
	get_tree().paused = false
	Game.state = Game.State.MENU
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _on_quit() -> void:
	Log.info("PauseMenu", "quit")
	get_tree().quit()
