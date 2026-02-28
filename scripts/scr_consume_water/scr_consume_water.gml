// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Consume water from barrels (consumes from first barrel first, then next, etc.)
/// @param {Real} amount Amount of water to consume
/// @returns {Bool} True if successful, false if not enough water

function scr_consume_water(amount) {
    var remaining = amount;
    
    for (var i = 0; i < array_length(obj_player.caravan.wagons); i++) {
        var wagon = obj_player.caravan.wagons[i];
        
        // Check equipment slot for water barrels
        if (variable_struct_exists(wagon.slots, "equipment")) {
            var equipment = wagon.slots.equipment.contents;
            
            for (var j = 0; j < array_length(equipment); j++) {
                var item = equipment[j];
                if (item.type == "BARREL" && item.subtype == "WATER" && item.water > 0) {
                    var take = min(remaining, item.water);
                    item.water -= take;
                    remaining -= take;
                    
                    if (remaining <= 0) {
                        return true;
                    }
                }
            }
        }
    }
    
    // If we get here, we didn't have enough water
    return (remaining <= 0);
}