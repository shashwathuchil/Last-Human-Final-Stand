extends Node3D
# The runner squad: formation, forward march, lane drag, count management.

signal wiped
signal count_changed(n: int)
signal runner_shot(pos: Vector3, dmg: float)

const RunnerScene := preload("res://scripts/runner.gd")
const RUNNER_GLB := "res://assets/models/runner.glb"

var speed: float = 6.0
var target_x: float = 0.0
var x_limit: float = 2.2
var marching: bool = true
var runners := []
var _runner_glb: PackedScene

func _ready() -> void:
	_runner_glb = load(RUNNER_GLB)

func count() -> int:
	return runners.size()

func set_count(n: int) -> void:
	for r in runners:
		r.queue_free()
	runners.clear()
	add_runners(n)

func add_runners(n: int) -> void:
	for i in n:
		var r = RunnerScene.new()
		var m: Node3D = _runner_glb.instantiate()
		r.add_child(m)
		add_child(r)
		r.want_shoot.connect(_on_runner_shoot)
		runners.append(r)
	_layout()
	count_changed.emit(runners.size())

func remove_runners(n: int) -> int:
	var killed: int = 0
	for i in n:
		if runners.is_empty():
			break
		var r: Node3D = runners.pop_back()
		r.die()
		killed += 1
	_layout()
	count_changed.emit(runners.size())
	if runners.is_empty():
		wiped.emit()
	return killed

func _on_runner_shoot(pos: Vector3, dmg: float) -> void:
	runner_shot.emit(pos, dmg)

func _layout() -> void:
	var cols: int = mini(runners.size(), 5)
	if cols == 0:
		return
	for i in runners.size():
		var row: int = i / cols
		var col: int = i % cols
		var in_row: int = mini(cols, runners.size() - row * cols)
		var x: float = (col - (in_row - 1) * 0.5) * 0.8
		var z: float = row * 0.75
		runners[i].position = Vector3(x, 0, z)

func _process(delta: float) -> void:
	if not marching:
		return
	position.z -= speed * delta
	position.x = lerpf(position.x, target_x, 10.0 * delta)

func drag(dx_px: float, screen_w: float) -> void:
	target_x = clampf(target_x + dx_px * (7.0 / screen_w), -x_limit, x_limit)
