// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate total water available across all barrels
/// @returns {Real} Total water available

function scr_get_total_water() {
    var total = 0;
    
    for (var i = 0; i < array_length(obj_player.caravan.wagons); i++) {
        var wagon = obj_player.caravan.wagons[i];
        
        // Check equipment slot for water barrels
        if (variable_struct_exists(wagon.slots, "equipment")) {
            var equipment = wagon.slots.equipment.contents;
            for (var j = 0; j < array_length(equipment); j++) {
                var item = equipment[j];
                if (item.type == "BARREL" && item.subtype == "WATER") {
                    total += item.water;
                }
            }
        }
    }
    
    return total;
}