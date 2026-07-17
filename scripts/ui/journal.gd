extends CanvasLayer
## Journal (Tab or J): quest log, neighborhood passport, recipes, FoodDex. Pauses the
## tree while open so the world is frozen behind the overlay.

var _root: Control
var _text: RichTextLabel
var _open := false
var gs: Node
var data: Node
var quests: Node

func _ready() -> void:
	layer = 175
	process_mode = Node.PROCESS_MODE_ALWAYS
	gs = get_node_or_null("/root/GameState")
	data = get_node_or_null("/root/GameData")
	quests = get_node_or_null("/root/QuestManager")
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.06, 0.94)
	dim.size = Vector2(320, 180)
	_root.add_child(dim)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.position = Vector2(10, 8)
	_text.size = Vector2(300, 164)
	_text.add_theme_font_size_override("normal_font_size", 8)
	_text.add_theme_font_size_override("bold_font_size", 9)
	_root.add_child(_text)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_J or event.keycode == KEY_TAB):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	_open = not _open
	_root.visible = _open
	get_tree().paused = _open
	if _open:
		_refresh()

func _refresh() -> void:
	if gs == null or data == null:
		return
	var s := "[b]JOURNAL[/b]   (Tab/J to close)\n\n"
	# Quest log
	var qid := "L1_MAIN"
	var lvl: Dictionary = data.get_level(String(gs.current_level_id))
	if lvl.has("completion_quest_id"):
		qid = String(lvl["completion_quest_id"])
	var qdef: Dictionary = data.get_quest(qid)
	if not qdef.is_empty():
		s += "[b]Quest: %s[/b]\n" % String(qdef.get("title", qid))
		for step in qdef.get("steps", []):
			var sid := String(step.get("id", ""))
			var done: bool = quests != null and quests.is_step_done(qid, sid)
			var cur: bool = quests != null and quests.current_step_id(qid) == sid
			var mark: String = "[color=#7fd67f][x][/color]" if done else ("[color=#ffd85a]>[/color]" if cur else "  ")
			s += "  %s %s\n" % [mark, String(step.get("text", sid))]
	# Passport
	s += "\n[b]Passport[/b]  (%d/5)\n" % gs.stamp_count()
	for sid in data.STAMPS.keys():
		var got: bool = gs.has_stamp(sid)
		s += "  %s %s\n" % ["[color=#7fd67f][x][/color]" if got else "-", data.stamp_name(sid)]
	# Recipes
	s += "\n[b]Recipes[/b]  (%d)\n" % gs.recipe_count()
	for rid in data.RECIPES.keys():
		if gs.has_recipe(rid):
			s += "  - %s\n" % data.recipe_name(rid)
	# FoodDex
	s += "\n[b]FoodDex[/b]\n"
	var dex_names := ["Unknown", "Rumored", "Discovered", "Visited", "Signature", "Secret"]
	for rid in data.RESTAURANTS.keys():
		var st: int = gs.food_dex_state(rid)
		var nm := String(data.get_restaurant(rid).get("display_name", rid))
		if st == 0:
			s += "  - ??? (Unknown)\n"
		else:
			s += "  - %s - %s\n" % [nm, dex_names[st]]
	_text.text = s
