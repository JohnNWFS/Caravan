// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle TRAVEL command - shows available destinations with costs

function scr_cmd_travel() {
    console_print("=== AVAILABLE DESTINATIONS ===");
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
        
        console_print(""); // Blank line between destinations
    }
    
    console_print("Use 'GO <name>' or 'GO <number>' to travel");
}