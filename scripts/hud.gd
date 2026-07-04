extends CanvasLayer
## Minimal HUD bound to the GameState autoload: Fullness / Energy bars, Power, clock,
## plus a transient toast line for interaction feedback. Resolved via node path so it
## parses cleanly headlessly.

var _full: ProgressBar
var _energy: ProgressBar
var _power_lbl: Label
var _clock_lbl: Label
var _toast_lbl: Label
var _toast_t := 0.0

func _ready() -> void:
    layer = 100
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _make_label(root, Vector2(4, 2), "FULL")
    _full = _make_bar(root, Vector2(34, 3), Color(0.95, 0.62, 0.20))
    _make_label(root, Vector2(4, 12), "NRG")
    _energy = _make_bar(root, Vector2(34, 13), Color(0.35, 0.80, 0.42))
    _power_lbl = _make_label(root, Vector2(4, 22), "PWR 0")
    _clock_lbl = _make_label(root, Vector2(246, 2), "Day 1  08:00")

    _toast_lbl = _make_label(root, Vector2(8, 160), "")
    _toast_lbl.size = Vector2(304, 16)
    _toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _toast_lbl.modulate.a = 0.0

    var g := _gs()
    if g:
        g.meters_changed.connect(_refresh)
        g.time_changed.connect(_refresh_clock)
        g.collapsed.connect(func() -> void: self.toast("Food coma! Alp & Xiao lost ~a day."))
    _refresh()
    _refresh_clock()

func _gs() -> Node:
    return get_node_or_null("/root/GameState")

func toast(text: String) -> void:
    _toast_lbl.text = text
    _toast_lbl.modulate.a = 1.0
    _toast_t = 3.0

func _process(delta: float) -> void:
    if _toast_t > 0.0:
        _toast_t -= delta
        if _toast_t <= 0.0:
            _toast_lbl.modulate.a = 0.0
        elif _toast_t < 0.6:
            _toast_lbl.modulate.a = _toast_t / 0.6

func _refresh() -> void:
    var g := _gs()
    if g == null:
        return
    _full.value = g.fullness
    _full.modulate = Color(1, 0.4, 0.4) if g.fullness > 70.0 else Color(1, 1, 1)
    _energy.value = g.energy
    _energy.modulate = Color(1, 0.4, 0.4) if g.energy < 25.0 else Color(1, 1, 1)
    _power_lbl.text = "PWR %d" % g.power

func _refresh_clock() -> void:
    var g := _gs()
    if g:
        _clock_lbl.text = g.clock_string()

func _make_bar(parent: Control, pos: Vector2, color: Color) -> ProgressBar:
    var b := ProgressBar.new()
    b.position = pos
    b.custom_minimum_size = Vector2(70, 7)
    b.size = Vector2(70, 7)
    b.min_value = 0
    b.max_value = 100
    b.value = 0
    b.show_percentage = false
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0, 0, 0, 0.55)
    var fg := StyleBoxFlat.new()
    fg.bg_color = color
    b.add_theme_stylebox_override("background", bg)
    b.add_theme_stylebox_override("fill", fg)
    parent.add_child(b)
    return b

func _make_label(parent: Control, pos: Vector2, text: String) -> Label:
    var l := Label.new()
    l.position = pos
    l.text = text
    l.add_theme_font_size_override("font_size", 8)
    l.add_theme_color_override("font_color", Color(1, 1, 1))
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    l.add_theme_constant_override("outline_size", 3)
    parent.add_child(l)
    return l
