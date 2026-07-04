extends Node2D
## Dense city: pavement sidewalks + asphalt roads (no grass). Blocks are packed with
## flat 8-bit buildings that block movement; restaurants/parks/home/legendary/NPC sit on
## block edges facing the sidewalks. Cars drive the roads. Spawns duo, camera, HUD, FX.

const TILE := 16
const COLS := 40
const ROWS := 30
const SPAWN := Vector2i(18, 18)

const GridPlayerScript := preload("res://scripts/grid_player.gd")
const HudScript := preload("res://scripts/hud.gd")
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
const CarScript := preload("res://scripts/car.gd")
const GameOverScript := preload("res://scripts/game_over.gd")

const H_ROADS: Array[int] = [8, 19]
const V_ROADS: Array[int] = [13, 26]
const FILLERS: Array[String] = ["fill_apartment_a", "fill_apartment_b", "fill_office", "fill_shop_a", "fill_shop_b", "fill_house"]

var blocked: Dictionary = {}
var roads: Dictionary = {}
var sidewalk: Dictionary = {}
var objects: Array = []
var objects_by_cell: Dictionary = {}
var player: Node2D
var hud: CanvasLayer
var gs: Node
var cars: Array = []
var _over := false

var _pavement: Texture2D
var _asphalt: Texture2D
var _wall: Texture2D
var _star: Texture2D
var _sprites: Dictionary = {}

func _ready() -> void:
    gs = get_node_or_null("/root/GameState")
    _load_textures()
    _build_world()
    _spawn_player()
    _spawn_cars()
    _setup_camera()
    _setup_hud()
    if gs and gs.quest_state == 0:
        gs.set_quest_state(1)
    if gs:
        gs.bike_changed.connect(_on_bike_changed)
    queue_redraw()

func _load_textures() -> void:
    _pavement = _tex("res://assets/tiles/pavement.png")
    _asphalt = _tex("res://assets/tiles/asphalt.png")
    _wall = _tex("res://assets/tiles/wall.png")
    _star = _tex("res://assets/fx/star.png")
    var ids := ["taco", "boba", "ramen", "diner", "dumpling", "golden_ladle", "home"] + FILLERS
    for id in ids:
        _sprites[id] = _tex("res://assets/buildings/%s.png" % id)
    _sprites["park"] = _tex("res://assets/buildings/park.png")
    _sprites["npc"] = _tex("res://assets/props/npc.png")
    _sprites["bench"] = _tex("res://assets/props/bench.png")
    _sprites["car"] = _tex("res://assets/props/car.png")
    _sprites["bike"] = _tex("res://assets/props/bike.png")

func _tex(path: String) -> Texture2D:
    var img := Image.new()
    if img.load(path) == OK:
        return ImageTexture.create_from_image(img)
    return null

func _build_world() -> void:
    for x in COLS:
        blocked[Vector2i(x, 0)] = true
        blocked[Vector2i(x, ROWS - 1)] = true
    for y in ROWS:
        blocked[Vector2i(0, y)] = true
        blocked[Vector2i(COLS - 1, y)] = true
    for r in H_ROADS:
        for x in range(1, COLS - 1):
            roads[Vector2i(x, r)] = true
            roads[Vector2i(x, r + 1)] = true
    for cc in V_ROADS:
        for y in range(1, ROWS - 1):
            roads[Vector2i(cc, y)] = true
            roads[Vector2i(cc + 1, y)] = true
    for cell in roads.keys():
        for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var n: Vector2i = cell + d
            if n.x > 0 and n.y > 0 and n.x < COLS - 1 and n.y < ROWS - 1 and not roads.has(n):
                sidewalk[n] = true
    _place_objects()
    _fill_buildings()

