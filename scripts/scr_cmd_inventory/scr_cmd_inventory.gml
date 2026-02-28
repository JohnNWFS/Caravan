/// @desc Show detailed inventory focused on trade goods and their values

function scr_cmd_inventory() {
    // Get current location for pricing
    var current_loc = undefined;
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
            current_loc = obj_heartbeat.world.locations[i];
            break;
        }
    }
    
    console_print("");
    console_print("=== INVENTORY ===");
    console_print("");
    
    // === GOLD ===
    console_print("Gold: " + string(obj_player.gold));
    console_print("");
    
    // === CREW/PEOPLE SLOTS ===
    console_print("CREW:");
    var total_crew_slots = 0;
    var used_crew_slots = 0;
    
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        total_crew_slots += wagon.slots.crew.capacity;
        
        for (var c = 0; c < array_length(wagon.slots.crew.contents); c++) {
            var crew = wagon.slots.crew.contents[c];
            used_crew_slots++;
            console_print("  Slot " + string(c + 1) + ": " + crew.name + " (" + crew.type + ")");
        }
    }
    
    console_print("  Total: " + string(used_crew_slots) + "/" + string(total_crew_slots) + " crew slots");
    console_print("");
    
    // === CARGO SLOTS (WAGON/CART) ===
    console_print("WAGON CARGO:");
    var standard_slots_total = 0;
    var standard_slots_used = 0;
    var total_cargo_value = 0;
    
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        var cargo_slots = wagon.slots.cargo.contents;
        
        for (var s = 0; s < array_length(cargo_slots); s++) {
            var slot = cargo_slots[s];
            
            // Skip saddlebag slots (we'll show those separately)
            if (slot != undefined && variable_struct_exists(slot, "slot_type")) {
                if (slot.slot_type == "SADDLEBAG_BULK") {
                    continue;
                }
            }
            
            standard_slots_total++;
            
            if (slot == undefined) {
                console_print("  Slot " + string(s + 1) + ": (empty)");
            } else {
                standard_slots_used++;
                
                // Get commodity info
                var commodity = scr_get_commodity_by_id(slot.good_id);
                
                if (commodity != undefined) {
                    var quantity = slot.quantity;
                    var value = 0;
                    
                    // Calculate sell value at current location
                    if (current_loc != undefined) {
                        value = scr_calculate_sell_price(current_loc, slot.good_id, quantity);
                    }
                    
                    var line = "  Slot " + string(s + 1) + ": ";
                    line += commodity.name + " x" + string(quantity);
                    line += "/" + string(commodity.units_per_slot);
                    line += " (" + slot.storage_type + ")";
                    
                    if (value > 0) {
                        line += " - Worth: " + string(value) + "g";
                        total_cargo_value += value;
                    }
                    
                    console_print(line);
                } else {
                    console_print("  Slot " + string(s + 1) + ": Unknown item");
                }
            }
        }
    }
    
    console_print("  Total: " + string(standard_slots_used) + "/" + string(standard_slots_total) + " wagon slots used");
    console_print("");
    
    // === PACK ANIMAL SLOTS (SADDLEBAGS) ===
    var has_saddlebags = false;
    var saddlebag_slots_total = 0;
    var saddlebag_slots_used = 0;
    
    // Check if player has pack animals with saddlebags
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        
        for (var a = 0; a < array_length(wagon.slots.animals.contents); a++) {
            var animal = wagon.slots.animals.contents[a];
            if (variable_struct_exists(animal, "has_saddlebags") && animal.has_saddlebags) {
                has_saddlebags = true;
                break;
            }
        }
    }
    
    if (has_saddlebags) {
        console_print("PACK ANIMAL CARGO (BULK only):");
        
        for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
            var wagon = obj_player.caravan.wagons[w];
            var cargo_slots = wagon.slots.cargo.contents;
            
            for (var s = 0; s < array_length(cargo_slots); s++) {
                var slot = cargo_slots[s];
                
                // Only show saddlebag slots
                if (slot != undefined && variable_struct_exists(slot, "slot_type")) {
                    if (slot.slot_type == "SADDLEBAG_BULK") {
                        saddlebag_slots_total++;
                        
                        if (slot.contents == undefined) {
                            console_print("  Saddlebag " + string(s + 1) + ": (empty)");
                        } else {
                            saddlebag_slots_used++;
                            
                            var commodity = scr_get_commodity_by_id(slot.contents.good_id);
                            
                            if (commodity != undefined) {
                                var quantity = slot.contents.quantity;
                                var value = 0;
                                
                                if (current_loc != undefined) {
                                    value = scr_calculate_sell_price(current_loc, slot.contents.good_id, quantity);
                                }
                                
                                var line = "  Saddlebag " + string(s + 1) + ": ";
                                line += commodity.name + " x" + string(quantity);
                                line += "/" + string(commodity.units_per_slot);
                                
                                if (value > 0) {
                                    line += " - Worth: " + string(value) + "g";
                                    total_cargo_value += value;
                                }
                                
                                console_print(line);
                            }
                        }
                    }
                }
            }
        }
        
        console_print("  Total: " + string(saddlebag_slots_used) + "/" + string(saddlebag_slots_total) + " saddlebag slots used");
        console_print("");
    }
    
    // === EQUIPMENT SLOTS ===
    console_print("EQUIPMENT:");
    var equipment_count = 0;
    
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        
        if (variable_struct_exists(wagon.slots, "equipment")) {
            for (var e = 0; e < array_length(wagon.slots.equipment.contents); e++) {
                var item = wagon.slots.equipment.contents[e];
                equipment_count++;
                
                if (item.type == "BARREL" && item.subtype == "WATER") {
                    console_print("  Equipment " + string(e + 1) + ": Water Barrel (" + string(item.water) + "/" + string(item.max_water) + ")");
                } else {
                    console_print("  Equipment " + string(e + 1) + ": " + item.type);
                }
            }
        }
    }
    
    if (equipment_count == 0) {
        console_print("  (no equipment)");
    }
    
    console_print("");
    
    // === SUMMARY ===
    console_print("--- SUMMARY ---");
    console_print("Total cargo value: " + string(total_cargo_value) + " gold");
    console_print("Total wealth: " + string(obj_player.gold + total_cargo_value) + " gold");
    console_print("");
    console_print("Provisions: " + string(obj_player.provisions));
    console_print("Water: " + string(scr_get_total_water()) + "/" + string(scr_get_max_water_capacity()));
    console_print("");
}