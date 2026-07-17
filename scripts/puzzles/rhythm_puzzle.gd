extends Node2D
## Rhythm/sequence puzzle (spec 13.7 bell sequence, 14.8 dance circle). Player reproduces
## a target token sequence (e.g. low/low/high). A wrong press resets the attempt with no
## penalty (main quests never hard-fail). Modal (pauses the tree). Esc leaves.

signal solved(puzzle_id)
signal closed(puzzle_id)

var puzzle_id := "trail_bells"
var target: Array = ["low", "low", "high"]
# keycode -> token
var key_tokens: Dictionary = {KEY_DOWN: "low", KEY_UP: "high"}
# token -> display symbol
var symbols: Dictionary = {"low": "lo", "high": "HI"}
var title_text := "Ring the bells: short, short, long"
var prompt_text := "Down = low bell    Up = high bell"

var input: Array = []
var _done := false
var _root: Control
var _target_lbl: Label
var _input_lbl: Label
var _feedback: Label

func configure(id: String, tgt: Array, keys: Dictionary = {}, syms: Dictionary = {}, ttl: String = "", prompt: String = "") -> void:
	puzzle_id = id
	if not tgt.is_empty():
		target = tgt.duplicate()
	if not keys.is_empty():
		key_tokens = keys.duplicate()
	if not syms.is_empty():
		symbols = syms.duplicate()
	if ttl != "":
		title_text = ttl
	if prompt != "":
		prompt_text = prompt

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var t := get_tree()
	if t:
		t.paused = true
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = Vector2(320, 180)
	add_child(dim)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var title := _mk(title_text, 9, Vector2(20, 34), 280)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_lbl = _mk("", 20, Vector2(20, 60), 280)
	_target_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input_lbl = _mk("", 20, Vector2(20, 92), 280)
	_input_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	_feedback = _mk("", 8, Vector2(20, 126), 280)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _mk(prompt_text + "    Esc leave", 8, Vector2(20, 150), 280)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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

func is_solved() -> bool:
	return input.size() == target.size() and _prefix_ok(input.size())

func _prefix_ok(n: int) -> bool:
	for i in n:
		if i >= target.size() or input[i] != target[i]:
			return false
	return true

func press_token(tok: String) -> void:
	if _done:
		return
	input.append(tok)
	if not _prefix_ok(input.size()):
		input.clear()
		if _feedback:
			_feedback.text = "The birds answer wrong. Try again."
	elif is_solved():
		_win()
	_refresh()

func _refresh() -> void:
	if _target_lbl == null:
		return
	_target_lbl.text = "Target:  " + _syms(target)
	_input_lbl.text = "You:     " + _syms(input)

func _syms(seq: Array) -> String:
	var out := ""
	for t in seq:
		out += String(symbols.get(t, "?")) + " "
	return out.strip_edges()

func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
		return
	if key_tokens.has(event.keycode):
		get_viewport().set_input_as_handled()
		press_token(String(key_tokens[event.keycode]))

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
