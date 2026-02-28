// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle all player input during the SETUP game state.
///       Called from cmd_parse when game_state == "SETUP".
/// @param {String} command  Uppercase command token (e.g. "1", "START", "GUIDE")
/// @param {String} args     Remainder of input after the command token

function scr_cmd_setup(command, args) {
    var _s = obj_heartbeat.setup_config;

    switch (command) {

        // ----------------------------------------------------------------
        // [1] Cycle world size
        // ----------------------------------------------------------------
        case "1":
            if      (_s.world_size == "SMALL")  _s.world_size = "MEDIUM";
            else if (_s.world_size == "MEDIUM") _s.world_size = "LARGE";
            else                                 _s.world_size = "SMALL";
            scr_show_setup_menu();
            break;

        // ----------------------------------------------------------------
        // [2] Cycle starting gear preset
        // ----------------------------------------------------------------
        case "2":
            _s.gear_preset = (_s.gear_preset >= 4) ? 1 : _s.gear_preset + 1;
            scr_show_setup_menu();
            break;

        // ----------------------------------------------------------------
        // [3] Toggle rival difficulty
        // ----------------------------------------------------------------
        case "3":
            _s.rivals_mode = (_s.rivals_mode == "NORMAL") ? "AGGRESSIVE" : "NORMAL";
            scr_show_setup_menu();
            break;

        // ----------------------------------------------------------------
        // [4] Cycle game mode:
        //   JOURNEY-10 -> JOURNEY-25 -> JOURNEY-50 -> JOURNEY-100 -> ENDLESS -> back
        // ----------------------------------------------------------------
        case "4":
            if (_s.game_mode == "ENDLESS") {
                _s.game_mode     = "JOURNEY";
                _s.journey_limit = 10;
            } else if (_s.journey_limit == 10) {
                _s.journey_limit = 25;
            } else if (_s.journey_limit == 25) {
                _s.journey_limit = 50;
            } else if (_s.journey_limit == 50) {
                _s.journey_limit = 100;
            } else {
                _s.game_mode = "ENDLESS";
            }
            scr_show_setup_menu();
            break;

        // ----------------------------------------------------------------
        // START / BEGIN / PLAY — generate world and begin
        // ----------------------------------------------------------------
        case "START":
        case "BEGIN":
        case "PLAY":
            // Apply starting gear and gold to obj_player
            scr_apply_game_settings();

            // Determine n_rivals and gold_mult from config
            var _n_rivals = 2;
            if (_s.world_size == "MEDIUM") _n_rivals = 3;
            if (_s.world_size == "LARGE")  _n_rivals = 5;
            var _gold_mult = (_s.rivals_mode == "AGGRESSIVE") ? 2.0 : 1.0;

            // Generate the world with selected settings
            console_print("Generating world...");
            obj_heartbeat.world = world_generate(obj_heartbeat.world_seed,
                                                  _s.world_size,
                                                  _n_rivals,
                                                  _gold_mult);

            // Set player start location
            obj_player.current_location = obj_heartbeat.world.start_location_id;

            // Find start location name
            var _start_name = "the road";
            var _locs = obj_heartbeat.world.locations;
            for (var _i = 0; _i < array_length(_locs); _i++) {
                if (_locs[_i].id == obj_player.current_location) {
                    _start_name = _locs[_i].name;
                    break;
                }
            }

            // Announce
            console_print("World: " + string(array_length(_locs)) + " locations, "
                          + string(_n_rivals) + " rival"
                          + ((_n_rivals == 1) ? "" : "s") + ".");
            console_print("");
            console_print("You begin your journey in " + _start_name + ".");
            console_print("Type HELP for commands. Type GUIDE for a full tutorial.");
            console_print("");
            obj_heartbeat.game_state = "TOWN";
            break;

        // ----------------------------------------------------------------
        // GUIDE — full typewriter tutorial
        // ----------------------------------------------------------------
        case "GUIDE":
            console_clear();
            scr_show_game_guide();
            break;

        // ----------------------------------------------------------------
        // HELP / H / ? — quick setup reminder
        // ----------------------------------------------------------------
        case "HELP":
        case "H":
        case "?":
            console_print("");
            console_print("SETUP OPTIONS:");
            console_print("  1          - Cycle world size (SMALL / MEDIUM / LARGE)");
            console_print("  2          - Cycle starting kit (gear + gold preset)");
            console_print("  3          - Toggle rival difficulty (NORMAL / AGGRESSIVE)");
            console_print("  4          - Cycle mode (JOURNEY 10/25/50/100 trips or ENDLESS)");
            console_print("  START      - Begin the game with current settings");
            console_print("  GUIDE      - Full game tutorial (typewriter)");
            console_print("");
            break;

        // ----------------------------------------------------------------
        // Unknown input
        // ----------------------------------------------------------------
        default:
            console_print("Type 1 / 2 / 3 to change options, or START to begin.");
            break;
    }
}
