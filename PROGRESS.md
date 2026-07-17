# LA Food Quest — Build Progress

Tracking the expansion from prototype → 5-level game per
`LA_Food_Quest_Gameplay_and_Implementation_Spec.md`.

## Verify commands
- Smoke: `godot --headless --path . --quit`
- Logic tests: `godot --headless --path . -s res://test/logic_test.gd`
- Web export (deploy): `godot --headless --path . --export-release "Web" docs/index.html`

## Architecture (target)
- `GameState` (autoload): all persistent state + meters/clock + save/load (migration-safe).
- `GameData` (autoload): data-driven content registry (restaurants, recipes, levels, dialogues, quests).
- `QuestManager` (autoload): quest state machine + steps + flags.
- `DialogueManager` (autoload): runs dialogue graphs, sets flags, choices.
- `level_controller.gd`: builds a level from data, interaction router, transitions.
- Puzzles under `scripts/puzzles/` with testable solve logic + procedural visuals.

## Milestones
- [x] M1 Architecture refactor (data-driven systems)
- [x] M2 Level 1 Echo Park vertical slice
- [~] M3 Levels 2 & 3  (Level 2 Griffith DONE; Level 3 Koreatown pending)
- [ ] M4 Level 4
- [ ] M5 Level 5 + ending
- [ ] M6 Polish & release

## Where I am / What's next
- DONE (M1): data-driven foundation (GameState, GameData, Quest/Dialogue managers). Tested.
- DONE (M2): Level 1 Echo Park slice (scent + lake-map puzzles, park, bike unlock, stamp). Tested + web-verified.
- DONE (Level 2 Griffith): level-to-level transitions; RhythmPuzzle (bell seq) + generalized RotationPuzzle (labels/target) reused for trail markers + sundial; Observatory Café; Hill Intervals grants Bike Bell; exit needs Bike Bell; Griffith Star stamp -> unlocks Koreatown. Full L2 flow logic-tested; puzzle UI web-verified.
- FIXED: Godot default font can't show Unicode arrows/symbols -> switched all UI to ASCII (rotation nodes show N/E/S/W). Important: keep UI text ASCII-only.
- NEXT: Level 3 Koreatown (neon circuit puzzle, ingredient ID, tabletop cooking timing, dance-circle rhythm, Cooler Basket). Then L4, L5, polish.

## Key files
- scripts/game_state.gd, scripts/data/game_data.gd, scripts/quest_manager.gd, scripts/dialogue_manager.gd
- scripts/level_controller.gd (+ scenes/level.tscn)
- scripts/puzzles/{rotation_puzzle,rhythm_puzzle}.gd
- scripts/ui/{dialogue_box,journal,level_complete}.gd, scripts/hud.gd
- test/logic_test.gd (foundation + L1 + L2 flows + reachability)

## Controls
Arrows move; Space/Enter interact/advance; A Trail Finder; S Food Sense; D dismount bike; Tab/J journal; Esc pause.

Detailed live task list is in the session todos table.
