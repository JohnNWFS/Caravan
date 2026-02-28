// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Get available travel destinations from current location
/// @returns Array of destination structs

/// @desc Get available travel destinations from current location
/// @returns Array of destination structs

function scr_get_travel_options() {
    var current_loc_id = obj_player.current_location;
    var options = [];
    
    // Find all routes connected to current location
    for (var i = 0; i < array_length(obj_heartbeat.world.routes); i++) {
        var route = obj_heartbeat.world.routes[i];
        var dest_id = "";
        
        // Check if this route connects to our current location
        if (route.from_id == current_loc_id) {
            dest_id = route.to_id;
        } else if (route.to_id == current_loc_id) {
            dest_id = route.from_id;
        }
        
        // If we found a connection, get destination details
        if (dest_id != "") {
            // Find the destination location in world.locations
            for (var j = 0; j < array_length(obj_heartbeat.world.locations); j++) {
                var loc = obj_heartbeat.world.locations[j];
                if (loc.id == dest_id) {
                    array_push(options, {
                        name: loc.name,
                        type: loc.type,
                        distance: route.distance,
                        terrain: route.terrain,
                        danger: route.danger,
                        id: dest_id
                    });
                    break;
                }
            }
        }
    }
    
    // Sort by distance (closest first)
    array_sort(options, function(a, b) {
        return a.distance - b.distance;
    });
    
    return options;
}