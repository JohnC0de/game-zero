extends Button
class_name UpgradeChoiceCard

const UIStyle: Script = preload("res://src/ui/ui_style.gd")

var accent: ColorRect = null
var title_label: Label = null
var rarity_badge: Label = null
var type_badge: Label = null
var effect_label: Label = null
var description_label: Label = null

var upgrade: UpgradeData = null
var _accent: Color = UIStyle.COLOR_ACCENT


func _ready() -> void:
	_resolve_nodes()
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UIStyle.apply_body(title_label, UIStyle.COLOR_TEXT, 18)
	UIStyle.apply_subtitle(rarity_badge, UIStyle.COLOR_MUTED, 12)
	UIStyle.apply_subtitle(type_badge, UIStyle.COLOR_MUTED, 12)
	UIStyle.apply_body(effect_label, UIStyle.COLOR_TEXT, 16)
	UIStyle.apply_subtitle(description_label, UIStyle.COLOR_MUTED, 13)
	set_highlighted(false)
	if upgrade != null:
		_apply_upgrade_to_ui(upgrade)


func set_upgrade(p_upgrade: UpgradeData) -> void:
	upgrade = p_upgrade
	if upgrade == null:
		return
	_resolve_nodes()
	_apply_upgrade_to_ui(upgrade)


func _resolve_nodes() -> void:
	if accent == null:
		accent = get_node_or_null("Margin/HBox/Accent") as ColorRect
	if title_label == null:
		title_label = get_node_or_null("Margin/HBox/Content/TopRow/Title") as Label
	if rarity_badge == null:
		rarity_badge = get_node_or_null("Margin/HBox/Content/TopRow/RarityBadge") as Label
	if type_badge == null:
		type_badge = get_node_or_null("Margin/HBox/Content/Badges/TypeBadge") as Label
	if effect_label == null:
		effect_label = get_node_or_null("Margin/HBox/Content/Effect") as Label
	if description_label == null:
		description_label = get_node_or_null("Margin/HBox/Content/Description") as Label


func _apply_upgrade_to_ui(u: UpgradeData) -> void:
	if accent == null or title_label == null or rarity_badge == null or type_badge == null:
		return

	_accent = u.icon_color
	accent.color = _accent

	title_label.text = u.display_name
	rarity_badge.text = _rarity_text(u.rarity)
	type_badge.text = _type_text(u.type)

	# Keep card scannable: show a short effect line + a short description.
	if effect_label != null:
		effect_label.text = _primary_effect_text(u)
	if description_label != null:
		description_label.text = u.description

	_apply_badge_color(rarity_badge, u.icon_color)
	_apply_badge_color(type_badge, UIStyle.COLOR_MUTED)
	set_highlighted(false)


func set_highlighted(highlighted: bool) -> void:
	# Use focus/hover-like styling as selection highlight.
	add_theme_stylebox_override("normal", UIStyle.make_button_style(_accent, highlighted, false))
	add_theme_stylebox_override("hover", UIStyle.make_button_style(_accent, true, false))
	add_theme_stylebox_override("pressed", UIStyle.make_button_style(_accent, false, true))
	add_theme_stylebox_override("focus", UIStyle.make_button_style(_accent, true, false))
	add_theme_color_override("font_color", UIStyle.COLOR_TEXT)
	add_theme_color_override("font_hover_color", UIStyle.COLOR_TEXT)
	add_theme_color_override("font_pressed_color", UIStyle.COLOR_TEXT)
	add_theme_color_override("font_focus_color", UIStyle.COLOR_TEXT)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 2)

	# Subtle lift on selection.
	if highlighted:
		scale = Vector2(1.01, 1.01)
	else:
		scale = Vector2.ONE


func _apply_badge_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 2)


func _rarity_text(rarity: UpgradeData.Rarity) -> String:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return "COMMON"
		UpgradeData.Rarity.UNCOMMON:
			return "UNCOMMON"
		UpgradeData.Rarity.RARE:
			return "RARE"
	return ""


func _type_text(t: UpgradeData.Type) -> String:
	match t:
		UpgradeData.Type.NEW_WEAPON:
			return "NEW WEAPON"
		UpgradeData.Type.UPGRADE_WEAPON:
			return "UPGRADE"
		UpgradeData.Type.STAT_BOOST:
			return "PASSIVE"
	return ""


func _primary_effect_text(u: UpgradeData) -> String:
	match u.type:
		UpgradeData.Type.NEW_WEAPON:
			return "Unlock weapon"
		UpgradeData.Type.UPGRADE_WEAPON:
			var lvl: int = int(u.stat_value)
			return "Weapon level %d" % lvl
		UpgradeData.Type.STAT_BOOST:
			return _format_stat_effect(u.stat, u.stat_op, u.stat_value)
	return ""


func _format_stat_effect(stat: Stats.Stat, op: UpgradeData.StatOp, value: float) -> String:
	# Keep in sync with LevelUpUI formatting.
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
