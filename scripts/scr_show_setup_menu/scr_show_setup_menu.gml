// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Render the current new-game setup options to the console.
///       Called from BOOT and whenever a setup option changes.

function scr_show_setup_menu() {
    var _s = obj_heartbeat.setup_config;

    var _gear_names = [
        "",
        "The Broke Peddler (150g)",
        "The Road Merchant (700g)",
        "The Caravan Master (2500g)",
        "The Merchant Prince (8000g)"
    ];

    var _sz_detail = "25 places, 2 rivals";
    if (_s.world_size == "MEDIUM") _sz_detail = "40 places, 3 rivals";
    if (_s.world_size == "LARGE")  _sz_detail = "60 places, 5 rivals";

    var _mode_str = "ENDLESS";
    if (_s.game_mode == "JOURNEY") {
        _mode_str = "JOURNEY - " + string(_s.journey_limit) + " trips";
    } else if (_s.game_mode == "BEAT_AI") {
        _mode_str = "BEAT THE AI - 100 trips";
    }

    // === Full-width box layout (56 chars wide, 54-char inner content) ===
    // Matches the boot screen box width exactly.
    var _W       = 54;
    var _sep_top = chr(9484) + string_repeat(chr(9472), _W) + chr(9488); // ┌────┐
    var _sep_mid = chr(9500) + string_repeat(chr(9472), _W) + chr(9508); // ├────┤
    var _sep_bot = chr(9492) + string_repeat(chr(9472), _W) + chr(9496); // └────┘
    var _vc      = chr(9474);                                             // │

    // --- Centered title ---
    var _title  = "NEW GAME OPTIONS";
    var _tpad_l = (_W - string_length(_title)) div 2;
    var _tpad_r = _W - string_length(_title) - _tpad_l;

    // --- Option row content strings (vertical char is added by the print call) ---
    var _r1 = " [1] World:   " + _s.world_size
              + string_repeat(" ", max(0, 8 - string_length(_s.world_size)))
              + "(" + _sz_detail + ")";
    var _r2 = " [2] Kit:     " + _gear_names[_s.gear_preset];
    var _r3 = " [3] Rivals:  " + _s.rivals_mode
              + ((_s.rivals_mode == "AGGRESSIVE") ? " (rivals start with 2x gold)" : "");
    var _r4 = " [4] Mode:    " + _mode_str;

    // --- Instruction row content strings ---
    var _i1 = " Type 1 / 2 / 3 / 4 to cycle options.";
    var _i2 = " Type START to begin your journey.";
    var _i3 = " Type GUIDE for a full tutorial.";

    // --- Print: each content line is padded with spaces to exactly _W chars ---
    console_print(_sep_top);
    console_print(_vc + string_repeat(" ", _tpad_l) + _title + string_repeat(" ", _tpad_r) + _vc);
    console_print(_sep_mid);
    console_print(_vc + _r1 + string_repeat(" ", max(0, _W - string_length(_r1))) + _vc);
    console_print(_vc + _r2 + string_repeat(" ", max(0, _W - string_length(_r2))) + _vc);
    console_print(_vc + _r3 + string_repeat(" ", max(0, _W - string_length(_r3))) + _vc);
    console_print(_vc + _r4 + string_repeat(" ", max(0, _W - string_length(_r4))) + _vc);
    console_print(_sep_mid);
    console_print(_vc + _i1 + string_repeat(" ", max(0, _W - string_length(_i1))) + _vc);
    console_print(_vc + _i2 + string_repeat(" ", max(0, _W - string_length(_i2))) + _vc);
    console_print(_vc + _i3 + string_repeat(" ", max(0, _W - string_length(_i3))) + _vc);
    console_print(_sep_bot);
    console_print("");
}
