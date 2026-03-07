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

// === DEBUG EVENT INJECTION ===
debug_force_event = "";  // If non-empty, scr_journey_event fires this type next trip (then clears)

// === MAP STATE ===
map_open         = false; // true while the world map overlay is visible
map_close_delay  = 0;     // countdown frames before ESC/click can close the map

// === MAP TERRAIN SURFACE ===
map_terrain_surface = -1;     // cached surface ID; -1 = needs (re)build

// === MAP TRAVEL ANIMATION ===
map_travel_active   = false;  // true while travel dot is animating
map_travel_timer    = 0;      // frames elapsed this trip
map_travel_duration = 120;    // total frames for current trip
map_travel_progress = 0;      // 0.0..1.0 (raw, pre-easing)
map_travel_from_x   = 0;      // world X of origin
map_travel_from_y   = 0;      // world Y of origin
map_travel_to_x     = 0;      // world X of destination
map_travel_to_y     = 0;      // world Y of destination
map_travel_ctrl_x   = 0;      // bezier control point world X for current trip
map_travel_ctrl_y   = 0;      // bezier control point world Y for current trip
map_travel_to_name  = "";     // destination display name
map_travel_dest_id  = "";     // destination location id (for deferred journey call)
map_travel_costs    = noone;  // travel cost struct (for deferred journey call)

// === MAP SELECTION ===
map_hovered_loc_id   = "";   // ID of node currently under the mouse (written each frame by scr_draw_map)
selected_location_id = "";   // ID of last left-clicked node; persists until DIRECTIONS executes or ESC clears it

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