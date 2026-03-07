// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func scr_cmd_save()
/// @desc Serialize the current game state to caravan_save.json in the working directory.
///       Only valid while in TOWN state (not mid-journey).
///       Saves: game/world state on obj_heartbeat, player + caravan on obj_player.
///       undefined cargo slots serialize to null in JSON; scr_fixup_loaded_cargo()
///       converts them back on load.

function scr_cmd_save() {

    if (obj_heartbeat.game_state != "TOWN") {
        console_print("You can only save while resting at a location.");
        return;
    }

    // ------------------------------------------------------------------
    // Build a pure-data save struct (no instance refs, no surface IDs)
    // ------------------------------------------------------------------
    var _save = {
        version:       1,
        game_state:    obj_heartbeat.game_state,
        day:           obj_heartbeat.day,
        turn:          obj_heartbeat.turn,
        journey_count: obj_heartbeat.journey_count,
        world_seed:    obj_heartbeat.world_seed,
        setup_config:  obj_heartbeat.setup_config,

        player: {
            gold:             obj_player.gold,
            hp:               obj_player.hp,
            max_hp:           obj_player.max_hp,
            reputation:       obj_player.reputation,
            provisions:       obj_player.provisions,
            current_location: obj_player.current_location,
            relationships:    obj_player.relationships,
            active_contracts: obj_player.active_contracts,
            hired_crew:       obj_player.hired_crew,
            inventory:        obj_player.inventory,
            caravan:          obj_player.caravan,
        },

        world: obj_heartbeat.world,
    };

    // ------------------------------------------------------------------
    // Serialize to JSON and write to disk
    // ------------------------------------------------------------------
    var _json = json_stringify(_save);
    var _path = working_directory + "caravan_save.json";
    var _f = file_text_open_write(_path);
    file_text_write_string(_f, _json);
    file_text_close(_f);

    // ------------------------------------------------------------------
    // Confirmation message
    // ------------------------------------------------------------------
    var _loc_name = "Unknown";
    for (var _li = 0; _li < array_length(obj_heartbeat.world.locations); _li++) {
        if (obj_heartbeat.world.locations[_li].id == obj_player.current_location) {
            _loc_name = obj_heartbeat.world.locations[_li].name;
            break;
        }
    }

    console_print("");
    console_print("Game saved.  (Day " + string(obj_heartbeat.day) + " — " + _loc_name + ")");
    console_print("");
}
