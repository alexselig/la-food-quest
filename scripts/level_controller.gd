extends Node2D
## LevelController: builds a level from GameData.LEVELS[id], routes interactions, and
## handles level completion/transition. Build + interaction logic is tree-independent so
## it can be unit-tested headless (inject gs/data/quests/dlg, call build_from_data /
## interact_at). Visual setup (player, camera, HUD, puzzle UI) only runs in-tree.

const TILE := 16
const CHAR_H := 26.0
const GameStateScript := preload("res://scripts/game_state.gd")
const GridPlayerScript := preload("res://scripts/grid_player.gd")
const HudScript := preload("res://scripts/hud.gd")
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")
const JournalScript := preload("res://scripts/ui/journal.gd")
const LevelCompleteScript := preload("res://scripts/ui/level_complete.gd")
const RotationPuzzleScript := preload("res://scripts/puzzles/rotation_puzzle.gd")
const RhythmPuzzleScript := preload("res://scripts/puzzles/rhythm_puzzle.gd")
const CircuitPuzzleScript := preload("res://scripts/puzzles/circuit_puzzle.gd")

# Injectable dependencies (default to autoloads in-tree)
var gs: Node
var data: Node
var quests: Node
var dlg: Node

var level_id := "echo_park"
var level: Dictionary = {}
var cols := 34
var rows := 22

var blocked: Dictionary = {}
var water: Dictionary = {}
var paths: Dictionary = {}
var objects: Array = []
var objects_by_cell: Dictionary = {}

var player: Node2D
var hud: CanvasLayer
var trail_finder_active := false
var food_sense_active := false
var _completing := false

var _grass: Texture2D
var _wall: Texture2D
var _pavement: Texture2D
var _star: Texture2D
var _sprites: Dictionary = {}

func _ready() -> void:
	_resolve_deps()
	level_id = String(gs.current_level_id) if gs else "echo_park"
	_load_textures()
	build_from_data(level_id)
	_spawn_player()
	_setup_camera()
	_setup_hud()
	if quests:
		quests.quest_updated.connect(func(_q): _refresh_objective())
	_refresh_objective()
	var opening := String(level.get("opening_dialogue", ""))
	if dlg and opening != "" and gs and not gs.dialogue_played(opening):
		dlg.start(opening)
	queue_redraw()

func _resolve_deps() -> void:
	if gs == null: gs = get_node_or_null("/root/GameState")
	if data == null: data = get_node_or_null("/root/GameData")
	if quests == null: quests = get_node_or_null("/root/QuestManager")
	if dlg == null: dlg = get_node_or_null("/root/DialogueManager")

# ---------------------------------------------------------------- build (testable)
func build_from_data(id: String) -> void:
	level_id = id
	level = data.get_level(id) if data else {}
	cols = int(level.get("cols", 34))
	rows = int(level.get("rows", 22))
	blocked.clear()
	water.clear()
	paths.clear()
	objects.clear()
	objects_by_cell.clear()
	for x in cols:
		blocked[Vector2i(x, 0)] = true
		blocked[Vector2i(x, rows - 1)] = true
	for y in rows:
		blocked[Vector2i(0, y)] = true
		blocked[Vector2i(cols - 1, y)] = true
	for w in level.get("water", []):
		var wr := _arr_rect(w)
		for c in _rect_cells(wr):
			water[c] = true
			blocked[c] = true
	for pth in level.get("paths", []):
		for c in _rect_cells(_arr_rect(pth)):
			paths[c] = true
	for ob in level.get("obstacles", []):
		_add_object({"type": "obstacle", "id": ob.get("id", ""), "_rect": _arr_rect(ob["rect"])})
	for od in level.get("objects", []):
		var o: Dictionary = od.duplicate(true)
		o["_rect"] = _obj_rect(o)
		# A mounted tandem rides with the player; don't also place it on the map.
		if String(o.get("type", "")) == "bike_rack" and gs != null and gs.on_bike:
			continue
		_add_object(o)

func _obj_rect(o: Dictionary) -> Rect2i:
	if o.has("rect"):
		return _arr_rect(o["rect"])
	var c: Array = o.get("cell", [0, 0])
	return Rect2i(int(c[0]), int(c[1]), 1, 1)