func _place_objects() -> void:
    _place(2, 5, 3, 2, {"type": "restaurant", "id": "taco", "name": "Taco Truck", "power": 20, "fullness": 35.0})
    _place(6, 5, 2, 2, {"type": "restaurant", "id": "boba", "name": "Boba Shop", "power": 20, "fullness": 30.0})
    _place(9, 5, 2, 2, {"type": "restaurant", "id": "ramen", "name": "Ramen Bar", "power": 25, "fullness": 40.0})
    _place(16, 5, 2, 2, {"type": "restaurant", "id": "dumpling", "name": "Dumpling House", "power": 20, "fullness": 40.0})
    _place(20, 5, 3, 2, {"type": "restaurant", "id": "diner", "name": "Burger Diner", "power": 25, "fullness": 45.0})
    _place(30, 5, 2, 2, {"type": "rest_home", "id": "home", "name": "Home"})
    _place(2, 11, 4, 3, {"type": "exercise", "id": "park", "name": "Echo Park", "fullness": 35.0, "energy": 20.0, "mins": 60})
    _place(16, 11, 4, 3, {"type": "exercise", "id": "park", "name": "Sunset Park", "fullness": 45.0, "energy": 30.0, "mins": 60})
    _place(5, 17, 1, 1, {"type": "rest_bench", "id": "bench", "name": "Bus Bench", "energy": 25.0, "mins": 90})
    _place(18, 17, 1, 1, {"type": "npc", "id": "critic", "name": "Remy the Critic"})
    _place(29, 22, 3, 3, {"type": "legendary", "id": "golden_ladle", "name": "The Golden Ladle"})
    _place(16, 18, 1, 1, {"type": "bike", "id": "bike", "name": "Green Bike"})
    _place(12, 10, 1, 1, {"type": "bike", "id": "bike", "name": "Green Bike"})
    _place(28, 21, 1, 1, {"type": "bike", "id": "bike", "name": "Green Bike"})

func _place(x: int, y: int, w: int, h: int, o: Dictionary) -> void:
    o["rect"] = Rect2i(x, y, w, h)
    objects.append(o)
    for i in range(x, x + w):
        for j in range(y, y + h):
            var c := Vector2i(i, j)
            objects_by_cell[c] = o
            blocked[c] = true

func _fill_buildings() -> void:
    var idx := 0
    for ay in range(1, ROWS - 2, 2):
        for ax in range(1, COLS - 2, 2):
            var ok := true
            for i in range(2):
                for j in range(2):
                    if not _buildable(Vector2i(ax + i, ay + j)):
                        ok = false
            if not ok:
                continue
            var o := {"type": "filler", "id": FILLERS[idx % FILLERS.size()], "rect": Rect2i(ax, ay, 2, 2)}
            idx += 1
            objects.append(o)
            for i in range(2):
                for j in range(2):
                    var c := Vector2i(ax + i, ay + j)
                    objects_by_cell[c] = o
                    blocked[c] = true

func _buildable(cell: Vector2i) -> bool:
    if cell.x < 1 or cell.y < 1 or cell.x >= COLS - 1 or cell.y >= ROWS - 1:
        return false
    if roads.has(cell) or sidewalk.has(cell) or blocked.has(cell) or objects_by_cell.has(cell):
        return false
    if cell == SPAWN:
        return false
    return true

func _spawn_player() -> void:
    player = GridPlayerScript.new()
    add_child(player)
    player.setup(SPAWN, Callable(self, "is_blocked"))
    player.on_interact = Callable(self, "_on_interact")

