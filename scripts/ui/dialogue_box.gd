extends CanvasLayer
## DialogueBox: renders DialogueManager lines in a bottom panel. Space/Enter advances.
## Player movement/interaction is locked while active (grid_player checks
## DialogueManager.is_active(); this box consumes ui_accept in _input so it never
## leaks to the world interaction handler).

var _panel: PanelContainer
var _name_lbl: Label
var _text_lbl: Label
var _hint_lbl: Label
var _dm: Node
var _data: Node

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	_data = get_node_or_null("/root/GameData")
	_build()
	_dm = get_node_or_null("/root/DialogueManager")
	if _dm:
		_dm.line_shown.connect(_on_line)
		_dm.dialogue_finished.connect(_on_finished)

func _build() -> void:
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	sb.border_color = Color(0.9, 0.8, 0.4, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(6, 128)
	_panel.size = Vector2(308, 46)
	_panel.visible = false
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	_panel.add_child(vb)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 9)
	_name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_name_lbl.add_theme_constant_override("outline_size", 3)
	vb.add_child(_name_lbl)

	_text_lbl = Label.new()
	_text_lbl.custom_minimum_size = Vector2(296, 22)
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.add_theme_font_size_override("font_size", 9)
	_text_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	_text_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_text_lbl.add_theme_constant_override("outline_size", 3)
	vb.add_child(_text_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.text = "\u25B6 Space"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_lbl.add_theme_font_size_override("font_size", 7)
	_hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(_hint_lbl)

func _on_line(speaker_id: String, text: String) -> void:
	var nm: String = _data.speaker_name(speaker_id) if _data else speaker_id
	_name_lbl.text = nm
	_name_lbl.visible = nm != ""
	_name_lbl.add_theme_color_override("font_color", _data.speaker_color(speaker_id) if _data else Color(1, 1, 1))
	_text_lbl.text = text
	_panel.visible = true

func _on_finished(_id: String) -> void:
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if _dm == null or not _dm.is_active():
		return
	if event.is_action_pressed("ui_accept"):
		_dm.advance()
		get_viewport().set_input_as_handled()
