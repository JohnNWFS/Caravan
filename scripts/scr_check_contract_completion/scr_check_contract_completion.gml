/// @func scr_check_contract_completion(destination_id)
/// @desc Resolve active contracts after the player arrives at a new location.
///
///       For each active contract:
///         • If destination matches AND cargo requirement met → complete, award gold + rep
///         • If destination matches AND cargo insufficient   → fail, penalise rep
///         • If deadline has passed (regardless of location) → fail, penalise rep
///         • Otherwise                                       → keep active
///
///       Does NOT print anything — returns a result struct so that
///       scr_begin_journey() can print the outcome at the correct place in output.
///
/// @param {String} destination_id  The location the player just arrived at
/// @return {Struct}  { completed: Array, failed: Array }
///
///   completed[] — completed contract structs (after removal from active_contracts)
///   failed[]    — failed contract structs extended with:
///                   fail_reason  {String}  "cargo" | "deadline"
///                   in_cargo     {Real}    Units actually in cargo at destination

function scr_check_contract_completion(destination_id) {

    var _completed = [];
    var _failed    = [];
    var _kept      = [];

    for (var _i = 0; _i < array_length(obj_player.active_contracts); _i++) {
        var _c = obj_player.active_contracts[_i];

        if (_c.dest_id == destination_id) {
            // Arrived at the contract's destination — check cargo
            var _in_cargo = scr_count_cargo(_c.good_id);

            if (_in_cargo >= _c.quantity) {
                // SUCCESS: remove goods, award gold and reputation
                scr_remove_cargo(_c.good_id, _c.quantity);
                obj_player.gold       += _c.reward_gold;
                obj_player.reputation += 2;
                array_push(_completed, _c);
            } else {
                // FAIL: at destination but short on cargo
                obj_player.reputation -= 1;
                var _fail = {};
                var _keys = variable_struct_get_names(_c);
                for (var _k = 0; _k < array_length(_keys); _k++) {
                    _fail[$ _keys[_k]] = _c[$ _keys[_k]];
                }
                _fail.fail_reason = "cargo";
                _fail.in_cargo    = _in_cargo;
                array_push(_failed, _fail);
            }

        } else if (obj_heartbeat.day > _c.deadline_day) {
            // FAIL: deadline passed and player is elsewhere
            obj_player.reputation -= 1;
            var _fail2 = {};
            var _keys2 = variable_struct_get_names(_c);
            for (var _k2 = 0; _k2 < array_length(_keys2); _k2++) {
                _fail2[$ _keys2[_k2]] = _c[$ _keys2[_k2]];
            }
            _fail2.fail_reason = "deadline";
            _fail2.in_cargo    = 0;
            array_push(_failed, _fail2);

        } else {
            // Still active — keep it
            array_push(_kept, _c);
        }
    }

    obj_player.active_contracts = _kept;

    return {
        completed: _completed,
        failed:    _failed
    };
}
