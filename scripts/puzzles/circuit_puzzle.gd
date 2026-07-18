extends CanvasLayer
## Neon circuit puzzle as "lights-out": toggling a relay flips it and its neighbors; solved
## when every relay is lit. Start is a fixed scramble from all-lit, so it is always solvable.
## High-res UI-kit styled modal. Left/Right select, Space toggle, R reset, Esc leave.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal solved(puzzle_id)
signal closed(puzzle_id)

var puzzle_id := "neon_circuit"
var n := 5
var labels: Array = ["Source", "Ember", "Karaoke", "Dessert", "Relay"]
var scramble: Array = [1, 3]
var title_text := "Neon Circuit: light every relay"

var lights: Array = []
var sel := 0
var _done := false
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
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.hi_res(self)
	init_state()
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
	card.size = Vector2(960, 380)
	card.position = (UIKit.REF - card.size) / 2.0
	card.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16, true))
	add_child(card)

	var title := UIKit.label(title_text, UIKit.bold(), 22, UIKit.INK)
	title.position = Vector2(0, 28)
	title.size = Vector2(card.size.x, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)

	var gap := 24.0
	var total := card.size.x - 80.0
	var cw: float = (total - gap * (n - 1)) / float(n)
	for i in n:
		var cx := 40.0 + i * (cw + gap)
		var cell := Panel.new()
		cell.position = Vector2(cx, 110)
		cell.size = Vector2(cw, 120)
		card.add_child(cell)
		var lbl := UIKit.label(String(labels[i]) if i < labels.size() else str(i), UIKit.bold(), 15, UIKit.INK)
		lbl.position = Vector2(cx, 240)
		lbl.size = Vector2(cw, 22)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(lbl)
		_cells.append(cell)

	var help := UIKit.label("Left / Right  select      Space  toggle      R  reset      Esc  leave", UIKit.reg(), 14, Color.html("6a5a3a"))
	help.position = Vector2(0, 330)
	help.size = Vector2(card.size.x, 22)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(help)

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
		var bg := Color.html("3ad07a") if lit else Color.html("3a2020")
		var border := UIKit.GOLD if i == sel else (Color.html("2a8a55") if lit else Color.html("5a3030"))
		_cells[i].add_theme_stylebox_override("panel", UIKit.panel_style(bg, border, 4 if i == sel else 2, 10))

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
