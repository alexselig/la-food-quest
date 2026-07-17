extends Node
## QuestManager: quest state machine over GameState.active_quests + GameData.QUESTS
## (spec 18.6). Steps are tracked as a completed-set so they may be finished in any
## gameplay-permitted order. Main quests never enter an unrecoverable failed state.

signal quest_updated(quest_id)
signal quest_completed(quest_id)
signal step_completed(quest_id, step_id)

var gs: Node          # injectable for headless tests
var data: Node

func _ready() -> void:
	gs = get_node_or_null("/root/GameState")
	data = get_node_or_null("/root/GameData")

func _gs() -> Node:
	return gs if gs != null else get_node_or_null("/root/GameState")

func _data() -> Node:
	return data if data != null else get_node_or_null("/root/GameData")

func start_quest(quest_id: String) -> void:
	var g := _gs()
	if g == null or g.active_quests.has(quest_id):
		return
	g.active_quests[quest_id] = {"state": "active", "completed": {}}
	quest_updated.emit(quest_id)

func is_active(quest_id: String) -> bool:
	var g := _gs()
	return g != null and g.active_quests.has(quest_id) \
		and g.active_quests[quest_id].get("state", "") == "active"

func is_complete(quest_id: String) -> bool:
	var g := _gs()
	return g != null and g.active_quests.has(quest_id) \
		and g.active_quests[quest_id].get("state", "") == "complete"

func _steps(quest_id: String) -> Array:
	var d := _data()
	return d.get_quest(quest_id).get("steps", []) if d != null else []

func _has_step(quest_id: String, step_id: String) -> bool:
	for s in _steps(quest_id):
		if s.get("id", "") == step_id:
			return true
	return false

func is_step_done(quest_id: String, step_id: String) -> bool:
	var g := _gs()
	if g == null or not g.active_quests.has(quest_id):
		return false
	return bool(g.active_quests[quest_id].get("completed", {}).get(step_id, false))

func complete_step(quest_id: String, step_id: String) -> void:
	var g := _gs()
	if g == null or not g.active_quests.has(quest_id) or not _has_step(quest_id, step_id):
		return
	var q: Dictionary = g.active_quests[quest_id]
	var comp: Dictionary = q.get("completed", {})
	if comp.get(step_id, false):
		return
	comp[step_id] = true
	q["completed"] = comp
	g.active_quests[quest_id] = q
	step_completed.emit(quest_id, step_id)
	quest_updated.emit(quest_id)
	var all_done := true
	for s in _steps(quest_id):
		if not comp.get(s.get("id", ""), false):
			all_done = false
	if all_done:
		complete_quest(quest_id)

## Complete `step_id` in whichever active quest owns it (used by dialogue/handlers).
func note_step(step_id: String) -> void:
	var g := _gs()
	if g == null:
		return
	for qid in g.active_quests.keys():
		if is_active(qid) and _has_step(qid, step_id):
			complete_step(qid, step_id)
			return

func complete_quest(quest_id: String) -> void:
	var g := _gs()
	if g == null or not g.active_quests.has(quest_id):
		return
	g.active_quests[quest_id]["state"] = "complete"
	quest_completed.emit(quest_id)
	quest_updated.emit(quest_id)

func current_step_id(quest_id: String) -> String:
	var g := _gs()
	if g == null or not g.active_quests.has(quest_id):
		return ""
	var comp: Dictionary = g.active_quests[quest_id].get("completed", {})
	for s in _steps(quest_id):
		if not comp.get(s.get("id", ""), false):
			return s.get("id", "")
	return ""

func current_objective(quest_id: String) -> String:
	if is_complete(quest_id):
		return "Complete!"
	var sid := current_step_id(quest_id)
	for s in _steps(quest_id):
		if s.get("id", "") == sid:
			return s.get("text", "")
	return ""
