extends RefCounted
# Level tuning table. Everything is data-driven so levels/balance change here only.

static func level(n: int) -> Dictionary:
	return {
		"length": 150.0 + float(n) * 18.0,      # road distance to the boss zone (m)
		"crowd_count": 9 + n * 5,                # enemy crowds spawned along the road
		"crowd_size": 6 + n * 2,                 # enemies per crowd
		"enemy_hp": 5.0 + float(n) * 1.4,
		"enemy_speed": 2.1 + float(n) * 0.16,
		"boss_hp": 350.0 + float(n) * 200.0,
		"boss_speed": 1.1 + float(n) * 0.08,
		"squad_start": 6 + mini(n, 4),
		"gates": _gates_for(n),
	}

static func _gates_for(n: int) -> Array:
	var g: Array = []
	var pool: Array = [-3, 3, -2, 5, 4, -4, 6, -3, 8]
	for i in range(3 + mini(n, 3)):
		var v: int = pool[(i * 2 + n) % pool.size()]
		var t: String = "add" if v > 0 else "remove"
		if i == 2:
			t = "gold"  # third gate turns the hero golden
		g.append({"type": t, "value": absi(v)})
	return g
