extends CanvasLayer
## Rotation puzzle (spec 12.6): four markers each rotated to a target compass facing;
## solved when all match. Rendered on a high-res CanvasLayer with the UI-kit styling so it
## reads like the dialogue box. Left/Right select, Up/Down rotate, A hint, R reset, Esc leave.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal solved(puzzle_id)
signal closed(puzzle_id)

const ARROWS := ["N", "E", "S", "W"]
const DIR_VEC := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const LABELS := ["Lotus", "Fountain", "Bridge", "Boathouse"]

var puzzle_id := "lake_map"
var target := [1, 2, 0, 3]
var labels: Array = LABELS.duplicate()
var title_text := "Broken Lake Map"
var orient := [0, 0, 0, 0]
var sel := 0
var show_hint := false
var _done := false

var _nodes: Array = []   # {panel, arrow, letter}
var _hint_lbl: Label
var _gs: Node

func configure(id: String, tgt: Array, lbls: Array = [], ttl: String = "") -> void:
	puzzle_id = id
	if tgt.size() == 4:
		target = tgt.duplicate()
	if lbls.size() == 4:
		labels = lbls.duplicate()
	if ttl != "":
		title_text = ttl

func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.hi_res(self)
	_gs = get_node_or_null("/root/GameState")
	_restore_state()
	_build()
	var t := get_tree()
	if t:
		t.paused = true
	_refresh()

func _restore_state() -> void:
	if _gs == null:
		return
	var st: Dictionary = _gs.get_puzzle_state(puzzle_id)
	if st.has("orient") and st["orient"] is Array and st["orient"].size() == 4:
		orient = (st["orient"] as Array).duplicate()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.position = Vector2.ZERO
	dim.size = UIKit.REF
	add_child(dim)

	var card := Panel.new()
	card.size = Vector2(920, 470)
	card.position = (UIKit.REF - card.size) / 2.0
	card.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16, true))
	add_child(card)

	var title := UIKit.label(title_text, UIKit.bold(), 24, UIKit.INK)
	title.position = Vector2(0, 24)
	title.size = Vector2(card.size.x, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	UIKit.fit(title, UIKit.bold(), 24, card.size.x - 48)

	var route := UIKit.label("Connect the route:   " + "  >  ".join(labels), UIKit.reg(), 16, Color.html("6a5a3a"))
	route.position = Vector2(0, 64)
	route.size = Vector2(card.size.x, 22)
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(route)
	UIKit.fit(route, UIKit.reg(), 16, card.size.x - 48)

	for i in 4:
		var nx := 55 + i * 210
		var panel := Panel.new()
		panel.position = Vector2(nx, 108)
		panel.size = Vector2(180, 230)
		panel.add_theme_stylebox_override("panel", _node_style(false))
		card.add_child(panel)
		var name_lbl := UIKit.label(String(labels[i]), UIKit.bold(), 16, UIKit.INK)
		name_lbl.position = Vector2(0, 12)
		name_lbl.size = Vector2(180, 22)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(name_lbl)
		var arrow := Control.new()
		arrow.position = Vector2(40, 44)
		arrow.size = Vector2(100, 100)
		var idx := i
		arrow.draw.connect(func() -> void: _draw_arrow(arrow, orient[idx]))
		panel.add_child(arrow)
		var letter := UIKit.label(ARROWS[orient[i]], UIKit.bold(), 22, UIKit.INK)
		letter.position = Vector2(0, 150)
		letter.size = Vector2(180, 30)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(letter)
		_nodes.append({"panel": panel, "arrow": arrow, "letter": letter})

	_hint_lbl = UIKit.label("", UIKit.reg(), 16, Color.html("2a6a8a"))
	_hint_lbl.position = Vector2(0, 356)
	_hint_lbl.size = Vector2(card.size.x, 24)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_hint_lbl)

	var help := UIKit.label("Left / Right  select      Up / Down  rotate      A  hint      R  reset      Esc  leave", UIKit.reg(), 14, Color.html("6a5a3a"))
	help.position = Vector2(0, 420)
	help.size = Vector2(card.size.x, 22)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(help)

func _node_style(selected: bool) -> StyleBoxFlat:
	return UIKit.panel_style(Color.html("fffaf0"), UIKit.GOLD if selected else UIKit.CREAM_INSET, 4 if selected else 2, 12)

func _draw_arrow(ctl: Control, dir: int) -> void:
	var c := ctl.size / 2.0
	var d: Vector2 = DIR_VEC[dir]
	var perp := Vector2(-d.y, d.x)
	var tip := c + d * 40.0
	var b1 := c - d * 22.0 + perp * 26.0
	var b2 := c - d * 22.0 - perp * 26.0
	ctl.draw_colored_polygon(PackedVector2Array([tip, b1, b2]), UIKit.GOLD)
	ctl.draw_circle(c - d * 30.0, 6.0, UIKit.INK)

func is_solved() -> bool:
	for i in 4:
		if orient[i] != target[i]:
			return false
	return true

func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var handled := true
	match event.keycode:
		KEY_LEFT:
			sel = (sel + 3) % 4
		KEY_RIGHT:
			sel = (sel + 1) % 4
		KEY_UP, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			orient[sel] = (orient[sel] + 1) % 4
		KEY_DOWN:
			orient[sel] = (orient[sel] + 3) % 4
		KEY_A:
			show_hint = not show_hint
		KEY_R:
			orient = [0, 0, 0, 0]
		KEY_ESCAPE:
			_save_state()
			_close()
		_:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh()
		if is_solved():
			_win()

func _refresh() -> void:
	for i in _nodes.size():
		_nodes[i]["letter"].text = ARROWS[orient[i]]
		_nodes[i]["arrow"].queue_redraw()
		_nodes[i]["panel"].add_theme_stylebox_override("panel", _node_style(i == sel))
	_hint_lbl.text = ("Trail Finder - target facings:   " + "   ".join(target.map(func(t): return ARROWS[t]))) if show_hint else ""

func _win() -> void:
	if _done:
		return
	_done = true
	_save_state(true)
	solved.emit(puzzle_id)
	_close()

func _save_state(is_solved_flag: bool = false) -> void:
	if _gs == null:
		return
	var st := {"orient": orient.duplicate()}
	if is_solved_flag:
		st["solved"] = true
	_gs.set_puzzle_state(puzzle_id, st)

func _close() -> void:
	var t := get_tree()
	if t:
		t.paused = false
	closed.emit(puzzle_id)
	queue_free()
