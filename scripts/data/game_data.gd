extends Node
## GameData: data-driven content registry (spec 18.3-18.6).
## Content (restaurants, recipes, stamps, levels, dialogues, quests) lives here as
## plain data, separated from logic. Managers/level_controller read from it.

# --- Speakers (dialogue portraits are name + color for now) ---
const SPEAKERS := {
	"alp": {"name": "Alp", "color": Color(0.78, 0.80, 0.88)},
	"xiao": {"name": "Xiao", "color": Color(0.92, 0.38, 0.32)},
	"remy": {"name": "Remy the Critic", "color": Color(0.93, 0.76, 0.32)},
	"mara": {"name": "Vendor Mara", "color": Color(0.42, 0.82, 0.72)},
	"nia": {"name": "Nia", "color": Color(0.45, 0.80, 0.42)},
	"narrator": {"name": "", "color": Color(1, 1, 1)},
}

# --- Recipes (spec 9.3) ---
const RECIPES := {
	"chili_crisp_noodles": "Chili Crisp Noodles",
	"trail_mix_toast": "Trail Mix Toast",
	"tabletop_mushroom_wrap": "Tabletop Mushroom Wrap",
	"pier_citrus_tacos": "Pier Citrus Tacos",
	"golden_broth": "Golden Broth",
}

# --- Neighborhood stamps (spec 9.2) ---
const STAMPS := {
	"echo_park_lotus": "Echo Park Lotus",
	"griffith_star": "Griffith Star",
	"koreatown_grill": "Koreatown Grill",
	"santa_monica_wave": "Santa Monica Wave",
	"downtown_golden_fork": "Downtown Golden Fork",
}

# --- Restaurants (spec 18.4 / 25.1) ---
const RESTAURANTS := {
	"sunset_noodle": {
		"display_name": "Sunset Noodle Window",
		"neighborhood": "Echo Park",
		"signature_dish": "Chili Crisp Noodles",
		"power": 20, "fullness": 38.0, "energy": 0.0, "minutes": 30,
		"open_minute": 360, "close_minute": 1380,
		"first_visit_dialogue": "L1_RESTAURANT_ARRIVAL",
		"meal_dialogue": "L1_RESTAURANT_MEAL",
		"repeat_dialogue": "",
		"food_dex_description": "A windowless window. Toasted pepper, scallion, chili crisp. No sign, no address, all credibility.",
		"sprite": "ramen",
	},
}

# --- Levels ---
# Objects use "cell":[x,y] (1x1) or "rect":[x,y,w,h]. Coordinates are grid cells.
const LEVELS := {
	"echo_park": {
		"display_name": "Echo Park & Silver Lake",
		"cols": 34, "rows": 22,
		"ground": "grass",
		"next_level_id": "griffith",
		"stamp": "echo_park_lotus",
		"ability_unlock": "tandem_bike",
		"bonus_power": 5,
		"completion_quest_id": "L1_MAIN",
		"opening_dialogue": "L1_OPENING",
		"spawns": {"start": [3, 5], "from_griffith": [31, 10]},
		"water": [[10, 9, 13, 6]],
		"obstacles": [
			{"id": "fill_apartment_a", "rect": [10, 5, 2, 2]},
			{"id": "fill_shop_a", "rect": [14, 5, 2, 2]},
			{"id": "fill_office", "rect": [24, 6, 2, 2]},
			{"id": "fill_house", "rect": [3, 12, 2, 2]},
		],
		"objects": [
			{"type": "rest_point", "id": "home", "name": "Apartment", "rect": [2, 2, 3, 2], "mode": "home", "sprite": "home"},
			{"type": "npc", "id": "remy", "name": "Remy the Critic", "cell": [7, 3], "dialogue": "L1_MEET_REMY", "starts_quest": "L1_MAIN", "sprite": "npc"},
			{"type": "sign", "id": "sign_noodles", "name": "\"Famous Noodles\" sign", "cell": [10, 3], "scent": "fake", "dialogue": "L1_FAKE_SCENT_NOODLES"},
			{"type": "sign", "id": "sign_dumplings", "name": "\"Secret Dumplings\" poster", "cell": [14, 3], "scent": "fake", "dialogue": "L1_FAKE_SCENT_DUMPLINGS"},
			{"type": "sign", "id": "sign_alley", "name": "Unmarked alley", "cell": [18, 3], "scent": "real", "dialogue": "L1_REAL_SCENT"},
			{"type": "puzzle", "id": "lake_map", "name": "Broken Lake Map", "cell": [7, 8], "kind": "rotation"},
			{"type": "restaurant", "id": "sunset_noodle", "name": "Sunset Noodle Window", "rect": [28, 3, 2, 2], "require_flag": "scent_solved"},
			{"type": "park_activity", "id": "echo_loop", "name": "Echo Park Loop", "cell": [6, 17], "fullness": 35.0, "energy": 18.0, "mins": 45, "recipe": "chili_crisp_noodles", "step": "park_loop"},
			{"type": "item", "id": "chain_pin", "name": "Chain Pin", "cell": [12, 18], "hint": "from the bridge"},
			{"type": "item", "id": "oil", "name": "Oil Can", "cell": [26, 11], "hint": "from the maintenance shed"},
			{"type": "item", "id": "bell_screw", "name": "Bell Screw", "cell": [30, 15], "hint": "near the bike rack"},
			{"type": "mechanic", "id": "nia", "name": "Nia (boathouse)", "rect": [16, 17, 2, 2], "sprite": "npc", "needs": ["chain_pin", "oil", "bell_screw"], "dialogue": "L1_MEET_NIA", "unlock_dialogue": "L1_BIKE_UNLOCK"},
			{"type": "bike_rack", "id": "bike_rack", "name": "Bike Rack", "cell": [30, 16]},
			{"type": "rest_point", "id": "bench", "name": "Lake Bench", "cell": [4, 9], "mode": "bench", "energy": 25.0, "mins": 90, "sprite": "bench"},
			{"type": "exit", "id": "silver_lake_exit", "name": "Silver Lake Gate", "cell": [32, 10], "target_level": "griffith", "target_spawn": "from_echo"},
		],
	},
}

