extends SceneTree
## Headless logic tests for the core loop (no rendering).
## Run: godot --headless --path . -s res://test/logic_test.gd

const GameStateScript := preload("res://scripts/game_state.gd")
const WorldScript := preload("res://scripts/world.gd")
const _Intro := preload("res://scripts/intro.gd")
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
    f += ck(W.is_blocked(Vector2i(2, 3)) == true, "building footprint cell is blocked")
    f += ck(W.is_blocked(Vector2i(5, 5)) == false, "open sidewalk is walkable")
    f += ck(W.is_blocked(Vector2i(20, 8)) == false, "road is walkable")
    f += ck(W.is_blocked(Vector2i(-1, 5)) == true, "out-of-bounds is blocked")

    # --- interaction dispatch (inject a fresh GameState) ---
    var GS2 = GameStateScript.new()
    W.gs = GS2
    GS2.set_quest_state(GameStateScript.Quest.ACTIVE)
    var m1 = W.interact_at(Vector2i(2, 3))   # Taco Truck
    f += ck(GS2.power == 20 and GS2.discovered.has("taco"), "restaurant interact raises power + discovers")
    f += ck(m1.begins_with("Discovered"), "restaurant discovery toast")
    GS2.fullness = 90.0
    var m2 = W.interact_at(Vector2i(2, 3))
    f += ck("Too full" in m2, "restaurant blocked when too full")
    var full0 = GS2.fullness
    W.interact_at(Vector2i(8, 12))           # Echo Park exercise
    f += ck(GS2.fullness < full0, "exercise interact lowers fullness")
    W.interact_at(Vector2i(29, 23))          # Legendary while locked
    f += ck(GS2.quest_state != GameStateScript.Quest.COMPLETE, "legendary locked below threshold")
    GS2.set_quest_state(GameStateScript.Quest.UNLOCKED)
    var mwin = W.interact_at(Vector2i(29, 23))
    f += ck(GS2.quest_state == GameStateScript.Quest.COMPLETE and ("WIN" in mwin), "legendary wins when unlocked")
    GS2.free()

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
