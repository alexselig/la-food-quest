extends CanvasLayer
## Level-complete / legendary screen (UI handoff section 8). High-res CanvasLayer with the
## exported legendary_bg gold burst, a Press Start 2P title, Silkscreen subtitle, sparkles,
## and a blinking prompt pill. Continues to the next district (if built) or the title.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

var _level: Dictionary = {}
var _stamp := ""
var _gs: Node
var _data: Node
var _next_id := ""
var _next_spawn := "start"

var _prompt: Panel
var _blink := 0.0

func configure(level: Dictionary, stamp_id: String, gs: Node, data: Node, next_id: String = "", next_spawn: String = "start") -> void:
	_level = level
	_stamp = stamp_id
	_gs = gs
	_data = data
	_next_id = next_id
	_next_spawn = next_spawn

func _ready() -> void:
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	UIKit.hi_res(self)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# full-bleed gold burst background
	var bg := TextureRect.new()
	bg.texture = _load("res://assets/ui/legendary_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.position = Vector2.ZERO
	bg.size = UIKit.REF
	root.add_child(bg)

	var is_final: bool = _data != null and _next_id != "" and not _data.has_level(_next_id)
	var has_next: bool = _data != null and _next_id != "" and _data.has_level(_next_id)

	# sparkles
	var star := _load("res://assets/fx/star.png")
	if star:
		for p in [[220, 150, 0.5], [1000, 180, 0.7], [360, 300, 0.35], [900, 360, 0.5]]:
			var s := TextureRect.new()
			s.texture = star
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.size = Vector2(64, 64) * p[2]
			s.position = Vector2(p[0], p[1])
			s.modulate = Color(1, 1, 1, 0.85)
			root.add_child(s)

	# optional building art for the true Golden Ladle finale
	if is_final:
		var bld := _load("res://assets/buildings/golden_ladle.png")
		if bld:
			var b := TextureRect.new()
			b.texture = bld
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			b.size = Vector2(320, 200)
			b.position = Vector2((UIKit.REF.x - 320) / 2.0, 150)
			root.add_child(b)

	var title_text := "THE GOLDEN LADLE" if is_final else "DISTRICT CLEARED!"
	var title := UIKit.label(title_text, UIKit.title(), 34, Color.html("fff6e6"))
	title.position = Vector2(0, 250)
	title.size = Vector2(UIKit.REF.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color.html("5a2416"))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_constant_override("shadow_outline_size", 2)
	root.add_child(title)
	UIKit.fit(title, UIKit.title(), 34, UIKit.REF.x - 100)

	var stamp_name: String = _data.stamp_name(_stamp) if _data else _stamp
	var bonus := int(_level.get("bonus_power", 0))
	var sub := "* %s stamp earned *" % stamp_name
	if bonus > 0:
		sub += "    +%d Power" % bonus
	var subtitle := UIKit.label(sub, UIKit.bold(), 21, Color.html("5a2416"))
	subtitle.position = Vector2(0, 330)
	subtitle.size = Vector2(UIKit.REF.x, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)
	UIKit.fit(subtitle, UIKit.bold(), 21, UIKit.REF.x - 100)

	if has_next:
		var nxt := UIKit.label("Next: %s" % _pretty(_next_id), UIKit.bold(), 16, Color.html("5a2416"))
		nxt.position = Vector2(0, 366)
		nxt.size = Vector2(UIKit.REF.x, 24)
		nxt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(nxt)

	# prompt pill
	_prompt = Panel.new()
	_prompt.size = Vector2(360, 52)
	_prompt.position = Vector2((UIKit.REF.x - 360) / 2.0, 470)
	_prompt.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.PANEL, UIKit.GOLD, 4, 16, true))
	root.add_child(_prompt)
	var msg := "> PRESS ENTER TO TRAVEL ON" if has_next else "> PRESS ENTER"
	var pl := UIKit.label(msg, UIKit.bold(), 18, UIKit.CREAM)
	pl.set_anchors_preset(Control.PRESET_FULL_RECT)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_child(pl)

func _load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

func _pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()

func _process(delta: float) -> void:
	if _prompt:
		_blink += delta
		if _blink >= 0.55:
			_blink = 0.0
			_prompt.visible = not _prompt.visible

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	if _gs and _data and _next_id != "" and _data.has_level(_next_id):
		_gs.current_level_id = _next_id
		_gs.current_spawn_id = _next_spawn
		_gs.set_bike(false)
		_gs.save_game()
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	else:
		if _gs:
			_gs.save_game()
		get_tree().change_scene_to_file("res://scenes/title.tscn")