# --- Quests (spec 10.3) ---
const QUESTS := {
	"L1_MAIN": {
		"title": "Follow the Scent",
		"level_id": "echo_park",
		"steps": [
			{"id": "meet_remy", "text": "Find Remy near the lake entrance."},
			{"id": "solve_scent", "text": "Use Food Sense (S) to find the real aroma."},
			{"id": "repair_map", "text": "Repair the broken lake map with Trail Finder (A)."},
			{"id": "find_restaurant", "text": "Discover the Sunset Noodle Window."},
			{"id": "eat_noodles", "text": "Eat the Chili Crisp Noodles."},
			{"id": "park_loop", "text": "Too full! Do a lap at Echo Park."},
			{"id": "unlock_bike", "text": "Fix Nia's tandem bike (find 3 parts)."},
			{"id": "reach_exit", "text": "Ride to the Silver Lake exit."},
		],
	},
}

# --- Dialogues (graphs). node: {speaker,text,next,set_flags?,complete_step?} ---
# "next":"" ends the dialogue.
const DIALOGUES := {
	# Global barks
	"GLOBAL_TOO_FULL_01": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "I have room.", "next": "b"},
		"b": {"speaker": "alp", "text": "Your meter is visibly red.", "next": "c"},
		"c": {"speaker": "xiao", "text": "That feels judgmental.", "next": ""},
	}},
	"GLOBAL_LOW_ENERGY_01": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "I can still smell dinner. I just can't reach it.", "next": "b"},
		"b": {"speaker": "alp", "text": "Bench first. Heroics later.", "next": ""},
	}},
	"GLOBAL_COLLAPSE_01": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Five minutes.", "next": "b"},
		"b": {"speaker": "alp", "text": "You said that yesterday.", "next": ""},
	}},
	"GLOBAL_FIRST_BIKE_MOUNT": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "I'll steer.", "next": "b"},
		"b": {"speaker": "alp", "text": "You are sitting in the back.", "next": "c"},
		"c": {"speaker": "xiao", "text": "I'll steer emotionally.", "next": "d"},
		"d": {"speaker": "alp", "text": "That explains several things.", "next": ""},
	}},
	# Level 1
	"L1_OPENING": {"start": "a", "nodes": {
		"a": {"speaker": "narrator", "text": "Echo Park. Alp & Xiao arrive with a blank list: \"Five Places Worth Crossing Town For.\"", "next": "b"},
		"b": {"speaker": "xiao", "text": "Blank. Except for a golden spoon.", "next": "c"},
		"c": {"speaker": "alp", "text": "A list that fills itself. My favorite kind of unreliable.", "next": ""},
	}},
	"L1_MEET_REMY": {"start": "a", "nodes": {
		"a": {"speaker": "remy", "text": "The Golden Ladle appears only for diners who understand this city.", "next": "b"},
		"b": {"speaker": "remy", "text": "Earn each neighborhood's trust. Start by finding what's real near the lake.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Finally, an assignment I was born for.", "set_flags": ["met_remy"], "complete_step": "meet_remy", "next": ""},
	}},
	"L1_FAKE_SCENT_NOODLES": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Strong garlic. Toasted sesame. Maybe scallion.", "next": "b"},
		"b": {"speaker": "alp", "text": "You are smelling the advertisement.", "next": "c"},
		"c": {"speaker": "xiao", "text": "It is a persuasive advertisement.", "next": ""},
	}},
	"L1_FAKE_SCENT_DUMPLINGS": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Dumplings. Definitely.", "next": "b"},
		"b": {"speaker": "alp", "text": "That is laminated paper.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Then the printer was inspired.", "next": ""},
	}},
	"L1_REAL_SCENT": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "There. Behind the jasmine.", "next": "b"},
		"b": {"speaker": "alp", "text": "No sign. No address.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Finally, credible evidence.", "set_flags": ["scent_solved"], "complete_step": "solve_scent", "next": ""},
	}},
	"L1_MAP_HINT_01": {"start": "a", "nodes": {
		"a": {"speaker": "alp", "text": "The landmarks are correct. Their directions are not.", "next": ""},
	}},
	"L1_MAP_SOLVED": {"start": "a", "nodes": {
		"a": {"speaker": "alp", "text": "Lotus, fountain, bridge, boathouse. The route is continuous.", "set_flags": ["map_solved"], "complete_step": "repair_map", "next": ""},
	}},
	"L1_RESTAURANT_ARRIVAL": {"start": "a", "nodes": {
		"a": {"speaker": "mara", "text": "You found the window. Most people find the mural and stop.", "next": "b"},
		"b": {"speaker": "xiao", "text": "The mural does not smell like toasted pepper.", "next": "c"},
		"c": {"speaker": "alp", "text": "He has a system. It is difficult to document.", "next": ""},
	}},
	"L1_RESTAURANT_MEAL": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "This is exactly what I hoped it would be.", "next": "b"},
		"b": {"speaker": "alp", "text": "You had no information.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Hope is pre-information.", "next": ""},
	}},
	"L1_TOO_FULL": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "I have become furniture.", "next": "b"},
		"b": {"speaker": "alp", "text": "Park. Now.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Roll me there.", "next": ""},
	}},
	"L1_MEET_NIA": {"start": "a", "nodes": {
		"a": {"speaker": "nia", "text": "The tandem's got a loose chain. Bring me a chain pin, oil, and a bell screw.", "next": "b"},
		"b": {"speaker": "alp", "text": "Bridge, shed, bike rack. Noted.", "next": ""},
	}},
	"L1_BIKE_UNLOCK": {"start": "a", "nodes": {
		"a": {"speaker": "nia", "text": "It seats two, corners badly, and attracts attention.", "next": "b"},
		"b": {"speaker": "xiao", "text": "Perfect.", "next": "c"},
		"c": {"speaker": "alp", "text": "None of those were endorsements.", "set_flags": ["bike_unlocked"], "complete_step": "unlock_bike", "next": ""},
	}},
	"L1_COMPLETE": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "One neighborhood down.", "next": "b"},
		"b": {"speaker": "alp", "text": "The list is filling in. Silver Lake is that way.", "next": ""},
	}},
}

# --- Lookups ---
func get_level(id: String) -> Dictionary:
	return LEVELS.get(id, {})

func has_level(id: String) -> bool:
	return LEVELS.has(id)

func get_restaurant(id: String) -> Dictionary:
	return RESTAURANTS.get(id, {})

func get_quest(id: String) -> Dictionary:
	return QUESTS.get(id, {})

func get_dialogue(id: String) -> Dictionary:
	return DIALOGUES.get(id, {})

func has_dialogue(id: String) -> bool:
	return DIALOGUES.has(id)

func recipe_name(id: String) -> String:
	return RECIPES.get(id, id)

func stamp_name(id: String) -> String:
	return STAMPS.get(id, id)

func speaker_name(id: String) -> String:
	return SPEAKERS.get(id, {}).get("name", id)

func speaker_color(id: String) -> Color:
	return SPEAKERS.get(id, {}).get("color", Color(1, 1, 1))
