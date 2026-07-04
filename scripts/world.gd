extends Node2D
## Placeholder neighborhood for the vertical slice: a code-drawn tile grid, border
## walls, and data-driven interactable objects (restaurants / exercise / rest / NPC /
## legendary). Real TileMapLayer art is swapped in during Phase 5. Spawns the duo, a
## follow camera, and the HUD, and dispatches interactions to GameState.

const TILE := 16
const COLS := 40
const ROWS := 30

const GridPlayerScript := preload("res://scripts/grid_player.gd")
const HudScript := preload("res://scripts/hud.gd")

var blocked: Dictionary = {}          # Vector2i -> true
var objects_by_cell: Dictionary = {}  # Vector2i -> object dict
var player: Node2D
var hud: CanvasLayer
var gs: Node                          # GameState autoload (injected in tests)

func _ready() -> void:
    gs = get_node_or_null("/root/GameState")
    _build_world()
    _spawn_player()
    _setup_camera()
    _setup_hud()
    if gs and gs.quest_state == 0:
        gs.set_quest_state(1)  # Quest.ACTIVE — give the goal immediately
    queue_redraw()

func _build_world() -> void:
    for x in COLS:
        blocked[Vector2i(x, 0)] = true
        blocked[Vector2i(x, ROWS - 1)] = true
    for y in ROWS:
        blocked[Vector2i(0, y)] = true
        blocked[Vector2i(COLS - 1, y)] = true
    _add_objects()

func _add_objects() -> void:
    var defs := [
        {"cell": Vector2i(6, 8),   "type": "restaurant", "id": "taco",     "name": "Taco Truck",     "power": 20, "fullness": 35.0, "color": Color(0.95, 0.80, 0.25)},
        {"cell": Vector2i(14, 7),  "type": "restaurant", "id": "boba",     "name": "Boba Shop",      "power": 20, "fullness": 30.0, "color": Color(0.93, 0.55, 0.75)},
        {"cell": Vector2i(28, 8),  "type": "restaurant", "id": "ramen",    "name": "Ramen Bar",      "power": 25, "fullness": 40.0, "color": Color(0.95, 0.55, 0.25)},
        {"cell": Vector2i(32, 20), "type": "restaurant", "id": "diner",    "name": "Burger Diner",   "power": 25, "fullness": 45.0, "color": Color(0.85, 0.30, 0.25)},
        {"cell": Vector2i(10, 22), "type": "restaurant", "id": "dumpling", "name": "Dumpling House", "power": 20, "fullness": 40.0, "color": Color(0.85, 0.75, 0.55)},
        {"cell": Vector2i(8, 16),  "type": "exercise", "name": "Park Loop",   "fullness": 35.0, "energy": 20.0, "mins": 60, "color": Color(0.30, 0.70, 0.35)},
        {"cell": Vector2i(24, 22), "type": "exercise", "name": "Stair Climb", "fullness": 45.0, "energy": 30.0, "mins": 60, "color": Color(0.20, 0.55, 0.30)},
        {"cell": Vector2i(18, 10), "type": "rest_home",  "name": "Home",       "color": Color(0.35, 0.45, 0.85)},
        {"cell": Vector2i(26, 6),  "type": "rest_bench", "name": "Park Bench", "energy": 25.0, "mins": 90, "color": Color(0.55, 0.70, 0.95)},
        {"cell": Vector2i(20, 12), "type": "npc", "id": "critic", "name": "Remy the Critic", "color": Color(0.65, 0.45, 0.85)},
        {"cell": Vector2i(34, 25), "type": "legendary", "id": "golden_ladle", "name": "The Golden Ladle", "color": Color(0.95, 0.82, 0.30)},
    ]
    for o in defs:
        objects_by_cell[o["cell"]] = o
        blocked[o["cell"]] = true

func _spawn_player() -> void:
    player = GridPlayerScript.new()
    add_child(player)
    player.setup(Vector2i(COLS / 2, ROWS / 2), Callable(self, "is_blocked"))
    player.on_interact = Callable(self, "_on_interact")

func is_blocked(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
        return true
    return blocked.has(cell)

func _on_interact(cell: Vector2i) -> void:
    var msg := interact_at(cell)
    if msg != "" and hud:
        hud.toast(msg)

## Resolve an interaction and apply its effect to GameState. Returns a toast string.
func interact_at(cell: Vector2i) -> String:
    if not objects_by_cell.has(cell) or gs == null:
        return ""
    var o = objects_by_cell[cell]
    match o["type"]:
        "restaurant":
            var was_new: bool = not gs.discovered.has(o["id"])
            if gs.eat(o["power"], o["fullness"], o["id"]):
                if was_new:
                    return "Discovered %s!  +%d PWR" % [o["name"], o["power"]]
                return "Ate at %s  +%d PWR" % [o["name"], o["power"]]
            return "Too full to eat! Go exercise."
        "exercise":
            gs.exercise(o["fullness"], o["energy"], o["mins"])
            return "Worked out at %s. Fullness down, energy spent." % o["name"]
        "rest_home":
            gs.rest_full()
            return "Slept at Home. Energy full — new day."
        "rest_bench":
            gs.rest(o["energy"], o["mins"])
            return "Rested at %s. +%d energy." % [o["name"], int(o["energy"])]
        "npc":
            if gs.quest_state >= 2:
                return "%s: The Golden Ladle awaits — go taste greatness!" % o["name"]
            return "%s: Find The Golden Ladle! Eat around town to prove yourselves (reach 100 PWR)." % o["name"]
        "legendary":
            if gs.quest_state >= 2:
                gs.set_quest_state(3)  # COMPLETE
                return "You found THE GOLDEN LADLE! Alp & Xiao feast like kings. YOU WIN!"
            return "The Golden Ladle stays hidden... become stronger eaters first (100 PWR)."
    return ""

func _setup_camera() -> void:
    var cam := Camera2D.new()
    player.add_child(cam)
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = COLS * TILE
    cam.limit_bottom = ROWS * TILE
    cam.make_current()

func _setup_hud() -> void:
    hud = HudScript.new()
    add_child(hud)

func _draw() -> void:
    for x in COLS:
        for y in ROWS:
            var cell := Vector2i(x, y)
            var c := Color(0.30, 0.55, 0.32)
            if blocked.has(cell) and not objects_by_cell.has(cell):
                c = Color(0.46, 0.41, 0.39)
            draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), c)
    for cell in objects_by_cell:
        var o = objects_by_cell[cell]
        var r := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
        draw_rect(r, o["color"])
        draw_rect(r, Color(0, 0, 0, 0.6), false, 1.0)
    for x in range(COLS + 1):
        draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, ROWS * TILE), Color(0, 0, 0, 0.08))
    for y in range(ROWS + 1):
        draw_line(Vector2(0, y * TILE), Vector2(COLS * TILE, y * TILE), Color(0, 0, 0, 0.08))