func _arr_rect(a: Array) -> Rect2i:
	return Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))

func _rect_cells(r: Rect2i) -> Array:
	var out: Array = []
	for i in range(r.position.x, r.position.x + r.size.x):
		for j in range(r.position.y, r.position.y + r.size.y):
			out.append(Vector2i(i, j))
	return out

func _add_object(o: Dictionary) -> void:
	objects.append(o)
	for c in _rect_cells(o["_rect"]):
		objects_by_cell[c] = o
		blocked[c] = true

func _remove_object(o: Dictionary) -> void:
	for c in _rect_cells(o["_rect"]):
		objects_by_cell.erase(c)
		blocked.erase(c)
	objects.erase(o)
	queue_redraw()

func is_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
		return true
	return blocked.has(cell)

# ---------------------------------------------------------------- interaction (testable)
func _on_interact(cell: Vector2i) -> void:
	var msg := interact_at(cell)
	if msg == "" and gs != null and gs.on_bike and not objects_by_cell.has(cell):
		_dismount_bike()
		return
	if msg != "" and hud:
		hud.toast(msg)

func interact_at(cell: Vector2i) -> String:
	if not objects_by_cell.has(cell) or gs == null:
		return ""
	var o: Dictionary = objects_by_cell[cell]
	match String(o.get("type", "")):
		"npc":
			if o.has("starts_quest") and quests:
				quests.start_quest(String(o["starts_quest"]))
			_play(String(o.get("dialogue", "")))
			return ""
		"sign":
			_play(String(o.get("dialogue", "")))
			return ""
		"restaurant":
			return _interact_restaurant(o)
		"park_activity":
			return _interact_park(o)
		"item":
			gs.add_item(String(o["id"]))
			_remove_object(o)
			var hint := String(o.get("hint", ""))
			return "Picked up %s%s." % [String(o.get("name", o["id"])), (" " + hint) if hint != "" else ""]
		"mechanic":
			return _interact_mechanic(o)
		"bike_rack":
			return _interact_bike_rack(o)
		"rest_point":
			return _interact_rest(o)
		"puzzle":
			if gs.is_puzzle_solved(String(o["id"])):
				return String(o.get("solved_msg", "That puzzle is already solved."))
			var preq := String(o.get("require_flag", ""))
			if preq != "" and not gs.has_flag(preq):
				return String(o.get("locked_hint", "You can't start this yet."))
			_open_puzzle(o)
			return ""
		"exit":
			return _interact_exit(o)
	return ""

func _interact_restaurant(o: Dictionary) -> String:
	var rid := String(o["id"])
	var rdef: Dictionary = data.get_restaurant(rid) if data else {}
	var req := String(o.get("require_flag", ""))
	if req != "" and not gs.has_flag(req):
		return String(o.get("locked_hint", "This place isn't open to you yet."))
	if gs.food_dex_state(rid) == GameStateScript.Dex.UNKNOWN:
		gs.set_food_dex(rid, GameStateScript.Dex.DISCOVERED)
		if quests:
			quests.note_step(String(o.get("discover_step", "")))
		_play(String(rdef.get("first_visit_dialogue", "")))
		return "Discovered %s!" % String(rdef.get("display_name", o.get("name", rid)))
	if gs.eat(int(rdef.get("power", 0)), float(rdef.get("fullness", 0.0)), rid, float(rdef.get("energy", 0.0))):
		if quests:
			quests.note_step(String(o.get("eat_step", "")))
		_play(String(rdef.get("meal_dialogue", "")))
		return "+%d PWR - %s" % [int(rdef.get("power", 0)), String(rdef.get("signature_dish", ""))]
	_play("GLOBAL_TOO_FULL_01")
	return "Too full to eat! Work off a meal at a park first."

