extends Control
## Illustrated "how to play" screen shown before a new run. ENTER begins the game.

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.08, 0.09, 0.14)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var tex := _load_tex("res://assets/ui/intro.png")
    if tex:
        var tr := TextureRect.new()
        tr.texture = tex
        tr.position = Vector2(0, 0)
        tr.size = Vector2(320, 104)
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        tr.clip_contents = true
        add_child(tr)

    var panel := ColorRect.new()
    panel.color = Color(0, 0, 0, 0.82)
    panel.position = Vector2(0, 104)
    panel.size = Vector2(320, 76)
    add_child(panel)

    _line("HOW TO PLAY", 106, 11, Color(1, 0.9, 0.4))
    _line("Arrows: move     Space/Enter: talk & eat     Esc: pause", 122, 8, Color(1, 1, 1))
    _line("Eat at restaurants to reach 100 PWR, then find The Golden Ladle!", 133, 8, Color(1, 1, 1))
    _line("Too full? Jog at a park. Low energy? Rest - or you lose a day.", 144, 8, Color(1, 1, 1))
    _line("WATCH OUT: cars on the road will run you over!", 155, 8, Color(1, 0.7, 0.55))
    _line("Press ENTER to begin", 167, 9, Color(0.7, 1, 0.7))

func _line(text: String, y: float, size: int, col: Color) -> void:
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
        get_tree().change_scene_to_file("res://scenes/world.tscn")
