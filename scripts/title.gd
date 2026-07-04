extends Control
## Title screen: start a new run or load a save.

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.11, 0.13, 0.20)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    _label("LA FOOD QUEST", 50, 18)
    _label("Alp & Xiao's LA Food Adventure", 78, 8)
    _label("Press ENTER to start", 116, 9)
    var gs := get_node_or_null("/root/GameState")
    if gs and gs.has_save():
        _label("Press L to load your save", 132, 8)
    _label("Arrows: move     Space/Enter: interact     Esc: pause", 160, 7)

func _label(text: String, y: float, size: int) -> void:
    var l := Label.new()
    l.text = text
    l.position = Vector2(10, y)
    l.size = Vector2(300, size + 6)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(1, 1, 1))
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    l.add_theme_constant_override("outline_size", 3)
    add_child(l)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _start_new()
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
        var gs := get_node_or_null("/root/GameState")
        if gs and gs.has_save() and gs.load_game():
            get_tree().change_scene_to_file("res://scenes/world.tscn")

func _start_new() -> void:
    var gs := get_node_or_null("/root/GameState")
    if gs:
        gs.reset()
    get_tree().change_scene_to_file("res://scenes/world.tscn")
