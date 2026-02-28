// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Generate economy for a location based on terrain and type
/// @param {Struct} location The location to generate economy for
/// @returns {Struct} Economy data structure

function scr_generate_location_economy(location) {
    var economy = {
        produces: [],           // What they sell (cheap here)
        demands: [],            // What they buy (expensive here)
        discovered_wants: [],   // Goods they've learned to want
        stock_levels: {},       // How much of each good they have
        price_modifiers: {},    // Price adjustments per good
        resale_stock: {},       // Goods sold by the player; tracked separately for decay & fixed pricing
        last_simulated_day: 0,  // For ghost caravan simulation
        player_visited: false,  // Has player been here yet?
        ghost_trade_history: [] // Record of ghost trades
    };

	 // === ALWAYS ADD PROVISIONS ===
    // Every settlement has basic food/supplies available
    var provisions_stock = 200; // Base stock
    var provisions_price = 1.0; // Base price modifier
    
    // Adjust by location type
    if (location.type == "CITY") {
        provisions_stock = 500; // Cities have more
        provisions_price = 0.9; // Slightly cheaper (economy of scale)
    } else if (location.type == "VILLAGE") {
        provisions_stock = 100; // Villages have less
        provisions_price = 1.1; // Slightly more expensive
    }
    
    // TODO: Adjust price by terrain (DESERT/MOUNTAIN = more expensive)
    // This will be implemented later when we add terrain-based modifiers
    
    array_push(economy.produces, {
        good_id: "provisions",
        stock: provisions_stock,
        base_price_mod: provisions_price
    });
    
    economy.stock_levels[$ "provisions"] = provisions_stock;
    economy.price_modifiers[$ "provisions"] = provisions_price;

    // Determine terrain type from nearest location characteristics
    // For now, we'll use a simple approach based on location type
    var terrain = "PLAINS"; // Default
    
    // You can enhance this later to use actual terrain data if available
    // For now, we'll infer from location properties or randomize weighted by region
    
    // === DETERMINE PRODUCTION (What they SELL cheap) ===
    var production_count = 0;
    
    // Cities produce more variety
    if (location.type == "CITY") {
        production_count = irandom_range(2, 3);
    } else if (location.type == "TOWN") {
        production_count = irandom_range(1, 2);
    } else { // VILLAGE
        production_count = 1;
    }
    
    // Get commodities that match this location's characteristics
    var available_commodities = scr_filter_commodities_by_terrain(location);
    
    // Select random goods to produce
    for (var i = 0; i < production_count; i++) {
        if (array_length(available_commodities) == 0) break;
        
        var picked_index = irandom(array_length(available_commodities) - 1);
        var commodity = available_commodities[picked_index];
        
        // Add to production
        array_push(economy.produces, {
            good_id: commodity.id,
            stock: irandom_range(100, 500), // Initial stock
            base_price_mod: 0.7 // They sell 30% cheaper
        });
        
        // Initialize stock level
        economy.stock_levels[$ commodity.id] = irandom_range(100, 500);
        
        // Initialize price modifier
        economy.price_modifiers[$ commodity.id] = 0.7;
        
        // Remove from available pool so we don't pick it again
        array_delete(available_commodities, picked_index, 1);
    }
    
    // === DETERMINE DEMAND (What they BUY expensive) ===
    var demand_count = 0;
    
    if (location.type == "CITY") {
        demand_count = irandom_range(2, 4);
    } else if (location.type == "TOWN") {
        demand_count = irandom_range(1, 3);
    } else { // VILLAGE
        demand_count = irandom_range(1, 2);
    }
    
    // Get all commodities they DON'T produce
    var demand_pool = [];
    for (var i = 0; i < array_length(global.commodities); i++) {
        var commodity = global.commodities[i];
        var already_producing = false;
        
        // Check if already in production
        for (var j = 0; j < array_length(economy.produces); j++) {
            if (economy.produces[j].good_id == commodity.id) {
                already_producing = true;
                break;
            }
        }
        
        if (!already_producing) {
            array_push(demand_pool, commodity);
        }
    }
    
    // Select random goods to demand
    for (var i = 0; i < demand_count; i++) {
        if (array_length(demand_pool) == 0) break;
        
        var picked_index = irandom(array_length(demand_pool) - 1);
        var commodity = demand_pool[picked_index];
        
        // Add to demand
        array_push(economy.demands, {
            good_id: commodity.id,
            demand_level: irandom_range(50, 200), // How much they want
            base_price_mod: 1.5 // They pay 50% more
        });
        
        // Initialize price modifier
        economy.price_modifiers[$ commodity.id] = 1.5;
        
        // Remove from pool
        array_delete(demand_pool, picked_index, 1);
    }
    
    return economy;
}