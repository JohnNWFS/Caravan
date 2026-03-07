// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func scr_cmd_load()
/// @desc Load game state from caravan_save.json.
///       Valid from TOWN, SETUP, or GAMEOVER states.
///       After loading, game_state is set to "TOWN" and the console refreshes.
///
/// @func scr_fixup_loaded_cargo()
/// @desc Convert pointer_null back to undefined in wagon cargo slot arrays.
///       GML's json_stringify encodes undefined as null; json_parse converts null
///       back to pointer_null rather than undefined, which breaks slot checks.
///       Must be called after restoring obj_player.caravan from JSON.

// ---------------------------------------------------------------------------

function scr_cmd_load() {

    var _path = working_directory + "caravan_save.json";

    // ------------------------------------------------------------------
    // File existence check
    // ------------------------------------------------------------------
    if (!file_exists(_path)) {
        console_print("No save file found. Use SAVE to create one.");
        return;
    }

    // ------------------------------------------------------------------
    // Read the file (json_stringify produces a single-line string, so
    // one file_text_read_string call is sufficient, but we loop for safety)
    // ------------------------------------------------------------------
    var _f = file_text_open_read(_path);
    var _json = "";
    while (!file_text_eof(_f)) {
        _json += file_text_read_string(_f);
        if (!file_text_eof(_f)) file_text_readln(_f);
    }
    file_text_close(_f);

    if (_json == "") {
        console_print("ERROR: Save file is empty or unreadable.");
        return;
    }

    // ------------------------------------------------------------------
    // Parse and version-check
    // ------------------------------------------------------------------
    var _save = json_parse(_json);

    if (!variable_struct_exists(_save, "version") || _save.version != 1) {
        console_print("ERROR: Incompatible save file version — cannot load.");
        return;
    }

    // ------------------------------------------------------------------
    // Restore obj_heartbeat game / world state
    // ------------------------------------------------------------------
    obj_heartbeat.game_state    = "TOWN";   // Always land in TOWN on load
    obj_heartbeat.day           = _save.day;
    obj_heartbeat.turn          = _save.turn;
    obj_heartbeat.journey_count = _save.journey_count;
    obj_heartbeat.world_seed    = _save.world_seed;
    obj_heartbeat.setup_config  = _save.setup_config;
    obj_heartbeat.world         = _save.world;

    // Free and invalidate the terrain surface — it will rebuild on next draw
    if (surface_exists(obj_heartbeat.map_terrain_surface)) {
        surface_free(obj_heartbeat.map_terrain_surface);
    }
    obj_heartbeat.map_terrain_surface = -1;

    // Reset any in-progress travel animation
    obj_heartbeat.map_open            = false;
    obj_heartbeat.map_travel_active   = false;
    obj_heartbeat.map_travel_timer    = 0;
    obj_heartbeat.map_travel_progress = 0;
    obj_heartbeat.map_travel_costs    = noone;

    // ------------------------------------------------------------------
    // Restore obj_player
    // ------------------------------------------------------------------
    var _pl = _save.player;
    obj_player.gold             = _pl.gold;
    obj_player.hp               = _pl.hp;
    obj_player.max_hp           = _pl.max_hp;
    obj_player.reputation       = _pl.reputation;
    obj_player.provisions       = _pl.provisions;
    obj_player.current_location = _pl.current_location;
    obj_player.relationships    = _pl.relationships;
    obj_player.active_contracts = _pl.active_contracts;
    obj_player.hired_crew       = _pl.hired_crew;
    obj_player.inventory        = _pl.inventory;
    obj_player.caravan          = _pl.caravan;
    obj_player.pending_action   = undefined;   // Never restore mid-action state

    // ------------------------------------------------------------------
    // Fix up undefined → pointer_null conversion from the JSON round-trip
    // ------------------------------------------------------------------
    scr_fixup_loaded_cargo();

    // ------------------------------------------------------------------
    // Show a clean confirmation screen
    // ------------------------------------------------------------------
    console_clear();

    var _loc_name = "Unknown";
    var _loc_type = "";
    for (var _li = 0; _li < array_length(obj_heartbeat.world.locations); _li++) {
        var _loc = obj_heartbeat.world.locations[_li];
        if (_loc.id == obj_player.current_location) {
            _loc_name = _loc.name;
            _loc_type = _loc.type;
            break;
        }
    }

    console_print(_hdr("GAME LOADED"));
    console_print("Day " + string(obj_heartbeat.day)
                  + " — " + _loc_name + " (" + _loc_type + ")");
    console_print("Gold: "       + string(obj_player.gold)
                  + "   Provisions: " + string(obj_player.provisions)
                  + "   Reputation: " + string(obj_player.reputation));
    console_print("");
    console_print("Type HELP for commands, STATUS for caravan details.");
    console_print("");
}

// ---------------------------------------------------------------------------

function scr_fixup_loaded_cargo() {
    /// @desc Walk every wagon's cargo slot array and convert pointer_null back
    ///       to undefined.  json_stringify encodes undefined as null; json_parse
    ///       converts null back to pointer_null — which breaks slot-empty checks
    ///       such as (slot == undefined) throughout the codebase.
    ///
    ///       Two cases handled:
    ///         1. Standard empty slot: the array element itself is pointer_null
    ///            → replaced with undefined.
    ///         2. Saddlebag/typed slot: the struct's .contents field is
    ///            pointer_null (or missing because it was undefined before save)
    ///            → .contents restored to undefined.

    var _wagons = obj_player.caravan.wagons;
    for (var _wi = 0; _wi < array_length(_wagons); _wi++) {
        var _wagon = _wagons[_wi];
        if (!variable_struct_exists(_wagon, "slots"))        continue;
        if (!variable_struct_exists(_wagon.slots, "cargo"))  continue;

        var _arr = _wagon.slots.cargo.contents;
        for (var _ci = 0; _ci < array_length(_arr); _ci++) {
            var _slot = _arr[_ci];

            if (_slot == pointer_null) {
                // Case 1 — empty standard slot
                _arr[_ci] = undefined;

            } else if (is_struct(_slot) && variable_struct_exists(_slot, "slot_type")) {
                // Case 2 — typed slot (e.g. SADDLEBAG_BULK)
                if (!variable_struct_exists(_slot, "contents")) {
                    // The contents field was undefined → omitted from JSON → restore it
                    _slot.contents = undefined;
                } else if (_slot.contents == pointer_null) {
                    _slot.contents = undefined;
                }
            }
        }
    }
}
