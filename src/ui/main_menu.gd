extends CanvasLayer
class_name MainMenu
## Main menu screen

const UIStyle: Script = preload("res://src/ui/ui_style.gd")
const UIFx: Script = preload("res://src/ui/ui_fx.gd")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://src/ui/settings_menu.tscn")

@onready var title: Label = $Panel/VBox/Title
@onready var start_button: Button = $Panel/VBox/StartButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

@onready var update_panel: PanelContainer = $Panel/VBox/UpdatePanel
@onready var update_label: Label = $Panel/VBox/UpdatePanel/UpdateVBox/UpdateLabel
@onready var update_button: Button = $Panel/VBox/UpdatePanel/UpdateVBox/UpdateHBox/UpdateButton
@onready var update_progress: Label = $Panel/VBox/UpdatePanel/UpdateVBox/UpdateProgress

@onready var version_label: Label = $Panel/VBox/VersionLabel

var _settings_menu: CanvasLayer = null


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	update_button.pressed.connect(_on_update_pressed)
	UIStyle.apply_title(title)
	UIStyle.apply_button(start_button, UIStyle.COLOR_ACCENT)
	UIStyle.apply_button(settings_button, UIStyle.COLOR_WARN)
	UIStyle.apply_button(quit_button, UIStyle.COLOR_GOOD)
	UIStyle.apply_button(update_button, UIStyle.COLOR_WARN)
	UIStyle.apply_body(update_label, UIStyle.COLOR_TEXT, 16)
	UIStyle.apply_subtitle(update_progress, UIStyle.COLOR_MUTED, 14)
	update_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.COLOR_WARN))
	UIStyle.apply_subtitle(version_label, UIStyle.COLOR_MUTED, 14)
	version_label.text = "Version: %s" % UpdateManager.get_current_version()
	UIFx.set_initial_focus(start_button)
	UIFx.fade_in($Panel as CanvasItem)

	# Pulsing title animation
	_animate_title()

	_update_panel_hide()
	_update_connect_signals()
	UpdateManager.check_for_updates()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_quit_pressed()


func _on_start_pressed() -> void:
	Log.info("MainMenu", "start_pressed")
	start_button.disabled = true
	quit_button.disabled = true
	UIFx.fade_out_then(
		$Panel as CanvasItem,
		func() -> void: get_tree().change_scene_to_file("res://world.tscn")
	)


func _on_quit_pressed() -> void:
	Log.info("MainMenu", "quit_pressed")
	get_tree().quit()


func _on_settings_pressed() -> void:
	if not _settings_menu:
		_settings_menu = SETTINGS_MENU_SCENE.instantiate() as CanvasLayer
		add_child(_settings_menu)
		if _settings_menu.has_signal("closed"):
			_settings_menu.connect(
				"closed",
				func() -> void:
					UIFx.set_initial_focus(settings_button)
			)
	_settings_menu.call("open")


func _on_update_pressed() -> void:
	Log.info("MainMenu", "update_pressed")
	update_button.disabled = true
	update_progress.text = "Downloading..."
	UpdateManager.start_update_download()


func _update_connect_signals() -> void:
	UpdateManager.update_checked.connect(_on_update_checked)
	UpdateManager.update_download_progress.connect(_on_update_progress)
	UpdateManager.update_ready.connect(_on_update_ready)
	UpdateManager.update_error.connect(_on_update_error)


func _update_panel_hide() -> void:
	update_panel.visible = false
	update_label.text = ""
	update_progress.text = ""
	update_button.disabled = false


func _on_update_checked(update_available: bool, current_version: String, latest_version: String) -> void:
	if not update_available:
		_update_panel_hide()
		return
	update_panel.visible = true
	update_label.text = "New version: %s\nCurrent: %s" % [latest_version, current_version]
	update_progress.text = ""
	update_button.disabled = false


func _on_update_progress(downloaded_bytes: int, total_bytes: int) -> void:
	if total_bytes <= 0:
		update_progress.text = "%0.1f MB" % (float(downloaded_bytes) / 1048576.0)
		return
	var pct: float = (float(downloaded_bytes) / float(total_bytes)) * 100.0
	var mb_done: float = float(downloaded_bytes) / 1048576.0
	var mb_total: float = float(total_bytes) / 1048576.0
	update_progress.text = "%0.1f%% (%0.1f/%0.1f MB)" % [pct, mb_done, mb_total]


func _on_update_ready(latest_version: String) -> void:
	Log.info("MainMenu", "update_ready", {"version": latest_version})
	update_progress.text = "Applying update..."
	UpdateManager.apply_update_and_restart()


func _on_update_error(message: String) -> void:
	Log.warn("MainMenu", "update_error", {"message": message})
	update_panel.visible = true
	update_label.text = "Update failed"
	update_progress.text = message
	update_button.disabled = false


func _animate_title() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(title, "modulate:a", 0.7, 1.0)
	tween.tween_property(title, "modulate:a", 1.0, 1.0)
