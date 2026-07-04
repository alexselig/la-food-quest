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

func setup(start_cell: Vector2i, blocked_check: Callable) -> void:
    cell = start_cell
    is_blocked = blocked_check
    position = _cell_to_pos(cell)
    z_index = 10
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

func _draw() -> void:
    # Placeholder duo: tall Alp (blue) + short Xiao (red), centered on the tile.
    # Alp
    draw_rect(Rect2(-7, -14, 5, 12), Color(0.20, 0.36, 0.68))   # jacket
    draw_rect(Rect2(-7, -18, 5, 4), Color(0.80, 0.66, 0.52))    # head
    draw_rect(Rect2(-6, -20, 3, 2), Color(0.12, 0.10, 0.12))    # spike
    # Xiao
    draw_rect(Rect2(1, -10, 5, 8), Color(0.78, 0.20, 0.20))     # hoodie
    draw_rect(Rect2(1, -13, 5, 3), Color(0.95, 0.84, 0.70))     # head
    draw_rect(Rect2(2, -15, 3, 2), Color(0.10, 0.09, 0.11))     # spike
