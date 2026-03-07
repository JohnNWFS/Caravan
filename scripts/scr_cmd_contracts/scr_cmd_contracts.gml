/// @func scr_cmd_contracts(args)
/// @desc Handle the CONTRACTS command.
///
///   CONTRACTS             — List available delivery contracts at current city/town
///   CONTRACTS ACTIVE (A)  — List the player's currently accepted contracts
///
/// Contracts are generated fresh on first visit; refreshed after 7 in-game days.
/// Each contract asks the player to deliver N units of a good to a named destination.
/// The player must purchase and carry the goods themselves; the reward is paid on arrival.

function scr_cmd_contracts(args) {

    var _sub = string_upper(string_trim(args));

    // -----------------------------------------------------------------------
    // Sub-command: ACTIVE — show what the player has accepted
    // -----------------------------------------------------------------------
    if (_sub == "ACTIVE" || _sub == "A") {

        console_print("");
        console_print(_hdr("ACTIVE CONTRACTS"));

        if (array_length(obj_player.active_contracts) == 0) {
            console_print("You have no active contracts.");
            console_print("Visit a city or town and type CONTRACTS to find work.");
            console_print("");
            return;
        }

        for (var _i = 0; _i < array_length(obj_player.active_contracts); _i++) {
            var _c        = obj_player.active_contracts[_i];
            var _in_cargo = scr_count_cargo(_c.good_id);
            var _days_left = _c.deadline_day - obj_heartbeat.day;
            var _urgent   = (_days_left <= 4) ? "  *** URGENT ***" : "";

            console_print("  " + string(_i + 1) + ".  ["
                          + _c.origin_name + "  >  " + _c.dest_name + "]"
                          + "  Deliver " + string(_c.quantity) + " " + _c.good_name
                          + "  |  Reward: " + string(_c.reward_gold) + "g"
                          + _urgent);
            console_print("     In cargo: " + string(_in_cargo) + "/" + string(_c.quantity)
                          + "  |  Deadline: Day " + string(_c.deadline_day)
                          + " (" + string(_days_left) + " days remaining)");
        }
        console_print("");
        return;
    }

    // -----------------------------------------------------------------------
    // Default: list available contracts at current location
    // -----------------------------------------------------------------------

    // Get current location
    var _loc = undefined;
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == obj_player.current_location) {
            _loc = obj_heartbeat.world.locations[_i];
            break;
        }
    }
    if (_loc == undefined) {
        console_print("ERROR: Current location not found.");
        return;
    }

    // Check the contracts tag
    var _has_tag = false;
    for (var _ti = 0; _ti < array_length(_loc.tags); _ti++) {
        if (_loc.tags[_ti] == "contracts") { _has_tag = true; break; }
    }
    if (!_has_tag) {
        console_print("There is no contract board here.");
        console_print("Contracts are available in cities and towns.");
        return;
    }

    // Generate or refresh contracts when stale (first visit or older than 7 days)
    var _needs_gen = !variable_struct_exists(_loc, "available_contracts")
                  || !variable_struct_exists(_loc, "contracts_issued_day")
                  ||  obj_heartbeat.day - _loc.contracts_issued_day >= 7
                  ||  array_length(_loc.available_contracts) == 0;
    if (_needs_gen) {
        scr_generate_contracts(_loc);
    }

    // Build display list: available contracts not yet accepted and not expired
    var _display = [];
    for (var _ci = 0; _ci < array_length(_loc.available_contracts); _ci++) {
        var _c = _loc.available_contracts[_ci];
        // Skip expired
        if (_c.deadline_day <= obj_heartbeat.day) continue;
        // Skip if already accepted
        var _taken = false;
        for (var _ai = 0; _ai < array_length(obj_player.active_contracts); _ai++) {
            if (obj_player.active_contracts[_ai].id == _c.id) { _taken = true; break; }
        }
        if (!_taken) array_push(_display, _c);
    }

    console_print("");
    console_print(_hdr("CONTRACTS AVAILABLE IN " + string_upper(_loc.name)));
    console_print("Deliver goods to earn gold and reputation. You supply the cargo.");
    console_print("");

    if (array_length(_display) == 0) {
        console_print("No contracts currently available.");
    } else {
        for (var _di = 0; _di < array_length(_display); _di++) {
            var _c = _display[_di];
            var _days_left = _c.deadline_day - obj_heartbeat.day;
            console_print("  " + string(_di + 1) + ".  Deliver " + string(_c.quantity)
                          + " " + _c.good_name
                          + "  >  " + _c.dest_name
                          + "  |  by Day " + string(_c.deadline_day)
                          + " (" + string(_days_left) + " days)"
                          + "  |  Reward: " + string(_c.reward_gold) + "g");
        }
        console_print("");
        console_print("Type ACCEPT <number> to take a contract.");
    }

    var _active_cnt = array_length(obj_player.active_contracts);
    if (_active_cnt > 0) {
        console_print("Active contracts: " + string(_active_cnt)
                      + "  (CONTRACTS ACTIVE to view)");
    }
    console_print("");
}
