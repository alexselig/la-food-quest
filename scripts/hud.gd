extends CanvasLayer
## HUD (UI handoff sections 4-6): high-res CanvasLayer (1280x720 ref) so text is crisp.
## Gold-bordered stat panel (portrait + PWR/FULL/NRG meters), day/time badge, objective
## line, and a cream discovery toast.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

var _root: Control
var _pwr_bar: TextureProgressBar
var _full_bar: TextureProgressBar
var _nrg_bar: TextureProgressBar
var _pwr_val: Label
var _full_val: Label
var _nrg_val: Label
var _clock_lbl: Label
var _obj_lbl: Label

var _toast_panel: PanelContainer
var _toast_lbl: RichTextLabel
var _toast_t := 0.0

func _ready() -> void:
	layer = 100
	UIKit.hi_res(self)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_stat_panel()
	_build_time_badge()
	_build_objective()
	_build_hint()
	_build_toast()

	var g := _gs()
	if g:
		g.meters_changed.connect(_refresh)
		g.time_changed.connect(_refresh_clock)
		g.collapsed.connect(func() -> void: self.toast("Food coma! Alp & Xiao passed out and lost a whole day."))
	_refresh()
	_refresh_clock()

func _gs() -> Node:
	return get_node_or_null("/root/GameState")

func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

# ---------------------------------------------------------------- stat panel
func _build_stat_panel() -> void:
	var panel := Panel.new()
	panel.position = Vector2(21, 21)
	panel.size = Vector2(400, 145)
	panel.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.PANEL, UIKit.GOLD, 4, 13, true))
	_root.add_child(panel)

	var inset := Panel.new()
	inset.position = Vector2(2, 2)
	inset.size = Vector2(396, 141)
	inset.add_theme_stylebox_override("panel", UIKit.panel_style(Color(0, 0, 0, 0), UIKit.PANEL_INSET, 1, 11))
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(inset)

	# Portrait chip
	var chip := Panel.new()
	chip.position = Vector2(16, 16)
	chip.size = Vector2(45, 45)
	chip.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.PORTRAIT_BG, UIKit.GOLD, 3, 8))
	panel.add_child(chip)
	var por := TextureRect.new()
	por.texture = _tex("res://assets/characters/duo_down.png")
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.position = Vector2(3, 3)
	por.size = Vector2(39, 39)
	chip.add_child(por)

	var name_lbl := UIKit.label("ALP & XIAO", UIKit.bold(), 15, UIKit.CREAM)
	name_lbl.position = Vector2(75, 12)
	name_lbl.size = Vector2(300, 20)
	panel.add_child(name_lbl)

	var meters := [
		["PWR", UIKit.PWR, "pwr"],
		["FULL", UIKit.FULL, "full"],
		["NRG", UIKit.NRG, "nrg"],
	]
	for i in meters.size():
		var m = meters[i]
		var y := 40 + i * 33
		var pill := Panel.new()
		pill.position = Vector2(75, y)
		pill.size = Vector2(52, 22)
		pill.add_theme_stylebox_override("panel", UIKit.panel_style(m[1], (m[1] as Color).darkened(0.35), 1, 8))
		panel.add_child(pill)
		var pl := UIKit.label(m[0], UIKit.bold(), 12, UIKit.INK)
		pl.set_anchors_preset(Control.PRESET_FULL_RECT)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.add_child(pl)

		var bar := TextureProgressBar.new()
		bar.texture_under = _tex("res://assets/ui/bar_track.png")
		bar.texture_progress = _tex("res://assets/ui/bar_fill_%s.png" % m[2])
		bar.nine_patch_stretch = true
		bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 0
		bar.position = Vector2(135, y + 3)
		bar.size = Vector2(174, 16)
		bar.custom_minimum_size = Vector2(174, 16)
		panel.add_child(bar)

		var val := UIKit.label("0/100", UIKit.reg(), 13, UIKit.VALUE)
		val.position = Vector2(315, y + 1)
		val.size = Vector2(70, 20)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(val)

		match m[2]:
			"pwr":
				_pwr_bar = bar
				_pwr_val = val
			"full":
				_full_bar = bar
				_full_val = val
			"nrg":
				_nrg_bar = bar
				_nrg_val = val

# ---------------------------------------------------------------- day/time badge
func _build_time_badge() -> void:
	var badge := Panel.new()
	badge.size = Vector2(232, 34)
	badge.position = Vector2(UIKit.REF.x - 21 - badge.size.x, 21)
	badge.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.PANEL, UIKit.GOLD, 4, 17, true))
	_root.add_child(badge)
	var dot := Panel.new()
	dot.position = Vector2(14, 11)
	dot.size = Vector2(12, 12)
	dot.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.GOLD, UIKit.GOLD, 0, 6))
	badge.add_child(dot)
	_clock_lbl = UIKit.label("DAY 1 - 8:00 AM", UIKit.bold(), 15, UIKit.CREAM)
	_clock_lbl.position = Vector2(34, 0)
	_clock_lbl.size = Vector2(190, 34)
	_clock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(_clock_lbl)

