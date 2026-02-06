extends CanvasLayer
class_name GameHUD
## In-game HUD showing health, XP, level, time, and combo

const COMBO_TIMEOUT: float = 2.0  # Seconds before combo resets
const COMBO_THRESHOLD: int = 3  # Minimum kills to show combo

@onready var health_bar: ProgressBar = $Container/TopBar/HealthBar
@onready var xp_bar: ProgressBar = $Container/TopBar/XPBar
@onready var level_label: Label = $Container/TopBar/LevelLabel
@onready var time_label: Label = $Container/TopBar/TimeLabel
@onready var kills_label: Label = $Container/TopBar/KillsLabel
@onready var combo_label: Label = $Container/ComboContainer/ComboLabel
@onready var combo_text: Label = $Container/ComboContainer/ComboText

var _combo_count: int = 0
var _combo_timer: float = 0.0

var _xp_tween: Tween = null


func _ready() -> void:
	Events.player_damaged.connect(_on_player_health_changed)
	Events.player_healed.connect(_on_player_health_changed)
	Events.xp_collected.connect(_on_xp_collected)
	Events.level_up.connect(_on_level_up)
	Events.enemy_killed.connect(_on_enemy_killed)

	_update_xp_bar()
	_update_combo_display()
	Log.debug("HUD", "ready")


func _process(delta: float) -> void:
	if Game.state == Game.State.PLAYING:
		_update_time()
		_update_kills()
		_update_combo_timer(delta)


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_xp_collected(_amount: int, _total: int) -> void:
	_update_xp_bar(true)


func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv.%d" % new_level
	_update_xp_bar(false)



func _update_xp_bar(animated: bool = false) -> void:
	xp_bar.max_value = Game.xp_to_next_level
	if _xp_tween:
		_xp_tween.kill()
		_xp_tween = null
	if animated:
		_xp_tween = create_tween().set_ignore_time_scale(true)
		var t: PropertyTweener = _xp_tween.tween_property(
			xp_bar, "value", float(Game.current_xp), 0.12
		)
		t.set_trans(Tween.TRANS_SINE)
		t.set_ease(Tween.EASE_OUT)
	else:
		xp_bar.value = Game.current_xp
	level_label.text = "Lv.%d" % Game.current_level


func _update_time() -> void:
	var minutes: int = int(Game.run_time / 60.0)
	var seconds: int = int(Game.run_time) % 60
	time_label.text = "%d:%02d" % [minutes, seconds]


func _update_kills() -> void:
	kills_label.text = "%d kills" % Game.kills


func _on_enemy_killed(_enemy: Node2D, _pos: Vector2) -> void:
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	_update_combo_display()

	# Pop animation on combo increase
	if _combo_count >= COMBO_THRESHOLD:
		_animate_combo_pop()


func _update_combo_timer(delta: float) -> void:
	if _combo_timer > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_reset_combo()


func _reset_combo() -> void:
	_combo_count = 0
	_update_combo_display()


func _update_combo_display() -> void:
	if _combo_count >= COMBO_THRESHOLD:
		combo_label.text = "%dx" % _combo_count
		combo_text.text = _get_combo_text(_combo_count)
		combo_label.visible = true
		combo_text.visible = true
	else:
		combo_label.visible = false
		combo_text.visible = false


func _get_combo_text(combo: int) -> String:
	if combo >= 50:
		return "GODLIKE!"
	elif combo >= 30:
		return "UNSTOPPABLE!"
	elif combo >= 20:
		return "RAMPAGE!"
	elif combo >= 10:
		return "KILLING SPREE!"
	elif combo >= 5:
		return "COMBO!"
	else:
		return "COMBO"


func _animate_combo_pop() -> void:
	var tween: Tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.08)
