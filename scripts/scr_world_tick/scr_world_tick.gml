// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Global economy heartbeat — advance every location's economy to the current day.
///       Called from scr_begin_journey after the day counter is advanced.
///       The destination location is SKIPPED here; scr_simulate_ghost_trades handles it
///       (setting player_visited, running ghost-trade rolls, etc.).
/// @param {String} destination_id  ID of the location the player just arrived at.

function scr_world_tick(destination_id) {

    var _locations = obj_heartbeat.world.locations;
    var _today     = obj_heartbeat.day;

    for (var _li = 0; _li < array_length(_locations); _li++) {

        var _loc = _locations[_li];

        // Skip destination — scr_simulate_ghost_trades handles it separately
        if (_loc.id == destination_id) continue;

        var _days = _today - _loc.economy.last_simulated_day;
        if (_days <= 0) continue; // Already up to date

        // ----------------------------------------------------------------
        // 1. RESALE STOCK DECAY
        //    Player-sold goods slowly bought up by other travellers (1 unit/day/good).
        // ----------------------------------------------------------------
        if (variable_struct_exists(_loc.economy, "resale_stock")) {
            var _rkeys = variable_struct_get_names(_loc.economy.resale_stock);
            for (var _ri = 0; _ri < array_length(_rkeys); _ri++) {
                var _rkey = _rkeys[_ri];
                var _re   = _loc.economy.resale_stock[$ _rkey];
                _re.qty -= _days;
                if (_re.qty <= 0) {
                    variable_struct_remove(_loc.economy.resale_stock, _rkey);
                }
            }
        }

        // ----------------------------------------------------------------
        // 2. PROVISIONS REGENERATION
        //    Every settlement produces food locally; never stays at zero.
        // ----------------------------------------------------------------
        var _prov_regen = 0;
        var _prov_cap   = 0;
        switch (_loc.type) {
            case "CITY":    _prov_regen = 15; _prov_cap = 500; break;
            case "TOWN":    _prov_regen =  8; _prov_cap = 300; break;
            case "VILLAGE": _prov_regen =  4; _prov_cap = 150; break;
            default:        _prov_regen =  4; _prov_cap = 150; break;
        }
        var _cur_prov = variable_struct_exists(_loc.economy.stock_levels, "provisions")
                        ? _loc.economy.stock_levels[$ "provisions"] : 0;
        _loc.economy.stock_levels[$ "provisions"] =
            min(_cur_prov + (_prov_regen * _days), _prov_cap);

        // ----------------------------------------------------------------
        // 3. PRODUCED GOODS REGENERATION
        //    Craftsmen, farmers, and miners keep working whether or not
        //    the player visits.  Prevents permanent depletion of trade goods.
        // ----------------------------------------------------------------
        var _prod_regen = 0;
        var _prod_cap   = 0;
        switch (_loc.type) {
            case "CITY":    _prod_regen = 5; _prod_cap = 200; break;
            case "TOWN":    _prod_regen = 3; _prod_cap = 150; break;
            case "VILLAGE": _prod_regen = 2; _prod_cap = 100; break;
            default:        _prod_regen = 2; _prod_cap = 100; break;
        }
        for (var _pi = 0; _pi < array_length(_loc.economy.produces); _pi++) {
            var _pgid = _loc.economy.produces[_pi].good_id;
            if (_pgid == "provisions") continue; // handled above
            var _pcur = variable_struct_exists(_loc.economy.stock_levels, _pgid)
                        ? _loc.economy.stock_levels[$ _pgid] : 0;
            _loc.economy.stock_levels[$ _pgid] =
                min(_pcur + (_prod_regen * _days), _prod_cap);
        }

        // ----------------------------------------------------------------
        // 4. ADVANCE SIMULATION TIMESTAMP
        //    NOTE: do NOT set player_visited here — the player has not been here.
        // ----------------------------------------------------------------
        _loc.economy.last_simulated_day = _today;
    }
}
