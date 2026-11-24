extends Node
# Persistent progress (unlocked level, best score).

const PATH := "user://save.cfg"

var unlocked: int = 1
var best_score: int = 0

func load_save() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) == OK:
		unlocked = int(c.get_value("progress", "unlocked", 1))
		best_score = int(c.get_value("progress", "best_score", 0))

func save_now() -> void:
	var c := ConfigFile.new()
	c.set_value("progress", "unlocked", unlocked)
	c.set_value("progress", "best_score", best_score)
	c.save(PATH)
