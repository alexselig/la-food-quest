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
- [ ] M1 Architecture refactor (data-driven systems)
- [ ] M2 Level 1 Echo Park vertical slice
- [ ] M3 Levels 2 & 3
- [ ] M4 Level 4
- [ ] M5 Level 5 + ending
- [ ] M6 Polish & release

## Where I am / What's next
- DONE (M1): GameState expanded (abilities/inventory/fooddex/recipes/stamps/flags/puzzle_states/levels + migration-safe save/load); GameData registry (Level 1 content, dialogues, quest); QuestManager; DialogueManager. All logic tests pass.
- NEXT (M2): DialogueBox UI, level_controller + interaction router, Trail Finder/Food Sense abilities, Level 1 puzzles (scent, lake-map rotation, bike repair), wire Echo Park level, HUD/quest-log/FoodDex panels, Level 1 flow tests, web export + commit.

Detailed live task list is in the session todos table.
