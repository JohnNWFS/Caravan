/// @func scr_generate_contracts(location)
/// @desc Generate a fresh pool of delivery contracts for a city or town.
///       Contracts are stored on the location struct:
///         location.available_contracts   — array of contract structs
///         location.contracts_issued_day  — day contracts were generated (staleness check)
///
///       Called by scr_cmd_contracts() on first visit, or when existing pool is stale
///       (older than 7 in-game days).
///
/// @param {Struct} location  The location struct from obj_heartbeat.world.locations
///
/// Contract struct fields:
///   id            {String}  Unique ID: "CTR_<loc_id>_<index>"
///   origin_id     {String}  Issuing location ID
///   origin_name   {String}  Issuing location display name
///   dest_id       {String}  Destination location ID
///   dest_name     {String}  Destination location display name
///   good_id       {String}  Commodity ID (lowercase, e.g. "salt")
///   good_name     {String}  Commodity display name (e.g. "Salt")
///   quantity      {Real}    Units to deliver
///   reward_gold   {Real}    Gold paid on successful delivery
///   deadline_day  {Real}    Player must arrive with goods by this day
///   issued_day    {Real}    Day the contract pool was generated

function scr_generate_contracts(location) {

    location.available_contracts  = [];
    location.contracts_issued_day = obj_heartbeat.day;

    // Only locations with the "contracts" tag issue contracts (cities and towns)
    var _has_tag = false;
    for (var _ti = 0; _ti < array_length(location.tags); _ti++) {
        if (location.tags[_ti] == "contracts") { _has_tag = true; break; }
    }
    if (!_has_tag) return;

    // Number of contracts by location tier
    var _count = (location.type == "CITY") ? irandom_range(3, 4) : irandom_range(1, 2);

    // Candidate destinations: other cities and towns only (villages don't receive shipments)
    var _candidates = [];
    for (var _li = 0; _li < array_length(obj_heartbeat.world.locations); _li++) {
        var _loc = obj_heartbeat.world.locations[_li];
        if (_loc.id == location.id) continue;
        if (_loc.type == "VILLAGE")  continue;
        array_push(_candidates, _loc);
    }
    if (array_length(_candidates) == 0) return;

    // Goods that cannot appear in contracts (stored outside the standard cargo slot system)
    var _excluded = ["provisions", "horses", "cattle", "pigs"];

    // Fallback goods when the destination has no explicit demands
    var _common_goods = ["salt", "wheat", "wool", "iron", "timber", "pottery", "barley", "tools"];

    // Track (dest_id + "_" + good_id) to avoid duplicate contracts in the same batch
    var _used_dest_good = [];
    var _ctr_index      = 0;

    for (var _ci = 0; _ci < _count; _ci++) {

        // --- Pick destination ---
        var _dest = _candidates[irandom(array_length(_candidates) - 1)];

        // --- Pick a good ---
        // Prefer goods that the destination explicitly demands (higher sell value there)
        var _good_id   = "";
        var _commodity = undefined;

        if (array_length(_dest.economy.demands) > 0) {
            // Shuffle demand indices for random order
            var _didx = [];
            for (var _d = 0; _d < array_length(_dest.economy.demands); _d++) {
                array_push(_didx, _d);
            }
            for (var _d = array_length(_didx) - 1; _d > 0; _d--) {
                var _sw = irandom(_d);
                var _tmp = _didx[_d]; _didx[_d] = _didx[_sw]; _didx[_sw] = _tmp;
            }
            for (var _d = 0; _d < array_length(_didx); _d++) {
                var _gid = _dest.economy.demands[_didx[_d]].good_id;
                // Skip excluded goods
                var _excl = false;
                for (var _ei = 0; _ei < array_length(_excluded); _ei++) {
                    if (_excluded[_ei] == _gid) { _excl = true; break; }
                }
                // Skip if this dest+good combo already used
                var _dup = false;
                for (var _ui = 0; _ui < array_length(_used_dest_good); _ui++) {
                    if (_used_dest_good[_ui] == _dest.id + "_" + _gid) { _dup = true; break; }
                }
                if (!_excl && !_dup) { _good_id = _gid; break; }
            }
        }

        // Fall back to common goods if no valid demand found
        if (_good_id == "") {
            for (var _gi = 0; _gi < 12; _gi++) {
                var _cg = _common_goods[irandom(array_length(_common_goods) - 1)];
                var _dup = false;
                for (var _ui = 0; _ui < array_length(_used_dest_good); _ui++) {
                    if (_used_dest_good[_ui] == _dest.id + "_" + _cg) { _dup = true; break; }
                }
                if (!_dup) { _good_id = _cg; break; }
            }
        }
        if (_good_id == "") continue;   // Couldn't find a unique good — skip this slot

        // Look up canonical commodity record
        _commodity = scr_find_commodity_by_name(_good_id);
        var _good_name;
        if (_commodity != undefined) {
            _good_name = _commodity.name;
            _good_id   = _commodity.id;   // Use canonical lowercase ID
        } else {
            _good_name = string_upper(string_copy(_good_id, 1, 1))
                       + string_delete(_good_id, 1, 1);
        }

        // Track this dest+good pair
        array_push(_used_dest_good, _dest.id + "_" + _good_id);

        // --- Quantity (rounded to nearest 5) ---
        var _qty = (location.type == "CITY") ? irandom_range(15, 40) : irandom_range(8, 20);
        _qty = max(5, round(_qty / 5) * 5);

        // --- Reward ---
        // Reward = base_value × quantity × multiplier (2.0–3.0×), rounded to nearest 5g.
        // Always higher than spot-market selling price so contracts are attractive.
        var _base_val = (_commodity != undefined) ? _commodity.base_value : 8;
        var _mult     = (location.type == "CITY") ? (20 + irandom(10)) : (18 + irandom(8));
        var _reward   = max(50, round(_base_val * _qty * _mult / 10));
        _reward       = round(_reward / 5) * 5;

        // --- Deadline ---
        // Find direct route distance; estimate travel days; add generous buffer.
        var _route_dist = 300;   // default ≈ 8 days if no direct route found
        for (var _ri = 0; _ri < array_length(obj_heartbeat.world.routes); _ri++) {
            var _rt = obj_heartbeat.world.routes[_ri];
            if ((_rt.from_id == location.id && _rt.to_id == _dest.id) ||
                (_rt.from_id == _dest.id    && _rt.to_id == location.id)) {
                _route_dist = _rt.distance;
                break;
            }
        }
        var _travel_days = max(3, ceil(_route_dist / 40));
        // Deadline = now + (3× travel time) + random buffer (5–15 days)
        var _deadline = obj_heartbeat.day + _travel_days * 3 + irandom_range(5, 15);

        // Discard contract if it cannot realistically be fulfilled
        if (!scr_contract_is_fulfillable(_good_id, _qty, _dest.id, _deadline)) continue;

        // --- Build contract struct ---
        var _id = "CTR_" + location.id + "_" + string(_ctr_index);
        _ctr_index++;

        array_push(location.available_contracts, {
            id:           _id,
            origin_id:    location.id,
            origin_name:  location.name,
            dest_id:      _dest.id,
            dest_name:    _dest.name,
            good_id:      _good_id,
            good_name:    _good_name,
            quantity:     _qty,
            reward_gold:  _reward,
            deadline_day: _deadline,
            issued_day:   obj_heartbeat.day
        });
    }
}

