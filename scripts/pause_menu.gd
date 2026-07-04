extends CanvasLayer
## Pause overlay: Esc toggles pause; while paused, S saves, Q quits to title.
## Uses PROCESS_MODE_ALWAYS so it keeps handling input while the tree is paused.

var _overlay: ColorRect
var _label: Label
var _paused := false

func _ready() -> void:
    layer = 200
    process_mode = Node.PROCESS_MODE_ALWAYS
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 0.6)
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.visible = false
    add_child(_overlay)
    _label = Label.new()
    _label.position = Vector2(0, 66)
    _label.size = Vector2(320, 60)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.add_theme_font_size_override("font_size", 9)
    _label.add_theme_color_override("font_color", Color(1, 1, 1))
    _label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _label.add_theme_constant_override("outline_size", 3)
    _set_text("")
    _overlay.add_child(_label)

func _set_text(extra: String) -> void:
    _label.text = "PAUSED %s\nEsc: resume    S: save    Q: quit to title" % extra

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _toggle()
        get_viewport().set_input_as_handled()
    elif _paused and event is InputEventKey and event.pressed and not event.echo:
        var gs := get_node_or_null("/root/GameState")
        if event.keycode == KEY_S and gs:
            gs.save_game()
            _set_text("(saved!)")
        elif event.keycode == KEY_Q:
            get_tree().paused = false
            get_tree().change_scene_to_file("res://scenes/title.tscn")

func _toggle() -> void:
    _paused = not _paused
    get_tree().paused = _paused
    _overlay.visible = _paused
    if _paused:
        _set_text("")
