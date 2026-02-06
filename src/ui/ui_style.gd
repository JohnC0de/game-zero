extends RefCounted

const COLOR_BG: Color = Color(0.02, 0.02, 0.05, 1.0)
const COLOR_PANEL: Color = Color(0.08, 0.08, 0.12, 0.92)
const COLOR_TEXT: Color = Color(0.9, 0.9, 0.95, 1.0)
const COLOR_MUTED: Color = Color(0.65, 0.65, 0.7, 1.0)
const COLOR_ACCENT: Color = Color(0.2, 0.9, 1.0, 1.0)
const COLOR_GOOD: Color = Color(0.3, 1.0, 0.5, 1.0)
const COLOR_WARN: Color = Color(1.0, 0.9, 0.2, 1.0)
const COLOR_BAD: Color = Color(1.0, 0.3, 0.3, 1.0)

const RADIUS: int = 10
const BORDER: int = 2


static func make_panel_style(accent: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = COLOR_PANEL
	s.border_width_left = BORDER
	s.border_width_top = BORDER
	s.border_width_right = BORDER
	s.border_width_bottom = BORDER
	s.border_color = accent
	s.corner_radius_top_left = RADIUS
	s.corner_radius_top_right = RADIUS
	s.corner_radius_bottom_left = RADIUS
	s.corner_radius_bottom_right = RADIUS
	s.shadow_color = Color(0, 0, 0, 0.65)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 8)
	return s


static func make_button_style(
	accent: Color = COLOR_ACCENT, hovered: bool = false, pressed: bool = false
) -> StyleBoxFlat:
	var s: StyleBoxFlat = make_panel_style(accent)
	if hovered:
		s.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	if pressed:
		s.bg_color = Color(0.16, 0.16, 0.22, 0.95)
	return s


static func apply_button(button: Button, accent: Color = COLOR_ACCENT) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", make_button_style(accent, false, false))
	button.add_theme_stylebox_override("hover", make_button_style(accent, true, false))
	button.add_theme_stylebox_override("pressed", make_button_style(accent, false, true))
	button.add_theme_stylebox_override("focus", make_button_style(accent, true, false))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_TEXT)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	button.add_theme_constant_override("outline_size", 2)


static func apply_title(label: Label, color: Color = COLOR_ACCENT, size: int = 56) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)


static func apply_subtitle(label: Label, color: Color = COLOR_MUTED, size: int = 18) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)


static func apply_body(label: Label, color: Color = COLOR_TEXT, size: int = 18) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 2)
