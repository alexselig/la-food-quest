extends SceneTree
const GameStateScript := preload("res://scripts/game_state.gd")
const GameDataScript := preload("res://scripts/data/game_data.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const DialogueManagerScript := preload("res://scripts/dialogue_manager.gd")
const LevelControllerScript := preload("res://scripts/level_controller.gd")
func _initialize() -> void:
	var GSl = GameStateScript.new()
	var DataL = GameDataScript.new()
	var QML = QuestManagerScript.new(); QML.gs = GSl; QML.data = DataL
	var DML = DialogueManagerScript.new(); DML.gs = GSl; DML.data = DataL; DML.quests = QML
	var LC = LevelControllerScript.new(); LC.gs = GSl; LC.data = DataL; LC.quests = QML; LC.dlg = DML
	LC.build_from_data("echo_park")
	LC.interact_at(Vector2i(7,3))
	var n := 0
	while DML.is_active() and n < 30: DML.advance(); n += 1
	LC.free(); GSl.free(); DataL.free(); QML.free(); DML.free()
	print("probe done")
	quit(0)
