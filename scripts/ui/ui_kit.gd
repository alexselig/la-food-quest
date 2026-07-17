extends Object
## Shared UI palette, fonts and StyleBox factories from the LA Food Quest UI handoff.
## UI renders on high-res CanvasLayers (1280x720 reference) scaled to counter the 320x180
## world stretch, so text stays crisp/legible.

# Reference design resolution (window px). World stays 320x180.
const REF := Vector2(1280, 720)

# --- Palette (handoff section 1) ---
static var INK := Color.html("241a3a")
static var PANEL := Color.html("221b34")
static var GOLD := Color.html("f4c95d")
static var PANEL_INSET := Color.html("4a3a6e")
static var CREAM := Color.html("fdf8ec")
static var CREAM_INSET := Color.html("b89a5a")
static var VALUE := Color.html("d8cdf0")
static var ACCENT := Color.html("c17a1e")
static var PWR := Color.html("e8a93a")
static var FULL := Color.html("e8823a")
static var NRG := Color.html("5fbf7a")
static var PORTRAIT_BG := Color.html("0f0c1a")

const FONT_REG := "res://assets/fonts/Silkscreen-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/Silkscreen-Bold.ttf"
const FONT_TITLE := "res://assets/fonts/PressStart2P-Regular.ttf"

static var _cache := {}

static func _font(path: String) -> Font:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]

static func reg() -> Font:
	return _font(FONT_REG)

static func bold() -> Font:
	return _font(FONT_BOLD)

static func title() -> Font:
	return _font(FONT_TITLE)

# Scale a CanvasLayer so its children, laid out in 1280x720 window px, render 1:1 in the
# window regardless of the 320x180 world stretch.
static func hi_res(layer: CanvasLayer) -> void:
	var vp := layer.get_viewport().get_visible_rect().size if layer.get_viewport() else REF
	if vp.x > 0.0:
		layer.scale = Vector2(vp.x / REF.x, vp.y / REF.y)

static func label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func panel_style(bg: Color, border_c: Color, bw: int, radius: int, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = border_c
	sb.set_corner_radius_all(radius)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
	return sb