func is_blocked(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
        return true
    return blocked.has(cell)

func _on_interact(cell: Vector2i) -> void:
    var msg := interact_at(cell)
    if msg == "" and gs != null and gs.on_bike and not objects_by_cell.has(cell):
        _dismount_bike()
        return
    if msg != "" and hud:
        hud.toast(msg)

func _mount_bike(o: Dictionary) -> void:
    gs.set_bike(true)
    _remove_object(o)

func _dismount_bike() -> void:
    if gs == null or not gs.on_bike:
        return
    gs.set_bike(false)
    if player != null:
        for c in [player.cell - player.facing, player.cell + player.facing]:
            if not is_blocked(c):
                _add_bike_at(c)
                break
    if hud:
        hud.toast("Hopped off the bike. The streets are calm again.")

func _remove_object(o: Dictionary) -> void:
    var rect: Rect2i = o["rect"]
    for i in range(rect.position.x, rect.position.x + rect.size.x):
        for j in range(rect.position.y, rect.position.y + rect.size.y):
            var c := Vector2i(i, j)
            objects_by_cell.erase(c)
            blocked.erase(c)
    objects.erase(o)
    queue_redraw()

func _add_bike_at(cell: Vector2i) -> void:
    var o := {"type": "bike", "id": "bike", "name": "Green Bike", "rect": Rect2i(cell.x, cell.y, 1, 1)}
    objects.append(o)
    objects_by_cell[cell] = o
    blocked[cell] = true
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_D:
        if gs != null and gs.on_bike:
            _dismount_bike()

func interact_at(cell: Vector2i) -> String:
    if not objects_by_cell.has(cell) or gs == null:
        return ""
    var o = objects_by_cell[cell]
    match o["type"]:
        "restaurant":
            var was_new: bool = not gs.discovered.has(o["id"])
            if gs.eat(o["power"], o["fullness"], o["id"]):
                _celebrate(("NEW! +%d PWR" % o["power"]) if was_new else ("+%d PWR" % o["power"]))
                if was_new:
                    return "Discovered %s!  +%d PWR" % [o["name"], o["power"]]
                return "Ate at %s.  +%d PWR" % [o["name"], o["power"]]
            return "Too full to eat! Work out at a park first."
        "exercise":
            gs.exercise(o["fullness"], o["energy"], o["mins"])
            return "Jogged around %s. Fullness down, energy spent." % o["name"]
        "rest_home":
            gs.rest_full()
            return "Slept at Home. Energy full - a new day begins."
        "rest_bench":
            gs.rest(o["energy"], o["mins"])
            return "Rested at the %s. +%d energy." % [o["name"], int(o["energy"])]
        "npc":
            if gs.quest_state >= 2:
                return "%s: The Golden Ladle is open to you now - go feast!" % o["name"]
            return "%s: Reach 100 PWR by eating, then find The Golden Ladle!" % o["name"]
        "legendary":
            if gs.quest_state >= 2:
                gs.set_quest_state(3)
                _celebrate("YOU WIN!")
                return "You found THE GOLDEN LADLE! Alp & Xiao feast like kings. YOU WIN!"
            return "The Golden Ladle stays hidden... reach 100 PWR first to prove yourselves."
        "bike":
            _mount_bike(o)
            return "Hopped on the tandem bike! Move 2 tiles per step. Press D to hop off. Cars are out now - dodge them!"
    return ""

func _celebrate(text: String) -> void:
    if player == null:
        return
    var root := Node2D.new()
    root.position = player.position + Vector2(0, -14)
    root.z_index = 50
    add_child(root)
    if _star:
        var s := Sprite2D.new()
        s.texture = _star
        s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        s.scale = Vector2(0.12, 0.12)
        root.add_child(s)
        var ts := create_tween()
        ts.set_parallel(true)
        ts.tween_property(s, "scale", Vector2(0.5, 0.5), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        ts.tween_property(s, "modulate:a", 0.0, 0.65)
    var lbl := Label.new()
    lbl.text = text
    lbl.add_theme_font_size_override("font_size", 8)
    lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.4))
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.position = Vector2(-16, -6)
    root.add_child(lbl)
    var tl := create_tween()
    tl.set_parallel(true)
    tl.tween_property(root, "position", root.position + Vector2(0, -16), 0.75)
    tl.tween_property(lbl, "modulate:a", 0.0, 0.75)
    tl.chain().tween_callback(root.queue_free)

func _spawn_cars() -> void:
    var tex: Texture2D = _sprites.get("car", null)
    var lo := float(TILE)
    var hix := float((COLS - 1) * TILE)
    var hiy := float((ROWS - 1) * TILE)
    for r in H_ROADS:
        _add_car(tex, 0, 1, r * TILE + TILE / 2.0, lo + 40.0, 44.0, lo, hix)
        _add_car(tex, 0, -1, (r + 1) * TILE + TILE / 2.0, hix - 90.0, 52.0, lo, hix)
    for cc in V_ROADS:
        _add_car(tex, 1, 1, cc * TILE + TILE / 2.0, lo + 60.0, 40.0, lo, hiy)
        _add_car(tex, 1, -1, (cc + 1) * TILE + TILE / 2.0, hiy - 60.0, 48.0, lo, hiy)

