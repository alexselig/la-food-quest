extends Node
## Global game state for LA Food Quest.
## Shared meters for the Alp + Xiao duo, in-game clock, quest + discovery, save/load.

signal meters_changed
signal time_changed
signal restaurant_discovered(id)
signal quest_changed(state)
signal collapsed
signal bike_changed(on)
signal ability_unlocked(ability)
signal stamp_earned(id)
signal recipe_learned(id)
signal food_dex_updated(id)
signal inventory_changed
signal flags_changed

# --- Meters (shared by the duo) ---
var power: int = 0            # progression; never decreases
var fullness: float = 0.0    # 0..100
var energy: float = 100.0    # 0..100

const FULLNESS_MAX := 100.0
const ENERGY_MAX := 100.0
const FULL_THRESHOLD := 70.0   # cannot eat while fullness is above this
const POWER_TO_WIN := 100      # legendary restaurant unlocks at/after this power

# --- In-game clock ---
var minutes: int = 8 * 60      # start at 08:00
var day: int = 1

# --- Quest / discovery ---
enum Quest { NOT_GIVEN, ACTIVE, UNLOCKED, COMPLETE }
var quest_state: int = Quest.NOT_GIVEN
var discovered: Dictionary = {}   # restaurant_id -> true
var on_bike := false

# --- Data-driven progression state (spec 18.2) ---
enum Dex { UNKNOWN, RUMORED, DISCOVERED, VISITED, SIGNATURE, SECRET }

const DEFAULT_ABILITIES := {
    "trail_finder": true,
    "food_sense": true,
    "tandem_bike": false,
    "bike_bell": false,
    "cooler_basket": false,
    "portable_grill": false,
}

var abilities: Dictionary = DEFAULT_ABILITIES.duplicate()

# Levels
var current_level_id: String = "echo_park"
var current_spawn_id: String = "start"
var unlocked_levels: Array = ["echo_park"]
var completed_levels: Dictionary = {}    # level_id -> true

# Collections
var inventory: Dictionary = {}            # item_id -> count
var food_dex: Dictionary = {}             # restaurant_id -> Dex state (int)
var recipes: Dictionary = {}              # recipe_id -> true
var neighborhood_stamps: Dictionary = {}  # stamp_id -> true
var quest_flags: Dictionary = {}          # gameplay flag -> true
var dialogue_flags: Dictionary = {}       # dialogue_id -> true (one-time played)
var puzzle_states: Dictionary = {}        # puzzle_id -> Dictionary
var active_quests: Dictionary = {}        # quest_id -> {state,current_step,steps}

func reset() -> void:
    power = 0
    fullness = 0.0
    energy = ENERGY_MAX
    minutes = 8 * 60
    day = 1
    quest_state = Quest.NOT_GIVEN
    discovered.clear()
    on_bike = false
    abilities = DEFAULT_ABILITIES.duplicate()
    current_level_id = "echo_park"
    current_spawn_id = "start"
    unlocked_levels = ["echo_park"]
    completed_levels = {}
    inventory = {}
    food_dex = {}
    recipes = {}
    neighborhood_stamps = {}
    quest_flags = {}
    dialogue_flags = {}
    puzzle_states = {}
    active_quests = {}
    meters_changed.emit()
    time_changed.emit()
    bike_changed.emit(false)

# --- Eating ---
func can_eat() -> bool:
    return fullness <= FULL_THRESHOLD

func eat(power_gain: int, fullness_gain: float, restaurant_id: String = "") -> bool:
    if not can_eat():
        return false
    if restaurant_id != "":
        if not discovered.has(restaurant_id):
            discovered[restaurant_id] = true
            restaurant_discovered.emit(restaurant_id)
        set_food_dex(restaurant_id, Dex.VISITED)
    power += power_gain
    fullness = clampf(fullness + fullness_gain, 0.0, FULLNESS_MAX)
    _check_quest_unlock()
    meters_changed.emit()
    advance_time(30)
    return true

