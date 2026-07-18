extends CanvasLayer
## Rhythm/sequence puzzle (bell sequence, cooking stages). Reproduce the target token
## sequence; a wrong press resets with no penalty. High-res UI-kit styled modal.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal solved(puzzle_id)
signal closed(puzzle_id)

var puzzle_id := "trail_bells"
var target: Array = ["low", "low", "high"]
var key_tokens: Dictionary = {KEY_DOWN: "low", KEY_UP: "high"}
var symbols: Dictionary = {"low": "LOW", "high": "HIGH"}
var title_text := "Ring the bells: short, short, long"
var prompt_text := "Down = low bell      Up = high bell"

var input: Array = []
var _done := false
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
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.hi_res(self)
	_build()
	var t := get_tree()
	if t:
		t.paused = true
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.position = Vector2.ZERO
	dim.size = UIKit.REF
	add_child(dim)
	var card := Panel.new()
	card.size = Vector2(900, 360)
	card.position = (UIKit.REF - card.size) / 2.0
	card.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16, true))
	add_child(card)

	_mk(card, title_text, UIKit.bold(), 22, 30, UIKit.INK)
	_target_lbl = _mk(card, "", UIKit.bold(), 30, 110, UIKit.INK)
	_input_lbl = _mk(card, "", UIKit.bold(), 30, 170, Color.html("c17a1e"))
	_feedback = _mk(card, "", UIKit.reg(), 16, 240, Color.html("b03030"))
	_mk(card, prompt_text + "        Esc  leave", UIKit.reg(), 14, 310, Color.html("6a5a3a"))

func _mk(card: Panel, text: String, font: Font, size: int, y: int, color: Color) -> Label:
	var l := UIKit.label(text, font, size, color)
	l.position = Vector2(0, y)
	l.size = Vector2(card.size.x, size + 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(l)
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
			_feedback.text = "Not quite - the birds answer wrong. Try again."
	elif is_solved():
		_win()
	_refresh()

func _refresh() -> void:
	if _target_lbl == null:
		return
	_target_lbl.text = "Target:    " + _syms(target)
	_input_lbl.text = "You:        " + _syms(input)

func _syms(seq: Array) -> String:
	var out := ""
	for t in seq:
		out += String(symbols.get(t, "?")) + "   "
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
