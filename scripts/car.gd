extends Node2D
## A car that drives along a road lane and wraps around the map. The world checks
## car-vs-player overlap and triggers game over on contact. axis 0 = horizontal, 1 = vertical.
## Car art points up (north); it is rotated to face its travel direction.

var axis := 0
var dir := 1
var speed := 46.0
var lo := 0.0
var hi := 640.0
var _spr: Sprite2D

func setup(tex: Texture2D, a: int, d: int, lane: float, start: float, spd: float, lo_: float, hi_: float) -> void:
    axis = a
    dir = d
    speed = spd
    lo = lo_
    hi = hi_
    z_index = 8
    _spr = Sprite2D.new()
    _spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _spr.scale = Vector2(0.5, 0.5)
    if tex:
        _spr.texture = tex
    else:
        var r := ColorRect.new()
        r.color = Color(0.85, 0.2, 0.2)
        r.size = Vector2(12, 20)
        r.position = Vector2(-6, -10)
        add_child(r)
    add_child(_spr)
    if axis == 0:
        _spr.rotation = deg_to_rad(90.0 if dir > 0 else -90.0)
        position = Vector2(start, lane)
    else:
        _spr.rotation = 0.0 if dir > 0 else deg_to_rad(180.0)
        position = Vector2(lane, start)

func _process(delta: float) -> void:
    if axis == 0:
        position.x += dir * speed * delta
        if dir > 0 and position.x > hi:
            position.x = lo
        elif dir < 0 and position.x < lo:
            position.x = hi
    else:
        position.y += dir * speed * delta
        if dir > 0 and position.y > hi:
            position.y = lo
        elif dir < 0 and position.y < lo:
            position.y = hi
