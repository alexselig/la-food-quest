extends Node2D
## Placeholder neighborhood: a code-drawn tile grid with border walls and a few
## blocked "buildings". Real TileMapLayer art comes in Phase 5. Spawns the duo and
## a follow camera. This proves the grid-movement loop end to end.

const TILE := 16
const COLS := 40
const ROWS := 30

var blocked: Dictionary = {}   # Vector2i -> true
var player: GridPlayer

func _ready() -> void:
    _build_world()
    _spawn_player()
    _setup_camera()
    queue_redraw()

func _build_world() -> void:
    # Border walls
    for x in COLS:
        blocked[Vector2i(x, 0)] = true
        blocked[Vector2i(x, ROWS - 1)] = true
    for y in ROWS:
        blocked[Vector2i(0, y)] = true
        blocked[Vector2i(COLS - 1, y)] = true
    # Placeholder buildings (blocked footprints)
    _block_rect(5, 5, 4, 3)
    _block_rect(20, 7, 5, 4)
    _block_rect(30, 16, 5, 4)
    _block_rect(11, 20, 4, 3)

func _block_rect(x: int, y: int, w: int, h: int) -> void:
    for i in range(x, x + w):
        for j in range(y, y + h):
            blocked[Vector2i(i, j)] = true

func _spawn_player() -> void:
    player = (preload("res://scripts/grid_player.gd") as GDScript).new()
    add_child(player)
    player.setup(Vector2i(COLS / 2, ROWS / 2), Callable(self, "is_blocked"))

func is_blocked(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
        return true
    return blocked.has(cell)

func _setup_camera() -> void:
    var cam := Camera2D.new()
    player.add_child(cam)
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = COLS * TILE
    cam.limit_bottom = ROWS * TILE
    cam.make_current()

func _draw() -> void:
    for x in COLS:
        for y in ROWS:
            var c := Color(0.30, 0.55, 0.32)          # grass
            if blocked.has(Vector2i(x, y)):
                c = Color(0.46, 0.41, 0.39)            # wall/building placeholder
            draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), c)
    for x in range(COLS + 1):
        draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, ROWS * TILE), Color(0, 0, 0, 0.08))
    for y in range(ROWS + 1):
        draw_line(Vector2(0, y * TILE), Vector2(COLS * TILE, y * TILE), Color(0, 0, 0, 0.08))