func _interact_park(o: Dictionary) -> String:
	gs.exercise(float(o.get("fullness", 35.0)), float(o.get("energy", 18.0)), int(o.get("mins", 45)))
	if quests:
		quests.note_step(String(o.get("step", "park_loop")))
	var extra := ""
	var rec := String(o.get("recipe", ""))
	if rec != "" and gs.learn_recipe(rec):
		extra = "  Recipe learned: %s!" % (data.recipe_name(rec) if data else rec)
	var ab := String(o.get("grants_ability", ""))
	if ab != "" and gs.unlock_ability(ab):
		_play(String(o.get("unlock_dialogue", "")))
		extra += "  %s unlocked!" % _ability_label(ab)
	return "Lap done at %s. Fullness down, energy spent.%s" % [String(o.get("name", "the park")), extra]

func _interact_mechanic(o: Dictionary) -> String:
	var grants_ab := String(o.get("grants_ability", ""))
	var set_flag := String(o.get("set_flag", ""))
	var already: bool = (grants_ab != "" and gs.has_ability(grants_ab)) or (set_flag != "" and gs.has_flag(set_flag))
	if already:
		return String(o.get("done_msg", "Thanks again!"))
	var needs: Array = o.get("needs", [])
	var have_all := true
	for n in needs:
		if not gs.has_item(String(n)):
			have_all = false
	if not have_all:
		_play(String(o.get("dialogue", "")))
		return String(o.get("need_msg", "You still need to gather everything."))
	for n in needs:
		gs.remove_item(String(n))
	if grants_ab != "":
		gs.unlock_ability(grants_ab)
	if set_flag != "":
		gs.set_flag(set_flag)
	var step := String(o.get("complete_step", ""))
	if step != "" and quests:
		quests.note_step(step)
	_play(String(o.get("unlock_dialogue", "")))
	return String(o.get("done_msg", "Done!"))

func _interact_bike_rack(o: Dictionary) -> String:
	if not gs.has_ability("tandem_bike"):
		return "The tandem bike is still broken. See Nia at the boathouse."
	if gs.on_bike:
		return "You're already riding. Press D to hop off."
	gs.set_bike(true)
	_remove_object(o)  # pick the bike up; it now rides with the duo
	if dlg and not gs.dialogue_played("GLOBAL_FIRST_BIKE_MOUNT"):
		_play("GLOBAL_FIRST_BIKE_MOUNT")
	return "Hopped on the tandem bike! 2 tiles per step. Press D to hop off."

func _interact_rest(o: Dictionary) -> String:
	if String(o.get("mode", "bench")) == "home":
		gs.rest_full()
		return "Slept at the apartment. A new day - energy full."
	gs.rest(float(o.get("energy", 25.0)), int(o.get("mins", 90)))
	return "Rested at the %s. +%d energy." % [String(o.get("name", "bench")), int(o.get("energy", 25.0))]

func _interact_exit(o: Dictionary) -> String:
	var qid := String(level.get("completion_quest_id", ""))
	if quests == null or qid == "":
		return ""
	var next_level := String(o.get("target_level", level.get("next_level_id", "")))
	var next_spawn := String(o.get("target_spawn", "start"))
	var need_ab := String(o.get("require_ability", ""))
	if quests.is_complete(qid):
		_complete_level(next_level, next_spawn)
		return ""
	var others_done := true
	for s in (data.get_quest(qid).get("steps", []) if data else []):
		var sid3 := String(s.get("id", ""))
		if sid3 != "reach_exit" and not quests.is_step_done(qid, sid3):
			others_done = false
	if not others_done:
		return "The gate stays shut. First: %s" % quests.current_objective(qid)
	if need_ab != "" and not gs.has_ability(need_ab):
		return "You need the %s to clear the way here." % _ability_label(need_ab)
	quests.note_step("reach_exit")
	_complete_level(next_level, next_spawn)
	return ""

func _ability_label(id: String) -> String:
	match id:
		"tandem_bike": return "Tandem Bike"
		"bike_bell": return "Bike Bell"
		"cooler_basket": return "Cooler Basket"
		"portable_grill": return "Portable Grill"
	return id.capitalize()

func _complete_level(next_id: String = "", next_spawn: String = "start") -> void:
	if _completing:
		return
	_completing = true
	gs.complete_level(level_id)
	var stamp := String(level.get("stamp", ""))
	if stamp != "":
		gs.add_stamp(stamp)
	if next_id == "":
		next_id = String(level.get("next_level_id", ""))
	if next_id != "":
		gs.unlock_level(next_id)
	var ab := String(level.get("ability_unlock", ""))
	if ab != "":
		gs.unlock_ability(ab)
	var bonus := int(level.get("bonus_power", 0))
	if bonus > 0:
		gs.power += bonus
		gs.meters_changed.emit()
	_show_level_complete(stamp, next_id, next_spawn)

