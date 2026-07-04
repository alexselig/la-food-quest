extends Node2D
class_name GridPlayer
## Grid/tile-locked movement for the Alp + Xiao duo (one combined unit).
## Placeholder art (two rects) until the AI sprite is swapped in (Phase 5).

const TILE := 16
const MOVE_TIME := 0.14

var cell: Vector2i = Vector2i.ZERO
var moving := false
var facing := Vector2i.DOWN
var is_blocked: Callable   # set by world: func(cell: Vector2i) -> bool
var on_interact: Callable  # set by world: func(cell: Vector2i) -> void

var _sprite: Sprite2D
var _tex_down: Texture2D
var _tex_up: Texture2D
var _tex_side: Texture2D

func setup(start_cell: Vector2i, blocked_check: Callable) -> void:
    cell = start_cell
    is_blocked = blocked_check
    position = _cell_to_pos(cell)
    z_index = 10
    _init_sprite()
    queue_redraw()

func _process(_delta: float) -> void:
    if moving:
        return
    if on_interact.is_valid() and Input.is_action_just_pressed("ui_accept"):
        on_interact.call(facing_cell())
        return
    var dir := Vector2i.ZERO
    if Input.is_action_pressed("ui_up"):
        dir = Vector2i.UP
    elif Input.is_action_pressed("ui_down"):
        dir = Vector2i.DOWN
    elif Input.is_action_pressed("ui_left"):
        dir = Vector2i.LEFT
    elif Input.is_action_pressed("ui_right"):
        dir = Vector2i.RIGHT
    if dir != Vector2i.ZERO:
        facing = dir
        _update_sprite()
        _try_move(dir)

func _try_move(dir: Vector2i) -> void:
    var target := cell + dir
    if is_blocked.is_valid() and is_blocked.call(target):
        return
    cell = target
    moving = true
    var t := create_tween()
    t.tween_property(self, "position", _cell_to_pos(cell), MOVE_TIME).set_trans(Tween.TRANS_SINE)
    t.finished.connect(func() -> void: moving = false)

func facing_cell() -> Vector2i:
    return cell + facing

func _cell_to_pos(c: Vector2i) -> Vector2:
    return Vector2(c.x * TILE + TILE / 2, c.y * TILE + TILE / 2)

func _init_sprite() -> void:
    _tex_down = _load_tex("res://assets/characters/duo_down.png")
    _tex_up = _load_tex("res://assets/characters/duo_up.png")
    _tex_side = _load_tex("res://assets/characters/duo_side.png")
    if _tex_down == null and _tex_up == null and _tex_side == null:
        return
    _sprite = Sprite2D.new()
    _sprite.centered = true
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.scale = Vector2(0.25, 0.25)
    _sprite.position = Vector2(0, -5)
    add_child(_sprite)
    _update_sprite()

func _load_tex(path: String) -> Texture2D:
    var img := Image.new()
    if img.load(path) == OK:
        return ImageTexture.create_from_image(img)
    return null

func _update_sprite() -> void:
    if _sprite == null:
        return
    if facing == Vector2i.UP and _tex_up:
        _sprite.texture = _tex_up
        _sprite.flip_h = false
    elif facing == Vector2i.LEFT and _tex_side:
        _sprite.texture = _tex_side
        _sprite.flip_h = true
    elif facing == Vector2i.RIGHT and _tex_side:
        _sprite.texture = _tex_side
        _sprite.flip_h = false
    elif _tex_down:
        _sprite.texture = _tex_down
        _sprite.flip_h = false

func _draw() -> void:
    if _sprite != null:
        return
    # Placeholder duo: tall Alp (blue) + short Xiao (red), centered on the tile.
    # Alp
    draw_rect(Rect2(-7, -14, 5, 12), Color(0.20, 0.36, 0.68))   # jacket
    draw_rect(Rect2(-7, -18, 5, 4), Color(0.80, 0.66, 0.52))    # head
    draw_rect(Rect2(-6, -20, 3, 2), Color(0.12, 0.10, 0.12))    # spike
    # Xiao
    draw_rect(Rect2(1, -10, 5, 8), Color(0.78, 0.20, 0.20))     # hoodie
    draw_rect(Rect2(1, -13, 5, 3), Color(0.95, 0.84, 0.70))     # head
    draw_rect(Rect2(2, -15, 3, 2), Color(0.10, 0.09, 0.11))     # spike
