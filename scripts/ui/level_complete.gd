extends CanvasLayer
## Shown when a level is completed. Displays the neighborhood stamp and rewards, then
## returns to the title screen (subsequent districts are built in later milestones).

var _level: Dictionary = {}
var _stamp := ""
var _gs: Node
var _data: Node

func configure(level: Dictionary, stamp_id: String, gs: Node, data: Node) -> void:
	_level = level
	_stamp = stamp_id
	_gs = gs
	_data = data

func _ready() -> void:
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.96)
	dim.size = Vector2(320, 180)
	add_child(dim)

	var stamp_name: String = _data.stamp_name(_stamp) if _data else _stamp
	var next_id := String(_level.get("next_level_id", ""))
	var bonus := int(_level.get("bonus_power", 0))
	var body := "[center][b]NEIGHBORHOOD CLEARED[/b]\n\n"
	body += "[color=#ffd85a]\u2605 %s Stamp earned \u2605[/color]\n\n" % stamp_name
	body += "Tandem Bike unlocked\n"
	if bonus > 0:
		body += "+%d bonus Power\n" % bonus
	if next_id != "":
		body += "District unlocked: %s\n" % _pretty(next_id)
	body += "\n[color=#9fb4c8]To be continued...[/color]\n\n"
	body += "Press Enter[/center]"

	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.position = Vector2(20, 34)
	rt.size = Vector2(280, 120)
	rt.add_theme_font_size_override("normal_font_size", 9)
	rt.add_theme_font_size_override("bold_font_size", 12)
	rt.text = body
	add_child(rt)

func _pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if _gs:
			_gs.save_game()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		get_viewport().set_input_as_handled()