func _play(id: String) -> void:
	if id != "" and dlg:
		dlg.start(id)

# Public hook used by the puzzle-solved signal and tests.
func _on_puzzle_solved(puzzle_id: String) -> void:
	if gs:
		gs.mark_puzzle_solved(puzzle_id)
	var o := _find_object_by_id(puzzle_id)
	if not o.is_empty():
		_play(String(o.get("solved_dialogue", "")))

func _find_object_by_id(id: String) -> Dictionary:
	for o in objects:
		if String(o.get("id", "")) == id:
			return o
	return {}

# ---------------------------------------------------------------- tree-only visuals
func _open_puzzle(o: Dictionary) -> void:
	if not is_inside_tree():
		return
	var kind := String(o.get("kind", "rotation"))
	var pz
	if kind == "rhythm":
		pz = RhythmPuzzleScript.new()
		pz.configure(String(o["id"]), o.get("target", ["low", "low", "high"]), o.get("keys", {}), o.get("symbols", {}), String(o.get("title", "")), String(o.get("prompt", "")))
	elif kind == "circuit":
		pz = CircuitPuzzleScript.new()
		pz.configure(String(o["id"]), int(o.get("count", 5)), o.get("scramble", []), o.get("labels", []), String(o.get("title", "")))
	else:
		pz = RotationPuzzleScript.new()
		pz.configure(String(o["id"]), o.get("target", [1, 2, 0, 3]), o.get("labels", []), String(o.get("title", "")))
	pz.solved.connect(_on_puzzle_solved)
	add_child(pz)

func _spawn_player() -> void:
	var spawn_id := String(gs.current_spawn_id) if gs else "start"
	var spawns: Dictionary = level.get("spawns", {})
	var sc: Array = spawns.get(spawn_id, spawns.get("start", [3, 5]))
	player = GridPlayerScript.new()
	add_child(player)
	player.setup(Vector2i(int(sc[0]), int(sc[1])), Callable(self, "is_blocked"))
	player.on_interact = Callable(self, "_on_interact")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_D and gs != null and gs.on_bike:
		_dismount_bike()
	elif event.keycode == KEY_A and gs != null and gs.has_ability("trail_finder"):
		trail_finder_active = not trail_finder_active
		queue_redraw()
	elif event.keycode == KEY_S and gs != null and gs.has_ability("food_sense"):
		food_sense_active = not food_sense_active
		queue_redraw()

func _dismount_bike() -> void:
	if gs == null or not gs.on_bike:
		return
	gs.set_bike(false)
	if player != null:
		_drop_bike_at(player.cell)
	if hud:
		hud.toast("Parked the tandem bike here.")

# Leave exactly one bike where the duo dismounts (never a duplicate).
func _drop_bike_at(cell: Vector2i) -> void:
	for o in objects:
		if String(o.get("type", "")) == "bike_rack":
			return
	var bike := {
		"type": "bike_rack", "id": "bike", "name": "Tandem Bike",
		"cell": [cell.x, cell.y], "_rect": Rect2i(cell.x, cell.y, 1, 1),
	}
	_add_object(bike)

func _process(_delta: float) -> void:
	if trail_finder_active or food_sense_active:
		queue_redraw()

func _setup_camera() -> void:
	var cam := Camera2D.new()
	player.add_child(cam)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = cols * TILE
	cam.limit_bottom = rows * TILE
	cam.make_current()

func _setup_hud() -> void:
	hud = HudScript.new()
	add_child(hud)
	add_child(DialogueBoxScript.new())
	add_child(JournalScript.new())
	add_child(PauseMenuScript.new())

func _refresh_objective() -> void:
	if hud == null or quests == null:
		return
	var qid := String(level.get("completion_quest_id", ""))
	if qid != "" and quests.is_active(qid):
		hud.set_objective(quests.current_objective(qid))
	elif qid != "" and quests.is_complete(qid):
		hud.set_objective("Ride to the exit!")
	else:
		hud.set_objective("Find Remy near the lake.")

