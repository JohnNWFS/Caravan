/// @func scr_cmd_accept_contract(args)
/// @desc Accept a delivery contract by its listed number.
///
///   Usage: ACCEPT <number>
///   Example: ACCEPT 2
///
/// The number corresponds to the position in the CONTRACTS listing.
/// Once accepted, the contract is added to obj_player.active_contracts.
/// The player must buy and carry the required goods themselves, then
/// travel to the destination before the deadline.

function scr_cmd_accept_contract(args) {

    var _num = real(args);
    if (!is_real(_num) || _num < 1) {
        console_print("Usage: ACCEPT <number>");
        console_print("Type CONTRACTS to see available contracts.");
        return;
    }

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

    // Check that contracts exist here
    if (!variable_struct_exists(_loc, "available_contracts")
    ||   array_length(_loc.available_contracts) == 0) {
        console_print("No contracts available here. Type CONTRACTS to check the board.");
        return;
    }

    // Build the same filtered display list as scr_cmd_contracts
    var _display = [];
    for (var _ci = 0; _ci < array_length(_loc.available_contracts); _ci++) {
        var _c = _loc.available_contracts[_ci];
        if (_c.deadline_day <= obj_heartbeat.day) continue;
        var _taken = false;
        for (var _ai = 0; _ai < array_length(obj_player.active_contracts); _ai++) {
            if (obj_player.active_contracts[_ai].id == _c.id) { _taken = true; break; }
        }
        if (!_taken) array_push(_display, _c);
    }

    var _idx = _num - 1;
    if (_idx < 0 || _idx >= array_length(_display)) {
        console_print("Invalid contract number " + string(_num) + ".");
        console_print("Type CONTRACTS to see the current list.");
        return;
    }

    var _contract = _display[_idx];

    // Add to player's active contracts
    array_push(obj_player.active_contracts, _contract);

    // Confirmation report
    var _in_cargo  = scr_count_cargo(_contract.good_id);
    var _days_left = _contract.deadline_day - obj_heartbeat.day;
    var _need_more = _contract.quantity - _in_cargo;

    console_print("");
    console_print(_hdr("CONTRACT ACCEPTED"));
    console_print("Deliver " + string(_contract.quantity) + " " + _contract.good_name
                  + " to " + _contract.dest_name + ".");
    console_print("Deadline:  Day " + string(_contract.deadline_day)
                  + " (" + string(_days_left) + " days from now)");
    console_print("Reward:    " + string(_contract.reward_gold) + " gold on delivery");
    console_print("");
    console_print("In cargo now: " + string(_in_cargo) + " / " + string(_contract.quantity)
                  + " " + _contract.good_name + " needed.");
    if (_need_more > 0) {
        console_print("Buy " + string(_need_more) + " more at the MARKET, then GO to "
                      + _contract.dest_name + " before Day " + string(_contract.deadline_day) + ".");
    } else {
        console_print("You have enough! Travel to " + _contract.dest_name
                      + " before Day " + string(_contract.deadline_day) + " to collect.");
    }
    console_print("");
}
