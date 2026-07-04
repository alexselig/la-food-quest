extends Control
## Title screen using the illustrated title art (assets/ui/title.png).
## ENTER starts a new run (-> intro), L loads a save.

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.02, 0.04)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var tex := _load_tex("res://assets/ui/title.png")
    if tex:
        var tr := TextureRect.new()
        tr.texture = tex
        tr.set_anchors_preset(Control.PRESET_FULL_RECT)
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(tr)
    else:
        var l := Label.new()
        l.text = "LA FOOD QUEST\n\nPress ENTER to start"
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        add_child(l)

func _load_tex(path: String) -> Texture2D:
    var img := Image.new()
    if img.load(path) == OK:
        return ImageTexture.create_from_image(img)
    return null

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
    get_tree().change_scene_to_file("res://scenes/intro.tscn")
