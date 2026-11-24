extends Node3D
# Big minigunner on the pedestal. Auto-tracks the nearest enemy and streams fire.

signal hero_shot(pos: Vector3, dir: Vector3, dmg: float)

const HERO_GLB := "res://assets/models/hero.glb"
const PEDESTAL_GLB := "res://assets/models/pedestal.glb"

var dmg: float = 5.0
var fire_rate: float = 0.13
var golden: bool = false

var _model: Node3D
var _fire: float = 0.0
var _flash: OmniLight3D
var _target: Vector3 = Vector3(0, 1, -30)
var _gold_mat: StandardMaterial3D

func _ready() -> void:
	_model = load(HERO_GLB).instantiate()
	add_child(_model)
	var ped: Node3D = load(PEDESTAL_GLB).instantiate()
	ped.position = Vector3(0, -0.05, 0.4)
	add_child(ped)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(0.5, 0.8, 1.0)
	_flash.light_energy = 0.0
	_flash.omni_range = 6.0
	_flash.position = Vector3(0, 2.0, -2.2)
	add_child(_flash)
	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = Color(0.98, 0.75, 0.18)
	_gold_mat.metallic = 0.9
	_gold_mat.roughness = 0.3

func set_golden(on: bool) -> void:
	golden = on
	dmg = 12.0 if on else 5.0
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi:
			mi.material_override = _gold_mat if on else null

func aim_at(p: Vector3) -> void:
	_target = p

func _process(delta: float) -> void:
	_flash.light_energy = lerpf(_flash.light_energy, 0.0, 14.0 * delta)
	_model.position.y = 0.7 + absf(sin(Time.get_ticks_msec() * 0.004)) * 0.05
	# face the target
	var look: Vector3 = Vector3(_target.x, 0, _target.z)
	if global_position.distance_squared_to(look) > 0.1:
		var want: float = atan2(-(look.x - global_position.x), -(look.z - global_position.z))
		rotation.y = lerp_angle(rotation.y, want, 8.0 * delta)
	_fire -= delta
	if _fire <= 0.0:
		_fire = fire_rate
		var muzzle: Vector3 = global_position + Vector3(0, 2.0, 0) - global_transform.basis.z * 2.2
		var dir: Vector3 = (_target - muzzle).normalized()
		dir += Vector3(randf_range(-0.03, 0.03), randf_range(-0.02, 0.02), randf_range(-0.03, 0.03))
		_flash.light_energy = 3.0
		hero_shot.emit(muzzle, dir.normalized(), dmg)