// ---------------------------------------------------------------------------

/// @func scr_count_cargo(good_id)
/// @desc Count total units of a commodity across all wagon cargo slots.
/// @param {String} good_id  The commodity ID (lowercase)
/// @return {Real}  Total quantity currently in cargo

function scr_count_cargo(good_id) {
    var _total = 0;
    for (var _w = 0; _w < array_length(obj_player.caravan.wagons); _w++) {
        var _cargo = obj_player.caravan.wagons[_w].slots.cargo.contents;
        for (var _s = 0; _s < array_length(_cargo); _s++) {
            var _slot = _cargo[_s];
            if (_slot == undefined) continue;
            // Standard cargo slot
            if (variable_struct_exists(_slot, "good_id") && _slot.good_id == good_id) {
                _total += _slot.quantity;
            }
            // Saddlebag slot (has a nested contents struct)
            else if (variable_struct_exists(_slot, "contents")
                 &&  _slot.contents != undefined
                 &&  _slot.contents.good_id == good_id) {
                _total += _slot.contents.quantity;
            }
        }
    }
    return _total;
}

// ---------------------------------------------------------------------------

/// @func scr_remove_cargo(good_id, quantity)
/// @desc Remove a given number of units of a commodity from wagon cargo slots.
///       Removes from standard slots before saddlebag slots.
///       Slots that reach 0 are set to undefined (empty).
/// @param {String} good_id   The commodity ID
/// @param {Real}   quantity  How many units to remove
/// @return {Real}  Actual units removed (may be less than requested)