# --- Exercise ---
func exercise(fullness_drop: float, energy_cost: float, mins: int = 60) -> void:
    fullness = clampf(fullness - fullness_drop, 0.0, FULLNESS_MAX)
    _spend_energy(energy_cost)
    meters_changed.emit()
    advance_time(mins)

# --- Rest ---
func rest(energy_gain: float, mins: int) -> void:
    energy = clampf(energy + energy_gain, 0.0, ENERGY_MAX)
    meters_changed.emit()
    advance_time(mins)

func rest_full() -> void:
    # Sleep at home until 07:00 next morning; full energy.
    energy = ENERGY_MAX
    var target := 7 * 60
    var delta := (target - minutes) if minutes < target else ((24 * 60 - minutes) + target)
    _advance_clock(delta)
    meters_changed.emit()

# --- Time ---
func advance_time(mins: int) -> void:
    _advance_clock(mins)
    _spend_energy(float(mins) * 0.05)   # ~3 energy/hour passive drain

func _advance_clock(mins: int) -> void:
    minutes += mins
    while minutes >= 24 * 60:
        minutes -= 24 * 60
        day += 1
    time_changed.emit()

func _spend_energy(amount: float) -> void:
    if amount <= 0.0:
        return
    energy = clampf(energy - amount, 0.0, ENERGY_MAX)
    if energy <= 0.0:
        _collapse()

func _collapse() -> void:
    collapsed.emit()
    _advance_clock(24 * 60)   # forced 24-hour skip, no further drain
    energy = ENERGY_MAX
    meters_changed.emit()

func _check_quest_unlock() -> void:
    if quest_state == Quest.ACTIVE and power >= POWER_TO_WIN:
        quest_state = Quest.UNLOCKED
        quest_changed.emit(quest_state)

func set_quest_state(s: int) -> void:
    quest_state = s
    quest_changed.emit(quest_state)

func set_bike(v: bool) -> void:
    if on_bike == v:
        return
    on_bike = v
    bike_changed.emit(on_bike)

func clock_string() -> String:
    return "Day %d  %02d:%02d" % [day, minutes / 60, minutes % 60]

# --- Abilities ---
func unlock_ability(ability: String) -> bool:
    if abilities.get(ability, false):
        return false
    abilities[ability] = true
    ability_unlocked.emit(ability)
    return true

func has_ability(ability: String) -> bool:
    return abilities.get(ability, false)

# --- Inventory ---
func add_item(id: String, count: int = 1) -> void:
    inventory[id] = item_count(id) + count
    inventory_changed.emit()

func remove_item(id: String, count: int = 1) -> bool:
    var have := item_count(id)
    if have < count:
        return false
    if have == count:
        inventory.erase(id)
    else:
        inventory[id] = have - count
    inventory_changed.emit()
    return true

func has_item(id: String, count: int = 1) -> bool:
    return item_count(id) >= count

func item_count(id: String) -> int:
    return int(inventory.get(id, 0))

# --- FoodDex ---
func set_food_dex(id: String, state: int) -> void:
    if state > food_dex_state(id):
        food_dex[id] = state
        food_dex_updated.emit(id)

func food_dex_state(id: String) -> int:
    return int(food_dex.get(id, Dex.UNKNOWN))

# --- Recipes ---
func learn_recipe(id: String) -> bool:
    if recipes.has(id):
        return false
    recipes[id] = true
    recipe_learned.emit(id)
    return true

func has_recipe(id: String) -> bool:
    return recipes.has(id)

func recipe_count() -> int:
    return recipes.size()

# --- Stamps ---
func add_stamp(id: String) -> bool:
    if neighborhood_stamps.has(id):
        return false
    neighborhood_stamps[id] = true
    stamp_earned.emit(id)
    return true

func has_stamp(id: String) -> bool:
    return neighborhood_stamps.has(id)

func stamp_count() -> int:
    return neighborhood_stamps.size()

