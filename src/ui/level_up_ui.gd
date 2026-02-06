extends CanvasLayer
class_name LevelUpUI
## Shows upgrade choices when player levels up

const UIStyle: Script = preload("res://src/ui/ui_style.gd")
const UIFx: Script = preload("res://src/ui/ui_fx.gd")
const UpgradeChoiceCardScene: PackedScene = preload("res://src/ui/upgrade_choice_card.tscn")

signal upgrade_chosen(upgrade: UpgradeData)

@onready var panel: Control = $Panel
@onready var glow: TextureRect = $Panel/Backdrop/Glow

@onready var card: PanelContainer = $Panel/Card
@onready var title_label: Label = $Panel/Card/Margin/VBox/Header/LeftHeader/Title
@onready var subtitle_label: Label = $Panel/Card/Margin/VBox/Header/LeftHeader/Subtitle

@onready var build_panel: PanelContainer = $Panel/Card/Margin/VBox/Header/BuildPanel
@onready var build_title: Label = $Panel/Card/Margin/VBox/Header/BuildPanel/BuildMargin/BuildVBox/BuildTitle
@onready var build_weapons: HFlowContainer = $Panel/Card/Margin/VBox/Header/BuildPanel/BuildMargin/BuildVBox/Weapons
@onready var build_stats: VBoxContainer = $Panel/Card/Margin/VBox/Header/BuildPanel/BuildMargin/BuildVBox/Stats

@onready var choices_panel: PanelContainer = $Panel/Card/Margin/VBox/Content/ChoicesPanel
@onready var choices_title: Label = $Panel/Card/Margin/VBox/Content/ChoicesPanel/ChoicesMargin/ChoicesVBox/ChoicesTitle
@onready var choices_grid: GridContainer = (
	$Panel/Card/Margin/VBox/Content/ChoicesPanel/ChoicesMargin/ChoicesVBox/ChoicesGrid
)
@onready var hint_label: Label = (
	$Panel/Card/Margin/VBox/Content/ChoicesPanel/ChoicesMargin/ChoicesVBox/Hint
)

@onready var preview_panel: PanelContainer = $Panel/Card/Margin/VBox/Content/PreviewPanel
@onready var preview_icon: ColorRect = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/PreviewTop/Icon
)
@onready var preview_icon_glyph: Label = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/PreviewTop/Icon/IconGlyph
)
@onready var preview_name: Label = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/PreviewTop/PreviewMeta/Name
)
@onready var rarity_label: Label = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/PreviewTop/PreviewMeta/Rarity
)
@onready var description_label: Label = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/Description
)
@onready var effect_label: Label = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/Effect
)
@onready var details_container: VBoxContainer = (
	$Panel/Card/Margin/VBox/Content/PreviewPanel/PreviewMargin/PreviewVBox/Details
)

var _upgrade_manager: UpgradeManager = null
var _current_choices: Array[UpgradeData] = []
var _selected_index: int = 0

var _hover_tween: Tween = null
var _backdrop_tween: Tween = null
var _choice_buttons: Array[UpgradeChoiceCard] = []

func _ready() -> void:
	# Allow input while game is paused
	UIFx.allow_input_while_paused(self)

	# Find upgrade manager (could be sibling or anywhere in tree)
	_upgrade_manager = get_tree().get_first_node_in_group("upgrade_manager") as UpgradeManager
	if not _upgrade_manager:
		_upgrade_manager = get_node_or_null("../UpgradeManager") as UpgradeManager
	if not _upgrade_manager:
		# Create one if not found
		_upgrade_manager = UpgradeManager.new()
		get_tree().current_scene.add_child(_upgrade_manager)

	Events.level_up.connect(_on_level_up)
	hide()
	Log.debug("LevelUpUI", "ready")

	_apply_card_style(UIStyle.COLOR_WARN)
	build_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.COLOR_ACCENT))
	choices_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.COLOR_ACCENT))
	preview_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.COLOR_ACCENT))

	UIStyle.apply_title(title_label, UIStyle.COLOR_WARN, 40)
	UIStyle.apply_subtitle(subtitle_label, UIStyle.COLOR_MUTED, 14)
	UIStyle.apply_subtitle(build_title, UIStyle.COLOR_MUTED, 12)
	UIStyle.apply_subtitle(choices_title, UIStyle.COLOR_MUTED, 12)
	UIStyle.apply_subtitle(hint_label, UIStyle.COLOR_MUTED, 13)

	UIStyle.apply_body(preview_name, UIStyle.COLOR_TEXT, 22)
	UIStyle.apply_subtitle(rarity_label, UIStyle.COLOR_MUTED, 14)
	UIStyle.apply_body(description_label, UIStyle.COLOR_MUTED, 16)
	UIStyle.apply_subtitle(effect_label, UIStyle.COLOR_TEXT, 14)
	UIStyle.apply_title(preview_icon_glyph, UIStyle.COLOR_BG, 22)

	_stop_backdrop_fx()


