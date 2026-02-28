// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Render the current new-game setup options to the console.
///       Called from BOOT and whenever a setup option changes.

function scr_show_setup_menu() {
    var _s = obj_heartbeat.setup_config;

    var _gear_names = [
        "",
        "The Broke Peddler   (150g,  Handcart + Donkey)",
        "The Road Merchant   (700g,  Cart + Mule)",
        "The Caravan Master  (2500g, Wagon + Ox)",
        "The Merchant Prince (8000g, Merchant Wagon + Horse)"
    ];

    var _sz_detail = "25 places, 2 rivals";
    if (_s.world_size == "MEDIUM") _sz_detail = "40 places, 3 rivals";
    if (_s.world_size == "LARGE")  _sz_detail = "60 places, 5 rivals";

    console_print("+-----------------------------------------+");
    console_print("|          NEW GAME OPTIONS               |");
    console_print("+-----------------------------------------+");
    console_print("| [1] World:   " + _s.world_size
                  + string_repeat(" ", max(0, 8 - string_length(_s.world_size)))
                  + "(" + _sz_detail + ")");
    console_print("| [2] Kit:     " + _gear_names[_s.gear_preset]);
    console_print("| [3] Rivals:  " + _s.rivals_mode
                  + ((_s.rivals_mode == "AGGRESSIVE") ? " (rivals start with 2x gold)" : ""));

    var _mode_str = "ENDLESS";
    if (_s.game_mode == "JOURNEY") {
        _mode_str = "JOURNEY - " + string(_s.journey_limit) + " trips";
    }
    console_print("| [4] Mode:    " + _mode_str);

    console_print("+-----------------------------------------+");
    console_print("| Type 1 / 2 / 3 / 4 to cycle options.   |");
    console_print("| Type START to begin your journey.       |");
    console_print("| Type GUIDE for a full tutorial.         |");
    console_print("+-----------------------------------------+");
    console_print("");
}
