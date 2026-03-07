/// @func scr_cmd_hire(args)
/// @desc Handle the HIRE command — view and manage hired crew.
///
///   HIRE               → list available crew + your current roster
///   HIRE <n>           → hire crew member n from the available list
///   HIRE DISMISS <n>   → release hired crew member n (works anywhere)
///
/// Crew effects (applied automatically during travel):
///   GUARD  — halves gold lost in bandit events
///   DRIVER — cuts journey days by ~15%
///   TRADER — improves buy prices by 10% and sell prices by 10%
///
/// Max hired crew: 3. Wages (gold/day) are deducted per journey.
/// Only one crew member of each type may be hired at a time.

function scr_cmd_hire(args) {

    // Save-compatibility guard — older saves won't have this field
    if (!variable_struct_exists(obj_player, "hired_crew")) {
        obj_player.hired_crew = [];
    }

    // Find current location struct
    var _loc = undefined;
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == obj_player.current_location) {
            _loc = obj_heartbeat.world.locations[_i];
            break;
        }
    }

    if (_loc == undefined) {
        console_print("You are not at a valid location.");
        return;
    }

    var _sub = string_upper(string_trim(args));

    // ── HIRE DISMISS <n> — can dismiss from anywhere ───────────────────────
    if (string_length(_sub) >= 7 && string_copy(_sub, 1, 7) == "DISMISS") {
        var _num_str = string_trim(string_delete(_sub, 1, 7));
        if (_num_str == "" || string_digits(_num_str) != _num_str) {
            console_print("Usage: HIRE DISMISS <number>");
            console_print("Type HIRE to see your current crew.");
            return;
        }
        var _num = real(_num_str);
        if (_num < 1 || _num > array_length(obj_player.hired_crew)) {
            console_print("No crew member at that number.");
            console_print("Type HIRE to see your current crew.");
            return;
        }
        var _gone = obj_player.hired_crew[_num - 1];
        array_delete(obj_player.hired_crew, _num - 1, 1);
        console_print("");
        console_print(_gone.name + " (" + _gone.type + ") has been released.");
        console_print("You no longer owe wages to " + _gone.name + ".");
        console_print("");
        return;
    }

    // ── Location check — hiring only available in cities ────────────────────
    var _can_hire = false;
    if (variable_struct_exists(_loc, "tags")) {
        for (var _t = 0; _t < array_length(_loc.tags); _t++) {
            if (_loc.tags[_t] == "hire") { _can_hire = true; break; }
        }
    }

    if (!_can_hire) {
        console_print("Crew for hire are only found in cities.");
        console_print("Check your TRAVEL map for the nearest city.");
        // Still show current crew if any
        var _n = array_length(obj_player.hired_crew);
        if (_n > 0) {
            console_print("");
            console_print("Your current crew [" + string(_n) + "/3]:");
            for (var _i = 0; _i < _n; _i++) {
                var _h = obj_player.hired_crew[_i];
                var _np = _h.name + string_repeat(" ", max(0, 7 - string_length(_h.name)));
                console_print("  [" + string(_i + 1) + "] " + _np
                              + " (" + _h.type + ")"
                              + string_repeat(" ", max(0, 7 - string_length(_h.type)))
                              + "  " + string(_h.wage) + "g/day");
            }
            console_print("Type HIRE DISMISS <n> to release a crew member.");
        }
        console_print("");
        return;
    }

    // ── Generate/refresh crew pool (stale after 7 days) ─────────────────────
    if (!variable_struct_exists(_loc, "available_crew")
    ||  !variable_struct_exists(_loc, "crew_pool_day")
    ||  (obj_heartbeat.day - _loc.crew_pool_day) > 7) {
        scr_generate_crew_pool(_loc);
    }

    // ── HIRE <n> — recruit by number ─────────────────────────────────────────
    if (_sub != "" && string_digits(_sub) == _sub) {
        var _num = real(_sub);
        if (_num < 1 || _num > array_length(_loc.available_crew)) {
            console_print("No crew member at that number.");
            console_print("Type HIRE to see who is available.");
            return;
        }

        var _max_crew = 3;
        if (array_length(obj_player.hired_crew) >= _max_crew) {
            console_print("Your crew is full (" + string(_max_crew) + "/" + string(_max_crew) + ").");
            console_print("Dismiss someone first: HIRE DISMISS <n>.");
            return;
        }

        var _pick = _loc.available_crew[_num - 1];

        // Only one of each type allowed
        for (var _ci = 0; _ci < array_length(obj_player.hired_crew); _ci++) {
            if (obj_player.hired_crew[_ci].type == _pick.type) {
                console_print("You already have a " + string_lower(_pick.type)
                              + " in your crew.");
                return;
            }
        }

        array_push(obj_player.hired_crew, {
            name:      _pick.name,
            type:      _pick.type,
            wage:      _pick.wage,
            hired_day: obj_heartbeat.day
        });

        console_print("");
        console_print(_pick.name + " (" + _pick.type + ") joins your caravan.");
        console_print("Wage: " + string(_pick.wage) + "g per day of travel.");
        console_print(_pick.desc);
        console_print("");
        return;
    }

    // ── Default: show the full hire menu ─────────────────────────────────────
    console_print("");
    console_print(_hdr("CREW FOR HIRE"));
    console_print("At " + _loc.name + " (" + string_lower(_loc.type) + ")");
    console_print("");

    console_print("Available:");
    for (var _i = 0; _i < array_length(_loc.available_crew); _i++) {
        var _c   = _loc.available_crew[_i];
        var _np  = _c.name + string_repeat(" ", max(0, 7 - string_length(_c.name)));
        var _tp  = string_repeat(" ", max(0, 7 - string_length(_c.type)));
        console_print("  [" + string(_i + 1) + "] " + _np
                      + " (" + _c.type + ")" + _tp
                      + "  " + string(_c.wage) + "g/day");
        console_print("      " + _c.desc);
    }

    console_print("");

    var _n_hired  = array_length(obj_player.hired_crew);
    var _max_crew = 3;
    console_print("Your crew [" + string(_n_hired) + "/" + string(_max_crew) + "]:");
    if (_n_hired == 0) {
        console_print("  (none)");
    } else {
        for (var _i = 0; _i < _n_hired; _i++) {
            var _h  = obj_player.hired_crew[_i];
            var _hn = _h.name + string_repeat(" ", max(0, 7 - string_length(_h.name)));
            var _ht = string_repeat(" ", max(0, 7 - string_length(_h.type)));
            console_print("  [" + string(_i + 1) + "] " + _hn
                          + " (" + _h.type + ")" + _ht
                          + "  " + string(_h.wage) + "g/day");
        }
    }

    console_print("");
    console_print("HIRE <n> to recruit.  HIRE DISMISS <n> to release.");
    console_print("");
}
