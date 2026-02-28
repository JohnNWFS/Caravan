// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle BUY command - purchase goods from city
/// @param {String} good_name The commodity name
/// @param {Real} quantity How many to buy
/// @param {Bool} [confirmed] Internal flag set to true when player confirms a spillover prompt

function scr_cmd_buy(good_name, quantity, confirmed = false) {
    // === FIND CURRENT LOCATION ===
    var current_loc = undefined;
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
            current_loc = obj_heartbeat.world.locations[i];
            break;
        }
    }

    if (current_loc == undefined) {
        console_print("ERROR: Current location not found.");
        return;
    }

    // Find commodity by name or alias
    var commodity = scr_find_commodity_by_name(good_name);

    if (commodity == undefined) {
        console_print("Unknown commodity: " + good_name);
        console_print("Type 'MARKET' to see available goods.");
        return;
    }

    // === SPECIAL HANDLING: PROVISIONS ===
    // Provisions go directly to player stat, not cargo
    if (commodity.id == "provisions") {
        scr_buy_provisions(current_loc, quantity);
        return;
    }

    // Check if city has stock — produced goods live in stock_levels;
    // player-sold resale goods live in resale_stock.
    var economy      = current_loc.economy;
    var available_stock = 0;
    var _from_resale = false;

    if (variable_struct_exists(economy.stock_levels, commodity.id)) {
        available_stock = economy.stock_levels[$ commodity.id];
    }

    // Fall back to resale stock when the town has no produced supply
    if (available_stock <= 0
        && variable_struct_exists(economy, "resale_stock")
        && variable_struct_exists(economy.resale_stock, commodity.id)) {
        var _re = economy.resale_stock[$ commodity.id];
        if (_re.qty > 0) {
            available_stock = _re.qty;
            _from_resale    = true;
        }
    }

    if (available_stock <= 0) {
        console_print(current_loc.name + " doesn't have any " + commodity.name + " for sale.");
        return;
    }

    // Cap quantity by city stock
    var actual_quantity = min(quantity, available_stock);

    if (actual_quantity < quantity) {
        console_print("Only " + string(actual_quantity) + " available (you requested " + string(quantity) + ")");
    }

    // === CALCULATE TOTAL CARGO SPACE ===
    // partial_space  = room remaining in slots already holding this commodity
    // empty_slot_count = empty slots that accept this storage type
    var partial_space = 0;
    var empty_slot_count = 0;

    if (commodity.storage_type == "LIVESTOCK_LARGE") {
        for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
            var wagon = obj_player.caravan.wagons[w];
            if (!variable_struct_exists(wagon.slots, "livestock_trade")) continue;
            var ls = wagon.slots.livestock_trade;
            if (ls.capacity == 0) continue;
            for (var s = 0; s < array_length(ls.contents); s++) {
                var lslot = ls.contents[s];
                if (lslot == undefined) {
                    empty_slot_count++;
                } else if (lslot.good_id == commodity.id && lslot.quantity < lslot.max_quantity) {
                    partial_space += (lslot.max_quantity - lslot.quantity);
                }
            }
        }
    } else {
        for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
            var wagon = obj_player.caravan.wagons[w];
            var cargo = wagon.slots.cargo.contents;
            for (var s = 0; s < array_length(cargo); s++) {
                var slot = cargo[s];
                if (slot == undefined) {
                    empty_slot_count++;
                } else if (variable_struct_exists(slot, "slot_type")) {
                    // Saddlebag slot
                    if (slot.slot_type == "SADDLEBAG_BULK" && commodity.storage_type == "BULK") {
                        if (slot.contents == undefined) {
                            empty_slot_count++;
                        } else if (slot.contents.good_id == commodity.id && slot.contents.quantity < slot.contents.max_quantity) {
                            partial_space += (slot.contents.max_quantity - slot.contents.quantity);
                        }
                    }
                } else {
                    // Standard cargo slot
                    if (slot.good_id == commodity.id && slot.quantity < slot.max_quantity) {
                        partial_space += (slot.max_quantity - slot.quantity);
                    }
                }
            }
        }
    }

    var total_space = partial_space + (empty_slot_count * commodity.units_per_slot);

    if (total_space <= 0) {
        console_print("No cargo space available for " + commodity.name + "!");
        console_print("Sell or discard goods to free up a slot.");
        return;
    }

    // Cap purchase by total available cargo space
    if (actual_quantity > total_space) {
        actual_quantity = total_space;
        console_print("Only space for " + string(actual_quantity) + " " + commodity.name + " in your cargo.");
    }

    // Calculate price for the (possibly adjusted) quantity
    var total_price = scr_calculate_buy_price(current_loc, commodity.id, actual_quantity);

    if (total_price < 0) {
        console_print("Cannot buy " + commodity.name + " here.");
        return;
    }

    // Check if player has enough gold
    if (obj_player.gold < total_price) {
        console_print("Insufficient gold!");
        console_print("Need: " + string(total_price) + " gold");
        console_print("Have: " + string(obj_player.gold) + " gold");
        return;
    }

    // === SPILLOVER CONFIRMATION ===
    // Ask when: existing partial slot(s) exist but can't hold the full purchase.
    // A new slot would be consumed — confirm before taking it.
    if (!confirmed && partial_space > 0 && actual_quantity > partial_space) {
        var overflow = actual_quantity - partial_space;
        var new_slots_needed = ceil(overflow / commodity.units_per_slot);

        console_print("");
        console_print("CARGO NOTICE:");
        console_print("  " + string(partial_space) + " " + commodity.name + " will fill your existing slot(s)");
        console_print("  " + string(overflow) + " more will go into " + string(new_slots_needed) + " new slot(s)");
        console_print("  Total cost: " + string(total_price) + " gold");
        console_print("");
        console_print("Type YES to confirm or NO to cancel.");

        obj_player.pending_action = {
            type: "buy",
            good_name: good_name,
            quantity: actual_quantity
        };
        return;
    }

    // === EXECUTE PURCHASE ===
    obj_player.pending_action = undefined;

    obj_player.gold -= total_price;

    // Deplete from the correct stock source
    if (_from_resale) {
        economy.resale_stock[$ commodity.id].qty -= actual_quantity;
        if (economy.resale_stock[$ commodity.id].qty <= 0) {
            variable_struct_remove(economy.resale_stock, commodity.id);
        }
    } else {
        economy.stock_levels[$ commodity.id] -= actual_quantity;
    }

    // Placement loop: fill partial slots first, then take empty slots as needed.
    var remaining = actual_quantity;
    var topup_units = 0;    // units added to existing partial slots
    var new_slot_units = 0; // units placed in fresh empty slots

    while (remaining > 0) {
        var slot_info = scr_find_empty_cargo_slot(commodity.storage_type, commodity.id);

        if (slot_info == undefined) break; // shouldn't happen — space was pre-checked

        var wagon = obj_player.caravan.wagons[slot_info.wagon_index];
        var is_partial = variable_struct_exists(slot_info, "is_partial") && slot_info.is_partial;
        var to_place = remaining;

        if (slot_info.slot_type == "livestock_trade") {
            if (is_partial) {
                var ls = wagon.slots.livestock_trade.contents[slot_info.slot_index];
                to_place = min(remaining, ls.max_quantity - ls.quantity);
                ls.quantity += to_place;
            } else {
                to_place = min(remaining, commodity.units_per_slot);
                wagon.slots.livestock_trade.contents[slot_info.slot_index] = {
                    good_id: commodity.id,
                    quantity: to_place,
                    max_quantity: commodity.units_per_slot,
                    storage_type: commodity.storage_type
                };
            }
        } else if (variable_struct_exists(slot_info, "is_special") && slot_info.is_special) {
            var sb = wagon.slots.cargo.contents[slot_info.slot_index];
            if (is_partial) {
                to_place = min(remaining, sb.contents.max_quantity - sb.contents.quantity);
                sb.contents.quantity += to_place;
            } else {
                to_place = min(remaining, commodity.units_per_slot);
                sb.contents = {
                    good_id: commodity.id,
                    quantity: to_place,
                    max_quantity: commodity.units_per_slot
                };
            }
        } else {
            if (is_partial) {
                var existing = wagon.slots.cargo.contents[slot_info.slot_index];
                to_place = min(remaining, existing.max_quantity - existing.quantity);
                existing.quantity += to_place;
            } else {
                to_place = min(remaining, commodity.units_per_slot);
                wagon.slots.cargo.contents[slot_info.slot_index] = {
                    good_id: commodity.id,
                    quantity: to_place,
                    max_quantity: commodity.units_per_slot,
                    storage_type: commodity.storage_type
                };
            }
        }

        if (is_partial) {
            topup_units += to_place;
        } else {
            new_slot_units += to_place;
        }

        remaining -= to_place;
    }

    // === SUCCESS MESSAGE ===
    console_print("");
    console_print("PURCHASE COMPLETE");
    console_print("Bought: " + string(actual_quantity) + " " + commodity.name);
    if (topup_units > 0 && new_slot_units > 0) {
        console_print("  " + string(topup_units) + " added to existing slot(s)");
        console_print("  " + string(new_slot_units) + " placed in new slot(s)");
    }
    console_print("Cost: " + string(total_price) + " gold");
    console_print("Gold remaining: " + string(obj_player.gold));
    console_print("");
}
