extends Node
## DialogueManager: runs a dialogue graph from GameData (spec 18.5). Sequential lines,
## flag setting, and quest-step completion as nodes are entered. Emits signals a
## DialogueBox UI renders. While active, player movement/interaction is locked.

signal line_shown(speaker_id, text)
signal dialogue_finished(dialogue_id)

var gs: Node          # injectable for headless tests
var data: Node
var quests: Node

var _active := false
var _graph: Dictionary = {}
var _node_id := ""
var _id := ""

func _ready() -> void:
	gs = get_node_or_null("/root/GameState")
	data = get_node_or_null("/root/GameData")
	quests = get_node_or_null("/root/QuestManager")

func _gs() -> Node:
	return gs if gs != null else get_node_or_null("/root/GameState")

func _data() -> Node:
	return data if data != null else get_node_or_null("/root/GameData")

func _quests() -> Node:
	return quests if quests != null else get_node_or_null("/root/QuestManager")

func is_active() -> bool:
	return _active

func current_speaker() -> String:
	return String(_graph.get("nodes", {}).get(_node_id, {}).get("speaker", ""))

func current_text() -> String:
	return String(_graph.get("nodes", {}).get(_node_id, {}).get("text", ""))

func start(dialogue_id: String) -> bool:
	var d := _data()
	if d == null:
		return false
	var g: Dictionary = d.get_dialogue(dialogue_id)
	if g.is_empty():
		return false
	_graph = g
	_id = dialogue_id
	_node_id = String(g.get("start", ""))
	_active = true
	_enter_node()
	return true

func advance() -> void:
	if not _active:
		return
	var node: Dictionary = _graph.get("nodes", {}).get(_node_id, {})
	var nxt := String(node.get("next", ""))
	if nxt == "" or not _graph.get("nodes", {}).has(nxt):
		finish()
		return
	_node_id = nxt
	_enter_node()

func finish() -> void:
	if not _active:
		return
	_active = false
	var g := _gs()
	if g != null:
		g.set_dialogue_played(_id)
	dialogue_finished.emit(_id)

func _enter_node() -> void:
	if not _graph.get("nodes", {}).has(_node_id):
		finish()
		return
	var node: Dictionary = _graph["nodes"][_node_id]
	_apply_effects(node)
	line_shown.emit(String(node.get("speaker", "")), String(node.get("text", "")))

func _apply_effects(node: Dictionary) -> void:
	var g := _gs()
	if g != null:
		for flag in node.get("set_flags", []):
			g.set_flag(String(flag))
	if node.has("complete_step"):
		var qm := _quests()
		if qm != null:
			qm.note_step(String(node["complete_step"]))