function scr_remove_cargo(good_id, quantity) {
    var _remaining = quantity;
    for (var _w = 0; _w < array_length(obj_player.caravan.wagons) && _remaining > 0; _w++) {
        var _cargo = obj_player.caravan.wagons[_w].slots.cargo.contents;
        for (var _s = 0; _s < array_length(_cargo) && _remaining > 0; _s++) {
            var _slot = _cargo[_s];
            if (_slot == undefined) continue;
            // Standard cargo slot
            if (variable_struct_exists(_slot, "good_id") && _slot.good_id == good_id) {
                var _take = min(_slot.quantity, _remaining);
                _slot.quantity -= _take;
                _remaining     -= _take;
                if (_slot.quantity <= 0) _cargo[_s] = undefined;
            }
            // Saddlebag slot
            else if (variable_struct_exists(_slot, "contents")
                 &&  _slot.contents != undefined
                 &&  _slot.contents.good_id == good_id) {
                var _take = min(_slot.contents.quantity, _remaining);
                _slot.contents.quantity -= _take;
                _remaining              -= _take;
                if (_slot.contents.quantity <= 0) _slot.contents = undefined;
            }
        }
    }
    return quantity - _remaining;   // Units actually removed
}

// ---------------------------------------------------------------------------

/// @func scr_contract_is_fulfillable(good_id, quantity, dest_id, deadline_day)
/// @desc Returns true if a contract for [quantity] of [good_id] delivered to
///       [dest_id] by [deadline_day] is realistically completable given the
///       current world state and game mode.
///
///       Two checks:
///         A) Journey-mode turn budget — need at least 2 journeys remaining
///            (one to source the good, one to deliver it).
///         B) Good availability — at least one non-destination CITY or TOWN
///            must have sufficient stock OR produce the good, and the estimated
///            travel time from that source to the destination must fit within
///            the deadline with a 2-day safety margin.

function scr_contract_is_fulfillable(good_id, quantity, dest_id, deadline_day) {

    // --- Check A: Journey-mode turn budget ---
    var _cfg = obj_heartbeat.setup_config;
    if (variable_struct_exists(_cfg, "game_mode") && _cfg.game_mode == "JOURNEY") {
        var _turns_left = _cfg.journey_limit - obj_heartbeat.journey_count;
        if (_turns_left < 2) return false;
    }

    // --- Locate destination struct (needed for coordinate fallback) ---
    var _dest_struct = undefined;
    for (var _di = 0; _di < array_length(obj_heartbeat.world.locations); _di++) {
        if (obj_heartbeat.world.locations[_di].id == dest_id) {
            _dest_struct = obj_heartbeat.world.locations[_di];
            break;
        }
    }

    // --- Check B: Good must exist at an accessible source ---
    var _locs = obj_heartbeat.world.locations;
    for (var _li = 0; _li < array_length(_locs); _li++) {
        var _loc = _locs[_li];
        if (_loc.id == dest_id)     continue;   // Destination cannot be source
        if (_loc.type == "VILLAGE") continue;   // Villages have no market

        // 1. Stock snapshot: enough units currently on hand
        var _has_good = false;
        if (variable_struct_exists(_loc, "economy")
        &&  variable_struct_exists(_loc.economy, "stock_levels")
        &&  variable_struct_exists(_loc.economy.stock_levels, good_id)
        &&  _loc.economy.stock_levels[$ good_id] >= quantity) {
            _has_good = true;
        }

        // 2. Producer check: location generates this good (more reliable than snapshot)
        if (!_has_good && variable_struct_exists(_loc, "economy")) {
            for (var _pi = 0; _pi < array_length(_loc.economy.produces); _pi++) {
                if (_loc.economy.produces[_pi].good_id == good_id) {
                    _has_good = true;
                    break;
                }
            }
        }
        if (!_has_good) continue;

        // 3. Deadline feasibility: source → destination travel estimate
        var _dist = -1;
        for (var _ri = 0; _ri < array_length(obj_heartbeat.world.routes); _ri++) {
            var _rt = obj_heartbeat.world.routes[_ri];
            if ((_rt.from_id == _loc.id  && _rt.to_id == dest_id)
            ||  (_rt.from_id == dest_id  && _rt.to_id == _loc.id)) {
                _dist = _rt.distance;
                break;
            }
        }
        // No direct route: use coordinate-based approximation
        if (_dist < 0 && _dest_struct != undefined) {
            var _dx = _loc.x - _dest_struct.x;
            var _dy = _loc.y - _dest_struct.y;
            _dist   = sqrt(_dx * _dx + _dy * _dy);
        }
        var _src_to_dest_days = (_dist >= 0) ? max(1, ceil(_dist / 40)) : 5;

        // Require: current_day + source→dest + 2-day margin ≤ deadline
        if (obj_heartbeat.day + _src_to_dest_days + 2 <= deadline_day) {
            return true;
        }
    }

    return false;   // No valid, feasible source found
}
