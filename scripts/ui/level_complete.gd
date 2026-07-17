extends CanvasLayer
## Shown when a level is completed. Displays the neighborhood stamp and rewards, then
## returns to the title screen (subsequent districts are built in later milestones).

var _level: Dictionary = {}
var _stamp := ""
var _gs: Node
var _data: Node
var _next_id := ""
var _next_spawn := "start"

func configure(level: Dictionary, stamp_id: String, gs: Node, data: Node, next_id: String = "", next_spawn: String = "start") -> void:
	_level = level
	_stamp = stamp_id
	_gs = gs
	_data = data
	_next_id = next_id
	_next_spawn = next_spawn

func _ready() -> void:
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.96)
	dim.size = Vector2(320, 180)
	add_child(dim)

	var stamp_name: String = _data.stamp_name(_stamp) if _data else _stamp
	var bonus := int(_level.get("bonus_power", 0))
	var has_next: bool = _data != null and _next_id != "" and _data.has_level(_next_id)
	var body := "[center][b]NEIGHBORHOOD CLEARED[/b]\n\n"
	body += "[color=#ffd85a]* %s Stamp earned *[/color]\n\n" % stamp_name
	if bonus > 0:
		body += "+%d bonus Power\n" % bonus
	if _next_id != "":
		body += "District unlocked: %s\n\n" % _pretty(_next_id)
	if has_next:
		body += "[color=#9fe0a0]Press Enter to travel on ->[/color]"
	else:
		body += "[color=#9fb4c8]To be continued...[/color]\n\nPress Enter"
	body += "[/center]"

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
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	if _gs and _data and _next_id != "" and _data.has_level(_next_id):
		_gs.current_level_id = _next_id
		_gs.current_spawn_id = _next_spawn
		_gs.set_bike(false)
		_gs.save_game()
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	else:
		if _gs:
			_gs.save_game()
		get_tree().change_scene_to_file("res://scenes/title.tscn")
