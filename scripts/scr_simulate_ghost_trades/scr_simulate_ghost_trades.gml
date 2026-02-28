// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Simulate ghost caravan trades at a location based on time elapsed
/// @param {Struct} location The location to simulate

function scr_simulate_ghost_trades(location) {
    // TODO: INTELLIGENCE SYSTEM INTEGRATION
    // When intelligence gathering is implemented (spies, informants, trade reports),
    // this function should also be called for locations where the player has
    // active intelligence, not just on physical visits. This will provide
    // real-time market data for locations the player is monitoring remotely.
    
    var days_since_last = obj_heartbeat.day - location.economy.last_simulated_day;

    if (days_since_last <= 0) return; // Visited same day, no simulation

    // === RESALE STOCK DECAY ===
    // Simulate other travelers gradually buying up goods the player sold here.
    // Each good loses 1 unit per elapsed day; entries that reach 0 are removed.
    if (variable_struct_exists(location.economy, "resale_stock")) {
        var _rkeys = variable_struct_get_names(location.economy.resale_stock);
        for (var _ri = 0; _ri < array_length(_rkeys); _ri++) {
            var _rkey   = _rkeys[_ri];
            var _rentry = location.economy.resale_stock[$ _rkey];
            _rentry.qty -= days_since_last;
            if (_rentry.qty <= 0) {
                variable_struct_remove(location.economy.resale_stock, _rkey);
            }
        }
    }

    var possible_trades = 0;
    var base_chance = 0;
    
    // First visit gets special "catch-up" logic
    if (!location.economy.player_visited) {
        // More aggressive simulation - world has been trading without you
        possible_trades = floor(days_since_last / 10); // 1 per 10 days
        base_chance = 0.7; // 70% per potential trade
    } else {
        // Ongoing visits - lighter touch
        possible_trades = floor(days_since_last / 20); // 1 per 20 days
        base_chance = 0.4; // 40% per potential trade
    }
    
    // Execute ghost trades
    for (var i = 0; i < possible_trades; i++) {
        if (random(1) < base_chance) {
            // Random: ghost caravan sells TO city (adds stock)
            if (random(1) < 0.5) {
                var ghost_good = scr_pick_random_commodity();
                var ghost_qty = irandom_range(10, 50);
                scr_add_ghost_commodity(location, ghost_good.id, ghost_qty);
            } 
            // Or: ghost caravan buys FROM city (reduces stock)
            else {
                scr_reduce_random_commodity(location, irandom_range(10, 50));
            }
        }
    }
    
    // === PROVISIONS REGENERATION ===
    // Every settlement grows food locally — farms, gardens, livestock.
    // Daily replenishment scales by settlement size and is capped so towns
    // can't stockpile indefinitely. Running completely dry is unrealistic
    // for any inhabited place, and this ensures it never stays that way.
    var _prov_regen = 0;
    var _prov_cap   = 0;
    switch (location.type) {
        case "CITY":    _prov_regen = 15; _prov_cap = 500; break;
        case "TOWN":    _prov_regen =  8; _prov_cap = 300; break;
        case "VILLAGE": _prov_regen =  4; _prov_cap = 150; break;
        default:        _prov_regen =  4; _prov_cap = 150; break;
    }
    var _cur_prov = 0;
    if (variable_struct_exists(location.economy.stock_levels, "provisions")) {
        _cur_prov = location.economy.stock_levels[$ "provisions"];
    }
    location.economy.stock_levels[$ "provisions"] = min(_cur_prov + (_prov_regen * days_since_last), _prov_cap);

    // === PRODUCED GOODS REGENERATION ===
    // Craftsmen, farmers, and miners keep working even when the player is absent.
    // Same rates as scr_world_tick — prevents permanent depletion on active routes.
    var _prod_regen = 0;
    var _prod_cap   = 0;
    switch (location.type) {
        case "CITY":    _prod_regen = 5; _prod_cap = 200; break;
        case "TOWN":    _prod_regen = 3; _prod_cap = 150; break;
        case "VILLAGE": _prod_regen = 2; _prod_cap = 100; break;
        default:        _prod_regen = 2; _prod_cap = 100; break;
    }
    for (var _pi = 0; _pi < array_length(location.economy.produces); _pi++) {
        var _pgid = location.economy.produces[_pi].good_id;
        if (_pgid == "provisions") continue; // already handled above
        var _pcur = variable_struct_exists(location.economy.stock_levels, _pgid)
                    ? location.economy.stock_levels[$ _pgid] : 0;
        location.economy.stock_levels[$ _pgid] =
            min(_pcur + (_prod_regen * days_since_last), _prod_cap);
    }

    location.economy.last_simulated_day = obj_heartbeat.day;
    location.economy.player_visited = true;
}