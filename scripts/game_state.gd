extends Node
## Global game state for LA Food Quest.
## Shared meters for the Alp + Xiao duo, in-game clock, quest + discovery, save/load.

signal meters_changed
signal time_changed
signal restaurant_discovered(id)
signal quest_changed(state)
signal collapsed

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

func reset() -> void:
    power = 0
    fullness = 0.0
    energy = ENERGY_MAX
    minutes = 8 * 60
    day = 1
    quest_state = Quest.NOT_GIVEN
    discovered.clear()
    meters_changed.emit()
    time_changed.emit()

# --- Eating ---
func can_eat() -> bool:
    return fullness <= FULL_THRESHOLD

func eat(power_gain: int, fullness_gain: float, restaurant_id: String = "") -> bool:
    if not can_eat():
        return false
    if restaurant_id != "" and not discovered.has(restaurant_id):
        discovered[restaurant_id] = true
        restaurant_discovered.emit(restaurant_id)
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

func clock_string() -> String:
    return "Day %d  %02d:%02d" % [day, minutes / 60, minutes % 60]

# --- Save / load ---
func to_dict() -> Dictionary:
    return {
        "power": power, "fullness": fullness, "energy": energy,
        "minutes": minutes, "day": day, "quest": quest_state,
        "discovered": discovered,
    }

func from_dict(d: Dictionary) -> void:
    power = int(d.get("power", 0))
    fullness = float(d.get("fullness", 0.0))
    energy = float(d.get("energy", ENERGY_MAX))
    minutes = int(d.get("minutes", 8 * 60))
    day = int(d.get("day", 1))
    quest_state = int(d.get("quest", Quest.NOT_GIVEN))
    discovered = d.get("discovered", {})
    meters_changed.emit()
    time_changed.emit()
