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
	"sol": {"name": "Ranger Sol", "color": Color(0.55, 0.75, 0.45)},
	"ori": {"name": "Chef Ori", "color": Color(0.85, 0.6, 0.45)},
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
	"observatory_cafe": {
		"display_name": "Observatory Picnic Café",
		"neighborhood": "Los Feliz",
		"signature_dish": "Trail Mix Toast",
		"power": 20, "fullness": 32.0, "energy": 8.0, "minutes": 30,
		"open_minute": 360, "close_minute": 1380,
		"first_visit_dialogue": "L2_CAFE_ARRIVAL",
		"meal_dialogue": "L2_CAFE_MEAL",
		"repeat_dialogue": "",
		"food_dex_description": "Citrus ricotta, dates, toasted seeds, sea salt. The view gets people here; the toast brings them back.",
		"sprite": "diner",
	},
	"ember_table": {
		"display_name": "Ember Table BBQ",
		"neighborhood": "Koreatown",
		"signature_dish": "Mushroom Lettuce Wrap Feast",
		"power": 25, "fullness": 42.0, "energy": 0.0, "minutes": 45,
		"open_minute": 360, "close_minute": 1380,
		"first_visit_dialogue": "L3_EMBER_ARRIVAL",
		"meal_dialogue": "L3_EMBER_MEAL",
		"repeat_dialogue": "",
		"food_dex_description": "Crispy edge, soft center, cold leaf. Contrast is edible architecture.",
		"sprite": "dumpling",
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
		"paths": [[2, 7, 28, 1], [8, 7, 1, 10], [9, 8, 15, 1], [9, 15, 15, 1], [9, 8, 1, 8], [23, 8, 1, 8]],
		"obstacles": [
			{"id": "fill_apartment_a", "rect": [10, 5, 2, 2]},
			{"id": "fill_shop_a", "rect": [14, 5, 2, 2]},
			{"id": "fill_office", "rect": [24, 6, 2, 2]},
			{"id": "fill_house", "rect": [3, 12, 2, 2]},
			{"id": "tree", "rect": [5, 3, 1, 1]},
			{"id": "tree", "rect": [30, 4, 1, 1]},
			{"id": "tree", "rect": [2, 19, 1, 1]},
			{"id": "tree", "rect": [31, 18, 1, 1]},
			{"id": "tree", "rect": [26, 18, 1, 1]},
			{"id": "lotus", "rect": [13, 10, 1, 1]},
			{"id": "lotus", "rect": [17, 12, 1, 1]},
			{"id": "lotus", "rect": [20, 11, 1, 1]},
			{"id": "bridge", "rect": [10, 12, 3, 3]},
			{"id": "boathouse", "rect": [14, 12, 3, 3]},
			{"id": "shed", "rect": [27, 10, 2, 2]},
			{"id": "fountain", "rect": [19, 17, 2, 2]},
		],
		"objects": [
			{"type": "rest_point", "id": "home", "name": "Apartment", "rect": [2, 2, 3, 2], "mode": "home", "sprite": "home"},
			{"type": "npc", "id": "remy", "name": "Remy the Critic", "cell": [7, 3], "dialogue": "L1_MEET_REMY", "starts_quest": "L1_MAIN", "sprite": "npc"},
			{"type": "sign", "id": "sign_noodles", "name": "\"Famous Noodles\" sign", "cell": [10, 3], "scent": "fake", "dialogue": "L1_FAKE_SCENT_NOODLES"},
			{"type": "sign", "id": "sign_dumplings", "name": "\"Secret Dumplings\" poster", "cell": [14, 3], "scent": "fake", "dialogue": "L1_FAKE_SCENT_DUMPLINGS"},
			{"type": "sign", "id": "sign_alley", "name": "Unmarked alley", "cell": [18, 3], "scent": "real", "dialogue": "L1_REAL_SCENT"},
			{"type": "puzzle", "id": "lake_map", "name": "Broken Lake Map", "cell": [7, 8], "kind": "rotation", "target": [1, 2, 0, 3], "labels": ["Lotus", "Fountain", "Bridge", "Boathouse"], "title": "Broken Lake Map", "solved_dialogue": "L1_MAP_SOLVED"},
			{"type": "restaurant", "id": "sunset_noodle", "name": "Sunset Noodle Window", "rect": [28, 3, 2, 2], "require_flag": "scent_solved", "locked_hint": "The window stays hidden. Follow the real aroma first.", "discover_step": "find_restaurant", "eat_step": "eat_noodles"},
			{"type": "park_activity", "id": "echo_loop", "name": "Echo Park Loop", "cell": [6, 17], "fullness": 35.0, "energy": 18.0, "mins": 45, "recipe": "chili_crisp_noodles", "step": "park_loop"},
			{"type": "item", "id": "chain_pin", "name": "Chain Pin", "cell": [12, 18], "hint": "from the bridge"},
			{"type": "item", "id": "oil", "name": "Oil Can", "cell": [26, 11], "hint": "from the maintenance shed"},
			{"type": "item", "id": "bell_screw", "name": "Bell Screw", "cell": [30, 15], "hint": "near the bike rack"},
			{"type": "mechanic", "id": "nia", "name": "Nia (boathouse)", "rect": [16, 17, 2, 2], "sprite": "npc", "needs": ["chain_pin", "oil", "bell_screw"], "grants_ability": "tandem_bike", "dialogue": "L1_MEET_NIA", "unlock_dialogue": "L1_BIKE_UNLOCK", "need_msg": "Nia needs the chain pin, oil, and bell screw.", "done_msg": "Nia: The tandem's all yours - hop on at the bike rack."},
			{"type": "bike_rack", "id": "bike_rack", "name": "Bike Rack", "cell": [30, 16]},
			{"type": "rest_point", "id": "bench", "name": "Lake Bench", "cell": [4, 9], "mode": "bench", "energy": 25.0, "mins": 90, "sprite": "bench"},
			{"type": "exit", "id": "silver_lake_exit", "name": "Silver Lake Gate", "cell": [32, 10], "target_level": "griffith", "target_spawn": "from_echo"},
		],
	},
	"griffith": {
		"display_name": "Griffith Park & Los Feliz",
		"cols": 40, "rows": 24,
		"ground": "grass",
		"next_level_id": "koreatown",
		"stamp": "griffith_star",
		"ability_unlock": "bike_bell",
		"bonus_power": 5,
		"completion_quest_id": "L2_MAIN",
		"opening_dialogue": "L2_OPENING",
		"spawns": {"start": [4, 4], "from_echo": [4, 4]},
		"water": [],
		"paths": [[3, 6, 34, 1], [8, 6, 1, 15], [8, 20, 30, 1]],
		"obstacles": [
			{"id": "fill_office", "rect": [29, 3, 2, 2]},
			{"id": "fill_house", "rect": [14, 9, 2, 2]},
			{"id": "fill_shop_b", "rect": [22, 14, 2, 2]},
			{"id": "tree", "rect": [3, 3, 1, 1]},
			{"id": "tree", "rect": [37, 3, 1, 1]},
			{"id": "tree", "rect": [2, 21, 1, 1]},
			{"id": "tree", "rect": [37, 20, 1, 1]},
			{"id": "tree", "rect": [34, 17, 1, 1]},
			{"id": "tree", "rect": [17, 21, 1, 1]},
			{"id": "tree", "rect": [25, 8, 1, 1]},
		],
		"objects": [
			{"type": "npc", "id": "sol", "name": "Ranger Sol", "cell": [8, 4], "dialogue": "L2_MEET_RANGER", "starts_quest": "L2_MAIN", "sprite": "npc"},
			{"type": "puzzle", "id": "trail_markers", "name": "Rotated Trail Markers", "cell": [12, 6], "kind": "rotation", "target": [2, 1, 3, 0], "labels": ["Creek", "Observ.", "Overlook", "Fork"], "title": "Rotate the Trail Signs", "solved_dialogue": "L2_TRAIL_MARKERS_SOLVED"},
			{"type": "puzzle", "id": "shadow_dial", "name": "Observatory Shadow Dial", "cell": [20, 9], "kind": "rotation", "target": [3, 1, 2, 0], "labels": ["Owl", "Rabbit", "Bear", "Coyote"], "title": "Observatory Shadow Dial", "solved_dialogue": "L2_SUNDIAL_SOLVED"},
			{"type": "puzzle", "id": "trail_bells", "name": "Trail Bells", "cell": [27, 11], "kind": "rhythm", "target": ["low", "low", "high"], "title": "Ring the bells: short, short, long", "solved_dialogue": "L2_BELLS_SOLVED"},
			{"type": "restaurant", "id": "observatory_cafe", "name": "Observatory Picnic Café", "rect": [33, 5, 2, 2], "require_flag": "overlook_found", "locked_hint": "The overlook is still hidden. Ring the trail bells first.", "discover_step": "find_cafe", "eat_step": "eat_toast"},
			{"type": "park_activity", "id": "hill_intervals", "name": "Griffith Hill Intervals", "cell": [10, 18], "fullness": 40.0, "energy": 24.0, "mins": 60, "recipe": "trail_mix_toast", "step": "hill_intervals", "grants_ability": "bike_bell", "unlock_dialogue": "L2_BELL_UNLOCK"},
			{"type": "rest_point", "id": "bench2", "name": "Trail Bench", "cell": [6, 11], "mode": "bench", "energy": 25.0, "mins": 90, "sprite": "bench"},
			{"type": "bike_rack", "id": "bike_rack2", "name": "Bike Rack", "cell": [5, 6]},
			{"type": "exit", "id": "los_feliz_exit", "name": "Los Feliz Gate", "cell": [38, 12], "target_level": "koreatown", "target_spawn": "from_griffith", "require_ability": "bike_bell"},
		],
	},
	"koreatown": {
		"display_name": "Koreatown",
		"cols": 40, "rows": 24,
		"ground": "grass",
		"next_level_id": "santa_monica",
		"stamp": "koreatown_grill",
		"ability_unlock": "cooler_basket",
		"bonus_power": 5,
		"completion_quest_id": "L3_MAIN",
		"opening_dialogue": "L3_OPENING",
		"spawns": {"start": [4, 4], "from_griffith": [4, 4]},
		"water": [],
		"paths": [[3, 6, 34, 1], [8, 6, 1, 15], [8, 20, 30, 1]],
		"obstacles": [
			{"id": "fill_shop_a", "rect": [14, 4, 2, 2]},
			{"id": "fill_shop_b", "rect": [30, 8, 2, 2]},
			{"id": "fill_office", "rect": [20, 15, 2, 2]},
			{"id": "tree", "rect": [3, 21, 1, 1]},
			{"id": "tree", "rect": [37, 21, 1, 1]},
			{"id": "tree", "rect": [6, 20, 1, 1]},
			{"id": "tree", "rect": [14, 20, 1, 1]},
			{"id": "tree", "rect": [37, 3, 1, 1]},
		],
		"objects": [
			{"type": "npc", "id": "han", "name": "Mrs. Han", "cell": [8, 4], "dialogue": "L3_MEET_HAN", "starts_quest": "L3_MAIN", "sprite": "npc"},
			{"type": "puzzle", "id": "neon_circuit", "name": "Neon Relay Board", "cell": [12, 6], "kind": "circuit", "count": 5, "scramble": [1, 3], "labels": ["Source", "Ember", "Karaoke", "Dessert", "Relay"], "title": "Neon Circuit: light every relay", "solved_dialogue": "L3_CIRCUIT_SOLVED"},
			{"type": "item", "id": "perilla", "name": "Perilla Leaf", "cell": [16, 8], "hint": "(ingredient)"},
			{"type": "item", "id": "king_oyster", "name": "King Oyster Mushroom", "cell": [20, 6], "hint": "(ingredient)"},
			{"type": "item", "id": "garlic", "name": "Garlic", "cell": [24, 8], "hint": "(ingredient)"},
			{"type": "item", "id": "pear_marinade", "name": "Pear Marinade", "cell": [28, 6], "hint": "(ingredient)"},
			{"type": "item", "id": "decoy_kimchi", "name": "Extra Kimchi", "cell": [18, 10], "hint": "(a decoy)"},
			{"type": "item", "id": "decoy_tofu", "name": "Soft Tofu", "cell": [26, 10], "hint": "(a decoy)"},
			{"type": "mechanic", "id": "mina", "name": "Chef Mina", "cell": [22, 12], "sprite": "npc", "needs": ["perilla", "king_oyster", "garlic", "pear_marinade"], "set_flag": "ingredients_ready", "complete_step": "gather_ingredients", "dialogue": "L3_MEET_MINA", "unlock_dialogue": "L3_INGREDIENTS_READY", "need_msg": "Chef Mina needs perilla, king oyster mushroom, garlic, and pear marinade.", "done_msg": "Chef Mina: Perfect. Fire up the tabletop grill."},
			{"type": "puzzle", "id": "cooking", "name": "Tabletop Grill", "cell": [27, 14], "kind": "rhythm", "target": ["preheat", "place", "flip", "assemble"], "keys": {"49": "preheat", "50": "place", "51": "flip", "52": "assemble"}, "symbols": {"preheat": "1-PRE", "place": "2-PLACE", "flip": "3-FLIP", "assemble": "4-WRAP"}, "title": "Tabletop Grill: preheat, place, flip, wrap", "prompt": "Press 1, 2, 3, 4 in order", "require_flag": "ingredients_ready", "locked_hint": "Bring Chef Mina the ingredients first.", "solved_dialogue": "L3_COOK_DONE"},
			{"type": "restaurant", "id": "ember_table", "name": "Ember Table BBQ", "rect": [32, 5, 2, 2], "require_flag": "wrap_cooked", "locked_hint": "The grill's cold. Cook the wrap first.", "discover_step": "", "eat_step": "eat_wrap"},
			{"type": "park_activity", "id": "dance_circle", "name": "Seoul Park Dance Circle", "cell": [10, 18], "fullness": 45.0, "energy": 22.0, "mins": 45, "recipe": "tabletop_mushroom_wrap", "step": "dance_circle", "grants_ability": "cooler_basket", "unlock_dialogue": "L3_COOLER_UNLOCK"},
			{"type": "rest_point", "id": "bench3", "name": "K-town Bench", "cell": [6, 11], "mode": "bench", "energy": 25.0, "mins": 90, "sprite": "bench"},
			{"type": "bike_rack", "id": "bike_rack3", "name": "Bike Rack", "cell": [5, 6]},
			{"type": "exit", "id": "ktown_exit", "name": "Eastern Gate", "cell": [38, 12], "target_level": "santa_monica", "target_spawn": "from_koreatown", "require_ability": "cooler_basket"},
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
	"L2_MAIN": {
		"title": "Where the City Looks Small",
		"level_id": "griffith",
		"steps": [
			{"id": "meet_ranger", "text": "Talk to Ranger Sol at the entrance."},
			{"id": "fix_trail_markers", "text": "Fix the rotated trail markers (Trail Finder, A)."},
			{"id": "solve_sundial", "text": "Solve the observatory shadow dial."},
			{"id": "ring_bells", "text": "Ring the trail bells: short, short, long."},
			{"id": "find_cafe", "text": "Find the Observatory Picnic Café."},
			{"id": "eat_toast", "text": "Eat the Trail Mix Toast."},
			{"id": "hill_intervals", "text": "Run the hill intervals to earn the Bike Bell."},
			{"id": "reach_exit", "text": "Ring the bell and ride to the Los Feliz exit."},
		],
	},
	"L3_MAIN": {
		"title": "The Table That's Hottest When the Lights Go Out",
		"level_id": "koreatown",
		"steps": [
			{"id": "meet_han", "text": "Talk to Mrs. Han at the market."},
			{"id": "fix_circuit", "text": "Fix the neon relay board (light every relay)."},
			{"id": "gather_ingredients", "text": "Gather 4 ingredients for Chef Mina (Food Sense, S)."},
			{"id": "cook_wrap", "text": "Cook the wrap on the tabletop grill."},
			{"id": "eat_wrap", "text": "Eat the Mushroom Lettuce Wrap at Ember Table."},
			{"id": "dance_circle", "text": "Join the Seoul Park dance circle (earns Cooler Basket)."},
			{"id": "reach_exit", "text": "Take the chilled dessert out the eastern gate."},
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
	# Level 2
	"L2_OPENING": {"start": "a", "nodes": {
		"a": {"speaker": "narrator", "text": "Remy's second clue: \"Eat where the city looks small and the appetite looks enormous.\"", "next": "b"},
		"b": {"speaker": "xiao", "text": "The observatory. Obviously.", "next": "c"},
		"c": {"speaker": "alp", "text": "It says where, not inside. Try to contain yourself.", "next": ""},
	}},
	"L2_MEET_RANGER": {"start": "a", "nodes": {
		"a": {"speaker": "sol", "text": "Wind spun the trail signs around. Half the park is walking in circles.", "next": "b"},
		"b": {"speaker": "sol", "text": "Set them right with your eye for routes, and the overlook opens up.", "next": "c"},
		"c": {"speaker": "alp", "text": "Finally. A problem with a correct answer.", "complete_step": "meet_ranger", "next": ""},
	}},
	"L2_TRAIL_MARKERS_SOLVED": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Couldn't we just follow someone confident?", "next": "b"},
		"b": {"speaker": "alp", "text": "Confidence is how these signs got rotated.", "complete_step": "fix_trail_markers", "next": ""},
	}},
	"L2_SUNDIAL_SOLVED": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "We moved four stone animals and opened a café.", "next": "b"},
		"b": {"speaker": "alp", "text": "Urban planning used to be more ambitious.", "complete_step": "solve_sundial", "next": ""},
	}},
	"L2_BELLS_SOLVED": {"start": "a", "nodes": {
		"a": {"speaker": "sol", "text": "Short, short, long. There it is - the overlook trail opens.", "next": "b"},
		"b": {"speaker": "xiao", "text": "Three for snacks?", "next": "c"},
		"c": {"speaker": "alp", "text": "There is no snack protocol.", "set_flags": ["overlook_found"], "complete_step": "ring_bells", "next": ""},
	}},
	"L2_CAFE_ARRIVAL": {"start": "a", "nodes": {
		"a": {"speaker": "ori", "text": "The view gets people here. The toast brings them back.", "next": "b"},
		"b": {"speaker": "xiao", "text": "I came for the toast.", "next": "c"},
		"c": {"speaker": "alp", "text": "He did not know it existed.", "next": ""},
	}},
	"L2_CAFE_MEAL": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "You really do like knowing where we are.", "next": "b"},
		"b": {"speaker": "alp", "text": "It helps.", "next": "c"},
		"c": {"speaker": "xiao", "text": "I like not knowing yet.", "next": "d"},
		"d": {"speaker": "alp", "text": "That also seems to help.", "next": ""},
	}},
	"L2_BELL_UNLOCK": {"start": "a", "nodes": {
		"a": {"speaker": "sol", "text": "One ring for passing. Two for danger. Take the bell.", "next": "b"},
		"b": {"speaker": "xiao", "text": "Three for snacks.", "next": "c"},
		"c": {"speaker": "alp", "text": "He will not let this go.", "next": ""},
	}},
	"L2_COMPLETE": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Two stamps. We're basically locals.", "next": "b"},
		"b": {"speaker": "alp", "text": "Koreatown next. Bring your appetite and your patience.", "next": ""},
	}},
	# Level 3
	"L3_OPENING": {"start": "a", "nodes": {
		"a": {"speaker": "narrator", "text": "Koreatown. Third clue: \"Find the table that is hottest when every light goes out.\"", "next": "b"},
		"b": {"speaker": "xiao", "text": "A rolling blackout. Half the signs are dark.", "next": "c"},
		"c": {"speaker": "alp", "text": "So we find the one that still cooks. Efficient.", "next": ""},
	}},
	"L3_MEET_HAN": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "Three neon relays failed. Ember Table can't vent its grill without power.", "next": "b"},
		"b": {"speaker": "han", "text": "Light the whole board and the block comes back.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Dinner via municipal infrastructure. My favorite.", "complete_step": "meet_han", "next": ""},
	}},
	"L3_CIRCUIT_SOLVED": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "The whole block is glowing.", "next": "b"},
		"b": {"speaker": "alp", "text": "We repaired municipal infrastructure for dinner.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Finally, a reasonable reservation policy.", "set_flags": ["power_restored"], "complete_step": "fix_circuit", "next": ""},
	}},
	"L3_MEET_MINA": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "Chef Mina needs perilla, king oyster mushroom, garlic, and pear marinade.", "next": "b"},
		"b": {"speaker": "han", "text": "The right leaf smells sharp before it tastes sweet. Use your nose.", "next": ""},
	}},
	"L3_INGREDIENTS_READY": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "Good haul. The tabletop grill is yours - preheat, place, flip, wrap.", "next": ""},
	}},
	"L3_COOK_DONE": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "Crispy edge, soft center. That's the one.", "set_flags": ["wrap_cooked"], "complete_step": "cook_wrap", "next": ""},
	}},
	"L3_EMBER_ARRIVAL": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "A table is ready when you are ready to pay attention.", "next": "b"},
		"b": {"speaker": "xiao", "text": "I have never been more attentive.", "next": "c"},
		"c": {"speaker": "alp", "text": "He ignored three traffic lights to get here.", "next": ""},
	}},
	"L3_EMBER_MEAL": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Crispy edge, soft center, cold leaf.", "next": "b"},
		"b": {"speaker": "alp", "text": "You sound surprised by temperature.", "next": "c"},
		"c": {"speaker": "xiao", "text": "Contrast is edible architecture.", "next": ""},
	}},
	"L3_COOLER_UNLOCK": {"start": "a", "nodes": {
		"a": {"speaker": "han", "text": "Take this insulated basket. Keep the lid closed.", "next": "b"},
		"b": {"speaker": "xiao", "text": "Even if I need to inspect it?", "next": "c"},
		"c": {"speaker": "alp", "text": "Especially then. I understand the assignment.", "next": ""},
	}},
	"L3_COMPLETE": {"start": "a", "nodes": {
		"a": {"speaker": "xiao", "text": "Three down. The dessert's still cold.", "next": "b"},
		"b": {"speaker": "alp", "text": "To the coast. Try not to interpret the next clue as tacos.", "next": ""},
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
