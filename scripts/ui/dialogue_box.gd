extends CanvasLayer
## DialogueBox (UI handoff section 7): cream box on a high-res CanvasLayer that auto-sizes to
## its text (less text -> smaller box, centered at the bottom) with the text vertically
## centered. Gold name-tag tab, speaker portrait, 21px Silkscreen, blinking continue triangle.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const MARGIN_BOTTOM := 32.0
const VPAD := 24.0            # text padding top/bottom
const TEXT_LEFT_PORTRAIT := 117.0
const TEXT_LEFT_PLAIN := 34.0
const RIGHT_PAD := 34.0
const FONT_SIZE := 21

const PORTRAITS := {
	"alp": "res://assets/npcs/alp.png",
	"xiao": "res://assets/npcs/xiao.png",
	"narrator": "",
}

var _dm: Node
var _data: Node
var _box: Panel
var _inner: Panel
var _tag: Panel
var _tag_lbl: Label
var _chip: Panel
var _portrait: TextureRect
var _text: RichTextLabel
var _arrow: Control
var _blink := 0.0

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.hi_res(self)
	_data = get_node_or_null("/root/GameData")
	_build()
	_dm = get_node_or_null("/root/DialogueManager")
	if _dm:
		_dm.line_shown.connect(_on_line)
		_dm.dialogue_finished.connect(_on_finished)

func _build() -> void:
	_box = Panel.new()
	var sb := UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16)
	sb.corner_radius_top_left = 0
	_box.add_theme_stylebox_override("panel", sb)
	_box.visible = false
	add_child(_box)

	_inner = Panel.new()
	_inner.position = Vector2(2, 2)
	var isb := UIKit.panel_style(Color(0, 0, 0, 0), UIKit.CREAM_INSET, 1, 14)
	isb.corner_radius_top_left = 0
	_inner.add_theme_stylebox_override("panel", isb)
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_inner)

	_tag = Panel.new()
	_tag.size = Vector2(200, 32)
	_tag.position = Vector2(0, -32)
	var tsb := UIKit.panel_style(UIKit.GOLD, UIKit.INK, 4, 11)
	tsb.corner_radius_bottom_left = 0
	tsb.corner_radius_bottom_right = 0
	tsb.border_width_bottom = 0
	_tag.add_theme_stylebox_override("panel", tsb)
	_box.add_child(_tag)
	_tag_lbl = UIKit.label("", UIKit.bold(), 16, UIKit.INK)
	_tag_lbl.position = Vector2(21, 0)
	_tag_lbl.size = Vector2(160, 32)
	_tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tag.add_child(_tag_lbl)

	_chip = Panel.new()
	_chip.size = Vector2(69, 69)
	_chip.add_theme_stylebox_override("panel", UIKit.panel_style(UIKit.PORTRAIT_BG, UIKit.INK, 3, 11))
	_box.add_child(_chip)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.position = Vector2(4, 4)
	_portrait.size = Vector2(61, 61)
	_chip.add_child(_portrait)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_override("normal_font", UIKit.reg())
	_text.add_theme_font_override("bold_font", UIKit.bold())
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	_text.add_theme_color_override("default_color", UIKit.INK)
	_text.add_theme_constant_override("line_separation", 6)
	_box.add_child(_text)

	_arrow = Control.new()
	_arrow.size = Vector2(20, 20)
	_arrow.draw.connect(func() -> void:
		_arrow.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(14, 0), Vector2(7, 9)]), UIKit.INK))
	_box.add_child(_arrow)

func _portrait_for(speaker: String) -> Texture2D:
	var npc_path := "res://assets/npcs/%s.png" % speaker
	if ResourceLoader.exists(npc_path):
		return load(npc_path)
	var p := String(PORTRAITS.get(speaker, "res://assets/characters/duo_down.png"))
	return load(p) if p != "" and ResourceLoader.exists(p) else null

func _on_line(speaker_id: String, text: String) -> void:
	var nm: String = _data.speaker_name(speaker_id) if _data else speaker_id
	nm = nm.to_upper()
	var tex := _portrait_for(speaker_id)
	var has_p := tex != null

	_portrait.texture = tex
	_chip.visible = has_p
	_tag.visible = nm != ""
	_tag_lbl.text = nm

	var text_left: float = TEXT_LEFT_PORTRAIT if has_p else TEXT_LEFT_PLAIN
	var max_tw: float = UIKit.REF.x - 64.0 - text_left - RIGHT_PAD
	# measure natural single-line width; wrap only if it overflows
	var natural := UIKit.reg().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var tw: float = min(natural + 6.0, max_tw)
	_text.position.x = text_left
	_text.size.x = tw
	_text.text = text
	await get_tree().process_frame
	var th: float = _text.get_content_height()

	# box dimensions
	var box_w: float = text_left + tw + RIGHT_PAD
	var box_h: float = th + 2.0 * VPAD
	if has_p:
		box_h = max(box_h, 69.0 + 40.0)
	box_h = max(box_h, 84.0)
	box_h = min(box_h, UIKit.REF.y - 120.0)
	# make sure the name tag fits along the top edge
	var tag_w := 0.0
	if nm != "":
		tag_w = UIKit.bold().get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 44.0
		_tag.size.x = tag_w
	box_w = max(box_w, tag_w + 8.0, 300.0)
	box_w = min(box_w, UIKit.REF.x - 64.0)

	# position centered along the bottom
	_box.position = Vector2((UIKit.REF.x - box_w) / 2.0, UIKit.REF.y - MARGIN_BOTTOM - box_h)
	_box.size = Vector2(box_w, box_h)
	_inner.size = Vector2(box_w - 4.0, box_h - 4.0)

	# vertically centered text + portrait
	_text.size = Vector2(tw, th)
	_text.position.y = (box_h - th) / 2.0
	if has_p:
		_chip.position = Vector2(24, (box_h - 69.0) / 2.0)
	_arrow.position = Vector2(box_w - 34.0, box_h - 30.0)
	_box.visible = true

func _on_finished(_id: String) -> void:
	_box.visible = false

func _process(delta: float) -> void:
	if _box.visible and _arrow:
		_blink += delta
		if _blink >= 0.5:
			_blink = 0.0
			_arrow.visible = not _arrow.visible

func _input(event: InputEvent) -> void:
	if _dm == null or not _dm.is_active():
		return
	if event.is_action_pressed("ui_accept"):
		_dm.advance()
		get_viewport().set_input_as_handled()