func _on_level_up(new_level: int) -> void:
	title_label.text = "LEVEL %d" % new_level
	_show_choices()


func _show_choices() -> void:
	# Clear old choices
	for child: Node in choices_grid.get_children():
		child.queue_free()
	_choice_buttons.clear()

	# Generate new choices
	_current_choices = _upgrade_manager.generate_choices(3)
	_selected_index = 0

	_update_build_summary()

	# Create cards for each choice
	for i: int in _current_choices.size():
		var choice: UpgradeData = _current_choices[i]
		var card_btn: UpgradeChoiceCard = _create_choice_card(choice, i)
		_choice_buttons.append(card_btn)
		choices_grid.add_child(card_btn)

	_update_selection()
	_start_backdrop_fx()

	show()
	UIFx.fade_in(panel as CanvasItem)
	UIFx.set_initial_focus(_get_button(_selected_index) as Control)
	Log.info("LevelUpUI", "showing", {choices = _current_choices.size()})


func _create_choice_card(choice: UpgradeData, index: int) -> UpgradeChoiceCard:
	var card_btn: UpgradeChoiceCard = UpgradeChoiceCardScene.instantiate() as UpgradeChoiceCard
	card_btn.set_upgrade(choice)
	card_btn.pressed.connect(_on_choice_selected.bind(index))
	card_btn.focus_entered.connect(_on_choice_focused.bind(index))
	card_btn.mouse_entered.connect(_on_choice_hovered.bind(index))
	return card_btn


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	var pressed: bool = key != null and key.pressed
	var kc: int = key.keycode if key != null else 0
	var cols: int = maxi(1, choices_grid.columns)

	if event.is_action_pressed("ui_right") or (pressed and kc == KEY_RIGHT):
		_selected_index = mini(_selected_index + 1, _current_choices.size() - 1)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or (pressed and kc == KEY_LEFT):
		_selected_index = maxi(0, _selected_index - 1)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or (pressed and kc == KEY_DOWN):
		_selected_index = mini(_selected_index + cols, _current_choices.size() - 1)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or (pressed and kc == KEY_UP):
		_selected_index = maxi(0, _selected_index - cols)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (pressed and (kc == KEY_ENTER or kc == KEY_SPACE)):
		_on_choice_selected(_selected_index)
		get_viewport().set_input_as_handled()


func _on_choice_selected(index: int) -> void:
	if index >= _current_choices.size():
		return

	var choice: UpgradeData = _current_choices[index]
	_upgrade_manager.apply_upgrade(choice)

	_stop_backdrop_fx()
	hide()
	upgrade_chosen.emit(choice)
	Log.info("LevelUpUI", "choice_selected", {name = choice.display_name})


func _on_choice_focused(index: int) -> void:
	_selected_index = index
	_update_selection()


func _on_choice_hovered(index: int) -> void:
	_selected_index = index
	_update_selection()


func _update_selection() -> void:
	if _current_choices.is_empty():
		rarity_label.text = ""
		description_label.text = ""
		effect_label.text = ""
		return
	_selected_index = clampi(_selected_index, 0, _current_choices.size() - 1)
	var choice: UpgradeData = _current_choices[_selected_index]
	_update_preview(choice)
	_apply_card_style(choice.icon_color)

	for i: int in _choice_buttons.size():
		var b: UpgradeChoiceCard = _choice_buttons[i]
		if b:
			b.set_highlighted(i == _selected_index)

	var btn: Button = _get_button(_selected_index)
	if btn:
		btn.grab_focus()
		_animate_choice(btn)


func _animate_choice(button: Button) -> void:
	if _hover_tween:
		_hover_tween.kill()
		_hover_tween = null
	button.scale = Vector2.ONE
	_hover_tween = create_tween().set_ignore_time_scale(true)
	_hover_tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.08)
	_hover_tween.tween_property(button, "scale", Vector2.ONE, 0.08)


func _get_button(index: int) -> Button:
	if index < 0:
		return null
	if index >= choices_grid.get_child_count():
		return null
	return choices_grid.get_child(index) as Button