# --- Flags ---
func set_flag(flag: String, value: bool = true) -> void:
    if value:
        quest_flags[flag] = true
    else:
        quest_flags.erase(flag)
    flags_changed.emit()

func has_flag(flag: String) -> bool:
    return quest_flags.get(flag, false)

func set_dialogue_played(id: String) -> void:
    dialogue_flags[id] = true

func dialogue_played(id: String) -> bool:
    return dialogue_flags.get(id, false)

# --- Puzzle state ---
func set_puzzle_state(id: String, state: Dictionary) -> void:
    puzzle_states[id] = state

func get_puzzle_state(id: String) -> Dictionary:
    return puzzle_states.get(id, {})

func mark_puzzle_solved(id: String) -> void:
    var st: Dictionary = puzzle_states.get(id, {})
    st["solved"] = true
    puzzle_states[id] = st

func is_puzzle_solved(id: String) -> bool:
    return bool(get_puzzle_state(id).get("solved", false))

# --- Levels ---
func unlock_level(id: String) -> void:
    if not unlocked_levels.has(id):
        unlocked_levels.append(id)

func is_level_unlocked(id: String) -> bool:
    return unlocked_levels.has(id)

func complete_level(id: String) -> void:
    completed_levels[id] = true

func is_level_complete(id: String) -> bool:
    return completed_levels.get(id, false)

# --- Save / load ---
func to_dict() -> Dictionary:
    return {
        "power": power, "fullness": fullness, "energy": energy,
        "minutes": minutes, "day": day, "quest": quest_state,
        "discovered": discovered, "on_bike": on_bike,
        "abilities": abilities,
        "current_level_id": current_level_id, "current_spawn_id": current_spawn_id,
        "unlocked_levels": unlocked_levels, "completed_levels": completed_levels,
        "inventory": inventory, "food_dex": food_dex, "recipes": recipes,
        "neighborhood_stamps": neighborhood_stamps,
        "quest_flags": quest_flags, "dialogue_flags": dialogue_flags,
        "puzzle_states": puzzle_states, "active_quests": active_quests,
    }

func from_dict(d: Dictionary) -> void:
    power = int(d.get("power", 0))
    fullness = float(d.get("fullness", 0.0))
    energy = float(d.get("energy", ENERGY_MAX))
    minutes = int(d.get("minutes", 8 * 60))
    day = int(d.get("day", 1))
    quest_state = int(d.get("quest", Quest.NOT_GIVEN))
    discovered = d.get("discovered", {})
    on_bike = bool(d.get("on_bike", false))
    # Migration-safe: merge saved abilities onto current defaults so new
    # ability keys survive loading an older save.
    abilities = DEFAULT_ABILITIES.duplicate()
    var saved_ab: Dictionary = d.get("abilities", {})
    for k in abilities.keys():
        if saved_ab.has(k):
            abilities[k] = bool(saved_ab[k])
    current_level_id = String(d.get("current_level_id", "echo_park"))
    current_spawn_id = String(d.get("current_spawn_id", "start"))
    unlocked_levels = d.get("unlocked_levels", ["echo_park"])
    completed_levels = d.get("completed_levels", {})
    inventory = d.get("inventory", {})
    food_dex = d.get("food_dex", {})
    recipes = d.get("recipes", {})
    neighborhood_stamps = d.get("neighborhood_stamps", {})
    quest_flags = d.get("quest_flags", {})
    dialogue_flags = d.get("dialogue_flags", {})
    puzzle_states = d.get("puzzle_states", {})
    active_quests = d.get("active_quests", {})
    meters_changed.emit()
    time_changed.emit()
    bike_changed.emit(on_bike)

const SAVE_PATH := "user://save.json"

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
    var fa := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if fa:
        fa.store_string(JSON.stringify(to_dict()))
        fa.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var fa := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if fa == null:
        return false
    var txt := fa.get_as_text()
    fa.close()
    var data = JSON.parse_string(txt)
    if typeof(data) == TYPE_DICTIONARY:
        from_dict(data)
        return true
    return false
