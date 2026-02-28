/// @desc Refill all barrels to maximum capacity (called when arriving at a town)

function scr_refill_water() {
    var barrels_filled = 0;
    var water_added = 0;
    
    for (var i = 0; i < array_length(obj_player.caravan.wagons); i++) {
        var wagon = obj_player.caravan.wagons[i];
        
        // Check equipment slot for water barrels
        if (variable_struct_exists(wagon.slots, "equipment")) {
            var equipment = wagon.slots.equipment.contents;
            
            for (var j = 0; j < array_length(equipment); j++) {
                var item = equipment[j];
                if (item.type == "BARREL" && item.subtype == "WATER") {
                    var added = item.max_water - item.water;
                    item.water = item.max_water;
                    water_added += added;
                    barrels_filled++;
                }
            }
        }
    }
    
    return {
        barrels: barrels_filled,
        water: water_added
    };
}