func _rarity_text(rarity: UpgradeData.Rarity) -> String:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return "COMMON"
		UpgradeData.Rarity.UNCOMMON:
			return "UNCOMMON"
		UpgradeData.Rarity.RARE:
			return "RARE"
	return ""


func _effect_text(choice: UpgradeData) -> String:
	match choice.type:
		UpgradeData.Type.NEW_WEAPON:
			return "Unlock weapon"
		UpgradeData.Type.UPGRADE_WEAPON:
			var lvl: int = int(choice.stat_value)
			return "Upgrade to level %d" % lvl
		UpgradeData.Type.STAT_BOOST:
			return _format_stat_effect(choice.stat, choice.stat_op, choice.stat_value)
	return ""


func _format_stat_effect(stat: Stats.Stat, op: UpgradeData.StatOp, value: float) -> String:
	match op:
		UpgradeData.StatOp.MUL:
			var pct: float = (value - 1.0) * 100.0
			if pct >= 0.0:
				return "+%0.0f%%" % pct
			return "%0.0f%%" % pct
		UpgradeData.StatOp.ADD:
			match stat:
				Stats.Stat.PLAYER_MAX_HP_ADD:
					return "+%d HP" % int(value)
				Stats.Stat.WEAPON_PROJECTILE_ADD:
					return "+%d projectiles" % int(value)
			return "+%0.0f" % value
	return ""


func _apply_card_style(accent: Color) -> void:
	card.add_theme_stylebox_override("panel", UIStyle.make_panel_style(accent))


func _update_preview(choice: UpgradeData) -> void:
	preview_icon.color = choice.icon_color
	preview_icon_glyph.text = _icon_glyph(choice)
	preview_name.text = choice.display_name
	rarity_label.text = _rarity_text(choice.rarity)
	rarity_label.add_theme_color_override("font_color", choice.icon_color)
	description_label.text = choice.description
	effect_label.text = _effect_text(choice)

	for child: Node in details_container.get_children():
		child.queue_free()

	_add_detail("TYPE", _type_text(choice.type), UIStyle.COLOR_MUTED)
	_add_detail("RARITY", _rarity_text(choice.rarity), choice.icon_color)

	match choice.type:
		UpgradeData.Type.NEW_WEAPON:
			_add_detail("SLOT", "Adds a new weapon", UIStyle.COLOR_TEXT)
		UpgradeData.Type.UPGRADE_WEAPON:
			var weapon_name: String = choice.weapon_name
			var current_level: int = _get_weapon_level(weapon_name)
			var next_level: int = int(choice.stat_value)
			_add_detail("WEAPON", weapon_name, UIStyle.COLOR_TEXT)
			_add_detail("LEVEL", "Lv.%d -> Lv.%d" % [current_level, next_level], UIStyle.COLOR_TEXT)
		UpgradeData.Type.STAT_BOOST:
			_add_detail("STAT", _pretty_stat_name(choice.stat), UIStyle.COLOR_TEXT)
			_add_detail("GAIN", _format_stat_effect(choice.stat, choice.stat_op, choice.stat_value), UIStyle.COLOR_GOOD)


func _add_detail(label_left: String, label_right: String, color: Color) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var k: Label = Label.new()
	k.text = label_left
	UIStyle.apply_subtitle(k, UIStyle.COLOR_MUTED, 12)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v: Label = Label.new()
	v.text = label_right
	UIStyle.apply_body(v, color, 14)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	row.add_child(k)
	row.add_child(v)
	details_container.add_child(row)


func _type_text(t: UpgradeData.Type) -> String:
	match t:
		UpgradeData.Type.NEW_WEAPON:
			return "NEW WEAPON"
		UpgradeData.Type.UPGRADE_WEAPON:
			return "UPGRADE"
		UpgradeData.Type.STAT_BOOST:
			return "PASSIVE"
	return ""


func _icon_glyph(choice: UpgradeData) -> String:
	match choice.type:
		UpgradeData.Type.NEW_WEAPON:
			return "NEW"
		UpgradeData.Type.UPGRADE_WEAPON:
			return "UP"
		UpgradeData.Type.STAT_BOOST:
			return "+"
	return "?"


func _get_weapon_level(weapon_name: String) -> int:
	var player: Player = Game.player as Player
	if not player:
		return 0
	var weapon: Node2D = player.get_weapon_by_name(weapon_name)
	if not weapon:
		return 0
	var raw: Variant = weapon.get("level")
	if raw == null:
		return 1
	return raw as int


