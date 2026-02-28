/// @description Insert description here
// You can write your code in this editor
// === CORE STATE ===
game_state = "BOOT";  // BOOT, MENU, TOWN, TRAVEL, EVENT, etc.
day = 1;
turn = 0;

// === RNG ===
world_seed = irandom(999999);
randomize();  // We'll use GML's built-in for now

// === REFERENCES (instance IDs) ===
console = noone;  // Will store obj_console's ID
input = noone;    // Will store obj_input's ID

// === GAME DATA (we'll add these as we go) ===
player = noone;      // Will be a struct
caravan = noone;     // Will be a struct
world = noone;       // Will be a struct

// === GAME DATA ===
world = noone;  // Will hold world struct

// === COMMODITY DATABASE ===
global.commodities = scr_create_commodity_database();

// === VEHICLE & ANIMAL DATABASES ===
global.vehicles = scr_create_vehicle_database();
global.animals  = scr_create_animal_database();

// === DEBUG LOGGING ===
global.debug_log_enabled = false;  // true when actively writing to disk
global.debug_log_file    = -1;     // GML file handle; -1 = not open

// === MAP STATE ===
map_open         = false; // true while the world map overlay is visible
map_close_delay  = 0;     // countdown frames before ESC/click can close the map

// === JOURNEY TRACKING ===
journey_count = 0;    // Number of completed journeys this run

// === SETUP CONFIG (player's pre-game choices, set during SETUP state) ===
setup_config = {
    world_size:    "SMALL",    // "SMALL" (25 locs) | "MEDIUM" (40 locs) | "LARGE" (60 locs)
    gear_preset:   1,           // 1=Broke Peddler | 2=Road Merchant | 3=Caravan Master | 4=Merchant Prince
    rivals_mode:   "NORMAL",   // "NORMAL" | "AGGRESSIVE" (rivals start with 2x gold)
    game_mode:     "JOURNEY",  // "JOURNEY" (fixed trips) | "ENDLESS" (no end condition)
    journey_limit: 25,          // trips before game ends; only used in JOURNEY mode
};

// === MAKE PERSISTENT ===
persistent = true;