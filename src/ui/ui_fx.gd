extends RefCounted


static func allow_input_while_paused(node: Node) -> void:
	if not node:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS


static func set_initial_focus(control: Control) -> void:
	if not control:
		return
	control.focus_mode = Control.FOCUS_ALL
	control.call_deferred("grab_focus")


static func fade_in(item: CanvasItem, duration: float = 0.18) -> void:
	if not item:
		return
	item.modulate.a = 0.0
	var tween: Tween = item.create_tween().set_ignore_time_scale(true)
	tween.tween_property(item, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


static func fade_out_then(item: CanvasItem, callback: Callable, duration: float = 0.18) -> void:
	if not item:
		if callback.is_valid():
			callback.call()
		return
	var tween: Tween = item.create_tween().set_ignore_time_scale(true)
	tween.tween_property(item, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func() -> void:
			if callback.is_valid():
				callback.call()
	)
