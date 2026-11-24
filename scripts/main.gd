extends Node
# App shell: save data, main menu, level flow, end screens.

const Game := preload("res://scripts/game.gd")
const Hud := preload("res://scripts/hud.gd")
const Save := preload("res://scripts/save.gd")

var save
var game
var hud
var menu: CanvasLayer
var current_level: int = 1

func _ready() -> void:
	save = Save.new()
	add_child(save)
	save.load_save()
	current_level = save.unlocked
	_show_menu()
	# headless/dev autostart: godot -- --autoplay [level]
	var args := OS.get_cmdline_user_args()
	if args.has("--autoplay"):
		var i := args.find("--autoplay")
		if i + 1 < args.size():
			current_level = int(args[i + 1])
		_play()

func _show_menu() -> void:
	_clear_game()
	menu = CanvasLayer.new()
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-210, -300)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 26)
	menu.add_child(box)
	var title := Label.new()
	title.text = "LAST HUMAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "FINAL STAND"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 40)
	sub.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	box.add_child(sub)
	var lvl := Label.new()
	lvl.text = "LEVEL %d" % current_level
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 30)
	lvl.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(lvl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var minus := _btn("-")
	minus.pressed.connect(func(): _shift_level(-1, lvl))
	row.add_child(minus)
	var plus := _btn("+")
	plus.pressed.connect(func(): _shift_level(1, lvl))
	row.add_child(plus)
	var play := _btn("PLAY")
	play.custom_minimum_size = Vector2(320, 90)
	play.add_theme_font_size_override("font_size", 44)
	play.pressed.connect(_play)
	box.add_child(play)

func _shift_level(d: int, lbl: Label) -> void:
	current_level = clampi(current_level + d, 1, save.unlocked)
	lbl.text = "LEVEL %d" % current_level

func _btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(90, 60)
	b.add_theme_font_size_override("font_size", 34)
	return b

func _play() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	game = Game.new()
	add_child(game)
	game.level_won.connect(_on_won)
	game.level_lost.connect(_on_lost)
	hud = Hud.new()
	add_child(hud)
	hud.set_level(current_level)
	game.hud_squad.connect(hud.set_squad)
	game.hud_score.connect(hud.set_score)
	game.hud_progress.connect(hud.set_progress)
	game.hud_boss.connect(hud.set_boss)
	game.start_level(current_level)

func _on_won(score: int) -> void:
	save.unlocked = maxi(save.unlocked, current_level + 1)
	save.best_score = maxi(save.best_score, score)
	save.save_now()
	_end_screen(true, score)

func _on_lost() -> void:
	_end_screen(false, 0)

func _end_screen(won: bool, score: int) -> void:
	await get_tree().create_timer(1.2).timeout
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-200, -180)
	box.custom_minimum_size = Vector2(400, 0)
	box.add_theme_constant_override("separation", 30)
	layer.add_child(box)
	var msg := Label.new()
	msg.text = "VICTORY!" if won else "SQUAD WIPED"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 64)
	msg.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2) if won else Color(1.0, 0.3, 0.25))
	box.add_child(msg)
	if won:
		var sc := Label.new()
		sc.text = "SCORE %d" % score
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sc.add_theme_font_size_override("font_size", 34)
		sc.add_theme_color_override("font_color", Color.WHITE)
		box.add_child(sc)
	var b := _btn("NEXT" if won else "RETRY")
	b.custom_minimum_size = Vector2(320, 80)
	b.pressed.connect(func():
		layer.queue_free()
		if won:
			current_level += 1
		_play())
	box.add_child(b)
	var mb := _btn("MENU")
	mb.pressed.connect(func():
		layer.queue_free()
		_show_menu())
	box.add_child(mb)

func _clear_game() -> void:
	if is_instance_valid(game):
		game.queue_free()
		game = null
	if is_instance_valid(hud):
		hud.queue_free()
		hud = null
