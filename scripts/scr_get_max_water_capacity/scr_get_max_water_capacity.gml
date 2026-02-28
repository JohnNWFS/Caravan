// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

/// @desc Calculate maximum water capacity across all barrels
/// @returns {Real} Maximum water capacity

function scr_get_max_water_capacity() {
    var total = 0;
    
    for (var i = 0; i < array_length(obj_player.caravan.wagons); i++) {
        var wagon = obj_player.caravan.wagons[i];
        
        // Check equipment slot for water barrels
        if (variable_struct_exists(wagon.slots, "equipment")) {
            var equipment = wagon.slots.equipment.contents;
            for (var j = 0; j < array_length(equipment); j++) {
                var item = equipment[j];
                if (item.type == "BARREL" && item.subtype == "WATER") {
                    total += item.max_water;
                }
            }
        }
    }
    
    return total;
}