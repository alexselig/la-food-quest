extends SceneTree
## Headless logic tests for the core loop (no rendering).
## Run: godot --headless --path . -s res://test/logic_test.gd

const GameStateScript := preload("res://scripts/game_state.gd")
const WorldScript := preload("res://scripts/world.gd")
const GameDataScript := preload("res://scripts/data/game_data.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const DialogueManagerScript := preload("res://scripts/dialogue_manager.gd")
const LevelControllerScript := preload("res://scripts/level_controller.gd")
const CircuitPuzzleScript := preload("res://scripts/puzzles/circuit_puzzle.gd")
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
    f += ck(DM.start("L1_REAL_SCENT") == true, "dialogue starts")
    f += ck(DM.is_active(), "dialogue active after start")
    f += ck(DM.current_speaker() == "xiao", "first line speaker is xiao")
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
    f += ck("locked" in early_exit.to_lower(), "exit locked before quest complete")
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
            printerr("  L1 unreachable: ", o.get("name", o.get("id", "?")))
    f += ck(unreach2 == 0, "all L1 interactive objects reachable from spawn")

    # 9b. Out-of-order progress: a step finished before its quest is active still counts
    var GSoo = GameStateScript.new()
    var QMoo = QuestManagerScript.new()
    QMoo.gs = GSoo
    QMoo.data = DataL
    QMoo.note_step("repair_map")   # e.g. solved the lake map before meeting Remy
    f += ck(not QMoo.is_step_done("L1_MAIN", "repair_map"), "early step is pending (quest not started)")
    QMoo.start_quest("L1_MAIN")
    f += ck(QMoo.is_step_done("L1_MAIN", "repair_map"), "pending step is credited when quest starts")
    QMoo.free()
    GSoo.free()

    # ============================================================
    # Level 2 (Griffith Park) flow + Echo->Griffith transition target
    # ============================================================
    f += ck(DataL.has_level("griffith"), "griffith level exists (transition target)")
    var GS2g = GameStateScript.new()
    var QM2 = QuestManagerScript.new()
    QM2.gs = GS2g
    QM2.data = DataL
    var DM2 = DialogueManagerScript.new()
    DM2.gs = GS2g
    DM2.data = DataL
    DM2.quests = QM2
    var LC2 = LevelControllerScript.new()
    LC2.gs = GS2g
    LC2.data = DataL
    LC2.quests = QM2
    LC2.dlg = DM2
    LC2.build_from_data("griffith")
    f += ck(LC2.cols == 40 and LC2.rows == 24, "L2 grid dims from data")
    f += ck(not LC2.is_blocked(Vector2i(4, 4)), "L2 spawn walkable")

    LC2.interact_at(Vector2i(8, 4))  # Ranger Sol
    f += ck(QM2.is_active("L2_MAIN"), "L2 quest active after Ranger Sol")
    _play_out(DM2)
    f += ck(QM2.is_step_done("L2_MAIN", "meet_ranger"), "meet_ranger step done")

    var cafe_locked: String = LC2.interact_at(Vector2i(33, 5))
    f += ck("hidden" in cafe_locked.to_lower(), "cafe locked before overlook found")

    LC2._on_puzzle_solved("trail_markers")
    _play_out(DM2)
    f += ck(QM2.is_step_done("L2_MAIN", "fix_trail_markers"), "trail markers step done")
    LC2._on_puzzle_solved("shadow_dial")
    _play_out(DM2)
    f += ck(QM2.is_step_done("L2_MAIN", "solve_sundial"), "sundial step done")
    LC2._on_puzzle_solved("trail_bells")
    _play_out(DM2)
    f += ck(GS2g.has_flag("overlook_found"), "overlook_found flag set by bells")
    f += ck(QM2.is_step_done("L2_MAIN", "ring_bells"), "ring_bells step done")

    var disc2: String = LC2.interact_at(Vector2i(33, 5))
    f += ck("discovered" in disc2.to_lower(), "cafe discovered after overlook")
    f += ck(QM2.is_step_done("L2_MAIN", "find_cafe"), "find_cafe step done")
    _play_out(DM2)
    var pw2: int = GS2g.power
    LC2.interact_at(Vector2i(33, 5))
    f += ck(GS2g.power == pw2 + 20, "eating toast raises power +20")
    f += ck(QM2.is_step_done("L2_MAIN", "eat_toast"), "eat_toast step done")
    _play_out(DM2)

    f += ck(not GS2g.has_ability("bike_bell"), "bike bell locked before hill intervals")
    LC2.interact_at(Vector2i(10, 18))  # hill intervals
    _play_out(DM2)
    f += ck(QM2.is_step_done("L2_MAIN", "hill_intervals"), "hill_intervals step done")
    f += ck(GS2g.has_ability("bike_bell"), "hill intervals grants Bike Bell")
    f += ck(GS2g.has_recipe("trail_mix_toast"), "hill intervals grants recipe")

    LC2.interact_at(Vector2i(38, 12))  # exit (needs bike_bell, has it)
    f += ck(QM2.is_complete("L2_MAIN"), "L2 quest completes at exit")
    f += ck(GS2g.has_stamp("griffith_star"), "Griffith Star stamp earned")
    f += ck(GS2g.is_level_unlocked("koreatown"), "District 3 (koreatown) unlocked")
    f += ck(GS2g.power == pw2 + 20 + 5, "L2 completion grants +5 bonus power")

    var r3 := {}
    var q3: Array = [Vector2i(4, 4)]
    r3[Vector2i(4, 4)] = true
    while not q3.is_empty():
        var c3: Vector2i = q3.pop_back()
        for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var n3: Vector2i = c3 + dd
            if not LC2.is_blocked(n3) and not r3.has(n3):
                r3[n3] = true
                q3.append(n3)
    var un2 := 0
    for o in LC2.objects:
        if String(o.get("type", "")) in ["obstacle"]:
            continue
        var rr2: Rect2i = o["_rect"]
        var ok2 := false
        for ix in range(rr2.position.x, rr2.position.x + rr2.size.x):
            for jy in range(rr2.position.y, rr2.position.y + rr2.size.y):
                for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                    if r3.has(Vector2i(ix, jy) + dd):
                        ok2 = true
        if not ok2:
            un2 += 1
            printerr("  L2 unreachable: ", o.get("name", o.get("id", "?")))
    f += ck(un2 == 0, "all L2 interactive objects reachable from spawn")

    LC2.free()
    GS2g.free()
    QM2.free()
    DM2.free()

    # ============================================================
    # CircuitPuzzle (lights-out) logic
    # ============================================================
    var CP = CircuitPuzzleScript.new()
    CP.configure("c_test", 5, [1, 3])
    CP.init_state()
    f += ck(not CP.is_solved(), "circuit starts unsolved")
    CP.apply_toggle(1)
    CP.apply_toggle(3)
    f += ck(CP.is_solved(), "circuit solved by re-applying the scramble toggles")
    CP.apply_toggle(0)
    f += ck(not CP.is_solved(), "circuit unsolved again after a stray toggle")
    CP.free()

    # ============================================================
    # Level 3 (Koreatown) flow
    # ============================================================
    var GS3k = GameStateScript.new()
    var QM3 = QuestManagerScript.new()
    QM3.gs = GS3k
    QM3.data = DataL
    var DM3 = DialogueManagerScript.new()
    DM3.gs = GS3k
    DM3.data = DataL
    DM3.quests = QM3
    var LC3 = LevelControllerScript.new()
    LC3.gs = GS3k
    LC3.data = DataL
    LC3.quests = QM3
    LC3.dlg = DM3
    LC3.build_from_data("koreatown")
    f += ck(DataL.has_level("koreatown"), "koreatown level exists")
    f += ck(not LC3.is_blocked(Vector2i(4, 4)), "L3 spawn walkable")

    LC3.interact_at(Vector2i(8, 4))  # Mrs. Han
    f += ck(QM3.is_active("L3_MAIN"), "L3 quest active after Mrs. Han")
    _play_out(DM3)
    f += ck(QM3.is_step_done("L3_MAIN", "meet_han"), "meet_han step done")

    LC3._on_puzzle_solved("neon_circuit")
    _play_out(DM3)
    f += ck(GS3k.has_flag("power_restored"), "power restored by circuit")
    f += ck(QM3.is_step_done("L3_MAIN", "fix_circuit"), "fix_circuit step done")

    # Chef Mina refuses before ingredients
    var mina_need: String = LC3.interact_at(Vector2i(22, 12))
    f += ck("needs" in mina_need.to_lower(), "Chef Mina asks for ingredients first")
    _play_out(DM3)
    f += ck(not QM3.is_step_done("L3_MAIN", "gather_ingredients"), "gather not done without ingredients")

    LC3.interact_at(Vector2i(16, 8))   # perilla
    LC3.interact_at(Vector2i(20, 6))   # king oyster
    LC3.interact_at(Vector2i(24, 8))   # garlic
    LC3.interact_at(Vector2i(28, 6))   # pear marinade
    f += ck(GS3k.has_item("perilla") and GS3k.has_item("king_oyster") and GS3k.has_item("garlic") and GS3k.has_item("pear_marinade"), "collected all 4 ingredients")
    LC3.interact_at(Vector2i(22, 12))  # Chef Mina with ingredients
    _play_out(DM3)
    f += ck(GS3k.has_flag("ingredients_ready"), "ingredients_ready flag set")
    f += ck(QM3.is_step_done("L3_MAIN", "gather_ingredients"), "gather_ingredients step done")
    f += ck(not GS3k.has_item("perilla"), "ingredients consumed by chef")

    # Cooking puzzle gated until ingredients ready (it is now), solve it
    LC3._on_puzzle_solved("cooking")
    _play_out(DM3)
    f += ck(GS3k.has_flag("wrap_cooked"), "wrap_cooked flag set")
    f += ck(QM3.is_step_done("L3_MAIN", "cook_wrap"), "cook_wrap step done")

    # Ember Table gated on wrap_cooked
    var pw3: int = GS3k.power
    LC3.interact_at(Vector2i(32, 5))   # discover
    _play_out(DM3)
    LC3.interact_at(Vector2i(32, 5))   # eat
    f += ck(GS3k.power == pw3 + 25, "eating wrap raises power +25")
    f += ck(QM3.is_step_done("L3_MAIN", "eat_wrap"), "eat_wrap step done")
    _play_out(DM3)

    f += ck(not GS3k.has_ability("cooler_basket"), "cooler locked before dance")
    LC3.interact_at(Vector2i(10, 18))  # dance circle
    _play_out(DM3)
    f += ck(QM3.is_step_done("L3_MAIN", "dance_circle"), "dance_circle step done")
    f += ck(GS3k.has_ability("cooler_basket"), "dance grants Cooler Basket")

    LC3.interact_at(Vector2i(38, 12))  # exit (needs cooler_basket)
    f += ck(QM3.is_complete("L3_MAIN"), "L3 quest completes at exit")
    f += ck(GS3k.has_stamp("koreatown_grill"), "Koreatown Grill stamp earned")
    f += ck(GS3k.is_level_unlocked("santa_monica"), "District 4 (santa_monica) unlocked")
    f += ck(GS3k.power == pw3 + 25 + 5, "L3 completion grants +5 bonus power")

    var r4 := {}
    var q4: Array = [Vector2i(4, 4)]
    r4[Vector2i(4, 4)] = true
    while not q4.is_empty():
        var c4: Vector2i = q4.pop_back()
        for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var n4: Vector2i = c4 + dd
            if not LC3.is_blocked(n4) and not r4.has(n4):
                r4[n4] = true
                q4.append(n4)
    var un3 := 0
    for o in LC3.objects:
        if String(o.get("type", "")) in ["obstacle"]:
            continue
        var rr3: Rect2i = o["_rect"]
        var ok3 := false
        for ix in range(rr3.position.x, rr3.position.x + rr3.size.x):
            for jy in range(rr3.position.y, rr3.position.y + rr3.size.y):
                for dd in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                    if r4.has(Vector2i(ix, jy) + dd):
                        ok3 = true
        if not ok3:
            un3 += 1
            printerr("  L3 unreachable: ", o.get("name", o.get("id", "?")))
    f += ck(un3 == 0, "all L3 interactive objects reachable from spawn")

    LC3.free()
    GS3k.free()
    QM3.free()
    DM3.free()

    LC.free()
    GSl.free()
    DataL.free()
    QML.free()
    DML.free()

    GS.free()
    W.free()
    return f
