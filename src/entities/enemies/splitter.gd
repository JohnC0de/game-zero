extends "res://src/entities/enemies/enemy_base.gd"
## Enemy that splits into smaller versions when killed

const MINI_SCENE: PackedScene = preload("res://src/entities/enemies/splitter_mini.tscn")

@export var split_count: int = 2


func _update_behavior(_delta: float) -> void:
	var direction: Vector2 = get_direction_to_target()
	velocity = direction * move_speed

	if velocity.length_squared() > 0:
		sprite.rotation = velocity.angle() + PI / 2


func _die() -> void:
	# Spawn mini versions
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena:
		for i: int in split_count:
			var mini: Node2D = MINI_SCENE.instantiate()
			var offset: Vector2 = Vector2.from_angle(TAU * i / split_count) * 20.0
			mini.global_position = global_position + offset

			# Give them initial velocity away from center
			if mini.has_method("set_initial_velocity"):
				mini.set_initial_velocity(offset.normalized() * 150.0)

			arena.spawn_enemy_direct(mini)

	# Call base die (emits signal, queue_free)
	Events.enemy_killed.emit(self, global_position)
	died.emit(self)
	queue_free()
