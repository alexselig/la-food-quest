extends CanvasLayer
## Death cut-scene: illustration of a green bike run over by a red car on the road.
## ENTER returns to the title and resets state.

const VIEW := Vector2(320, 180)

func _ready() -> void:
    layer = 300
    process_mode = Node.PROCESS_MODE_ALWAYS
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.0, 0.0, 1.0)
    bg.position = Vector2.ZERO
    bg.size = VIEW
    add_child(bg)
    var tex := _load_tex("res://assets/ui/gameover.png")
    if tex:
        var tr := TextureRect.new()
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        tr.texture = tex
        tr.position = Vector2(0, 0)
        tr.size = Vector2(320, 124)
        tr.clip_contents = true
        add_child(tr)
    _label("GAME OVER", 126, 16, Color(1, 0.32, 0.32))
    _label("Alp & Xiao got run over on the bike!", 148, 8, Color(1, 0.92, 0.92))
    _label("Press ENTER to start over", 162, 9, Color(0.75, 1.0, 0.75))

func _label(text: String, y: float, size: int, col: Color) -> void:
    var l := Label.new()
    l.text = text
    l.position = Vector2(0, y)
    l.size = Vector2(320, size + 4)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", col)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    l.add_theme_constant_override("outline_size", 3)
    add_child(l)

func _load_tex(path: String) -> Texture2D:
    var img := Image.new()
    if img.load(path) == OK:
        return ImageTexture.create_from_image(img)
    return null

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        get_tree().paused = false
        var gs := get_node_or_null("/root/GameState")
        if gs:
            gs.reset()
        get_tree().change_scene_to_file("res://scenes/world.tscn")