func _pretty_stat_name(stat: Stats.Stat) -> String:
	match stat:
		Stats.Stat.PLAYER_DAMAGE_MUL:
			return "Damage"
		Stats.Stat.PLAYER_COOLDOWN_MUL:
			return "Cooldown"
		Stats.Stat.PLAYER_MOVE_SPEED_MUL:
			return "Move speed"
		Stats.Stat.PLAYER_PICKUP_RANGE_MUL:
			return "Pickup range"
		Stats.Stat.PLAYER_MAX_HP_ADD:
			return "Max HP"
		Stats.Stat.PLAYER_DAMAGE_REDUCTION_MUL:
			return "Damage taken"
		Stats.Stat.WEAPON_PROJECTILE_ADD:
			return "Projectiles"
		Stats.Stat.BLASTER_SPREAD_MUL:
			return "Blaster spread"
		Stats.Stat.MISSILE_TURN_RATE_MUL:
			return "Missile turn rate"
	return "Stat"


func _update_build_summary() -> void:
	for child: Node in build_weapons.get_children():
		child.queue_free()
	for child: Node in build_stats.get_children():
		child.queue_free()

	var player: Player = Game.player as Player
	if not player:
		return

	# Weapon chips
	for weapon: Node2D in player.weapons:
		var wn_raw: Variant = weapon.get("weapon_name")
		var weapon_name: String = wn_raw as String if wn_raw != null else weapon.name
		var lvl_raw: Variant = weapon.get("level")
		var lvl: int = lvl_raw as int if lvl_raw != null else 1
		var chip: Control = _make_chip("%s  Lv.%d" % [weapon_name, lvl], UIStyle.COLOR_ACCENT)
		build_weapons.add_child(chip)

	# Key run modifiers (scannable)
	_add_build_stat("Damage", _pct_mul(Stats.get_mul(Stats.Stat.PLAYER_DAMAGE_MUL)))
	_add_build_stat("Cooldown", _pct_inverse_mul(Stats.get_mul(Stats.Stat.PLAYER_COOLDOWN_MUL)))
	_add_build_stat("Move", _pct_mul(Stats.get_mul(Stats.Stat.PLAYER_MOVE_SPEED_MUL)))
	_add_build_stat("Pickup", _pct_mul(Stats.get_mul(Stats.Stat.PLAYER_PICKUP_RANGE_MUL)))
	_add_build_stat("HP", "+%d" % int(Stats.get_add(Stats.Stat.PLAYER_MAX_HP_ADD)))
	_add_build_stat("Projectiles", "+%d" % int(Stats.get_add(Stats.Stat.WEAPON_PROJECTILE_ADD)))


func _make_chip(text_value: String, accent: Color) -> Control:
	var panel_chip: PanelContainer = PanelContainer.new()
	panel_chip.add_theme_stylebox_override("panel", UIStyle.make_panel_style(accent))
	panel_chip.custom_minimum_size = Vector2(0, 28)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel_chip.add_child(margin)

	var label: Label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.apply_subtitle(label, UIStyle.COLOR_TEXT, 12)
	margin.add_child(label)
	return panel_chip


func _add_build_stat(name: String, value: String) -> void:
	var label: Label = Label.new()
	label.text = "%s: %s" % [name, value]
	UIStyle.apply_subtitle(label, UIStyle.COLOR_MUTED, 12)
	build_stats.add_child(label)


func _pct_mul(m: float) -> String:
	var pct: float = (m - 1.0) * 100.0
	if absf(pct) < 0.05:
		return "+0%"
	if pct >= 0.0:
		return "+%0.0f%%" % pct
	return "%0.0f%%" % pct


func _pct_inverse_mul(m: float) -> String:
	# For cooldown-like stats where lower multiplier is better.
	var pct: float = (1.0 - m) * 100.0
	if absf(pct) < 0.05:
		return "+0%"
	if pct >= 0.0:
		return "-%0.0f%%" % pct
	return "+%0.0f%%" % absf(pct)


func _start_backdrop_fx() -> void:
	_stop_backdrop_fx()
	if not glow:
		return
	glow.modulate.a = 0.28
	_backdrop_tween = create_tween().set_loops().set_ignore_time_scale(true)
	_backdrop_tween.tween_property(glow, "modulate:a", 0.42, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_backdrop_tween.tween_property(glow, "modulate:a", 0.28, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_backdrop_fx() -> void:
	if _backdrop_tween:
		_backdrop_tween.kill()
		_backdrop_tween = null
