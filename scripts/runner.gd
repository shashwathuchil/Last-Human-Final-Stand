extends Node3D
# One squad runner: bobs while running, periodically fires forward, dies on contact.

signal want_shoot(pos: Vector3, dmg: float)

var _t: float = 0.0
var _fire: float = 0.0
var _phase: float = 0.0
var dmg: float = 3.0
var dead: bool = false

func _ready() -> void:
	_phase = randf() * TAU
	_fire = randf() * 0.8  # stagger shots

func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	position.y = absf(sin(_t * 9.0 + _phase)) * 0.12  # run bob
	_fire -= delta
	if _fire <= 0.0:
		_fire = 0.85 + randf() * 0.3
		want_shoot.emit(global_position + Vector3(0, 0.9, -0.3), dmg)

func die() -> void:
	if dead:
		return
	dead = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.2, 0.05, 1.2), 0.18)
	tw.tween_callback(queue_free)
