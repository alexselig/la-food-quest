extends SceneTree
## Headless logic tests for the core loop (no rendering).
## Run: godot --headless --path . -s res://test/logic_test.gd

const GameStateScript := preload("res://scripts/game_state.gd")
const WorldScript := preload("res://scripts/world.gd")
const GameDataScript := preload("res://scripts/data/game_data.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const DialogueManagerScript := preload("res://scripts/dialogue_manager.gd")
const LevelControllerScript := preload("res://scripts/level_controller.gd")
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

func _play_out(dm) -> void:
    var n := 0
    while dm.is_active() and n < 30:
        dm.advance()
        n += 1

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
    f += ck(not Wb.objects_by_cell.has(Vector2i(16, 18)), "mounted bike disappears from the map")
    Wb._dismount_bike()
    f += ck(GS5.on_bike == false, "dismount (D) hops off the bike")
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

    # ============================================================
    # Foundation systems (data-driven expansion)
    # ============================================================

    # --- GameState: abilities / inventory / recipes / stamps / flags / puzzles / fooddex / levels ---
    var GSf = GameStateScript.new()
    f += ck(GSf.has_ability("trail_finder") and GSf.has_ability("food_sense"), "start: trail finder + food sense on")
    f += ck(not GSf.has_ability("tandem_bike"), "start: tandem bike locked")
    f += ck(GSf.unlock_ability("tandem_bike") == true, "unlock ability returns true first time")
    f += ck(GSf.unlock_ability("tandem_bike") == false, "unlock ability idempotent")
    GSf.add_item("chain_pin")
    f += ck(GSf.has_item("chain_pin") and GSf.item_count("chain_pin") == 1, "add/has item")
    f += ck(GSf.remove_item("chain_pin") and not GSf.has_item("chain_pin"), "remove item")
    f += ck(GSf.learn_recipe("chili_crisp_noodles") and GSf.has_recipe("chili_crisp_noodles"), "learn recipe")
    f += ck(GSf.learn_recipe("chili_crisp_noodles") == false, "recipe idempotent")
    f += ck(GSf.add_stamp("echo_park_lotus") and GSf.has_stamp("echo_park_lotus"), "add stamp")
    f += ck(GSf.add_stamp("echo_park_lotus") == false, "stamp idempotent")
    f += ck(GSf.stamp_count() == 1, "stamp count")
    GSf.set_flag("scent_solved")
    f += ck(GSf.has_flag("scent_solved"), "set/has flag")
    GSf.set_flag("scent_solved", false)
    f += ck(not GSf.has_flag("scent_solved"), "clear flag")
    GSf.set_flag("scent_solved")
    GSf.set_puzzle_state("lake_map", {"orient": [0, 1, 2, 3]})
    GSf.mark_puzzle_solved("lake_map")
    f += ck(GSf.is_puzzle_solved("lake_map"), "puzzle solved flag")
    GSf.set_food_dex("sunset_noodle", GameStateScript.Dex.VISITED)
    f += ck(GSf.food_dex_state("sunset_noodle") == GameStateScript.Dex.VISITED, "fooddex state set")
    GSf.set_food_dex("sunset_noodle", GameStateScript.Dex.RUMORED)
    f += ck(GSf.food_dex_state("sunset_noodle") == GameStateScript.Dex.VISITED, "fooddex never downgrades")
    f += ck(GSf.is_level_unlocked("echo_park") and not GSf.is_level_unlocked("griffith"), "level unlock defaults")
    GSf.unlock_level("griffith")
    GSf.complete_level("echo_park")
    f += ck(GSf.is_level_unlocked("griffith") and GSf.is_level_complete("echo_park"), "unlock + complete level")

    # --- Save/load round trip of new state ---
    GSf.save_game()
    var GSg = GameStateScript.new()
    f += ck(GSg.load_game(), "load succeeds (expanded state)")
    f += ck(GSg.has_ability("tandem_bike"), "loaded ability persists")
    f += ck(GSg.has_stamp("echo_park_lotus"), "loaded stamp persists")
    f += ck(GSg.has_flag("scent_solved"), "loaded flag persists")
    f += ck(GSg.is_puzzle_solved("lake_map"), "loaded puzzle-solved persists")
    f += ck(GSg.is_level_unlocked("griffith"), "loaded unlocked level persists")
    f += ck(GSg.food_dex_state("sunset_noodle") == GameStateScript.Dex.VISITED, "loaded fooddex persists")

    # --- Migration from an old (prototype) save that lacks the new keys ---
    var GSh = GameStateScript.new()
    GSh.from_dict({"power": 10, "fullness": 5.0, "energy": 50.0, "minutes": 600, "day": 1, "quest": 1, "discovered": {"taco": true}})
    f += ck(GSh.has_ability("trail_finder"), "migration: default abilities present")
    f += ck(not GSh.has_ability("tandem_bike"), "migration: locked ability stays locked")
    f += ck(GSh.is_level_unlocked("echo_park"), "migration: default unlocked levels")
    f += ck(GSh.power == 10 and GSh.discovered.has("taco"), "migration: old fields load")

    # --- QuestManager: step ordering + completion ---
    var QData = GameDataScript.new()
    var QM = QuestManagerScript.new()
    var GSq = GameStateScript.new()
    QM.gs = GSq
    QM.data = QData
    QM.start_quest("L1_MAIN")
    f += ck(QM.is_active("L1_MAIN"), "quest starts active")
    f += ck(QM.current_step_id("L1_MAIN") == "meet_remy", "first step is meet_remy")
    QM.complete_step("L1_MAIN", "meet_remy")
    f += ck(QM.current_step_id("L1_MAIN") == "solve_scent", "advances to solve_scent")
    f += ck(QM.is_step_done("L1_MAIN", "meet_remy"), "step marked done")
    QM.complete_step("L1_MAIN", "nonexistent_step")
    f += ck(QM.current_step_id("L1_MAIN") == "solve_scent", "invalid step ignored")
    QM.note_step("solve_scent")
    f += ck(QM.is_step_done("L1_MAIN", "solve_scent"), "note_step completes owning quest step")
    for sid in ["repair_map", "find_restaurant", "eat_noodles", "park_loop", "unlock_bike", "reach_exit"]:
        QM.complete_step("L1_MAIN", sid)
    f += ck(QM.is_complete("L1_MAIN"), "quest completes when all steps done")
    f += ck(QM.current_objective("L1_MAIN") == "Complete!", "objective shows complete")

    # --- DialogueManager: line flow + flag/step side effects ---
    var DData = GameDataScript.new()
    var GSd = GameStateScript.new()
    var QMd = QuestManagerScript.new()
    QMd.gs = GSd
    QMd.data = DData
    QMd.start_quest("L1_MAIN")
    QMd.complete_step("L1_MAIN", "meet_remy")
    var DM = DialogueManagerScript.new()
    DM.gs = GSd
    DM.data = DData
    DM.quests = QMd
    var lines: Array = []
    DM.line_shown.connect(func(sp, tx): lines.append([sp, tx]))
    f += ck(DM.start("L1_REAL_SCENT") == true, "dialogue starts")
    f += ck(DM.is_active(), "dialogue active after start")
    f += ck(lines.size() == 1 and lines[0][0] == "xiao", "first line shown (xiao)")
    DM.advance()  # -> alp
    DM.advance()  # -> xiao (applies set_flags + complete_step)
    f += ck(GSd.has_flag("scent_solved"), "dialogue set_flags applied")
    f += ck(QMd.is_step_done("L1_MAIN", "solve_scent"), "dialogue completed quest step")
    DM.advance()  # next "" -> finish
    f += ck(not DM.is_active(), "dialogue finishes at terminal node")
    f += ck(GSd.dialogue_played("L1_REAL_SCENT"), "dialogue marked played")
    f += ck(DM.start("NOPE_MISSING") == false, "missing dialogue returns false")

    GSf.free()
    GSg.free()
    GSh.free()
    GSq.free()
    QM.free()
    QData.free()
    GSd.free()
    QMd.free()
    DM.free()
    DData.free()

    # ============================================================
    # Level 1 (Echo Park) end-to-end flow through LevelController
    # ============================================================
    var GSl = GameStateScript.new()
    var DataL = GameDataScript.new()
    var QML = QuestManagerScript.new()
    QML.gs = GSl
    QML.data = DataL
    var DML = DialogueManagerScript.new()
    DML.gs = GSl
    DML.data = DataL
    DML.quests = QML
    var LC = LevelControllerScript.new()
    LC.gs = GSl
    LC.data = DataL
    LC.quests = QML
    LC.dlg = DML
    LC.build_from_data("echo_park")
    f += ck(LC.cols == 34 and LC.rows == 22, "L1 grid dims from data")
    f += ck(LC.is_blocked(Vector2i(0, 0)), "L1 border blocked")
    f += ck(LC.is_blocked(Vector2i(11, 10)), "L1 lake water blocked")
    f += ck(not LC.is_blocked(Vector2i(3, 5)), "L1 spawn walkable")

    # 1. Meet Remy -> quest starts, dialogue completes meet_remy
    LC.interact_at(Vector2i(7, 3))
    f += ck(QML.is_active("L1_MAIN"), "L1 quest active after Remy")
    _play_out(DML)
    f += ck(QML.is_step_done("L1_MAIN", "meet_remy"), "meet_remy step done")

    # exit locked before quest complete
    var early_exit: String = LC.interact_at(Vector2i(32, 10))
    f += ck("shut" in early_exit.to_lower(), "exit locked before quest complete")
    f += ck(not QML.is_complete("L1_MAIN"), "early exit does not complete quest")

    # 2. restaurant hidden before scent solved
    var hidden_msg: String = LC.interact_at(Vector2i(28, 3))
    f += ck("hidden" in hidden_msg.to_lower(), "restaurant hidden before scent")
    f += ck(GSl.food_dex_state("sunset_noodle") == GameStateScript.Dex.UNKNOWN, "restaurant unknown pre-scent")

    # 3. Follow the real aroma -> scent_solved
    LC.interact_at(Vector2i(18, 3))
    _play_out(DML)
    f += ck(GSl.has_flag("scent_solved"), "scent_solved flag set")
    f += ck(QML.is_step_done("L1_MAIN", "solve_scent"), "solve_scent step done")

    # 4. Repair the lake map (simulate puzzle solve)
    LC._on_puzzle_solved("lake_map")
    _play_out(DML)
    f += ck(GSl.is_puzzle_solved("lake_map"), "lake_map puzzle solved")
    f += ck(GSl.has_flag("map_solved") and QML.is_step_done("L1_MAIN", "repair_map"), "repair_map step done")

    # 5. Discover then eat the noodles
    var disc: String = LC.interact_at(Vector2i(28, 3))
    f += ck("discovered" in disc.to_lower(), "restaurant discovered after scent")
    f += ck(QML.is_step_done("L1_MAIN", "find_restaurant"), "find_restaurant step done")
    _play_out(DML)
    var pw0: int = GSl.power
    LC.interact_at(Vector2i(28, 3))
    f += ck(GSl.power == pw0 + 20, "eating raises power +20")
    f += ck(GSl.food_dex_state("sunset_noodle") == GameStateScript.Dex.VISITED, "restaurant visited after eating")
    f += ck(QML.is_step_done("L1_MAIN", "eat_noodles"), "eat_noodles step done")
    _play_out(DML)

    # 6. Park loop lowers fullness + grants recipe
    var full_before: float = GSl.fullness
    LC.interact_at(Vector2i(6, 17))
    f += ck(GSl.fullness < full_before, "park activity lowers fullness")
    f += ck(QML.is_step_done("L1_MAIN", "park_loop"), "park_loop step done")
    f += ck(GSl.has_recipe("chili_crisp_noodles"), "park grants recipe card")

    # 7. Collect 3 parts, fix the tandem bike with Nia
    f += ck(not GSl.has_ability("tandem_bike"), "bike locked before repair")
    LC.interact_at(Vector2i(16, 17))
    _play_out(DML)
    f += ck(not GSl.has_ability("tandem_bike"), "bike still locked without parts")
    LC.interact_at(Vector2i(12, 18))
    LC.interact_at(Vector2i(26, 11))
    LC.interact_at(Vector2i(30, 15))
    f += ck(GSl.has_item("chain_pin") and GSl.has_item("oil") and GSl.has_item("bell_screw"), "collected all 3 bike parts")
    LC.interact_at(Vector2i(16, 17))
    _play_out(DML)
    f += ck(GSl.has_ability("tandem_bike"), "tandem bike unlocked")
    f += ck(QML.is_step_done("L1_MAIN", "unlock_bike"), "unlock_bike step done")
    f += ck(not GSl.has_item("chain_pin"), "bike parts consumed")

    # 8. Exit completes the quest + awards stamp/level rewards
    LC.interact_at(Vector2i(32, 10))
    f += ck(QML.is_complete("L1_MAIN"), "quest completes at exit when all steps done")
    f += ck(GSl.has_stamp("echo_park_lotus"), "Echo Park Lotus stamp earned")
    f += ck(GSl.is_level_unlocked("griffith"), "District 2 (griffith) unlocked")
    f += ck(GSl.is_level_complete("echo_park"), "echo_park marked complete")
    f += ck(GSl.power == pw0 + 20 + 5, "level completion grants +5 bonus power")

    # 9. Reachability: every interactive L1 object reachable from spawn
    var reach2 := {}
    var q2: Array = [Vector2i(3, 5)]
    reach2[Vector2i(3, 5)] = true
    while not q2.is_empty():
        var cur2: Vector2i = q2.pop_back()
        for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var nn2: Vector2i = cur2 + dd
            if not LC.is_blocked(nn2) and not reach2.has(nn2):
                reach2[nn2] = true
                q2.append(nn2)
    var unreach2 := 0
    for o in LC.objects:
        if String(o.get("type", "")) in ["obstacle"]:
            continue
        var rr: Rect2i = o["_rect"]
        var okr := false
        for ix in range(rr.position.x, rr.position.x + rr.size.x):
            for jy in range(rr.position.y, rr.position.y + rr.size.y):
                for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                    if reach2.has(Vector2i(ix, jy) + dd):
                        okr = true
        if not okr:
            unreach2 += 1
            printerr("  L1 unreach2able: ", o.get("name", o.get("id", "?")))
    f += ck(unreach2 == 0, "all L1 interactive objects reach2able from spawn")

    GSl.free()
    DataL.free()
    QML.free()
    DML.free()
    LC.free()

    GS.free()
    W.free()
    return f
