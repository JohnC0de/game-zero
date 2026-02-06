extends CanvasLayer
class_name GameOverUI
## Game over screen with stats and restart option

const UIStyle: Script = preload("res://src/ui/ui_style.gd")
const UIFx: Script = preload("res://src/ui/ui_fx.gd")

@onready var stats_label: Label = $Panel/VBox/Stats
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton
@onready var version_label: Label = $Panel/VBox/VersionLabel


func _ready() -> void:
	# Allow input while game is paused (GAME_OVER pauses the tree).
	UIFx.allow_input_while_paused(self)

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	Events.game_over.connect(_on_game_over)
	hide()
	UIStyle.apply_button(restart_button, UIStyle.COLOR_GOOD)
	UIStyle.apply_button(menu_button, UIStyle.COLOR_ACCENT)
	UIStyle.apply_body(stats_label)
	UIStyle.apply_subtitle(version_label, UIStyle.COLOR_MUTED, 14)
	version_label.text = "Version: %s" % UpdateManager.get_current_version()


func _on_game_over(stats: Dictionary) -> void:
	var time: float = stats.get("time", 0.0) as float
	var minutes: int = int(time / 60.0)
	var seconds: int = int(time) % 60
	var kills: int = stats.get("kills", 0) as int
	var level: int = stats.get("level", 1) as int

	stats_label.text = "Time: %d:%02d\nKills: %d\nLevel: %d" % [minutes, seconds, kills, level]

	show()
	UIFx.fade_in($Panel as CanvasItem)
	UIFx.set_initial_focus(restart_button)
	Log.info("GameOver", "displayed", stats)


func _on_restart_pressed() -> void:
	Log.info("GameOver", "restart_pressed")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	Log.info("GameOver", "menu_pressed")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
