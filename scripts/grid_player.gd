extends Node2D
class_name GridPlayer
## Grid movement for Alp+Xiao. On foot: walking duo sprite, 1 tile/step. On the tandem bike:
## a tandem sprite (both riding it), 2 tiles/step. Reads GameState.on_bike.

const TILE := 16
const MOVE_TIME := 0.14

var cell: Vector2i = Vector2i.ZERO
var moving := false
var facing := Vector2i.DOWN
var is_blocked: Callable
var on_interact: Callable

var _sprite: Sprite2D
var _walk := {}
var _bike := {}
var _was_bike := false
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
    if _on_bike() != _was_bike:
        _was_bike = _on_bike()
        _update_sprite()
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
    _walk[Vector2i.DOWN] = _load_tex("res://assets/characters/duo_down.png")
    _walk[Vector2i.UP] = _load_tex("res://assets/characters/duo_up.png")
    _walk["side"] = _load_tex("res://assets/characters/duo_side.png")
    _bike[Vector2i.DOWN] = _load_tex("res://assets/characters/tandem_down.png")
    _bike[Vector2i.UP] = _load_tex("res://assets/characters/tandem_up.png")
    _bike["side"] = _load_tex("res://assets/characters/tandem_side.png")
    _sprite = Sprite2D.new()
    _sprite.centered = true
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
    var set_: Dictionary = _bike if _on_bike() else _walk
    var flip := false
    var tex: Texture2D = null
    if facing == Vector2i.UP:
        tex = set_.get(Vector2i.UP)
    elif facing == Vector2i.LEFT:
        tex = set_.get("side")
        flip = true
    elif facing == Vector2i.RIGHT:
        tex = set_.get("side")
    else:
        tex = set_.get(Vector2i.DOWN)
    if tex == null:
        tex = set_.get(Vector2i.DOWN)
    if tex == null:
        return
    _sprite.texture = tex
    _sprite.flip_h = flip
    var target_h: float = 34.0 if _on_bike() else 26.0
    _sprite.scale = Vector2.ONE * (target_h / float(tex.get_height()))
    _sprite.position = Vector2(0, -6.0 if _on_bike() else -5.0)

func _draw() -> void:
    if _sprite != null:
        return
