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
    console_print("=== JOURNEY TO " + string_upper(dest_name) + " ===");
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

// TODO: Phase 3 - Actually execute the journey
//console_print("[Travel execution not yet implemented]");
console_print("You have enough resources to make this journey!");
console_print("When complete, this will deduct resources and move you to " + dest_name + ".");
// === EXECUTE JOURNEY ===
scr_begin_journey(destination.id, cost);
}