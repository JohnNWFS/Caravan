// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate total cost for traveling between two locations
/// @param {String} from_id Starting location ID
/// @param {String} to_id Destination location ID
/// @returns {Struct} Total cost (provisions, water, gold, days, distance, terrain) or noone if route not found

function scr_calculate_travel_cost(from_id, to_id) {
    // === FIND THE ROUTE ===
    var route = noone;
    
    for (var i = 0; i < array_length(obj_heartbeat.world.routes); i++) {
        var r = obj_heartbeat.world.routes[i];
        
        // Routes are bidirectional
        if ((r.from_id == from_id && r.to_id == to_id) ||
            (r.from_id == to_id && r.to_id == from_id)) {
            route = r;
            break;
        }
    }
    
    // Route doesn't exist
    if (route == noone) {
        return noone;
    }
    
    // === CALCULATE JOURNEY TIME ===
    var days = scr_calculate_journey_time(route.distance, route.terrain);

    // Driver crew member cuts journey time by ~15% (minimum 1 day)
    var _has_driver = false;
    if (variable_struct_exists(obj_player, "hired_crew")) {
        for (var _ci = 0; _ci < array_length(obj_player.hired_crew); _ci++) {
            if (obj_player.hired_crew[_ci].type == "DRIVER") {
                _has_driver = true;
                break;
            }
        }
    }
    if (_has_driver) {
        days = max(1, floor(days * 0.85));
    }

    // Navigator crew member cuts journey time by ~10% (stacks with driver)
    var _has_navigator = false;
    if (variable_struct_exists(obj_player, "hired_crew")) {
        for (var _ni = 0; _ni < array_length(obj_player.hired_crew); _ni++) {
            if (obj_player.hired_crew[_ni].type == "NAVIGATOR") {
                _has_navigator = true;
                break;
            }
        }
    }
    if (_has_navigator) {
        days = max(1, floor(days * 0.90));
    }

    // === GET DAILY CONSUMPTION ===
    var daily = scr_calculate_daily_consumption();

    // === CREW WAGES (charged per day of travel) ===
    var _crew_wage = 0;
    if (variable_struct_exists(obj_player, "hired_crew")) {
        for (var _ci = 0; _ci < array_length(obj_player.hired_crew); _ci++) {
            _crew_wage += obj_player.hired_crew[_ci].wage;
        }
    }

    // === CALCULATE TOTAL COST ===
    var total_cost = {
        provisions: daily.provisions * days,
        water:      daily.water      * days,
        gold:       daily.gold       * days + _crew_wage * days,
        days:       days,
        distance:   route.distance,
        terrain:    route.terrain,
        crew_wage:  _crew_wage    // stored separately so TRAVEL command can display it
    };

    return total_cost;
}