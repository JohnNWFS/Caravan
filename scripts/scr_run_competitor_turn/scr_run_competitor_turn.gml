// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Execute one decision turn for a named competitor caravan.
///       Mirrors scr_ai_player's six-step loop but operates on a competitor
///       struct instead of obj_player, and uses no player-specific APIs.
/// @param {Struct} comp  The competitor struct (from world.competitors[])

function scr_run_competitor_turn(comp) {

    // ----------------------------------------------------------------
    // STEP 1 — Sell all cargo at current location
    // ----------------------------------------------------------------
    var _cur_loc = undefined;
    var _from_name = comp.current_location;
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == comp.current_location) {
            _cur_loc   = obj_heartbeat.world.locations[_i];
            _from_name = _cur_loc.name;
            break;
        }
    }
    if (_cur_loc == undefined) return;   // Location missing — skip

    var _sale_total = scr_competitor_sell(comp, _cur_loc);

    // ----------------------------------------------------------------
    // STEP 2 — Score all destinations and pick the best
    // ----------------------------------------------------------------
    var _best_score = -999999;
    var _best_dest  = undefined;
    var _best_cost  = undefined;

    for (var _oi = 0; _oi < array_length(obj_heartbeat.world.locations); _oi++) {
        var _opt = obj_heartbeat.world.locations[_oi];
        if (_opt.id == comp.current_location) continue;

        // Travel cost check
        var _c = scr_calculate_travel_cost(comp.current_location, _opt.id);
        if (_c == noone) continue;
        if (_c.days > comp.max_journey_days) continue;
        if (_c.water > 50) continue;   // Assume single-barrel capacity

        // Affordability: must be able to pay route toll + provisions buffer
        var _trip_gold = _c.gold + (_c.provisions * 2) + 50;
        if (comp.gold < _trip_gold) continue;

        // --- Recency / explore score ---
        var _score = 0;
        if (!variable_struct_exists(comp.unique_locs_visited, _opt.id)) {
            _score += comp.explore_bonus;
        } else {
            var _turns_since = comp.turn_count
                               - comp.unique_locs_visited[$ _opt.id].last_turn;
            if (_turns_since < comp.recency_turns) {
                _score -= comp.recency_penalty
                          * (1 - (_turns_since / comp.recency_turns));
            }
        }

        // --- Distance penalty ---
        _score -= _c.distance * comp.distance_weight;

        // --- Best-margin estimate (same pattern as scr_ai_player STEP 2) ---
        var _best_margin = 0;
        var _stock_keys  = variable_struct_get_names(_cur_loc.economy.stock_levels);
        for (var _si = 0; _si < array_length(_stock_keys); _si++) {
            var _gid = _stock_keys[_si];
            if (_gid == "provisions") continue;
            var _com = scr_get_commodity_by_id(_gid);
            if (_com == undefined) continue;
            if (_com.storage_type == "LIVESTOCK_LARGE") continue;
            if (_cur_loc.economy.stock_levels[$ _gid] <= 0) continue;

            var _bp = scr_calculate_buy_price(_cur_loc, _gid, 1);
            if (_bp <= 0) continue;   // Demanded good — not for sale

            var _sp  = scr_calculate_sell_price(_opt, _gid, 1);
            var _mrg = _sp - _bp;
            if (_mrg > _best_margin) _best_margin = _mrg;
        }
        _score += _best_margin * comp.margin_mult;

        if (_score > _best_score) {
            _best_score = _score;
            _best_dest  = _opt;
            _best_cost  = _c;
        }
    }

    // No viable destination — stay put this turn
    if (_best_dest == undefined) return;

    // ----------------------------------------------------------------
    // STEP 3 — Buy provisions for the journey
    // ----------------------------------------------------------------
    var _prov_needed = _best_cost.provisions + 10;
    if (comp.provisions < _prov_needed) {
        var _prov_buy = _prov_needed - comp.provisions;
        var _prov_stock = 0;
        if (variable_struct_exists(_cur_loc.economy.stock_levels, "provisions")) {
            _prov_stock = _cur_loc.economy.stock_levels[$ "provisions"];
        }
        // Cap to available stock and affordable amount (2g/unit approx)
        _prov_buy = min(_prov_buy, _prov_stock, floor((comp.gold - 50) / 2));
        if (_prov_buy > 0) {
            comp.gold -= _prov_buy * 2;
            _cur_loc.economy.stock_levels[$ "provisions"] -= _prov_buy;
            comp.provisions += _prov_buy;
        }
    }

    // ----------------------------------------------------------------
    // STEP 4 — Buy trade goods sorted by margin to destination
    // ----------------------------------------------------------------
    var _budget = comp.gold - 50;   // Keep 50g in reserve

    // Compute remaining cargo capacity
    var _used = 0;
    for (var _ci = 0; _ci < array_length(comp.cargo); _ci++) {
        _used += comp.cargo[_ci].quantity;
    }
    var _cap = comp.cargo_capacity - _used;

    if (_budget > 0 && _cap > 0) {
        // Build candidate list: {good_id, unit_price, margin, stock}
        var _buy_list = [];
        var _keys = variable_struct_get_names(_cur_loc.economy.stock_levels);
        for (var _ki = 0; _ki < array_length(_keys); _ki++) {
            var _gid   = _keys[_ki];
            if (_gid == "provisions") continue;
            var _com = scr_get_commodity_by_id(_gid);
            if (_com == undefined) continue;
            if (_com.storage_type == "LIVESTOCK_LARGE") continue;

            var _stock = _cur_loc.economy.stock_levels[$ _gid];
            if (_stock <= 0) continue;

            var _bp = scr_calculate_buy_price(_cur_loc, _gid, 1);
            if (_bp <= 0) continue;   // Not for sale (demanded good)

            var _sp  = scr_calculate_sell_price(_best_dest, _gid, 1);
            var _mrg = _sp - _bp;
            if (_mrg <= 0) continue;  // Unprofitable — skip

            array_push(_buy_list, {
                good_id:    _gid,
                unit_price: _bp,
                margin:     _mrg,
                stock:      _stock
            });
        }

        // Sort descending by margin (simple selection-style insertion sort for small arrays)
        for (var _a = 0; _a < array_length(_buy_list) - 1; _a++) {
            var _max_idx = _a;
            for (var _b = _a + 1; _b < array_length(_buy_list); _b++) {
                if (_buy_list[_b].margin > _buy_list[_max_idx].margin) {
                    _max_idx = _b;
                }
            }
            if (_max_idx != _a) {
                var _tmp         = _buy_list[_a];
                _buy_list[_a]    = _buy_list[_max_idx];
                _buy_list[_max_idx] = _tmp;
            }
        }

        // Buy in margin order until budget or capacity runs out
        for (var _bi = 0; _bi < array_length(_buy_list); _bi++) {
            if (_budget <= 0 || _cap <= 0) break;
            var _entry = _buy_list[_bi];
            var _qty   = min(_entry.stock, _cap, floor(_budget / _entry.unit_price));
            if (_qty <= 0) continue;
            scr_competitor_buy(comp, _cur_loc, _entry.good_id, _qty);
            _budget -= _entry.unit_price * _qty;
            _cap    -= _qty;
        }
    }

    // ----------------------------------------------------------------
    // STEP 5 — Travel to chosen destination
    // ----------------------------------------------------------------
    comp.provisions -= _best_cost.provisions;
    comp.provisions  = max(0, comp.provisions);
    comp.current_location = _best_dest.id;
    comp.unique_locs_visited[$ _best_dest.id] = { last_turn: comp.turn_count };
    comp.turn_count++;

    // ----------------------------------------------------------------
    // STEP 6 — Log (debug only — silent during normal play)
    // ----------------------------------------------------------------
    if (global.debug_log_enabled) {
        var _cargo_str = "";
        for (var _li = 0; _li < array_length(comp.cargo); _li++) {
            var _item = comp.cargo[_li];
            var _com  = scr_get_commodity_by_id(_item.good_id);
            var _nm   = (_com != undefined) ? _com.name : _item.good_id;
            if (_cargo_str != "") _cargo_str += ", ";
            _cargo_str += string(_item.quantity) + " " + _nm;
        }
        if (_cargo_str == "") _cargo_str = "empty";
        console_print("[RIVAL: " + comp.name + "]  "
                      + _from_name + " → " + _best_dest.name
                      + "  |  gold: " + string(comp.gold)
                      + "  |  cargo: " + _cargo_str);
    }
}