func _show_level_complete(stamp: String, next_id: String, next_spawn: String) -> void:
	if not is_inside_tree():
		return
	var lc = LevelCompleteScript.new()
	lc.configure(level, stamp, gs, data, next_id, next_spawn)
	add_child(lc)

# ---------------------------------------------------------------- drawing
func _load_textures() -> void:
	_grass = _tex("res://assets/tiles/grass.png")
	_wall = _tex("res://assets/tiles/wall.png")
	_pavement = _tex("res://assets/tiles/pavement.png")
	_star = _tex("res://assets/fx/star.png")
	for id in ["ramen", "taco", "boba", "diner", "dumpling", "home", "golden_ladle",
			"fill_apartment_a", "fill_apartment_b", "fill_office", "fill_shop_a", "fill_shop_b", "fill_house"]:
		_sprites[id] = _tex("res://assets/buildings/%s.png" % id)
	_sprites["park"] = _tex("res://assets/buildings/park.png")
	_sprites["npc"] = _tex("res://assets/props/npc.png")
	_sprites["bench"] = _tex("res://assets/props/bench.png")
	_sprites["bike"] = _tex("res://assets/props/bike.png")
	# Optional generated art (used automatically once present).
	for nid in ["remy", "nia", "mara", "sol", "ori", "han", "mina"]:
		var nt := _tex("res://assets/npcs/%s.png" % nid)
		if nt:
			_sprites["npc_" + nid] = nt
	for env in ["water", "path", "sand"]:
		var et := _tex("res://assets/tiles/%s.png" % env)
		if et:
			_sprites[env] = et
	for prop in ["tree", "lotus", "lamp", "sign", "gate", "mapboard"]:
		var pt := _tex("res://assets/props/%s.png" % prop)
		if pt:
			_sprites[prop] = pt

func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			return r
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _draw() -> void:
	for x in cols:
		for y in rows:
			var cell := Vector2i(x, y)
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			if x == 0 or y == 0 or x == cols - 1 or y == rows - 1:
				_blit(_wall, rect, Color(0.30, 0.30, 0.34))
			elif water.has(cell):
				_draw_water_cell(x, y, rect)
			elif paths.has(cell):
				_blit(_sprites.get("path", _pavement), rect, Color(0.62, 0.58, 0.5))
			else:
				_blit(_grass, rect, Color(0.36, 0.55, 0.32))
	# Objects back-to-front by footprint bottom edge so nearer things overlap farther ones.
	var ordered := objects.duplicate()
	ordered.sort_custom(func(a, b): return _bottom(a) < _bottom(b))
	for o in ordered:
		_draw_object(o)
	_draw_ability_overlay()

func _bottom(o: Dictionary) -> int:
	var r: Rect2i = o["_rect"]
	return r.position.y + r.size.y

func _draw_water_cell(x: int, y: int, rect: Rect2) -> void:
	if _sprites.get("water"):
		_blit(_sprites["water"], rect, Color(0.2, 0.42, 0.6))
	else:
		var checker := (x + y) % 2 == 0
		draw_rect(rect, Color(0.20, 0.42, 0.60) if checker else Color(0.23, 0.46, 0.65))
		# ripples
		draw_rect(Rect2(rect.position.x + 3, rect.position.y + 5, 5, 1), Color(0.42, 0.62, 0.78, 0.5))
		draw_rect(Rect2(rect.position.x + 9, rect.position.y + 11, 4, 1), Color(0.42, 0.62, 0.78, 0.35))
	# shoreline highlight on edges bordering non-water
	if not water.has(Vector2i(x, y - 1)):
		draw_rect(Rect2(rect.position.x, rect.position.y, TILE, 2), Color(0.62, 0.80, 0.88, 0.75))
	if not water.has(Vector2i(x - 1, y)):
		draw_rect(Rect2(rect.position.x, rect.position.y, 2, TILE), Color(0.55, 0.74, 0.84, 0.5))
	if not water.has(Vector2i(x + 1, y)):
		draw_rect(Rect2(rect.position.x + TILE - 2, rect.position.y, 2, TILE), Color(0.15, 0.32, 0.48, 0.5))

