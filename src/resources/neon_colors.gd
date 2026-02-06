class_name NeonColors
## Centralized neon color palette for consistent visuals

# Player colors
const PLAYER_CYAN: Color = Color(0.2, 0.9, 1.0)
const PLAYER_TRAIL: Color = Color(0.2, 0.9, 1.0, 0.5)

# Enemy colors by type
const ENEMY_RED: Color = Color(1.0, 0.2, 0.3)
const ENEMY_ORANGE: Color = Color(1.0, 0.5, 0.1)
const ENEMY_PINK: Color = Color(1.0, 0.3, 0.7)
const ENEMY_PURPLE: Color = Color(0.7, 0.2, 1.0)

# Projectile colors
const PROJECTILE_PLAYER: Color = Color(0.3, 1.0, 0.5)
const PROJECTILE_ENEMY: Color = Color(1.0, 0.3, 0.2)

# Pickup colors
const XP_GREEN: Color = Color(0.3, 1.0, 0.4)
const HEALTH_RED: Color = Color(1.0, 0.3, 0.4)

# UI colors
const UI_WHITE: Color = Color(1.0, 1.0, 1.0)
const UI_YELLOW: Color = Color(1.0, 0.9, 0.2)

# Effect colors
const EXPLOSION_ORANGE: Color = Color(1.0, 0.6, 0.2)
const DAMAGE_FLASH: Color = Color(1.0, 0.2, 0.2)


static func get_hdr(color: Color, intensity: float = 2.0) -> Color:
	## Returns an HDR version of the color for bloom effects
	return Color(color.r * intensity, color.g * intensity, color.b * intensity, color.a)


static func random_enemy_color() -> Color:
	var colors: Array[Color] = [ENEMY_RED, ENEMY_ORANGE, ENEMY_PINK, ENEMY_PURPLE]
	return colors[randi() % colors.size()]
