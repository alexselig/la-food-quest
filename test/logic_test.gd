extends SceneTree
## Headless logic tests for the core loop (no rendering).
## Run: godot --headless --path . -s res://test/logic_test.gd

const GameStateScript := preload("res://scripts/game_state.gd")
const WorldScript := preload("res://scripts/world.gd")
const _Title := preload("res://scripts/title.gd")
const _Car := preload("res://scripts/car.gd")
const _GameOver := preload("res://scripts/game_over.gd")
const _Hud := preload("res://scripts/hud.gd")
const _Pause := preload("res://scripts/pause_menu.gd")

func _initialize() -> void:
    var f := _run()
    if f == 0:
        print("ALL LOGIC TESTS PASSED")
    else:
        printerr("LOGIC TESTS FAILED: ", f)
    quit(1 if f > 0 else 0)

func ck(cond: bool, msg: String) -> int:
    if cond:
        return 0
    printerr("  FAIL: ", msg)
    return 1

func _run() -> int:
    var f := 0
    var GS = GameStateScript.new()

    # --- initial ---
    f += ck(GS.energy == 100.0 and GS.fullness == 0.0 and GS.power == 0, "initial meters")
    f += ck(GS.minutes == 480, "initial clock is 08:00")

    # --- eating: discover + power + fullness + time ---
    f += ck(GS.eat(20, 40.0, "taco") == true, "first eat succeeds")
    f += ck(GS.power == 20, "power raised by eating")
    f += ck(abs(GS.fullness - 40.0) < 0.01, "fullness raised by eating")
    f += ck(GS.discovered.has("taco"), "restaurant discovered on first visit")
    f += ck(GS.minutes == 510, "eating advances clock 30m")
    f += ck(GS.energy < 100.0, "time passing drains energy")

    # --- too full blocks eating ---
    GS.eat(10, 40.0, "ramen")  # fullness -> 80
    f += ck(GS.fullness >= 79.9, "fullness ~80 after 2nd meal")
    f += ck(GS.can_eat() == false, "cannot eat while too full (>70)")
    var pw = GS.power
    f += ck(GS.eat(10, 10.0, "boba") == false, "eat blocked when full")
    f += ck(GS.power == pw, "power unchanged when eat blocked")
    f += ck(not GS.discovered.has("boba"), "no discovery when eat blocked")

    # --- exercise lowers fullness, costs energy, re-enables eating ---
    var e0 = GS.energy
    GS.exercise(40.0, 20.0, 60)
    f += ck(GS.fullness <= 40.1, "exercise lowers fullness")
    f += ck(GS.energy < e0, "exercise costs energy")
    f += ck(GS.can_eat() == true, "can eat again after exercising down")

    # --- rest restores energy ---
    var e1 = GS.energy
    GS.rest(30.0, 60)
    f += ck(GS.energy > e1, "rest restores energy")

    # --- collapse when energy hits 0 ---
    GS.energy = 2.0
    var d0 = GS.day
    GS.exercise(0.0, 10.0, 0)  # energy -> 0 -> collapse
    f += ck(GS.energy == 100.0, "collapse restores energy")
    f += ck(GS.day == d0 + 1, "collapse skips ~24h to next day")

    # --- quest unlocks at power threshold ---
    GS.set_quest_state(GameStateScript.Quest.ACTIVE)
    GS.power = 95
    GS.fullness = 0.0
    GS.eat(10, 5.0, "diner")  # power -> 105 >= POWER_TO_WIN
    f += ck(GS.quest_state == GameStateScript.Quest.UNLOCKED, "legendary unlocks at power>=100")

    # --- world collision grid ---
    var W = WorldScript.new()
    W._build_world()
    f += ck(W.is_blocked(Vector2i(0, 0)) == true, "border is blocked")
    f += ck(W.is_blocked(Vector2i(2, 5)) == true, "building footprint cell is blocked")
    f += ck(W.is_blocked(Vector2i(3, 7)) == false, "open sidewalk is walkable")
    f += ck(W.is_blocked(Vector2i(20, 8)) == false, "road is walkable")
    f += ck(W.is_blocked(Vector2i(-1, 5)) == true, "out-of-bounds is blocked")

    # --- interaction dispatch (inject a fresh GameState) ---
    var GS2 = GameStateScript.new()
    W.gs = GS2
    GS2.set_quest_state(GameStateScript.Quest.ACTIVE)
    var m1 = W.interact_at(Vector2i(2, 5))   # Taco Truck
    f += ck(GS2.power == 20 and GS2.discovered.has("taco"), "restaurant interact raises power + discovers")
    f += ck(m1.begins_with("Discovered"), "restaurant discovery toast")
    GS2.fullness = 90.0
    var m2 = W.interact_at(Vector2i(2, 5))
    f += ck("Too full" in m2, "restaurant blocked when too full")
    var full0 = GS2.fullness
    W.interact_at(Vector2i(2, 11))           # Echo Park exercise
    f += ck(GS2.fullness < full0, "exercise interact lowers fullness")
    W.interact_at(Vector2i(29, 22))          # Legendary while locked
    f += ck(GS2.quest_state != GameStateScript.Quest.COMPLETE, "legendary locked below threshold")
    GS2.set_quest_state(GameStateScript.Quest.UNLOCKED)
    var mwin = W.interact_at(Vector2i(29, 22))
    f += ck(GS2.quest_state == GameStateScript.Quest.COMPLETE and ("WIN" in mwin), "legendary wins when unlocked")
    GS2.free()

    # --- green bike: mount/dismount toggles GameState.on_bike ---
    var GS5 = GameStateScript.new()
    var Wb = WorldScript.new()
    Wb.gs = GS5
    Wb._build_world()
    f += ck(GS5.on_bike == false, "starts off the bike")
    Wb.interact_at(Vector2i(16, 18))
    f += ck(GS5.on_bike == true, "interacting green bike mounts")
    Wb.interact_at(Vector2i(16, 18))
    f += ck(GS5.on_bike == false, "interacting green bike again dismounts")
    GS5.free()
    Wb.free()

    # --- reachability: every interactive object reachable from spawn ---
    var W2 = WorldScript.new()
    W2._build_world()
    var reach := {}
    var q: Array = [W2.SPAWN]
    reach[W2.SPAWN] = true
    while not q.is_empty():
        var cur = q.pop_back()
        for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var nn = cur + dd
            if not W2.is_blocked(nn) and not reach.has(nn):
                reach[nn] = true
                q.append(nn)
    var unreachable := 0
    for o in W2.objects:
        if o["type"] == "filler":
            continue
        var okr := false
        var rr = o["rect"]
        for ix in range(rr.position.x, rr.position.x + rr.size.x):
            for jy in range(rr.position.y, rr.position.y + rr.size.y):
                for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                    if reach.has(Vector2i(ix, jy) + dd):
                        okr = true
        if not okr:
            unreachable += 1
            printerr("  unreachable: ", o.get("name", o["id"]))
    f += ck(W2.is_blocked(W2.SPAWN) == false, "spawn is walkable")
    f += ck(unreachable == 0, "all interactive objects reachable from spawn")
    W2.free()

    # --- save / load ---
    var GS3 = GameStateScript.new()
    GS3.power = 42
    GS3.fullness = 33.0
    GS3.energy = 55.0
    GS3.minutes = 600
    GS3.day = 2
    GS3.discovered["taco"] = true
    GS3.save_game()
    var GS4 = GameStateScript.new()
    f += ck(GS4.has_save() == true, "save file exists")
    f += ck(GS4.load_game() == true, "load succeeds")
    f += ck(GS4.power == 42 and GS4.day == 2 and GS4.discovered.has("taco"), "loaded state matches saved")
    GS3.free()
    GS4.free()

    GS.free()
    W.free()
    return f
