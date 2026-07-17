extends CanvasLayer
## DialogueBox (UI handoff section 7): cream box on a high-res CanvasLayer, gold name-tag
## tab, speaker portrait, 21px Silkscreen text, blinking continue triangle. Space/Enter
## advances; player movement is locked while active (grid_player checks DialogueManager).

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const PORTRAITS := {
	"alp": "res://assets/characters/duo_down.png",
	"xiao": "res://assets/characters/duo_down.png",
	"narrator": "",
}

var _dm: Node
var _data: Node
var _box: Panel
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
	var bw := UIKit.REF.x - 64.0
	var bh := 176.0
	_box = Panel.new()
	_box.position = Vector2(32, UIKit.REF.y - 32 - bh)
	_box.size = Vector2(bw, bh)
	var sb := UIKit.panel_style(UIKit.CREAM, UIKit.INK, 5, 16)
	sb.corner_radius_top_left = 0
	_box.add_theme_stylebox_override("panel", sb)
	_box.visible = false
	add_child(_box)

	# inner hairline
	var inner := Panel.new()
	inner.position = Vector2(2, 2)
	inner.size = Vector2(bw - 4, bh - 4)
	var isb := UIKit.panel_style(Color(0, 0, 0, 0), UIKit.CREAM_INSET, 1, 14)
	isb.corner_radius_top_left = 0
	inner.add_theme_stylebox_override("panel", isb)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(inner)

	# name tag tab above the top-left corner
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

	# portrait chip
	_chip = Panel.new()
	_chip.position = Vector2(24, (bh - 69) / 2.0)
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

	# dialogue text
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(117, 20)
	_text.size = Vector2(bw - 117 - 40, bh - 40)
	_text.add_theme_font_override("normal_font", UIKit.reg())
	_text.add_theme_font_override("bold_font", UIKit.bold())
	_text.add_theme_font_size_override("normal_font_size", 21)
	_text.add_theme_font_size_override("bold_font_size", 21)
	_text.add_theme_color_override("default_color", UIKit.INK)
	_text.add_theme_constant_override("line_separation", 6)
	_box.add_child(_text)

	# blinking continue triangle (drawn, so it needs no font glyph)
	_arrow = Control.new()
	_arrow.position = Vector2(bw - 34, bh - 30)
	_arrow.size = Vector2(20, 20)
	_arrow.draw.connect(func() -> void:
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(14, 0), Vector2(7, 9)])
		_arrow.draw_colored_polygon(pts, UIKit.INK))
	_box.add_child(_arrow)

func _portrait_for(speaker: String) -> Texture2D:
	var npc_path := "res://assets/npcs/%s.png" % speaker
	if ResourceLoader.exists(npc_path):
		return load(npc_path)
	var p := String(PORTRAITS.get(speaker, "res://assets/characters/duo_down.png"))
	return load(p) if p != "" and ResourceLoader.exists(p) else null

func _on_line(speaker_id: String, text: String) -> void:
	var nm: String = _data.speaker_name(speaker_id) if _data else speaker_id
	_tag_lbl.text = nm.to_upper()
	_tag.visible = nm != ""
	var tex := _portrait_for(speaker_id)
	_portrait.texture = tex
	_chip.visible = tex != null
	_text.position.x = 117 if tex != null else 32
	_text.text = text
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