# ---------------------------------------------------------------- objective + hint
func _build_objective() -> void:
	_obj_lbl = UIKit.label("", UIKit.bold(), 15, UIKit.GOLD)
	_obj_lbl.position = Vector2(24, 176)
	_obj_lbl.size = Vector2(1000, 22)
	_obj_lbl.add_theme_color_override("font_outline_color", UIKit.INK)
	_obj_lbl.add_theme_constant_override("outline_size", 6)
	_root.add_child(_obj_lbl)

func _build_hint() -> void:
	var hint := UIKit.label("A Trail Finder   S Food Sense   Tab Journal   Esc Pause", UIKit.reg(), 12, Color(0.8, 0.82, 0.9, 0.85))
	hint.position = Vector2(21, UIKit.REF.y - 30)
	hint.size = Vector2(760, 20)
	hint.add_theme_color_override("font_outline_color", UIKit.INK)
	hint.add_theme_constant_override("outline_size", 5)
	_root.add_child(hint)

func set_objective(text: String) -> void:
	if _obj_lbl:
		_obj_lbl.text = ("> " + text) if text != "" else ""
		UIKit.fit(_obj_lbl, UIKit.bold(), 15, 1000)

# ---------------------------------------------------------------- toast
func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16))
	_toast_panel.visible = false
	_root.add_child(_toast_panel)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 27)
	pad.add_theme_constant_override("margin_right", 27)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	_toast_panel.add_child(pad)
	_toast_lbl = RichTextLabel.new()
	_toast_lbl.bbcode_enabled = true
	_toast_lbl.fit_content = true
	_toast_lbl.scroll_active = false
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_toast_lbl.add_theme_font_override("normal_font", UIKit.bold())
	_toast_lbl.add_theme_font_override("bold_font", UIKit.bold())
	_toast_lbl.add_theme_font_size_override("normal_font_size", 20)
	_toast_lbl.add_theme_font_size_override("bold_font_size", 20)
	_toast_lbl.add_theme_color_override("default_color", UIKit.INK)
	pad.add_child(_toast_lbl)

func toast(text: String) -> void:
	var fs := 20
	var tw: float = UIKit.bold().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	if tw > 1150.0 and tw > 0.0:
		fs = max(12, int(20.0 * 1150.0 / tw))
	_toast_lbl.add_theme_font_size_override("normal_font_size", fs)
	_toast_lbl.add_theme_font_size_override("bold_font_size", fs)
	var shown := text
	if "PWR" in text:
		var idx := text.find("+")
		if idx >= 0:
			shown = text.substr(0, idx) + "[color=#%s]" % UIKit.ACCENT.to_html(false) + text.substr(idx) + "[/color]"
	_toast_lbl.text = shown
	_toast_panel.reset_size()
	await get_tree().process_frame
	var sz := _toast_panel.get_combined_minimum_size()
	_toast_panel.size = sz
	_toast_panel.position = Vector2((UIKit.REF.x - sz.x) / 2.0, UIKit.REF.y - 21 - sz.y)
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	_toast_t = 3.6

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast_panel.visible = false
		elif _toast_t < 0.6:
			_toast_panel.modulate.a = _toast_t / 0.6

# ---------------------------------------------------------------- refresh
func _refresh() -> void:
	var g := _gs()
	if g == null:
		return
	if _pwr_bar:
		_pwr_bar.value = clampf(g.power, 0.0, 100.0)
		_pwr_val.text = "%d/100" % g.power
	if _full_bar:
		_full_bar.value = clampf(g.fullness, 0.0, 100.0)
		_full_val.text = "%d/100" % int(round(g.fullness))
	if _nrg_bar:
		_nrg_bar.value = clampf(g.energy, 0.0, 100.0)
		_nrg_val.text = "%d/100" % int(round(g.energy))

func _refresh_clock() -> void:
	var g := _gs()
	if g == null or _clock_lbl == null:
		return
	var h24 := int(g.minutes) / 60
	var mn := int(g.minutes) % 60
	var ampm := "AM" if h24 < 12 else "PM"
	var h12 := h24 % 12
	if h12 == 0:
		h12 = 12
	_clock_lbl.text = "DAY %d - %d:%02d %s" % [g.day, h12, mn, ampm]
