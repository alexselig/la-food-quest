extends CanvasLayer
## Shown when a car runs the duo over. ENTER returns to the title and resets state.

func _ready() -> void:
    layer = 300
    process_mode = Node.PROCESS_MODE_ALWAYS
    var bg := ColorRect.new()
    bg.color = Color(0.12, 0.0, 0.0, 0.78)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var lbl := Label.new()
    lbl.position = Vector2(0, 58)
    lbl.size = Vector2(320, 70)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.text = "GAME OVER\nAlp & Xiao got run over!\n\nPress ENTER for the title"
    lbl.add_theme_font_size_override("font_size", 12)
    lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    lbl.add_theme_constant_override("outline_size", 4)
    bg.add_child(lbl)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        get_tree().paused = false
        var gs := get_node_or_null("/root/GameState")
        if gs:
            gs.reset()
        get_tree().change_scene_to_file("res://scenes/title.tscn")
