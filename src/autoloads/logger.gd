extends Node
## Structured logging system with context and levels

enum Level { DEBUG, INFO, WARN, ERROR }

const LEVEL_NAMES: Array[String] = ["DBG", "INF", "WRN", "ERR"]
const LEVEL_COLORS: Dictionary = {
	Level.DEBUG: "gray", Level.INFO: "white", Level.WARN: "yellow", Level.ERROR: "red"
}

var min_level: Level = Level.DEBUG
var _frame_logs: Array[String] = []


func _ready() -> void:
	print("[Logger] initialized | min_level=%s" % LEVEL_NAMES[min_level])


func debug(ctx: String, msg: String, data: Dictionary = {}) -> void:
	_log(Level.DEBUG, ctx, msg, data)


func info(ctx: String, msg: String, data: Dictionary = {}) -> void:
	_log(Level.INFO, ctx, msg, data)


func warn(ctx: String, msg: String, data: Dictionary = {}) -> void:
	_log(Level.WARN, ctx, msg, data)


func error(ctx: String, msg: String, data: Dictionary = {}) -> void:
	_log(Level.ERROR, ctx, msg, data)
	push_error("[%s] %s | %s" % [ctx, msg, _format_data(data)])


func _log(level: Level, ctx: String, msg: String, data: Dictionary) -> void:
	if level < min_level:
		return

	var timestamp: String = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	var frame: int = Engine.get_process_frames()
	var data_str: String = _format_data(data) if data.size() > 0 else ""

	var line: String = (
		"[%s][F%d][%s][%s] %s%s"
		% [timestamp, frame, LEVEL_NAMES[level], ctx, msg, " | " + data_str if data_str else ""]
	)

	print_rich("[color=%s]%s[/color]" % [LEVEL_COLORS[level], line])


func _format_data(data: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in data:
		var val: Variant = data[key]
		if val is Vector2:
			parts.append("%s=(%.1f,%.1f)" % [key, val.x, val.y])
		elif val is float:
			parts.append("%s=%.2f" % [key, val])
		else:
			parts.append("%s=%s" % [key, str(val)])
	return " ".join(parts)
