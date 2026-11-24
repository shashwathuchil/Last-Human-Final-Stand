extends Node3D
# Pooled tracer bullet. The Game moves it and resolves hits; it only renders.

var velocity: Vector3 = Vector3.ZERO
var damage: float = 1.0
var active: bool = false
var mesh: MeshInstance3D

static var _mesh: BoxMesh
static var _mat_hero: StandardMaterial3D
static var _mat_squad: StandardMaterial3D

func _init() -> void:
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = Vector3(0.09, 0.09, 0.9)
		_mat_hero = StandardMaterial3D.new()
		_mat_hero.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_hero.albedo_color = Color(0.45, 0.8, 1.0)
		_mat_hero.emission_enabled = true
		_mat_hero.emission = Color(0.4, 0.75, 1.0)
		_mat_hero.emission_energy_multiplier = 4.0
		_mat_squad = StandardMaterial3D.new()
		_mat_squad.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_squad.albedo_color = Color(0.75, 0.9, 1.0)
		_mat_squad.emission_enabled = true
		_mat_squad.emission = Color(0.7, 0.85, 1.0)
		_mat_squad.emission_energy_multiplier = 2.5
	mesh = MeshInstance3D.new()
	mesh.mesh = _mesh
	add_child(mesh)
	visible = false

func launch(from: Vector3, dir: Vector3, dmg: float, hero_shot: bool) -> void:
	global_position = from
	velocity = dir.normalized() * (52.0 if hero_shot else 38.0)
	damage = dmg
	mesh.material_override = _mat_hero if hero_shot else _mat_squad
	mesh.scale = Vector3(1.6, 1.6, 2.2) if hero_shot else Vector3(0.8, 0.8, 1.0)
	look_at(global_position + dir, Vector3.UP)
	active = true
	visible = true

func kill() -> void:
	active = false
	visible = false
