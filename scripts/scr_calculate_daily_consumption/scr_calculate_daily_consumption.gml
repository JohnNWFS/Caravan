// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate daily resource consumption for the entire caravan.
///       Vehicle maintenance costs are read from the vehicle database.
///       Animal feed / water costs are read from each animal struct.
/// @returns {Struct} { provisions, water, gold }

function scr_calculate_daily_consumption() {

    var daily_cost = {
        provisions: 0,
        water:      0,
        gold:       0
    };

    // The merchant always needs 1 provision and 1 water per day
    var people_count = 1;

    var animal_feed_total  = 0;
    var animal_water_total = 0;
    var gold_cost          = 0;

    for (var _i = 0; _i < array_length(obj_player.caravan.wagons); _i++) {
        var _w = obj_player.caravan.wagons[_i];

        // --- Vehicle maintenance (database-driven) ---
        var _vdata = scr_get_vehicle_data(_w.type);
        var _maint = (_vdata != undefined) ? _vdata.maintenance : 3; // fallback
        gold_cost += _maint;

        // Damaged wagons cost more to keep running (incentive to repair)
        if (_w.condition < 75) {
            gold_cost += 2;
        }

        // --- Animals ---
        var _animals = _w.slots.animals.contents;
        for (var _j = 0; _j < array_length(_animals); _j++) {
            var _ani = _animals[_j];
            animal_feed_total  += _ani.feed_cost;
            // Use water_cost if present; older save structs without it default to 1
            animal_water_total += variable_struct_exists(_ani, "water_cost")
                                  ? _ani.water_cost : 1;
        }
    }

    // TODO: Later add crew wages per crew member

    daily_cost.provisions = people_count + animal_feed_total;
    daily_cost.water      = people_count + animal_water_total;
    daily_cost.gold       = gold_cost;

    return daily_cost;
}
