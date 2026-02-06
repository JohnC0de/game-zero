extends Resource
class_name UpgradeData
## Data container for an upgrade option

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

enum Type {
	NEW_WEAPON,  # Add a new weapon
	UPGRADE_WEAPON,  # Level up existing weapon
	STAT_BOOST,  # Increase a player stat
}

enum StatOp {
	MUL,
	ADD,
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var type: Type = Type.STAT_BOOST
@export var rarity: Rarity = Rarity.COMMON
@export var weight: float = 1.0
@export var max_stack: int = 99
@export var icon_color: Color = Color.WHITE
@export var weapon_scene: PackedScene  # For NEW_WEAPON type
@export var weapon_name: String = ""  # For UPGRADE_WEAPON type
@export var stat: Stats.Stat = Stats.Stat.PLAYER_DAMAGE_MUL  # For STAT_BOOST type
@export var stat_op: StatOp = StatOp.MUL  # For STAT_BOOST type
@export var stat_value: float = 0.0  # For STAT_BOOST and UPGRADE_WEAPON types
