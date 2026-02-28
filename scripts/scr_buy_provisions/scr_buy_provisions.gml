/// @desc Special handler for buying provisions (goes to player stat, not cargo)
/// @param {Struct} location Current location
/// @param {Real} quantity How many provisions to buy

function scr_buy_provisions(location, quantity) {
    var economy = location.economy;
    
    // Check stock
    var available_stock = 0;
    if (variable_struct_exists(economy.stock_levels, "provisions")) {
        available_stock = economy.stock_levels[$ "provisions"];
    }
    
    if (available_stock <= 0) {
        // === EMERGENCY RATIONS ===
        // No inhabited settlement ever truly runs out of food — locals will sell
        // from their personal stores at a premium. Capped at a small amount to
        // reflect scarcity. Regeneration in ghost trades will restore normal stock
        // before long.
        var _emerg_max  = 25;   // most you can buy this way
        var _emerg_mult = 1.5;  // 50% premium over base price

        // Find base price from commodity database
        var _emerg_unit = 3; // fallback: 3 gold each
        for (var _ei = 0; _ei < array_length(global.commodities); _ei++) {
            if (global.commodities[_ei].id == "provisions") {
                _emerg_unit = ceil(global.commodities[_ei].base_value * _emerg_mult);
                break;
            }
        }

        var _emerg_qty   = min(quantity, _emerg_max);
        var _emerg_total = _emerg_unit * _emerg_qty;

        console_print(location.name + " is out of regular provisions.");
        console_print("Locals can spare " + string(_emerg_qty)
                      + " emergency rations — " + string(_emerg_unit) + " gold each ("
                      + string(_emerg_total) + " total).");

        if (obj_player.gold < _emerg_total) {
            console_print("Insufficient gold for emergency rations.");
            console_print("Need: " + string(_emerg_total) + " gold  |  Have: " + string(obj_player.gold) + " gold");
            return;
        }

        obj_player.gold       -= _emerg_total;
        obj_player.provisions += _emerg_qty;

        console_print("");
        console_print("PURCHASE COMPLETE  (emergency rations)");
        console_print("Bought: " + string(_emerg_qty) + " provisions");
        console_print("Cost: " + string(_emerg_total) + " gold (" + string(_emerg_unit) + "g each)");
        console_print("Gold remaining: " + string(obj_player.gold));
        console_print("Provisions: " + string(obj_player.provisions));
        console_print("");
        return;
    }

    // Adjust quantity if needed
    var actual_quantity = min(quantity, available_stock);
    
    if (actual_quantity < quantity) {
        console_print("Only " + string(actual_quantity) + " available (you requested " + string(quantity) + ")");
    }
    
    // Calculate price
    var total_price = scr_calculate_buy_price(location, "provisions", actual_quantity);
    
    if (total_price < 0) {
        console_print("Cannot buy provisions here.");
        return;
    }
    
    // Check if player has enough gold
    if (obj_player.gold < total_price) {
        console_print("Insufficient gold!");
        console_print("Need: " + string(total_price) + " gold");
        console_print("Have: " + string(obj_player.gold) + " gold");
        return;
    }
    
    // === EXECUTE PURCHASE ===
    
    // Deduct gold
    obj_player.gold -= total_price;
    
    // Reduce city stock
    economy.stock_levels[$ "provisions"] -= actual_quantity;
    
    // Add directly to player provisions stat
    obj_player.provisions += actual_quantity;
    
    // === SUCCESS MESSAGE ===
    console_print("");
    console_print("PURCHASE COMPLETE");
    console_print("Bought: " + string(actual_quantity) + " provisions");
    console_print("Cost: " + string(total_price) + " gold (" + string(total_price / actual_quantity) + "g each)");
    console_print("Gold remaining: " + string(obj_player.gold));
    console_print("Provisions: " + string(obj_player.provisions));
    console_print("");
}