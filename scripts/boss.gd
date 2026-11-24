extends Node3D
# Giant boss: huge HP shown as a floating number, stomps toward the squad.

signal died
signal reached_squad

const BOSS_GLB := "res://assets/models/boss.glb"

var hp: float = 500.0
var max_hp: float = 500.0
var speed: float = 1.1
var dead: bool = false

var _model: Node3D
var _label: Label3D
var _bar_bg: MeshInstance3D
var _t: float = 0.0
var _drain: float = 0.0

func setup(h: float, s: float) -> void:
	hp = h
	max_hp = h
	speed = s
	_model = load(BOSS_GLB).instantiate()
	add_child(_model)
	_label = Label3D.new()
	_label.text = str(int(hp))
	_label.font_size = 96
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 5.2, 0)
	_label.modulate = Color.WHITE
	_label.outline_size = 12
	_label.outline_modulate = Color(0.5, 0.05, 0.05)
	add_child(_label)
	# red health bar behind the number
	var bg := StandardMaterial3D.new()
	bg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.albedo_color = Color(0.75, 0.15, 0.12)
	var bm := BoxMesh.new()
	bm.size = Vector3(3.0, 0.55, 0.05)
	_bar_bg = MeshInstance3D.new()
	_bar_bg.mesh = bm
	_bar_bg.material_override = bg
	_bar_bg.position = Vector3(0, 5.2, 0.05)
	add_child(_bar_bg)

func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	position.z += speed * delta
	_model.position.y = absf(sin(_t * 3.0)) * 0.15
	_model.rotation.z = sin(_t * 3.0) * 0.05
	_label.text = str(maxi(0, int(hp)))
	_bar_bg.scale.x = maxf(0.02, hp / max_hp)

func hit(dmg: float) -> void:
	if dead:
		return
	hp -= dmg
	if hp <= 0.0:
		die()

func drain_tick(delta: float) -> bool:
	# squad is in reach — chew through it
	_drain += delta
	if _drain >= 1.0:
		_drain = 0.0
		return true
	return false

func die() -> void:
	if dead:
		return
	dead = true
	_label.visible = false
	_bar_bg.visible = false
	died.emit()
	var tw := create_tween()
	tw.tween_property(_model, "rotation:x", -1.4, 0.7).set_trans(Tween.TRANS_BOUNCE)
	tw.parallel().tween_property(self, "scale", Vector3(1.05, 0.3, 1.05), 0.8)
	tw.tween_callback(queue_free)
