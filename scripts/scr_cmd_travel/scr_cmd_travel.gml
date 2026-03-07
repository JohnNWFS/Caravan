// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle TRAVEL command - shows available destinations with costs

function scr_cmd_travel() {
    console_print(_hdr("AVAILABLE DESTINATIONS"));
    console_print("");
    
    var options = scr_get_travel_options();
    
    if (array_length(options) == 0) {
        console_print("No travel routes available from this location.");
        return;
    }
    
    var current_loc_id = obj_player.current_location;
    
    // Display each destination with number and costs
    for (var i = 0; i < array_length(options); i++) {
        var dest = options[i];
        
        // Format the distance (round to nearest km)
        var dist_str = string(round(dest.distance));
        
        // Create formatted header line with number
        var line = string(i + 1) + ". ";
        line += string_upper(dest.name) + " (" + string_upper(dest.type) + ")";
        line += " - " + dist_str + " km - " + string_upper(dest.terrain);
        
        console_print(line);
        
        // Calculate travel costs for this route
        var cost = scr_calculate_travel_cost(current_loc_id, dest.id);
        
        if (cost != noone) {
            // Display journey requirements
            var cost_line = "   Journey: " + string(cost.days) + " days";
            cost_line += " | Requires: " + string(cost.provisions) + " provisions";
            cost_line += ", " + string(cost.water) + " water";
            cost_line += ", " + string(cost.gold) + " gold";
            
            console_print(cost_line);
        } else {
            console_print("   ERROR: Cannot calculate cost for this route");
        }

        // Calculate total sell value of current cargo at this destination
        var _dest_loc = undefined;
        for (var _li = 0; _li < array_length(obj_heartbeat.world.locations); _li++) {
            if (obj_heartbeat.world.locations[_li].id == dest.id) {
                _dest_loc = obj_heartbeat.world.locations[_li];
                break;
            }
        }
        var _cargo_val = 0;
        if (_dest_loc != undefined && variable_struct_exists(obj_player, "caravan")) {
            for (var _wi = 0; _wi < array_length(obj_player.caravan.wagons); _wi++) {
                var _cargo = obj_player.caravan.wagons[_wi].slots.cargo.contents;
                for (var _ci = 0; _ci < array_length(_cargo); _ci++) {
                    var _slot = _cargo[_ci];
                    if (_slot == undefined) continue;
                    if (variable_struct_exists(_slot, "slot_type")
                    &&  _slot.slot_type == "SADDLEBAG_BULK") {
                        // Saddlebag container — value is in its contents
                        if (_slot.contents != undefined) {
                            _cargo_val += scr_calculate_sell_price(
                                _dest_loc, _slot.contents.good_id, _slot.contents.quantity);
                        }
                    } else {
                        // Standard cargo slot
                        _cargo_val += scr_calculate_sell_price(
                            _dest_loc, _slot.good_id, _slot.quantity);
                    }
                }
            }
        }
        if (_cargo_val > 0) {
            console_print("   Cargo value there: " + string(_cargo_val) + "g");
        }

        console_print(""); // Blank line between destinations
    }
    
    console_print("Use 'GO <name>' or 'GO <number>' to travel");
}