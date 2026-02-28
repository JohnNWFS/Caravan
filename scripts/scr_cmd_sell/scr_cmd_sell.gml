// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle SELL command - sell goods to city
/// @param {String} good_name The commodity name
/// @param {Real} quantity How many to sell

function scr_cmd_sell(good_name, quantity) {
    // Get current location
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
        return;
    }

    var economy = current_loc.economy;

	    // === SPECIAL HANDLING: PROVISIONS ===
	    // Provisions live in the player stat, not a cargo slot.
	    // Selling reduces the stat directly and routes the stock back through the
	    // same three-way economy logic used for every other good.
	    if (commodity.id == "provisions") {
	        var _have_prov     = obj_player.provisions;
	        var _actual_sell_p = min(quantity, _have_prov);

	        if (_actual_sell_p <= 0) {
	            console_print("You have no provisions to sell.");
	            return;
	        }

	        var _prov_price = scr_calculate_sell_price(current_loc, "provisions", _actual_sell_p);

	        // Deduct from stat and pay player
	        obj_player.provisions -= _actual_sell_p;
	        obj_player.gold       += _prov_price;

	        // === UPDATE TOWN INVENTORY (three-way routing) ===
	        var _pp_is_produced = false;
	        for (var _ppi = 0; _ppi < array_length(economy.produces); _ppi++) {
	            if (economy.produces[_ppi].good_id == "provisions") { _pp_is_produced = true; break; }
	        }
	        var _pp_is_demanded = false;
	        for (var _pdi = 0; _pdi < array_length(economy.demands); _pdi++) {
	            if (economy.demands[_pdi].good_id == "provisions") { _pp_is_demanded = true; break; }
	        }

	        if (_pp_is_produced) {
	            // Farming town — sold provisions simply restock their supply
	            if (variable_struct_exists(economy.stock_levels, "provisions")) {
	                economy.stock_levels[$ "provisions"] += _actual_sell_p;
	            } else {
	                economy.stock_levels[$ "provisions"] = _actual_sell_p;
	            }
	        } else if (!_pp_is_demanded) {
	            // Neutral — small fraction enters resale stock at markup
	            var _pp_resale_qty   = max(1, round(_actual_sell_p * 0.25));
	            var _pp_unit_paid    = _prov_price / _actual_sell_p;
	            var _pp_resale_price = ceil(_pp_unit_paid * 1.25);
	            if (!variable_struct_exists(economy, "resale_stock")) economy.resale_stock = {};
	            if (variable_struct_exists(economy.resale_stock, "provisions")) {
	                economy.resale_stock[$ "provisions"].qty       += _pp_resale_qty;
	                economy.resale_stock[$ "provisions"].unit_price = _pp_resale_price;
	            } else {
	                economy.resale_stock[$ "provisions"] = { qty: _pp_resale_qty, unit_price: _pp_resale_price };
	            }
	        }
	        // Demanded town: provisions consumed internally — nothing enters market (they needed it)

	        // Success message
	        console_print("");
	        console_print("SALE COMPLETE");
	        console_print("Sold: " + string(_actual_sell_p) + " provisions");
	        console_print("Earned: " + string(_prov_price) + " gold");
	        console_print("Gold total: " + string(obj_player.gold));
	        console_print("Provisions remaining: " + string(obj_player.provisions));
	        console_print("");

	        // Warn if the player is cutting it dangerously close
	        if (obj_player.provisions < 15) {
	            console_print("WARNING: Only " + string(obj_player.provisions) + " provisions left.");
	            console_print("         Check journey costs before moving on.");
	            console_print("");
	        }
	        return;
	    }
	
	
    
    // Find commodity in player cargo
    var found_slot = undefined;
    var found_wagon = undefined;
    var player_has = 0;
    
    for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
        var wagon = obj_player.caravan.wagons[w];
        var cargo_slots = wagon.slots.cargo.contents;
        
        for (var s = 0; s < array_length(cargo_slots); s++) {
            var slot = cargo_slots[s];
            
            if (slot == undefined) continue;
            
            var slot_good_id = undefined;
            var slot_quantity = 0;
            
            // Check standard slot
            if (variable_struct_exists(slot, "good_id")) {
                slot_good_id = slot.good_id;
                slot_quantity = slot.quantity;
            }
            // Check special slot
            else if (variable_struct_exists(slot, "contents") && slot.contents != undefined) {
                slot_good_id = slot.contents.good_id;
                slot_quantity = slot.contents.quantity;
            }
            
            if (slot_good_id == commodity.id) {
                found_slot = s;
                found_wagon = w;
                player_has = slot_quantity;
                break;
            }
        }
        
        if (found_slot != undefined) break;
    }
    
    if (found_slot == undefined) {
        console_print("You don't have any " + commodity.name + " to sell.");
        return;
    }
    
    // Adjust quantity if trying to sell more than we have
    var actual_quantity = min(quantity, player_has);
    
    if (actual_quantity < quantity) {
        console_print("You only have " + string(actual_quantity) + " (you tried to sell " + string(quantity) + ")");
    }
    
    // Calculate price
    var total_price = scr_calculate_sell_price(current_loc, commodity.id, actual_quantity);
    
    // Check for discovery event (10% chance for new commodity)
    var is_new_commodity = true;
    
    // Check if they already produce or demand it
    for (var i = 0; i < array_length(economy.produces); i++) {
        if (economy.produces[i].good_id == commodity.id) {
            is_new_commodity = false;
            break;
        }
    }
    
    for (var i = 0; i < array_length(economy.demands); i++) {
        if (economy.demands[i].good_id == commodity.id) {
            is_new_commodity = false;
            break;
        }
    }
    
    // Check if already discovered
    for (var i = 0; i < array_length(economy.discovered_wants); i++) {
        if (economy.discovered_wants[i] == commodity.id) {
            is_new_commodity = false;
            break;
        }
    }
    
    var discovered = false;
    if (is_new_commodity && random(1) < 0.1) {
        // Discovery!
        discovered = true;
        array_push(economy.discovered_wants, commodity.id);
        
        // Recalculate price with discovery bonus
        total_price = scr_calculate_sell_price(current_loc, commodity.id, actual_quantity);
    }
    
    // === EXECUTE SALE ===
    
    // Add gold
    obj_player.gold += total_price;
    
    // === UPDATE TOWN INVENTORY ===
    // Three cases based on the town's relationship to this commodity:
    //   PRODUCED  — sold units simply replenish existing supply; priced normally.
    //   DEMANDED  — the town consumes the goods internally; no resale (they needed it).
    //   NEUTRAL   — a local merchant buys a fraction (25%, min 1) for resale at a
    //               25% markup over the player's sell price. The rest is absorbed.
    //               This stock decays over time as other travelers buy it up.
    var _is_produced = false;
    for (var _pi = 0; _pi < array_length(economy.produces); _pi++) {
        if (economy.produces[_pi].good_id == commodity.id) {
            _is_produced = true;
            break;
        }
    }

    var _is_demanded = false;
    for (var _di = 0; _di < array_length(economy.demands); _di++) {
        if (economy.demands[_di].good_id == commodity.id) {
            _is_demanded = true;
            break;
        }
    }

    if (_is_produced) {
        // Replenish the town's own supply
        if (variable_struct_exists(economy.stock_levels, commodity.id)) {
            economy.stock_levels[$ commodity.id] += actual_quantity;
        } else {
            economy.stock_levels[$ commodity.id] = actual_quantity;
        }
    } else if (!_is_demanded) {
        // Neutral good — fraction enters resale stock at a 25% markup
        var _resale_qty   = max(1, round(actual_quantity * 0.25));
        var _unit_paid    = total_price / actual_quantity; // gold player received per unit
        var _resale_price = ceil(_unit_paid * 1.25);       // town resells at 25% markup

        if (!variable_struct_exists(economy, "resale_stock")) {
            economy.resale_stock = {};
        }

        if (variable_struct_exists(economy.resale_stock, commodity.id)) {
            var _ex = economy.resale_stock[$ commodity.id];
            _ex.qty        += _resale_qty;
            _ex.unit_price  = _resale_price; // update to the latest transaction's price
        } else {
            economy.resale_stock[$ commodity.id] = {
                qty:        _resale_qty,
                unit_price: _resale_price
            };
        }
    }
    // Demanded goods: gold paid, goods consumed by the town — nothing enters the market.
    
    // Remove from player cargo
    var wagon = obj_player.caravan.wagons[found_wagon];
    var slot = wagon.slots.cargo.contents[found_slot];
    
    if (variable_struct_exists(slot, "contents")) {
        // Special slot
        slot.contents.quantity -= actual_quantity;
        if (slot.contents.quantity <= 0) {
            slot.contents = undefined; // Empty the slot
        }
    } else {
        // Standard slot
        slot.quantity -= actual_quantity;
        if (slot.quantity <= 0) {
            wagon.slots.cargo.contents[found_slot] = undefined; // Empty the slot
        }
    }
    
    // === SUCCESS MESSAGE ===
    console_print("");
    console_print("SALE COMPLETE");
    console_print("Sold: " + string(actual_quantity) + " " + commodity.name);
    console_print("Earned: " + string(total_price) + " gold");
    console_print("Gold total: " + string(obj_player.gold));
    
    if (discovered) {
        console_print("");
        console_print("*** DISCOVERY! ***");
        console_print(current_loc.name + " has discovered they love " + commodity.name + "!");
        console_print("They'll pay premium prices for it from now on.");
    }
    
    console_print("");
}