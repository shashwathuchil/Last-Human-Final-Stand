extends Node3D
# Roadside modifier sign: a small flag-style board at the road edge (like the
# reference "-3" marker), NOT a wall across the road. Applies its modifier when
# the squad marches past it.

signal applied(type: String, value: int)

var type: String = "add"
var value: int = 3
var triggered: bool = false

var _label: Label3D
var _plate: MeshInstance3D

func setup(t: String, v: int) -> void:
	type = t
	value = v
	var c := Color(0.2, 0.9, 0.35)
	var txt := ""
	match type:
		"add":
			txt = "+%d" % value
		"remove":
			txt = "-%d" % value
			c = Color(1.0, 0.15, 0.15)
		"gold":
			txt = "GOLD"
			c = Color(1.0, 0.8, 0.15)
	# post + sign board at the road edge
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.06
	pm.height = 2.4
	post.mesh = pm
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.55, 0.58, 0.62)
	rail_mat.metallic = 0.6
	rail_mat.roughness = 0.4
	post.material_override = rail_mat
	post.position = Vector3(0, 1.2, 0)
	add_child(post)
	_plate = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.1, 1.0, 0.18)
	_plate.mesh = bm
	var pm2 := StandardMaterial3D.new()
	pm2.albedo_color = c
	pm2.emission_enabled = true
	pm2.emission = c
	pm2.emission_energy_multiplier = 0.5
	_plate.material_override = pm2
	_plate.position = Vector3(0, 2.4, 0)
	add_child(_plate)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 110
	_label.pixel_size = 0.014
	_label.outline_size = 16
	_label.outline_modulate = Color.BLACK
	_label.modulate = Color.WHITE
	_label.text = txt
	_label.position = Vector3(0, 2.45, -0.12)
	add_child(_label)

func check_squad(squad_z: float) -> void:
	if triggered or squad_z > position.z:
		return
	triggered = true
	applied.emit(type, value)
	var tw := create_tween()
	tw.tween_property(_label, "position:y", 5.5, 0.6)
	tw.parallel().tween_property(_label, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_plate, "scale", Vector3.ONE * 0.01, 0.5)
