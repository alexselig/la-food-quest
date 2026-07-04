extends Node2D
class_name GridPlayer
## Grid movement for the Alp+Xiao duo. 1 tile/step on foot; on the green bike, 2 tiles/step
## (faster). Reads GameState.on_bike. Shows a green bike under the duo while riding.

const TILE := 16
const MOVE_TIME := 0.14

var cell: Vector2i = Vector2i.ZERO
var moving := false
var facing := Vector2i.DOWN
var is_blocked: Callable
var on_interact: Callable

var _sprite: Sprite2D
var _bike: Sprite2D
var _tex_down: Texture2D
var _tex_up: Texture2D
var _tex_side: Texture2D
var _gs: Node

func setup(start_cell: Vector2i, blocked_check: Callable) -> void:
    cell = start_cell
    is_blocked = blocked_check
    _gs = get_node_or_null("/root/GameState")
    position = _cell_to_pos(cell)
    z_index = 10
    _init_sprite()
    queue_redraw()

func _on_bike() -> bool:
    return _gs != null and _gs.on_bike

func _blk(c: Vector2i) -> bool:
    return is_blocked.is_valid() and is_blocked.call(c)

func _process(_delta: float) -> void:
    if _bike:
        _bike.visible = _on_bike()
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
    var one := cell + dir
    if _blk(one):
        return
    var dest := one
    var moved2 := false
    if _on_bike():
        var two := cell + dir * 2
        if not _blk(two):
            dest = two
            moved2 = true
    cell = dest
    moving = true
    var dur: float = (MOVE_TIME * 1.15) if moved2 else MOVE_TIME
    var t := create_tween()
    t.tween_property(self, "position", _cell_to_pos(cell), dur).set_trans(Tween.TRANS_SINE)
    t.finished.connect(func() -> void: moving = false)

func facing_cell() -> Vector2i:
    return cell + facing

func _cell_to_pos(c: Vector2i) -> Vector2:
    return Vector2(c.x * TILE + TILE / 2, c.y * TILE + TILE / 2)

func _init_sprite() -> void:
    _tex_down = _load_tex("res://assets/characters/duo_down.png")
    _tex_up = _load_tex("res://assets/characters/duo_up.png")
    _tex_side = _load_tex("res://assets/characters/duo_side.png")
    var bike_tex := _load_tex("res://assets/props/bike.png")
    if bike_tex:
        _bike = Sprite2D.new()
        _bike.texture = bike_tex
        _bike.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        _bike.scale = Vector2(0.4, 0.4)
        _bike.position = Vector2(0, 1)
        _bike.z_index = -1
        _bike.visible = false
        add_child(_bike)
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
    draw_rect(Rect2(-7, -14, 5, 12), Color(0.20, 0.36, 0.68))
    draw_rect(Rect2(-7, -18, 5, 4), Color(0.80, 0.66, 0.52))
    draw_rect(Rect2(1, -10, 5, 8), Color(0.78, 0.20, 0.20))
    draw_rect(Rect2(1, -13, 5, 3), Color(0.95, 0.84, 0.70))