func _add_car(tex: Texture2D, a: int, d: int, lane: float, start: float, spd: float, car_lo: float, car_hi: float) -> void:
    var car = CarScript.new()
    add_child(car)
    car.setup(tex, a, d, lane, start, spd, car_lo, car_hi)
    car.set_active(false)
    cars.append(car)

func _on_bike_changed(on: bool) -> void:
    for car in cars:
        car.set_active(on)

func _process(_delta: float) -> void:
    if _over or player == null or gs == null or not gs.on_bike:
        return
    var pp: Vector2 = player.position
    for car in cars:
        if absf(car.position.x - pp.x) < 10.0 and absf(car.position.y - pp.y) < 10.0:
            _trigger_game_over()
            return

func _trigger_game_over() -> void:
    _over = true
    add_child(GameOverScript.new())
    get_tree().paused = true

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
    add_child(PauseMenuScript.new())

func _draw() -> void:
    for x in COLS:
        for y in ROWS:
            var cell := Vector2i(x, y)
            var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
            if x == 0 or y == 0 or x == COLS - 1 or y == ROWS - 1:
                _blit(_wall, rect, Color(0.33, 0.32, 0.36))
            elif roads.has(cell):
                _blit(_asphalt, rect, Color(0.27, 0.28, 0.30))
            else:
                _blit(_pavement, rect, Color(0.69, 0.68, 0.66))
    _draw_road_lines()
    for o in objects:
        if not (o["type"] in ["npc", "rest_bench", "bike"]):
            _draw_object(o)
    # props (NPC, bench, bike) drawn last so they sit ON TOP of nearby buildings
    for o in objects:
        if o["type"] in ["npc", "rest_bench", "bike"]:
            _draw_object(o)

func _blit(tex: Texture2D, rect: Rect2, fallback: Color) -> void:
    if tex:
        draw_texture_rect(tex, rect, false)
    else:
        draw_rect(rect, fallback)

func _draw_road_lines() -> void:
    var yellow := Color(0.9, 0.8, 0.25, 0.9)
    for r in H_ROADS:
        var cy: int = (r + 1) * TILE
        var x := TILE
        while x < (COLS - 1) * TILE:
            draw_rect(Rect2(x, cy - 1, 6, 2), yellow)
            x += 12
    for cc in V_ROADS:
        var cx: int = (cc + 1) * TILE
        var y := TILE
        while y < (ROWS - 1) * TILE:
            draw_rect(Rect2(cx - 1, y, 2, 6), yellow)
            y += 12

func _draw_object(o: Dictionary) -> void:
    var rect: Rect2i = o["rect"]
    var t: String = o["type"]
    var px := rect.position.x * TILE
    var py := rect.position.y * TILE
    var pw := rect.size.x * TILE
    var ph := rect.size.y * TILE
    var tex: Texture2D = _sprite_for(o)
    if tex == null:
        draw_rect(Rect2(px, py, pw, ph), Color(0.5, 0.5, 0.55))
        return
    if t == "npc" or t == "rest_bench" or t == "bike":
        var sc := float(pw) / float(tex.get_width())
        var th := tex.get_height() * sc
        draw_texture_rect(tex, Rect2(px, (py + ph) - th, pw, th), false)
    else:
        draw_texture_rect(tex, Rect2(px, py, pw, ph), false)

func _sprite_for(o: Dictionary) -> Texture2D:
    var t: String = o["type"]
    if t == "restaurant" or t == "rest_home" or t == "legendary" or t == "filler":
        return _sprites.get(o["id"], null)
    if t == "exercise":
        return _sprites.get("park", null)
    if t == "npc":
        return _sprites.get("npc", null)
    if t == "rest_bench":
        return _sprites.get("bench", null)
    if t == "bike":
        return _sprites.get("bike", null)
    return null
