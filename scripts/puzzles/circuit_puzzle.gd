extends Node2D
## Neon circuit puzzle (spec 14.5) as a "lights-out" relay board: toggling a relay flips
## it and its neighbors; the block is powered when every relay is lit. The start state is a
## fixed scramble applied from all-lit, so it is always solvable by repeating that scramble.
## Modal (pauses tree). Left/Right select, Space toggle, R reset, Esc leave (no penalty).

signal solved(puzzle_id)
signal closed(puzzle_id)

var puzzle_id := "neon_circuit"
var n := 5
var labels: Array = ["Source", "Ember", "Karaoke", "Dessert", "Relay"]
var scramble: Array = [1, 3]     # toggles from all-lit -> solvable start
var title_text := "Neon Circuit: light every relay"

var lights: Array = []
var sel := 0
var _done := false
var _root: Control
var _cells: Array = []

func configure(id: String, count: int = 5, scr: Array = [], lbls: Array = [], ttl: String = "") -> void:
	puzzle_id = id
	n = count
	if not scr.is_empty():
		scramble = scr.duplicate()
	if lbls.size() == count:
		labels = lbls.duplicate()
	if ttl != "":
		title_text = ttl

func init_state() -> void:
	lights = []
	for i in n:
		lights.append(true)
	for i in scramble:
		apply_toggle(int(i))

## Pure logic: flip relay i and its immediate neighbors.
func apply_toggle(i: int) -> void:
	for j in [i - 1, i, i + 1]:
		if j >= 0 and j < n:
			lights[j] = not lights[j]

func is_solved() -> bool:
	for l in lights:
		if not l:
			return false
	return true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_state()
	_build()
	var t := get_tree()
	if t:
		t.paused = true
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = Vector2(320, 180)
	add_child(dim)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_mk(title_text, 9, Vector2(20, 26), 280).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var w := 300.0 / float(n)
	for i in n:
		var box := ColorRect.new()
		box.position = Vector2(12 + i * w, 70)
		box.size = Vector2(w - 8, 34)
		_root.add_child(box)
		var lbl := _mk(labels[i] if i < labels.size() else str(i), 6, Vector2(12 + i * w, 108), int(w))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cells.append(box)
	_mk("Left/Right select   Space toggle   R reset   Esc leave", 7, Vector2(20, 150), 280).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _mk(text: String, size: int, pos: Vector2, w: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, 16)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	_root.add_child(l)
	return l

func toggle(i: int) -> void:
	if _done:
		return
	apply_toggle(i)
	_refresh()
	if is_solved():
		_win()

func _refresh() -> void:
	for i in _cells.size():
		var lit: bool = lights[i]
		var c := _cells[i] as ColorRect
		c.color = Color(0.3, 1.0, 0.5) if lit else Color(0.25, 0.12, 0.12)
		if i == sel:
			c.color = c.color.lightened(0.25) if lit else Color(0.5, 0.3, 0.3)

func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT:
			sel = (sel + n - 1) % n
			_refresh()
		KEY_RIGHT:
			sel = (sel + 1) % n
			_refresh()
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_UP, KEY_DOWN:
			toggle(sel)
		KEY_R:
			init_state()
			_refresh()
		KEY_ESCAPE:
			_close()
		_:
			return
	get_viewport().set_input_as_handled()

func _win() -> void:
	if _done:
		return
	_done = true
	solved.emit(puzzle_id)
	_close()

func _close() -> void:
	var t := get_tree()
	if t:
		t.paused = false
	closed.emit(puzzle_id)
	queue_free()
