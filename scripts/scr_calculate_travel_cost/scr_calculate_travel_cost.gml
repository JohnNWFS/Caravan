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
    
    // === GET DAILY CONSUMPTION ===
    var daily = scr_calculate_daily_consumption();
    
    // === CALCULATE TOTAL COST ===
    var total_cost = {
        provisions: daily.provisions * days,
        water: daily.water * days,
        gold: daily.gold * days,
        days: days,
        distance: route.distance,
        terrain: route.terrain
    };
    
    return total_cost;
}