extends Node3D
# Game world: road, skyline, squad, hero, enemies, gates, boss, bullets, FX, camera.

signal level_won(score: int)
signal level_lost()
signal hud_squad(n: int)
signal hud_score(n: int)
signal hud_progress(t: float)
signal hud_boss(hp: float, max_hp: float)

const Data := preload("res://scripts/data.gd")
const Squad := preload("res://scripts/squad.gd")
const Hero := preload("res://scripts/hero.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Boss := preload("res://scripts/boss.gd")
const Gate := preload("res://scripts/gate.gd")
const Bullet := preload("res://scripts/bullet.gd")

const BRIDGE_GLB := "res://assets/models/bridge.glb"
const BUILDINGS_GLB := "res://assets/models/buildings.glb"
const BULLET_POOL := 140
const SPARK_POOL := 24

var level_n: int = 1
var cfg: Dictionary
var over: bool = false
var score: int = 0

var squad
var hero
var cam: Camera3D
var cam_rig: Node3D

var enemies := []
var gates := []
var events := []
var boss
var boss_active: bool = false

var bullets := []
var sparks: Array[GPUParticles3D] = []
var _spark_i: int = 0

func start_level(n: int) -> void:
	level_n = n
	_gamelog = OS.get_cmdline_user_args().has("--gamelog")
	cfg = Data.level(n)
	_build_world()
	_build_pools()
	squad = Squad.new()
	squad.runner_shot.connect(_on_runner_shot)
	squad.wiped.connect(_lose)
	add_child(squad)
	squad.set_count(int(cfg["squad_start"]))
	squad.count_changed.connect(func(c: int): hud_squad.emit(c))
	hud_squad.emit(squad.count())
	hero = Hero.new()
	hero.hero_shot.connect(_on_hero_shot)
	add_child(hero)
	_build_events()

# ---------------- world ----------------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.03, 0.05, 0.14)
	sky_mat.sky_horizon_color = Color(0.10, 0.14, 0.28)
	sky_mat.ground_bottom_color = Color(0.02, 0.03, 0.08)
	sky_mat.ground_horizon_color = Color(0.10, 0.14, 0.28)
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.75
	e.fog_enabled = true
	e.fog_light_color = Color(0.10, 0.14, 0.28)
	e.fog_density = 0.012
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(0.95, 0.9, 1.0)
	add_child(sun)
	cam_rig = Node3D.new()
	add_child(cam_rig)
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.position = Vector3(0.9, 7.2, 9.5)
	cam.rotation_degrees = Vector3(-22, 4, 0)
	cam_rig.add_child(cam)
	# road tiles
	var bridge: PackedScene = load(BRIDGE_GLB)
	var length: float = cfg["length"]
	var n_tiles: int = int((length + 90.0) / 20.0) + 2
	for i in n_tiles:
		var t: Node3D = bridge.instantiate()
		t.position = Vector3(0, 0, 10.0 - i * 20.0)
		add_child(t)
	# skyline: scatter building meshes from buildings.glb
	var bsrc: Node3D = load(BUILDINGS_GLB).instantiate()
	var meshes: Array = []
	for c in bsrc.get_children():
		meshes.append(c)
	for i in range(26):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var src: Node3D = meshes[i % meshes.size()]
		var b: Node3D = src.duplicate()
		b.position = Vector3(side * randf_range(11.0, 20.0), 0, -i * randf_range(9.0, 13.0) + 8.0)
		b.rotation.y = randf() * TAU
		add_child(b)
	bsrc.queue_free()

func _build_pools() -> void:
	for i in BULLET_POOL:
		var b = Bullet.new()
		add_child(b)
		bullets.append(b)
	# spark particles
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 55.0
	pmat.initial_velocity_min = 3.0
	pmat.initial_velocity_max = 6.0
	pmat.gravity = Vector3(0, -6, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.12
	pmat.color = Color(0.55, 0.85, 1.0)
	var dm := SphereMesh.new()
	dm.radius = 0.06
	dm.height = 0.12
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.55, 0.85, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.5, 0.8, 1.0)
	m.emission_energy_multiplier = 3.0
	dm.material = m
	for i in SPARK_POOL:
		var p := GPUParticles3D.new()
		p.amount = 10
		p.lifetime = 0.4
		p.one_shot = true
		p.explosiveness = 0.9
		p.process_material = pmat
		p.draw_pass_1 = dm
		add_child(p)
		sparks.append(p)

func _spark_at(pos: Vector3) -> void:
	var p: GPUParticles3D = sparks[_spark_i]
	_spark_i = (_spark_i + 1) % sparks.size()
	p.global_position = pos
	p.restart()

# ---------------- level events ----------------

func _build_events() -> void:
	events.clear()
	var length: float = cfg["length"]
	var crowds: int = int(cfg["crowd_count"])
	for i in crowds:
		var d: float = 22.0 + (length - 60.0) * (float(i) / maxf(1.0, float(crowds - 1)))
		events.append({"at": d, "kind": "crowd"})
	for i in cfg["gates"].size():
		var g: Dictionary = cfg["gates"][i]
		var d: float = length * (0.25 + 0.22 * i)
		events.append({"at": d, "kind": "gate", "gate": g})
	events.append({"at": length, "kind": "boss"})
	events.sort_custom(func(a: Dictionary, b: Dictionary): return a["at"] < b["at"])

func _fire_event(ev: Dictionary) -> void:
	match ev["kind"]:
		"crowd":
			_spawn_crowd()
		"gate":
			var g: Dictionary = ev["gate"]
			var gate = Gate.new()
			add_child(gate)
			gate.position = Vector3(2.9, 0, squad.position.z - 34.0)
			gate.setup(g["type"], int(g["value"]))
			gate.applied.connect(_on_gate)
			gates.append(gate)
		"boss":
			_spawn_boss()

func _spawn_crowd() -> void:
	var cx: float = randf_range(-2.4, 2.4)
	var n: int = int(cfg["crowd_size"])
	for i in n:
		var e = Enemy.new()
		add_child(e)
		e.setup(float(cfg["enemy_hp"]), float(cfg["enemy_speed"]))
		e.position = Vector3(
			clampf(cx + randf_range(-1.8, 1.8), -3.2, 3.2),
			0,
			squad.position.z - randf_range(42.0, 58.0))
		e.ox = e.position.x - squad.position.x
		e.target_x = e.position.x
		e.died.connect(_on_enemy_died)
		e.reached.connect(_on_enemy_reached)
		enemies.append(e)

func _spawn_boss() -> void:
	boss = Boss.new()
	add_child(boss)
	boss.position = Vector3(0, 0, squad.position.z - 55.0)
	boss.setup(float(cfg["boss_hp"]), float(cfg["boss_speed"]))
	boss.died.connect(_on_boss_died)
	boss_active = true

# ---------------- combat ----------------

func _on_runner_shot(pos: Vector3, dmg: float) -> void:
	# runners snap-aim at the nearest enemy in their lane ahead
	var dir := Vector3(0, 0, -1)
	var best: float = 1e9
	for e in enemies:
		var ep: Vector3 = e.global_position
		if ep.z < pos.z - 1.0 and absf(ep.x - pos.x) < 3.5:
			var d: float = (ep - pos).length_squared()
			if d < best:
				best = d
				dir = (ep + Vector3(0, 0.5, 0) - pos).normalized()
	if boss_active and is_instance_valid(boss) and not boss.dead:
		var bp: Vector3 = boss.global_position
		if bp.z < pos.z - 1.0 and absf(bp.x - pos.x) < 4.0:
			dir = (bp + Vector3(0, 1.5, 0) - pos).normalized()
	_fire_bullet(pos, dir, dmg, false)

func _on_hero_shot(pos: Vector3, dir: Vector3, dmg: float) -> void:
	_fire_bullet(pos, dir, dmg, true)

func _fire_bullet(from: Vector3, dir: Vector3, dmg: float, hero_shot: bool) -> void:
	for b in bullets:
		if not b.active:
			b.launch(from, dir, dmg, hero_shot)
			return

func _on_gate(type: String, value: int) -> void:
	match type:
		"add":
			squad.add_runners(value)
		"remove":
			squad.remove_runners(value)
		"gold":
			hero.set_golden(true)

func _on_enemy_died(e: Node3D) -> void:
	score += 10
	hud_score.emit(score)
	enemies.erase(e)
	_spark_at(e.global_position + Vector3(0, 0.6, 0))

func _on_enemy_reached(e: Node3D) -> void:
	enemies.erase(e)
	e.queue_free()
	squad.remove_runners(1)

func _on_boss_died() -> void:
	boss_active = false
	score += 250
	hud_score.emit(score)
	_win()

func _win() -> void:
	if over:
		return
	over = true
	print("[GAME] WON level=%d score=%d squad=%d" % [level_n, score, squad.count()])
	level_won.emit(score)

func _lose() -> void:
	if over:
		return
	over = true
	print("[GAME] LOST level=%d score=%d dist=%d" % [level_n, score, int(-squad.position.z)])
	level_lost.emit()

# ---------------- per-frame ----------------

var _gamelog: bool = false

func _process(delta: float) -> void:
	if over:
		return
	if _gamelog and Engine.get_process_frames() % 120 == 0:
		print("[LOG] t=%.0f dist=%.0f squad=%d enemies=%d boss=%s" % [Time.get_ticks_msec() / 1000.0, -squad.position.z, squad.count(), enemies.size(), boss_active])
	var sz: float = squad.position.z
	var dist: float = -sz
	# fire spawn events
	while not events.is_empty() and dist >= float(events[0]["at"]):
		_fire_event(events.pop_front())
	# hero rides ahead-left of the squad
	hero.position = Vector3(-3.3, 0, sz - 6.5)
	# hero aims at nearest enemy
	var tgt: Vector3 = Vector3(0, 1, sz - 35)
	var best: float = 1e9
	for e in enemies:
		var d: float = e.global_position.distance_squared_to(hero.global_position)
		if d < best:
			best = d
			tgt = e.global_position + Vector3(0, 0.7, 0)
	if boss_active and is_instance_valid(boss):
		var bd: float = boss.global_position.distance_squared_to(hero.global_position)
		if bd < best:
			tgt = boss.global_position + Vector3(0, 2.2, 0)
	hero.aim_at(tgt)
	# camera follows
	cam_rig.position = Vector3(squad.position.x * 0.3, 0, sz)
	# bullets (sub-stepped so fast shots can't tunnel through enemies)
	var zmin: float = sz - 95.0
	var zmax: float = sz + 12.0
	for b in bullets:
		if not b.active:
			continue
		var steps: int = mini(int(b.velocity.length() * delta / 0.45) + 1, 60)
		var step_dt: float = delta / steps
		var hit_done: bool = false
		for s in steps:
			b.global_position += b.velocity * step_dt
			var p: Vector3 = b.global_position
			if p.z < zmin or p.z > zmax or p.y < -0.5:
				b.kill()
				hit_done = true
				break
			for e in enemies:
				var ep: Vector3 = e.global_position
				var dx: float = p.x - ep.x
				var dz: float = p.z - ep.z
				var dy: float = p.y - (ep.y + 0.6)
				if dx * dx + dz * dz + dy * dy < 0.55:
					e.hit(b.damage)
					_spark_at(p)
					b.kill()
					hit_done = true
					break
			if hit_done:
				break
			if boss_active and is_instance_valid(boss) and not boss.dead:
				var bp: Vector3 = boss.global_position
				var dx: float = p.x - bp.x
				var dz: float = p.z - bp.z
				var dy: float = p.y - (bp.y + 2.0)
				if dx * dx + dz * dz + dy * dy < 3.6:
					boss.hit(b.damage)
					_spark_at(p)
					hud_boss.emit(maxf(0.0, boss.hp), boss.max_hp)
					b.kill()
					hit_done = true
					break
			if hit_done:
				break
	# enemy-vs-squad contact + homing + despawn behind the squad
	var rl: Array = squad.runners
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if e.position.z > sz + 12.0:
			enemies.remove_at(i)
			e.queue_free()
			continue
		if e.dead:
			continue
		e.target_x = clampf(squad.position.x + e.ox, -3.2, 3.2)
		for r in rl:
			if not is_instance_valid(r) or r.dead:
				continue
			var dx: float = e.position.x - (squad.position.x + r.position.x)
			var dz: float = e.position.z - (sz + r.position.z)
			if dx * dx + dz * dz < 0.55:
				e.reached.emit(e)
				break
	# gates
	for g in gates:
		g.check_squad(sz)
	# boss reach / hp hud
	if boss_active and is_instance_valid(boss):
		hud_boss.emit(maxf(0.0, boss.hp), boss.max_hp)
		if (sz - boss.position.z) < 4.0:
			if boss.drain_tick(delta):
				squad.remove_runners(1)
	hud_progress.emit(clampf(dist / float(cfg["length"]), 0.0, 1.0))

# ---------------- input ----------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		squad.drag(event.relative.x, float(get_viewport().get_visible_rect().size.x))
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		squad.drag(event.relative.x, float(get_viewport().get_visible_rect().size.x))
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			squad.target_x = clampf(squad.target_x - 0.8, -squad.x_limit, squad.x_limit)
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			squad.target_x = clampf(squad.target_x + 0.8, -squad.x_limit, squad.x_limit)
