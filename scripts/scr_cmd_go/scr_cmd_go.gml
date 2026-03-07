// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle GO command - travel to a destination
/// @param {String} argument Destination name or number

function scr_cmd_go(argument) {
    // Get available destinations
    var options = scr_get_travel_options();
    
    if (array_length(options) == 0) {
        console_print("No travel routes available from this location.");
        return;
    }
    
    // === PARSE ARGUMENT ===
    var destination = noone;
    var dest_name = "";
    
    // Check if argument is a number
    if (string_digits(argument) == argument && argument != "") {
        // It's a number - use as index
        var index = real(argument) - 1; // Convert to 0-based index
        
        if (index >= 0 && index < array_length(options)) {
            destination = options[index];
            dest_name = destination.name;
        } else {
            console_print("Invalid destination number. Type 'TRAVEL' to see options.");
            return;
        }
    } else {
        // It's a name - search for it (case-insensitive)
        var search_name = string_lower(argument);
        
        for (var i = 0; i < array_length(options); i++) {
            if (string_lower(options[i].name) == search_name) {
                destination = options[i];
                dest_name = destination.name;
                break;
            }
        }
        
        if (destination == noone) {
            console_print("Destination '" + argument + "' not found. Type 'TRAVEL' to see options.");
            return;
        }
    }
    
    // === CALCULATE COST ===
    var cost = scr_calculate_travel_cost(obj_player.current_location, destination.id);
    
    if (cost == noone) {
        console_print("ERROR: Cannot calculate travel cost to " + dest_name + ".");
        return;
    }
    
    // === DISPLAY JOURNEY PLAN ===
    console_print(_hdr("JOURNEY TO " + string_upper(dest_name)));
    console_print("Distance: " + string(round(cost.distance)) + " km");
    console_print("Terrain: " + string_upper(cost.terrain));
    console_print("Duration: " + string(cost.days) + " days");
    console_print("");
    console_print("Required resources:");
    console_print("  Provisions: " + string(cost.provisions));
    console_print("  Water: " + string(cost.water));
    console_print("  Gold: " + string(cost.gold));
    console_print("");
    
    // TODO: Phase 2 - Check if player can afford this journey
// === CHECK IF PLAYER CAN AFFORD ===
var check = scr_can_afford_journey(cost);

if (!check.can_afford) {
    console_print("INSUFFICIENT RESOURCES!");
    console_print("");
    console_print("You need:");
    
    if (check.missing.provisions > 0) {
        console_print("  " + string(check.missing.provisions) + " more provisions");
    }
    if (check.missing.water > 0) {
        console_print("  " + string(check.missing.water) + " more water");
    }
    if (check.missing.gold > 0) {
        console_print("  " + string(check.missing.gold) + " more gold");
    }
    
    console_print("");
    console_print("Type 'STATUS' to see your current resources.");
    return;
}

// === LAUNCH TRAVEL ANIMATION (journey executes when animation ends) ===
// Look up world x/y for origin and destination
var _dest_wx = 500;  var _dest_wy = 400;  // sensible fallback centre
var _from_wx = 500;  var _from_wy = 400;
var _from_id = obj_player.current_location;
for (var _ti = 0; _ti < array_length(obj_heartbeat.world.locations); _ti++) {
    var _tl = obj_heartbeat.world.locations[_ti];
    if (_tl.id == destination.id) { _dest_wx = _tl.x;  _dest_wy = _tl.y; }
    if (_tl.id == _from_id)       { _from_wx = _tl.x;  _from_wy = _tl.y; }
}

// Look up the route's bezier ctrl point so travel dot follows the curve
var _travel_ctrl_x = (_from_wx + _dest_wx) * 0.5;  // fallback: straight midpoint
var _travel_ctrl_y = (_from_wy + _dest_wy) * 0.5;
for (var _tri = 0; _tri < array_length(obj_heartbeat.world.routes); _tri++) {
    var _trt = obj_heartbeat.world.routes[_tri];
    if ((_trt.from_id == _from_id && _trt.to_id == destination.id) ||
        (_trt.from_id == destination.id && _trt.to_id == _from_id)) {
        if (variable_struct_exists(_trt, "ctrl_x")) {
            _travel_ctrl_x = _trt.ctrl_x;
            _travel_ctrl_y = _trt.ctrl_y;
        }
        break;
    }
}

obj_heartbeat.map_travel_active   = true;
obj_heartbeat.map_travel_timer    = 0;
obj_heartbeat.map_travel_duration = clamp(cost.days * 18, 120, 240);
obj_heartbeat.map_travel_progress = 0;
obj_heartbeat.map_travel_from_x   = _from_wx;
obj_heartbeat.map_travel_from_y   = _from_wy;
obj_heartbeat.map_travel_to_x     = _dest_wx;
obj_heartbeat.map_travel_to_y     = _dest_wy;
obj_heartbeat.map_travel_ctrl_x   = _travel_ctrl_x;
obj_heartbeat.map_travel_ctrl_y   = _travel_ctrl_y;
obj_heartbeat.map_travel_to_name  = dest_name;
obj_heartbeat.map_travel_dest_id  = destination.id;
obj_heartbeat.map_travel_costs    = cost;
obj_heartbeat.map_open            = true;
obj_heartbeat.map_close_delay     = 0;
}