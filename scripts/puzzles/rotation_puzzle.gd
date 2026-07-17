extends Node2D
## Rotation puzzle (spec 12.6 / 18.7): four nodes, each rotated to a target orientation.
## Solved when every node matches its target. Modal (pauses the tree). Trail Finder (A)
## toggles a hint showing the target arrows. Arrow keys select/rotate; Enter/Space rotate;
## R resets; Esc gives up (no penalty — main quests never hard-fail).

signal solved(puzzle_id)
signal closed(puzzle_id)

const ARROWS := ["N", "E", "S", "W"]  # facing direction: North East South West
const LABELS := ["Lotus", "Fountain", "Bridge", "Boathouse"]

var puzzle_id := "lake_map"
var target := [1, 2, 0, 3]   # correct orientations (route: Lotus->Fountain->Bridge->Boathouse)
var labels: Array = LABELS.duplicate()
var title_text := "Rotate the markers to connect the route"
var orient := [0, 0, 0, 0]
var sel := 0
var show_hint := false
var _done := false

var _root: Control
var _cells: Array = []
var _hint_lbl: Label
var _gs: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gs = get_node_or_null("/root/GameState")
	_restore_state()
	_build()
	var t := get_tree()
	if t:
		t.paused = true
	_refresh()

func configure(id: String, tgt: Array, lbls: Array = [], ttl: String = "") -> void:
	puzzle_id = id
	if tgt.size() == 4:
		target = tgt.duplicate()
	if lbls.size() == 4:
		labels = lbls.duplicate()
	if ttl != "":
		title_text = ttl

func _restore_state() -> void:
	if _gs == null:
		return
	var st: Dictionary = _gs.get_puzzle_state(puzzle_id)
	if st.has("orient") and st["orient"] is Array and st["orient"].size() == 4:
		orient = (st["orient"] as Array).duplicate()

func _build() -> void:
	layer_dim()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var title := _mk_label(title_text, 9, Vector2(20, 22))
	title.size = Vector2(280, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for i in 4:
		var box := Panel.new()
		box.position = Vector2(28 + i * 68, 60)
		box.size = Vector2(56, 56)
		_root.add_child(box)
		var arrow := _mk_label("", 22, Vector2(28 + i * 68, 66))
		arrow.size = Vector2(56, 34)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var name_lbl := _mk_label(labels[i], 7, Vector2(28 + i * 68, 120))
		name_lbl.size = Vector2(56, 10)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cells.append({"box": box, "arrow": arrow})

	_hint_lbl = _mk_label("", 7, Vector2(20, 140))
	_hint_lbl.size = Vector2(280, 24)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))

	var help := _mk_label("Left/Right select   Up/Down rotate   A hint   R reset   Esc leave", 7, Vector2(20, 160))
	help.size = Vector2(280, 10)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func layer_dim() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.size = Vector2(320, 180)
	add_child(dim)

func _mk_label(text: String, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	_root.add_child(l)
	return l

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
			_close(false)
		_:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh()
		if is_solved():
			_win()

func _refresh() -> void:
	for i in 4:
		_cells[i]["arrow"].text = ARROWS[orient[i]]
		var on := (i == sel)
		_cells[i]["arrow"].add_theme_color_override("font_color", Color(1, 0.9, 0.4) if on else Color(1, 1, 1))
	_hint_lbl.text = ("Trail Finder: target " + " ".join(target.map(func(t): return ARROWS[t]))) if show_hint else ""

func _win() -> void:
	if _done:
		return
	_done = true
	_save_state(true)
	solved.emit(puzzle_id)
	_close(true)

func _save_state(is_solved_flag: bool = false) -> void:
	if _gs == null:
		return
	var st := {"orient": orient.duplicate()}
	if is_solved_flag:
		st["solved"] = true
	_gs.set_puzzle_state(puzzle_id, st)

func _close(_success: bool) -> void:
	var t := get_tree()
	if t:
		t.paused = false
	closed.emit(puzzle_id)
	queue_free()
