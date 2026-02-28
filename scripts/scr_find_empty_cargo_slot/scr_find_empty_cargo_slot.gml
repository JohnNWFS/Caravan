/// @desc Find first available cargo slot that can hold a commodity.
/// Prefers partially-filled slots with the same commodity before taking an empty slot.
/// @param {String} storage_type The storage type needed (BULK, LUXURY, LIVESTOCK_SMALL, LIVESTOCK_LARGE, etc.)
/// @param {String} [commodity_id] Optional. When provided, partial slots with the same good are checked first.
/// @returns {Struct} {wagon_index, slot_index, slot_type, is_partial} or undefined if no space

function scr_find_empty_cargo_slot(storage_type, commodity_id = undefined) {
    // === PASS 1: PREFER EXISTING PARTIAL SLOTS WITH THE SAME COMMODITY ===
    // Fill available space before consuming a new empty slot.
    if (commodity_id != undefined) {
        if (storage_type == "LIVESTOCK_LARGE") {
            for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
                var wagon = obj_player.caravan.wagons[w];
                if (!variable_struct_exists(wagon.slots, "livestock_trade")) continue;
                var livestock_slots = wagon.slots.livestock_trade;
                if (livestock_slots.capacity == 0) continue;
                for (var s = 0; s < array_length(livestock_slots.contents); s++) {
                    var ls = livestock_slots.contents[s];
                    if (ls != undefined && ls.good_id == commodity_id && ls.quantity < ls.max_quantity) {
                        return {
                            wagon_index: w,
                            slot_index: s,
                            slot_type: "livestock_trade",
                            is_partial: true
                        };
                    }
                }
            }
        } else {
            for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
                var wagon = obj_player.caravan.wagons[w];
                var cargo_slots = wagon.slots.cargo.contents;
                for (var s = 0; s < array_length(cargo_slots); s++) {
                    var slot = cargo_slots[s];
                    if (slot == undefined) continue;
                    // Standard cargo slot with matching commodity and room
                    if (!variable_struct_exists(slot, "slot_type")) {
                        if (slot.good_id == commodity_id && slot.quantity < slot.max_quantity) {
                            return {
                                wagon_index: w,
                                slot_index: s,
                                slot_type: "cargo",
                                is_partial: true
                            };
                        }
                    }
                    // Saddlebag slot with matching commodity and room
                    if (variable_struct_exists(slot, "slot_type") && slot.slot_type == "SADDLEBAG_BULK" && storage_type == "BULK") {
                        if (slot.contents != undefined && slot.contents.good_id == commodity_id && slot.contents.quantity < slot.contents.max_quantity) {
                            return {
                                wagon_index: w,
                                slot_index: s,
                                slot_type: "saddlebag",
                                is_special: true,
                                is_partial: true
                            };
                        }
                    }
                }
            }
        }
    }

    // TODO: ADVANCED ANIMAL SYSTEM
    // Future enhancement: Separate pack animals (provide capacity), draft animals 
    // (required for pulling wagons), and trade livestock into distinct slot types.
    // This will enable features like:
    // - Draft slots: Required for WAGON/CARRIAGE (oxen, draft horses, drakes, dragons)
    // - Pack animal slots: Provide saddlebag capacity (donkeys, mules, pack horses)
    // - Trade livestock slots: For buying/selling large animals
    // - Small livestock: Can use regular cargo slots (pigs, chickens in cages)
    
    // === HANDLE LARGE LIVESTOCK ===
    // Large livestock (cattle, horses, oxen) need special livestock_trade slots
    if (storage_type == "LIVESTOCK_LARGE") {
        for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
            var wagon = obj_player.caravan.wagons[w];
            
            // Check if wagon has livestock_trade slots
            if (!variable_struct_exists(wagon.slots, "livestock_trade")) {
                continue; // This wagon type doesn't support large livestock
            }
            
            var livestock_slots = wagon.slots.livestock_trade;
            
            if (livestock_slots.capacity == 0) {
                continue; // No livestock capacity (like handcart)
            }
            
            // Find empty livestock slot
            for (var s = 0; s < array_length(livestock_slots.contents); s++) {
                if (livestock_slots.contents[s] == undefined) {
                    return {
                        wagon_index: w, 
                        slot_index: s, 
                        slot_type: "livestock_trade"
                    };
                }
            }
        }
        
        return undefined; // No livestock slots available
    }
    
    // === HANDLE REGULAR CARGO (including LIVESTOCK_SMALL) ===
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        var cargo_slots = wagon.slots.cargo.contents;
        
        for (var s = 0; s < array_length(cargo_slots); s++) {
            var slot = cargo_slots[s];
            
            // Check if slot is empty
            if (slot == undefined) {
                // Standard empty slot - can hold anything except LIVESTOCK_LARGE
                return {
                    wagon_index: w, 
                    slot_index: s,
                    slot_type: "cargo"
                };
            }
            
            // Check if it's a special slot (like saddlebag)
            if (variable_struct_exists(slot, "slot_type")) {
                // Check if slot is compatible and empty
                if (slot.slot_type == "SADDLEBAG_BULK" && storage_type == "BULK") {
                    if (slot.contents == undefined) {
                        return {
                            wagon_index: w, 
                            slot_index: s, 
                            slot_type: "saddlebag",
                            is_special: true
                        };
                    }
                }
            }
        }
    }
    
    return undefined; // No space available
}