extends Node3D
# Road gate: banner shows +N / -N / GOLD, applies its modifier when the squad crosses it.

signal applied(type: String, value: int)

const GATE_GLB := "res://assets/models/gate.glb"

var type: String = "add"
var value: int = 3
var triggered: bool = false

var _label: Label3D
var _plate: MeshInstance3D

func setup(t: String, v: int) -> void:
	type = t
	value = v
	var m: Node3D = load(GATE_GLB).instantiate()
	add_child(m)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 90
	_label.pixel_size = 0.012
	_label.outline_size = 14
	_label.outline_modulate = Color.BLACK
	_label.position = Vector3(0, 3.25, -0.2)
	var c := Color(0.2, 0.9, 0.35)
	match type:
		"add":
			_label.text = "+%d" % value
		"remove":
			_label.text = "-%d" % value
			c = Color(1.0, 0.15, 0.15)
		"gold":
			_label.text = "GOLD"
			c = Color(1.0, 0.8, 0.15)
	_label.modulate = c
	add_child(_label)
	# banner tint plate
	var pm := StandardMaterial3D.new()
	pm.albedo_color = c
	pm.emission_enabled = true
	pm.emission = c
	pm.emission_energy_multiplier = 0.6
	var bm := BoxMesh.new()
	bm.size = Vector3(5.4, 1.1, 0.15)
	_plate = MeshInstance3D.new()
	_plate.mesh = bm
	_plate.material_override = pm
	_plate.position = Vector3(0, 3.1, 0.05)
	add_child(_plate)

func check_squad(squad_z: float) -> void:
	if triggered or squad_z > position.z:
		return
	triggered = true
	applied.emit(type, value)
	var tw := create_tween()
	tw.tween_property(_label, "position:y", 5.5, 0.6)
	tw.parallel().tween_property(_label, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_plate, "scale", Vector3.ONE * 0.01, 0.5)
