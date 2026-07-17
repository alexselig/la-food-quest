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
- [x] M3 Levels 2 (Griffith) & 3 (Koreatown)
- [ ] M4 Level 4 (Santa Monica / Venice)
- [ ] M5 Level 5 (Downtown) + ending
- [ ] M6 Polish & release

## Where I am / What's next
- DONE M1: data-driven foundation (GameState, GameData, Quest/Dialogue managers). Tested.
- DONE M2: Level 1 Echo Park (scent + lake-map puzzles, park, bike unlock). Tested + web-verified.
- DONE M3: Level 2 Griffith (trail markers, sundial, bell rhythm; Bike Bell) + Level 3 Koreatown
  (neon lights-out circuit, ingredient collection + Chef Mina, tabletop cooking rhythm, dance
  circle; Cooler Basket). Level-to-level transitions. Full flows logic-tested; puzzle UI web-verified.
- Puzzle types so far: scent-select, rotation (lake map/trail markers/sundial), rhythm
  (bells/cooking), lights-out circuit, item-collection.
- Abilities: trail_finder, food_sense (start); tandem_bike (L1); bike_bell (L2); cooler_basket (L3).
- NEXT: M4 Level 4 Santa Monica/Venice - wind/umbrella maze, seagull diversion (bike bell),
  timed tandem delivery (cooler cargo), beach rings, Portable Grill. Then M5 Downtown finale, M6 polish.
  Consider: reduce puzzle sameness (add a genuinely new mechanic for L4 wind), and an art/audio pass.

## Key files
- scripts/game_state.gd, scripts/data/game_data.gd (all level content), scripts/quest_manager.gd, scripts/dialogue_manager.gd
- scripts/level_controller.gd (+ scenes/level.tscn)
- scripts/puzzles/{rotation_puzzle,rhythm_puzzle,circuit_puzzle}.gd
- scripts/ui/{dialogue_box,journal,level_complete}.gd, scripts/hud.gd
- test/logic_test.gd (foundation + L1/L2/L3 flows + circuit logic + reachability)

## Notes
- Keep world tiles/objects readable; UI text is ASCII where it uses the world font.
- UI HANDOFF implemented (LA Food Quest UI Handoff): HUD/dialogue/toast/legendary on
  high-res CanvasLayers (1280x720 ref, scaled to counter 320x180 stretch) so text is crisp.
  Palette + Silkscreen/Press Start 2P fonts + exported bar/legendary textures in scripts/ui/ui_kit.gd.
  Provided assets in assets/ui (bar_fill_*, bar_track, legendary_bg) + assets/fonts.
- Distinct NPC sprites generated via Gemini in assets/npcs/<id>.png (remy/nia/mara/sol/ori/han/mina);
  regenerate with `python3 tools/gen_npcs.py [ids|env]` (GEMINI_API_KEY from gitignored .env; never commit it).
- Renderer: characters drawn at fixed CHAR_H (consistent scale), buildings bottom-aligned + shadows,
  y-sorted, procedural water/sign/item/puzzle/gate/park + path layer.
- After adding raw assets, run `godot --headless --import` so they're bundled in the web export.

## Controls
Arrows move; Space/Enter interact/advance; A Trail Finder; S Food Sense; D dismount bike; Tab/J journal; Esc pause.

Detailed live task list is in the session todos table.