func _blit(tex: Texture2D, rect: Rect2, fallback: Color) -> void:
	if tex:
		draw_texture_rect(tex, rect, false)
	else:
		draw_rect(rect, fallback)

func _draw_object(o: Dictionary) -> void:
	var r: Rect2i = o["_rect"]
	var t := String(o.get("type", ""))
	var px := float(r.position.x * TILE)
	var py := float(r.position.y * TILE)
	var pw := float(r.size.x * TILE)
	var ph := float(r.size.y * TILE)
	match t:
		"obstacle":
			if String(o.get("id", "")) in ["tree", "lotus", "lamp"]:
				_draw_decor(String(o["id"]), px, py, pw, ph)
			else:
				_draw_building(_sprites.get(String(o.get("id", "")), null), px, py, pw, ph, Color(0.5, 0.5, 0.55))
		"restaurant":
			var rsp := String(data.get_restaurant(String(o["id"])).get("sprite", "ramen")) if data else "ramen"
			_draw_building(_sprites.get(rsp, null), px, py, pw, ph, Color(0.8, 0.4, 0.3))
		"park_activity":
			_draw_park_marker(px, py, pw, ph)
		"npc", "mechanic":
			_draw_character(o, px, py, pw, ph)
		"rest_point":
			if String(o.get("mode", "")) == "home":
				_draw_building(_sprites.get("home", null), px, py, pw, ph, Color(0.6, 0.5, 0.4))
			else:
				_draw_ground_prop(_sprites.get("bench", null), px, py, pw, ph, Color(0.5, 0.4, 0.3))
		"bike_rack":
			_draw_ground_prop(_sprites.get("bike", null), px, py, pw, ph, Color(0.4, 0.7, 0.4))
		"sign":
			_draw_sign(px, py, pw, ph)
		"item":
			_draw_item(px, py, pw, ph)
		"puzzle":
			_draw_puzzle_board(o, px, py, pw, ph)
		"exit":
			_draw_gate(px, py, pw, ph)

