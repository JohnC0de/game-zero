extends Node2D
class_name DeathParticles
## Spawns particle explosion on enemy death

const PARTICLE_COUNT: int = 8
const PARTICLE_SPEED: float = 200.0
const PARTICLE_LIFETIME: float = 0.4

const POOL_LIMIT: int = 64
static var _pool: Array[DeathParticles] = []

var color: Color = Color.WHITE

var _particles: Array[Polygon2D] = []
var _play_id: int = 0


func _ready() -> void:
	_ensure_particles()
	hide()


func _ensure_particles() -> void:
	if not _particles.is_empty():
		return

	for i: int in PARTICLE_COUNT:
		var particle: Polygon2D = _create_particle()
		_particles.append(particle)
		add_child(particle)


func _create_particle() -> Polygon2D:
	var particle: Polygon2D = Polygon2D.new()
	particle.color = color
	particle.polygon = PackedVector2Array(
		[Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)]
	)
	return particle


func _animate_particle(particle: Polygon2D, velocity: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Move outward
	tween.tween_property(particle, "position", velocity * PARTICLE_LIFETIME, PARTICLE_LIFETIME)

	# Fade out
	tween.tween_property(particle, "modulate:a", 0.0, PARTICLE_LIFETIME)

	# Shrink
	tween.tween_property(particle, "scale", Vector2.ZERO, PARTICLE_LIFETIME)


func _play() -> void:
	_ensure_particles()
	show()
	_play_id += 1
	var local_play_id: int = _play_id

	for i: int in PARTICLE_COUNT:
		var particle: Polygon2D = _particles[i]
		particle.color = color
		particle.position = Vector2.ZERO
		particle.scale = Vector2.ONE
		particle.modulate.a = 1.0

		var angle: float = (TAU / PARTICLE_COUNT) * i + randf_range(-0.2, 0.2)
		var velocity: Vector2 = Vector2.from_angle(angle) * PARTICLE_SPEED * randf_range(0.7, 1.3)
		_animate_particle(particle, velocity)

	get_tree().create_timer(PARTICLE_LIFETIME + 0.1).timeout.connect(
		func() -> void:
			if local_play_id != _play_id:
				return
			_recycle()
	)


func _recycle() -> void:
	hide()
	if is_inside_tree() and get_parent():
		get_parent().remove_child(self)

	if _pool.size() < POOL_LIMIT:
		_pool.append(self)
	else:
		queue_free()


static func clear_pool() -> void:
	for fx: DeathParticles in _pool:
		if is_instance_valid(fx):
			fx.free()
	_pool.clear()


static func spawn(parent: Node, pos: Vector2, particle_color: Color) -> DeathParticles:
	var instance: DeathParticles = _pool.pop_back() if not _pool.is_empty() else DeathParticles.new()
	instance.color = particle_color
	instance.global_position = pos
	parent.add_child(instance)
	instance._play()
	return instance
