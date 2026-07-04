extends CanvasLayer
## HUD: Fullness / Energy gauges (exact-size ColorRect bars), Power/goal, clock, and an
## auto-sizing toast panel that grows to fit multi-line messages.

const BAR_W := 78.0
var _full: ColorRect
var _energy: ColorRect
var _power_lbl: Label
var _clock_lbl: Label
var _toast_panel: PanelContainer
var _toast_lbl: Label
var _toast_t := 0.0

func _ready() -> void:
    layer = 100
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var panel := ColorRect.new()
    panel.color = Color(0, 0, 0, 0.45)
    panel.position = Vector2(2, 2)
    panel.size = Vector2(124, 42)
    root.add_child(panel)
    _label(root, Vector2(6, 3), "FULL", 9)
    _full = _bar(root, Vector2(42, 5), Color(0.95, 0.62, 0.20))
    _label(root, Vector2(6, 16), "NRG", 9)
    _energy = _bar(root, Vector2(42, 18), Color(0.35, 0.80, 0.42))
    _power_lbl = _label(root, Vector2(6, 29), "PWR 0 / 100", 10)
    _clock_lbl = _label(root, Vector2(196, 4), "Day 1  08:00", 10)
    _clock_lbl.size = Vector2(120, 14)
    _clock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    _toast_panel = PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0, 0, 0, 0.75)
    sb.set_corner_radius_all(2)
    sb.content_margin_left = 6
    sb.content_margin_right = 6
    sb.content_margin_top = 3
    sb.content_margin_bottom = 3
    _toast_panel.add_theme_stylebox_override("panel", sb)
    _toast_panel.visible = false
    root.add_child(_toast_panel)
    _toast_lbl = Label.new()
    _toast_lbl.custom_minimum_size = Vector2(280, 0)
    _toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _toast_lbl.add_theme_font_size_override("font_size", 9)
    _toast_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
    _toast_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _toast_lbl.add_theme_constant_override("outline_size", 3)
    _toast_panel.add_child(_toast_lbl)

    var g := _gs()
    if g:
        g.meters_changed.connect(_refresh)
        g.time_changed.connect(_refresh_clock)
        g.collapsed.connect(func() -> void: self.toast("Food coma! Alp & Xiao passed out and lost a whole day."))
    _refresh()
    _refresh_clock()

func _gs() -> Node:
    return get_node_or_null("/root/GameState")

func toast(text: String) -> void:
    _toast_lbl.text = text
    _toast_panel.reset_size()
    var sz := _toast_panel.get_combined_minimum_size()
    _toast_panel.size = sz
    _toast_panel.position = Vector2((320.0 - sz.x) / 2.0, 178.0 - sz.y)
    _toast_panel.visible = true
    _toast_panel.modulate.a = 1.0
    _toast_t = 3.4

func _process(delta: float) -> void:
    if _toast_t > 0.0:
        _toast_t -= delta
        if _toast_t <= 0.0:
            _toast_panel.visible = false
        elif _toast_t < 0.6:
            _toast_panel.modulate.a = _toast_t / 0.6

func _refresh() -> void:
    var g := _gs()
    if g == null:
        return
    _full.size.x = BAR_W * (clampf(g.fullness, 0.0, 100.0) / 100.0)
    _full.color = Color(1, 0.45, 0.45) if g.fullness > 70.0 else Color(0.95, 0.62, 0.20)
    _energy.size.x = BAR_W * (clampf(g.energy, 0.0, 100.0) / 100.0)
    _energy.color = Color(1, 0.45, 0.45) if g.energy < 25.0 else Color(0.35, 0.80, 0.42)
    _power_lbl.text = "PWR %d / 100" % g.power

func _refresh_clock() -> void:
    var g := _gs()
    if g:
        _clock_lbl.text = g.clock_string()

func _bar(parent: Control, pos: Vector2, color: Color) -> ColorRect:
    var bg := ColorRect.new()
    bg.position = pos
    bg.size = Vector2(BAR_W, 7)
    bg.color = Color(0, 0, 0, 0.6)
    parent.add_child(bg)
    var fill := ColorRect.new()
    fill.position = pos
    fill.size = Vector2(0, 7)
    fill.color = color
    parent.add_child(fill)
    return fill

func _label(parent: Control, pos: Vector2, text: String, size: int) -> Label:
    var l := Label.new()
    l.position = pos
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(1, 1, 1))
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    l.add_theme_constant_override("outline_size", 3)
    parent.add_child(l)
    return l
