# LA Food Quest — Alp & Xiao's Top-Down LA Food Adventure

## Overview
Top-down, grid/tile-locked (Pokemon-style) adventure. Alp & Xiao explore an LA neighborhood as a
co-op duo (shared meters). A quest-giver NPC sends them to find a hidden legendary restaurant.
Eat to power up, exercise to avoid getting too full (can't eat while full), rest or collapse
(Energy 0 = stuck 24 game hours).

- Engine: Godot 4.6, GDScript, GL Compatibility renderer.
- Render: 320x180 internal, integer-scaled 4x to a 1280x720 window (crisp on a 13" MacBook Retina;
  fullscreen-friendly, nearest-neighbor filtering). Grid tile size 16px, camera-follow.

## Characters
- Both are young men of the SAME age with short hair + a central spike.
- Alp: tall lanky Turkish man (olive skin, denim jacket).
- Xiao: short Chinese man (red hoodie). Height contrast must be obvious.
- On-map: ONE combined single-tile sprite showing both; 4-direction idle/walk.
- Reference: design/reference/alp_xiao_duo_ref.png

## Core systems
- GameState autoload (scripts/game_state.gd): shared meters (power/fullness/energy), in-game clock,
  quest state, discovered restaurants, save/load. Signals: meters_changed, time_changed,
  restaurant_discovered, quest_changed, collapsed.
- Meters: Power (eat to raise; legendary unlocks at POWER_TO_WIN=100). Fullness 0-100 (eat up,
  exercise down; can't eat if > FULL_THRESHOLD=70). Energy 0-100 (rest up, time/exercise down;
  0 = 24h collapse).

## Art pipeline
- Primary: Gemini `gemini-2.5-flash-image` (fast, overworld scale, reference-image consistency).
- Hero art only (optional): OpenAI `gpt-image-1` (native transparent bg).
- SECURITY: the OpenAI API key must NEVER be committed/pushed. Load from a gitignored/untracked env
  only (.env is gitignored). Same rule as Iron Wake's ElevenLabs key.
- Godot reimports assets only when the editor opens; after adding art, open the editor or clear
  .godot/imported/.

## Commands
- Run: `godot --path ~/la-food-quest`
- Editor (triggers reimport): `godot --editor --path ~/la-food-quest`
- Headless smoke test: `godot --headless --path ~/la-food-quest --quit`

## Git identity
Personal project — commit as: Alex Selig <alexselig@Alexs-MacBook-Pro.local> (set as local git config).
