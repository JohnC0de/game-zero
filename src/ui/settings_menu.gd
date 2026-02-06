extends CanvasLayer
class_name SettingsMenu

signal closed

const UIStyle: Script = preload("res://src/ui/ui_style.gd")
const UIFx: Script = preload("res://src/ui/ui_fx.gd")

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var volume_slider: HSlider = $Panel/VBox/VolumeRow/Volume
@onready var fullscreen_checkbox: CheckBox = $Panel/VBox/Fullscreen
@onready var back_button: Button = $Panel/VBox/Back


func _ready() -> void:
	UIFx.allow_input_while_paused(self)
	UIStyle.apply_title(title_label, UIStyle.COLOR_ACCENT, 36)
	UIStyle.apply_button(back_button, UIStyle.COLOR_ACCENT)
	UIStyle.apply_body($Panel/VBox/VolumeRow/VolumeLabel as Label)
	fullscreen_checkbox.add_theme_color_override("font_color", UIStyle.COLOR_TEXT)
	fullscreen_checkbox.add_theme_font_size_override("font_size", 18)

	back_button.pressed.connect(_on_back)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	hide()


func open() -> void:
	volume_slider.value = Settings.master_volume
	fullscreen_checkbox.button_pressed = Settings.fullscreen
	show()
	UIFx.fade_in(panel as CanvasItem)
	UIFx.set_initial_focus(back_button)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()


func _on_back() -> void:
	hide()
	closed.emit()


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.set_fullscreen(enabled)
