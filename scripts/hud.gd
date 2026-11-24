extends CanvasLayer
# Gameplay HUD: level/score/squad chips, progress bar, boss HP bar, drag hint.

var level_label: Label
var score_label: Label
var squad_label: Label
var progress: ProgressBar
var boss_bar: Control
var boss_fill: ColorRect
var boss_num: Label
var hint: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# top bar
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 10
	top.offset_left = 14
	top.offset_right = -14
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	level_label = _chip("LEVEL 1")
	top.add_child(level_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	score_label = _chip("0")
	top.add_child(score_label)
	# progress bar under top bar
	progress = ProgressBar.new()
	progress.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress.position = Vector2(60, 66)
	progress.size = Vector2(600, 14)
	progress.min_value = 0
	progress.max_value = 1
	progress.value = 0
	progress.show_percentage = false
	root.add_child(progress)
	# squad chip bottom-left
	squad_label = _chip("SQUAD 6")
	squad_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	squad_label.position = Vector2(14, -80)
	root.add_child(squad_label)
	# drag hint bottom-center
	hint = Label.new()
	hint.text = "< DRAG TO MOVE >"
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-140, -110)
	root.add_child(hint)
	var tw := create_tween().set_loops()
	tw.tween_property(hint, "modulate:a", 0.15, 0.9)
	tw.tween_property(hint, "modulate:a", 0.6, 0.9)
	# boss bar
	boss_bar = Control.new()
	boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(60, 96)
	boss_bar.size = Vector2(600, 40)
	boss_bar.visible = false
	root.add_child(boss_bar)
	var bb := ColorRect.new()
	bb.color = Color(0.15, 0.02, 0.02, 0.85)
	bb.size = Vector2(600, 40)
	boss_bar.add_child(bb)
	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.85, 0.12, 0.1)
	boss_fill.size = Vector2(600, 40)
	boss_bar.add_child(boss_fill)
	boss_num = Label.new()
	boss_num.add_theme_font_size_override("font_size", 30)
	boss_num.add_theme_color_override("font_color", Color.WHITE)
	boss_num.position = Vector2(250, 2)
	boss_bar.add_child(boss_num)

func _chip(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l

func set_level(n: int) -> void:
	level_label.text = "LEVEL %d" % n

func set_score(n: int) -> void:
	score_label.text = "%d" % n

func set_squad(n: int) -> void:
	squad_label.text = "SQUAD %d" % n

func set_progress(t: float) -> void:
	progress.value = t

func set_boss(hp: float, max_hp: float) -> void:
	if hp > 0.0:
		boss_bar.visible = true
		boss_fill.size.x = 600.0 * clampf(hp / max_hp, 0.0, 1.0)
		boss_num.text = str(int(hp))
	else:
		boss_bar.visible = false
