extends Node3D
# Horde enemy: advances on the squad, takes bullet damage, dies with a squash.

signal died(e: Node3D)
signal reached(e: Node3D)

const ENEMY_GLB := "res://assets/models/enemy.glb"

var hp: float = 6.0
var speed: float = 2.2
var target_x: float = 0.0
var ox: float = 0.0
var dead: bool = false

var _model: Node3D
var _t: float = 0.0

func setup(h: float, s: float) -> void:
	hp = h
	speed = s
	_model = load(ENEMY_GLB).instantiate()
	var sc: float = randf_range(0.9, 1.25)
	_model.scale = Vector3.ONE * sc
	add_child(_model)

func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	position.z += speed * delta
	position.x = lerpf(position.x, target_x, 2.0 * delta)
	_model.position.y = absf(sin(_t * 7.0)) * 0.08
	_model.rotation.x = 0.15 + sin(_t * 7.0) * 0.05

func hit(dmg: float) -> void:
	if dead:
		return
	hp -= dmg
	if hp <= 0.0:
		die()
	else:
		# hit flash
		for n in _model.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi:
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(1, 0.4, 0.4)
				mi.material_override = m
		var tw := create_tween()
		tw.tween_interval(0.05)
		tw.tween_callback(_clear_flash)

func _clear_flash() -> void:
	if is_instance_valid(_model):
		for n in _model.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi:
				mi.material_override = null

func die() -> void:
	if dead:
		return
	dead = true
	died.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.3, 0.05, 1.3), 0.2)
	tw.parallel().tween_property(_model, "rotation:z", 1.4, 0.2)
	tw.tween_callback(queue_free)