func _shadow(cx: float, base_y: float, w: float) -> void:
	draw_set_transform(Vector2(cx, base_y - 1.0), 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, w * 0.5, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Buildings: fit to footprint width, preserve aspect, sit on the ground (bottom-aligned).
func _draw_building(tex: Texture2D, px: float, py: float, pw: float, ph: float, fallback: Color) -> void:
	if tex == null:
		draw_rect(Rect2(px, py, pw, ph), fallback)
		return
	var sc := pw / float(tex.get_width())
	var tw := pw
	var th := tex.get_height() * sc
	var bottom := py + ph
	_shadow(px + pw * 0.5, bottom, pw * 0.9)
	draw_texture_rect(tex, Rect2(px, bottom - th, tw, th), false)

# Characters: constant on-screen size, centered on footprint, bottom-aligned (fixes the
# "footprint-scaled" giant NPC bug).
func _draw_character(o: Dictionary, px: float, py: float, pw: float, ph: float) -> void:
	var tex: Texture2D = _sprites.get("npc_" + String(o.get("id", "")), null)
	if tex == null:
		tex = _sprites.get("npc", null)
	var cx := px + pw * 0.5
	var bottom := py + ph
	if tex == null:
		_shadow(cx, bottom, 12)
		draw_rect(Rect2(cx - 6, bottom - 24, 12, 24), Color(0.85, 0.8, 0.5))
		return
	var h := CHAR_H
	var sc := h / float(tex.get_height())
	var w := tex.get_width() * sc
	var tint: Color = o.get("tint", Color(1, 1, 1))
	_shadow(cx, bottom, w * 0.7)
	draw_texture_rect(tex, Rect2(cx - w * 0.5, bottom - h, w, h), false, tint)

# Ground props (bench, bike rack): fit width, bottom-aligned, with a shadow.
func _draw_ground_prop(tex: Texture2D, px: float, py: float, pw: float, ph: float, fallback: Color) -> void:
	var bottom := py + ph
	if tex == null:
		_shadow(px + pw * 0.5, bottom, pw * 0.7)
		draw_rect(Rect2(px + 2, py + 2, pw - 4, ph - 4), fallback)
		return
	var sc := pw / float(tex.get_width())
	var th := tex.get_height() * sc
	_shadow(px + pw * 0.5, bottom, pw * 0.8)
	draw_texture_rect(tex, Rect2(px, bottom - th, pw, th), false)

func _draw_decor(kind: String, px: float, py: float, pw: float, ph: float) -> void:
	var tex: Texture2D = _sprites.get(kind, null)
	var bottom := py + ph
	if tex:
		var sc := pw / float(tex.get_width())
		var th := tex.get_height() * sc
		_shadow(px + pw * 0.5, bottom, pw * 0.7)
		draw_texture_rect(tex, Rect2(px, bottom - th, pw, th), false)
		return
	var cx := px + pw * 0.5
	if kind == "tree":
		_shadow(cx, bottom, pw * 0.7)
		draw_rect(Rect2(cx - 2, bottom - 10, 4, 10), Color(0.42, 0.28, 0.16))
		draw_circle(Vector2(cx, bottom - 15), pw * 0.5, Color(0.20, 0.45, 0.24))
		draw_circle(Vector2(cx - 4, bottom - 12), pw * 0.35, Color(0.24, 0.52, 0.28))
		draw_circle(Vector2(cx + 4, bottom - 13), pw * 0.32, Color(0.18, 0.42, 0.22))
	elif kind == "lotus":
		draw_circle(Vector2(cx, py + ph * 0.5), pw * 0.35, Color(0.25, 0.55, 0.35))
		draw_circle(Vector2(cx, py + ph * 0.5), pw * 0.18, Color(0.95, 0.6, 0.75))
	elif kind == "lamp":
		_shadow(cx, bottom, 6)
		draw_rect(Rect2(cx - 1, bottom - 22, 2, 22), Color(0.2, 0.2, 0.24))
		draw_circle(Vector2(cx, bottom - 23), 3, Color(1.0, 0.9, 0.55))

func _draw_park_marker(px: float, py: float, pw: float, ph: float) -> void:
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5
	# dirt track ring
	draw_set_transform(Vector2(cx, cy), 0.0, Vector2(1.0, 0.6))
	draw_arc(Vector2.ZERO, pw * 0.55, 0, TAU, 24, Color(0.72, 0.6, 0.4), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# a small tree in the middle
	_draw_decor("tree", px + pw * 0.25, py, pw * 0.5, ph)

func _draw_sign(px: float, py: float, pw: float, ph: float) -> void:
	if _sprites.get("sign"):
		_draw_ground_prop(_sprites["sign"], px, py, pw, ph, Color(0.85, 0.75, 0.45))
		return
	var cx := px + pw * 0.5
	var bottom := py + ph
	_shadow(cx, bottom, pw * 0.5)
	draw_rect(Rect2(cx - 1.5, bottom - 12, 3, 12), Color(0.42, 0.30, 0.18))  # post
	draw_rect(Rect2(px + 1, py + 1, pw - 2, 9), Color(0.85, 0.72, 0.42))     # board
	draw_rect(Rect2(px + 2, py + 3, pw - 4, 1), Color(0.5, 0.38, 0.2))
	draw_rect(Rect2(px + 2, py + 6, pw - 6, 1), Color(0.5, 0.38, 0.2))

func _draw_item(px: float, py: float, pw: float, ph: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var bob := sin(t * 3.0) * 1.5
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5 + bob
	_shadow(cx, py + ph - 1, pw * 0.45)
	draw_circle(Vector2(cx, cy), 5.5, Color(1.0, 0.95, 0.5, 0.35))  # halo
	# diamond gem
	var pts := PackedVector2Array([Vector2(cx, cy - 4), Vector2(cx + 4, cy), Vector2(cx, cy + 4), Vector2(cx - 4, cy)])
	draw_colored_polygon(pts, Color(0.98, 0.82, 0.30))
	draw_line(Vector2(cx, cy - 4), Vector2(cx, cy + 4), Color(1, 1, 0.8, 0.8), 1.0)

func _draw_puzzle_board(o: Dictionary, px: float, py: float, pw: float, ph: float) -> void:
	var cx := px + pw * 0.5
	var bottom := py + ph
	var solved: bool = gs != null and gs.is_puzzle_solved(String(o.get("id", "")))
	_shadow(cx, bottom, pw * 0.7)
	draw_rect(Rect2(cx - 2, bottom - 8, 4, 8), Color(0.35, 0.25, 0.15))       # post
	var frame := Rect2(px + 1, py + 1, pw - 2, ph - 6)
	draw_rect(frame, Color(0.30, 0.22, 0.42))                                 # frame
	var inner := Rect2(px + 3, py + 3, pw - 6, ph - 10)
	draw_rect(inner, Color(0.55, 0.85, 0.7) if solved else Color(0.72, 0.66, 0.85))
	# grid lines to suggest a map/circuit
	draw_line(Vector2(inner.position.x, inner.position.y + inner.size.y * 0.5), Vector2(inner.position.x + inner.size.x, inner.position.y + inner.size.y * 0.5), Color(0.3, 0.25, 0.4, 0.7), 1.0)
	draw_line(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y), Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y), Color(0.3, 0.25, 0.4, 0.7), 1.0)

func _draw_gate(px: float, py: float, pw: float, ph: float) -> void:
	var open: bool = quests != null and quests.is_complete(String(level.get("completion_quest_id", "")))
	var bottom := py + ph
	var post := Color(0.45, 0.32, 0.2)
	_shadow(px + pw * 0.5, bottom, pw * 0.9)
	draw_rect(Rect2(px + 1, bottom - ph, 3, ph), post)                        # left post
	draw_rect(Rect2(px + pw - 4, bottom - ph, 3, ph), post)                   # right post
	draw_rect(Rect2(px + 1, bottom - ph, pw - 2, 4), post)                    # top bar
	var mid := Rect2(px + 5, bottom - ph + 5, pw - 10, ph - 6)
	if open:
		draw_rect(mid, Color(0.45, 0.85, 0.5, 0.55))                          # open glow
		var ax := px + pw * 0.5
		draw_line(Vector2(ax - 3, bottom - ph * 0.5), Vector2(ax + 3, bottom - ph * 0.5), Color(1, 1, 1, 0.9), 1.5)
		draw_line(Vector2(ax + 1, bottom - ph * 0.5 - 2), Vector2(ax + 3, bottom - ph * 0.5), Color(1, 1, 1, 0.9), 1.5)
		draw_line(Vector2(ax + 1, bottom - ph * 0.5 + 2), Vector2(ax + 3, bottom - ph * 0.5), Color(1, 1, 1, 0.9), 1.5)
	else:
		for i in range(0, int(pw) - 8, 4):
			draw_rect(Rect2(px + 5 + i, bottom - ph + 5, 2, ph - 6), Color(0.7, 0.35, 0.35, 0.8))

func _draw_ability_overlay() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(t * 6.0)
	if food_sense_active:
		for o in objects:
			if String(o.get("type", "")) == "sign":
				var r: Rect2i = o["_rect"]
				var c := Vector2(r.position.x * TILE + TILE / 2.0, r.position.y * TILE - 4)
				var real := String(o.get("scent", "")) == "real"
				var col := Color(0.3, 1.0, 0.4, pulse) if real else Color(1.0, 0.4, 0.4, 0.4 + 0.3 * pulse)
				draw_circle(c, 3.0 + (2.0 * pulse if real else 0.0), col)
	if trail_finder_active:
		for o in objects:
			var tt := String(o.get("type", ""))
			if tt == "puzzle" and gs != null and not gs.is_puzzle_solved(String(o["id"])):
				var r2: Rect2i = o["_rect"]
				draw_circle(Vector2(r2.position.x * TILE + TILE / 2.0, r2.position.y * TILE - 4), 3.0 + 2.0 * pulse, Color(0.4, 0.8, 1.0, pulse))
			elif tt == "exit":
				var r3: Rect2i = o["_rect"]
				draw_circle(Vector2(r3.position.x * TILE + TILE / 2.0, r3.position.y * TILE - 4), 3.0 + 2.0 * pulse, Color(0.6, 0.9, 1.0, 0.5 * pulse))
