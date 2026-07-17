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
- [ ] M3 Levels 2 & 3
- [ ] M4 Level 4
- [ ] M5 Level 5 + ending
- [ ] M6 Polish & release

## Where I am / What's next
- DONE (M1): GameState expanded + migration-safe save/load; GameData registry; QuestManager; DialogueManager. Tested.
- DONE (M2): DialogueBox UI, level_controller + interaction router, Trail Finder/Food Sense, rotation + scent + bike-repair puzzles, Echo Park level, HUD objective, Journal (Tab), level-complete screen. Full Level 1 flow logic-tested; level scene boots headless clean.
- Game now boots title -> level.tscn (Echo Park). Legacy world.gd/world.tscn kept (still unit-tested) but no longer the main flow.
- NEXT: web export to docs/ + visual screenshot check, then M3 (Level 2 Griffith Park: trail-marker rotation, sundial, bell sequence, Bike Bell unlock).

## Key files
- scripts/game_state.gd, scripts/data/game_data.gd, scripts/quest_manager.gd, scripts/dialogue_manager.gd
- scripts/level_controller.gd (+ scenes/level.tscn), scripts/puzzles/rotation_puzzle.gd
- scripts/ui/{dialogue_box,journal,level_complete}.gd, scripts/hud.gd
- test/logic_test.gd (foundation + Level 1 flow + reachability)

## Controls
Arrows move; Space/Enter interact/advance; A Trail Finder; S Food Sense; D dismount bike; Tab/J journal; Esc pause.

Detailed live task list is in the session todos table.
