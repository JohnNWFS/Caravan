// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle REPAIR command — show per-wagon cost to restore all wagons to 100 % condition.
///       Sets pending_action for YES/NO confirmation before deducting gold.

function scr_cmd_repair() {

    var _total_cost  = 0;
    var _wagon_count = array_length(obj_player.caravan.wagons);
    var _any_damaged = false;

    console_print("");
    console_print("=== REPAIR ESTIMATE ===");

    for (var _i = 0; _i < _wagon_count; _i++) {
        var _w      = obj_player.caravan.wagons[_i];
        var _vdata  = scr_get_vehicle_data(_w.type);
        var _rate   = (_vdata != undefined) ? _vdata.repair_rate : 5; // fallback 5g / point
        var _damage = 100 - floor(_w.condition);

        if (_damage <= 0) {
            console_print("  Wagon " + string(_i + 1) + " (" + _w.type + "): perfect condition");
        } else {
            _any_damaged = true;
            var _cost = ceil(_damage * _rate);
            _total_cost += _cost;
            console_print("  Wagon " + string(_i + 1) + " (" + _w.type + "): "
                          + string(floor(_w.condition)) + "% condition  —  "
                          + string(_cost) + " gold to repair");
        }
    }

    if (!_any_damaged) {
        console_print("All wagons are in perfect condition. No repairs needed.");
        console_print("");
        return;
    }

    console_print("");
    console_print("Total repair cost: " + string(_total_cost) + " gold");
    console_print("Your gold:         " + string(obj_player.gold) + " gold");

    if (obj_player.gold < _total_cost) {
        console_print("");
        console_print("You cannot afford full repairs. Earn more gold with WORK <days> or sell goods.");
        console_print("");
        return;
    }

    console_print("");
    console_print("Type YES to confirm repairs, or NO to cancel.");
    console_print("");

    obj_player.pending_action = {
        type: "repair",
        cost: _total_cost
    };
}
