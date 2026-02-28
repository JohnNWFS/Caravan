// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func  scr_ai_player(journey_goal)
/// @desc  Simulate an AI trader completing [journey_goal] journeys.
///        Every decision is printed to the console so the debug log captures a
///        full play-through.  Tweak the CONFIG block below to adjust behaviour.
/// @param {Real} [journey_goal]  Number of journeys to attempt (default: 10)

function scr_ai_player(journey_goal = 10) {

    // ═══════════════════════════════════════════════════════════════════════
    // CONFIG  — change these numbers to tune AI behaviour
    // ═══════════════════════════════════════════════════════════════════════
    var AI_PROVISION_BUFFER  = 10;  // extra provisions to keep beyond journey cost
    var AI_GOLD_BUFFER       = 50;  // gold kept in reserve (not spent on goods)
    var AI_MAX_WORK_DAYS     = 7;   // max days the AI will work at one stop
    var AI_DEMAND_BONUS      = 100; // scoring bonus when destination actively demands a good
    var AI_REPAIR_THRESHOLD  = 70;  // auto-repair when worst wagon drops below this % condition
    var AI_UPGRADE_GOLD_MIN  = 3000; // minimum gold surplus before attempting any upgrade
    var AI_RECENCY_PENALTY   = 800;  // max score deducted for a recently-visited location
    var AI_RECENCY_TURNS     = 10;   // turns over which the recency penalty fades to zero
    var AI_MARGIN_BONUS_MULT = 5;    // score added per gold of estimated trade margin on a route
    var AI_CODE_VERSION      = "v1.5.0"; // increment with every Claude Code change

    // ═══════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════
    var journeys_done        = 0;
    var unique_locs_visited  = {};   // struct used as a visited-set
    var loc_visit_log        = [];   // ordered list of {name, day, role} for the summary

    // ═══════════════════════════════════════════════════════════════════════
    // OPENING BANNER
    // ═══════════════════════════════════════════════════════════════════════
    console_print("");
    console_print("╔══════════════════════════════════════════╗");
    console_print("║         AI AUTOPLAY STARTING             ║");
    console_print("╠══════════════════════════════════════════╣");
    console_print("║  Goal journeys : " + string(journey_goal));
    console_print("║  Prov. buffer  : " + string(AI_PROVISION_BUFFER));
    console_print("║  Gold reserve  : " + string(AI_GOLD_BUFFER));
    console_print("║  Version       : " + AI_CODE_VERSION);
    console_print("╚══════════════════════════════════════════╝");
    console_print("");

    // Record starting location
    var _start_id   = obj_player.current_location;
    var _start_name = "Unknown";
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == _start_id) {
            _start_name = obj_heartbeat.world.locations[_i].name;
            break;
        }
    }
    unique_locs_visited[$ _start_id] = { last_turn: 0 };
    array_push(loc_visit_log, { name: _start_name, day: obj_heartbeat.day, role: "START" });
    console_print("[AI] Starting at: " + _start_name
                  + "  |  Day " + string(obj_heartbeat.day)
                  + "  |  Gold: " + string(obj_player.gold)
                  + "  |  Prov: " + string(obj_player.provisions));
    console_print("");

    // ═══════════════════════════════════════════════════════════════════════
    // MAIN LOOP
    // ═══════════════════════════════════════════════════════════════════════
    while (journeys_done < journey_goal) {

        // ── Build O(1) location lookup map for this iteration ────────────
        var _loc_map = {};
        for (var _lmi = 0; _lmi < array_length(obj_heartbeat.world.locations); _lmi++) {
            var _lm_entry = obj_heartbeat.world.locations[_lmi];
            _loc_map[$ _lm_entry.id] = _lm_entry;
        }

        // ── Resolve current location struct ──────────────────────────────
        var _cur_loc = _loc_map[$ obj_player.current_location];
        if (_cur_loc == undefined) {
            console_print("[AI] FATAL: current location missing. Aborting.");
            break;
        }

        console_print("────────────────────────────────────────────────────────────────");
        console_print("[AI] TURN " + string(journeys_done + 1) + "/" + string(journey_goal)
                      + "  |  Day "   + string(obj_heartbeat.day)
                      + "  |  "       + _cur_loc.name + " (" + _cur_loc.type + ")"
                      + "  |  Gold: " + string(obj_player.gold)
                      + "  |  Prov: " + string(obj_player.provisions));
        console_print("────────────────────────────────────────────────────────────────");

        // ── STEP 1 : Sell all cargo ───────────────────────────────────────
        console_print("[AI] STEP 1 — Selling cargo");
        var _sold_any = false;
        for (var _w = 0; _w < array_length(obj_player.caravan.wagons); _w++) {
            var _cargo = obj_player.caravan.wagons[_w].slots.cargo.contents;
            for (var _s = 0; _s < array_length(_cargo); _s++) {
                var _sl = _cargo[_s];
                if (_sl == undefined) continue;

                var _gid = "";
                var _qty = 0;

                if (variable_struct_exists(_sl, "good_id")) {
                    _gid = _sl.good_id;
                    _qty = _sl.quantity;
                } else if (variable_struct_exists(_sl, "contents") && _sl.contents != undefined) {
                    _gid = _sl.contents.good_id;
                    _qty = _sl.contents.quantity;
                }
                if (_gid == "" || _qty <= 0) continue;

                var _sell_com = scr_get_commodity_by_id(_gid);
                if (_sell_com == undefined) continue;

                scr_cmd_sell(_sell_com.name, _qty);
                _sold_any = true;
            }
        }
        // Also sell livestock trade goods (horses, cattle, etc. in livestock_trade slots)
        for (var _lw = 0; _lw < array_length(obj_player.caravan.wagons); _lw++) {
            if (!variable_struct_exists(obj_player.caravan.wagons[_lw].slots, "livestock_trade")) continue;
            var _ltrade = obj_player.caravan.wagons[_lw].slots.livestock_trade.contents;
            for (var _ls = 0; _ls < array_length(_ltrade); _ls++) {
                var _lsl = _ltrade[_ls];
                if (_lsl == undefined) continue;

                var _lgid = "";
                var _lqty = 0;
                if (variable_struct_exists(_lsl, "good_id")) {
                    _lgid = _lsl.good_id;
                    _lqty = _lsl.quantity;
                } else if (variable_struct_exists(_lsl, "contents") && _lsl.contents != undefined) {
                    _lgid = _lsl.contents.good_id;
                    _lqty = _lsl.contents.quantity;
                }
                if (_lgid == "" || _lqty <= 0) continue;

                var _lsell_com = scr_get_commodity_by_id(_lgid);
                if (_lsell_com == undefined) continue;

                scr_cmd_sell(_lsell_com.name, _lqty);
                _sold_any = true;
            }
        }

        if (!_sold_any) console_print("[AI] (nothing to sell)");

        // ── STEP 1.5 : Auto-repair worn wagons ───────────────────────────
        console_print("[AI] STEP 1.5 — Wagon condition check");
        var _worst_cond = 100;
        for (var _rw = 0; _rw < array_length(obj_player.caravan.wagons); _rw++) {
            if (obj_player.caravan.wagons[_rw].condition < _worst_cond) {
                _worst_cond = obj_player.caravan.wagons[_rw].condition;
            }
        }

        if (_worst_cond < AI_REPAIR_THRESHOLD) {
            console_print("[AI] Worst wagon at " + string(floor(_worst_cond))
                          + "% — requesting repair...");
            scr_cmd_repair();  // sets pending_action if affordable, returns quietly if not

            if (obj_player.pending_action != undefined
            &&  variable_struct_exists(obj_player.pending_action, "type")
            &&  obj_player.pending_action.type == "repair") {
                var _repair_cost = obj_player.pending_action.cost;
                obj_player.gold -= _repair_cost;
                for (var _rw2 = 0; _rw2 < array_length(obj_player.caravan.wagons); _rw2++) {
                    obj_player.caravan.wagons[_rw2].condition = 100;
                }
                obj_player.pending_action = undefined;
                console_print("[AI] Repair confirmed. Paid " + string(_repair_cost)
                              + "g — all wagons restored to 100%.");
            } else {
                console_print("[AI] Cannot afford repairs right now.");
            }
        } else {
            console_print("[AI] Wagons OK (worst: " + string(floor(_worst_cond)) + "%).");
        }

        // ── STEP 1.6 : Auto-upgrade vehicles and animals ─────────────────
        console_print("[AI] STEP 1.6 — Upgrade check");

        // Only upgrade at TOWN or CITY (VILLAGE has no better stock)
        if (_cur_loc.type != "VILLAGE" && obj_player.gold >= AI_UPGRADE_GOLD_MIN) {

            // ── A. Vehicle upgrade ────────────────────────────────────────
            // "Upgrade" = more cargo slots than current best wagon.
            var _best_cargo_now = 0;
            for (var _ucw = 0; _ucw < array_length(obj_player.caravan.wagons); _ucw++) {
                var _ucv = scr_get_vehicle_data(obj_player.caravan.wagons[_ucw].type);
                if (_ucv != undefined && _ucv.cargo_slots > _best_cargo_now) {
                    _best_cargo_now = _ucv.cargo_slots;
                }
            }

            // Find the highest-cargo-slot vehicle we can afford (with surplus)
            var _upgrade_veh = undefined;
            for (var _uvi = 0; _uvi < array_length(global.vehicles); _uvi++) {
                var _uv = global.vehicles[_uvi];
                if (_uv.cargo_slots <= _best_cargo_now) continue; // not an upgrade

                // Location tier availability check
                var _uv_ok = false;
                for (var _uvai = 0; _uvai < array_length(_uv.available_at); _uvai++) {
                    if (_uv.available_at[_uvai] == _cur_loc.type) { _uv_ok = true; break; }
                }
                if (!_uv_ok) continue;

                // For requires_animal vehicles we must also budget for the cheapest animal here,
                // because scr_begin_journey aborts if any requires_animal wagon has no animal.
                var _bundle = _uv.price;
                if (_uv.requires_animal) {
                    var _cheapest_ani = 999999;
                    for (var _cai = 0; _cai < array_length(global.animals); _cai++) {
                        var _ca = global.animals[_cai];
                        var _ca_ok = false;
                        for (var _caai = 0; _caai < array_length(_ca.available_at); _caai++) {
                            if (_ca.available_at[_caai] == _cur_loc.type) { _ca_ok = true; break; }
                        }
                        if (_ca_ok && _ca.price < _cheapest_ani) _cheapest_ani = _ca.price;
                    }
                    if (_cheapest_ani == 999999) continue; // no animal sold here — skip this vehicle
                    _bundle += _cheapest_ani;
                }

                // Must leave AI_UPGRADE_GOLD_MIN in reserve after the full bundle purchase
                if (obj_player.gold - _bundle < AI_UPGRADE_GOLD_MIN) continue;

                // Keep the best (most cargo slots) we can afford
                if (_upgrade_veh == undefined || _uv.cargo_slots > _upgrade_veh.cargo_slots) {
                    _upgrade_veh = _uv;
                }
            }

            if (_upgrade_veh != undefined) {
                console_print("[AI] UPGRADE — Buying " + _upgrade_veh.name
                              + " (" + string(_upgrade_veh.cargo_slots) + " cargo slots)...");
                scr_cmd_shop("BUY", _upgrade_veh.id);

                // If requires_animal: immediately buy the cheapest available animal.
                // Must happen in the same turn or the new wagon blocks departure.
                if (_upgrade_veh.requires_animal) {
                    var _buy_ani_id   = "";
                    var _buy_ani_best = 999999;
                    for (var _bai = 0; _bai < array_length(global.animals); _bai++) {
                        var _ba = global.animals[_bai];
                        var _ba_ok = false;
                        for (var _baai = 0; _baai < array_length(_ba.available_at); _baai++) {
                            if (_ba.available_at[_baai] == _cur_loc.type) { _ba_ok = true; break; }
                        }
                        if (_ba_ok && _ba.price < _buy_ani_best) {
                            _buy_ani_best = _ba.price;
                            _buy_ani_id   = _ba.id;
                        }
                    }
                    if (_buy_ani_id != "") {
                        console_print("[AI] Buying required animal " + _buy_ani_id + " for new wagon...");
                        scr_cmd_shop("BUY", _buy_ani_id);
                    } else {
                        console_print("[AI] WARNING: No animal available for new wagon — journey may be blocked.");
                    }
                }
            } else {
                console_print("[AI] No vehicle upgrade available or affordable here.");
            }

            // ── B. Fill any empty animal slots (safety net) ───────────────
            // Catches requires_animal wagons that lost their animal or were bought
            // at a prior stop where no animal was available.
            for (var _esw = 0; _esw < array_length(obj_player.caravan.wagons); _esw++) {
                var _esv = scr_get_vehicle_data(obj_player.caravan.wagons[_esw].type);
                if (_esv == undefined || !_esv.requires_animal) continue;
                if (array_length(obj_player.caravan.wagons[_esw].slots.animals.contents) > 0) continue;

                // Find best-speed affordable animal at this location
                var _fill_id  = "";
                var _fill_spd = 0;
                for (var _fai = 0; _fai < array_length(global.animals); _fai++) {
                    var _fa = global.animals[_fai];
                    var _fa_ok = false;
                    for (var _faai = 0; _faai < array_length(_fa.available_at); _faai++) {
                        if (_fa.available_at[_faai] == _cur_loc.type) { _fa_ok = true; break; }
                    }
                    if (!_fa_ok) continue;
                    if (obj_player.gold - _fa.price < AI_UPGRADE_GOLD_MIN) continue;
                    if (_fa.speed > _fill_spd) { _fill_spd = _fa.speed; _fill_id = _fa.id; }
                }

                if (_fill_id != "") {
                    console_print("[AI] Filling empty animal slot on wagon "
                                  + string(_esw + 1) + " with " + _fill_id + "...");
                    scr_cmd_shop("BUY", _fill_id);
                } else {
                    console_print("[AI] WARNING: Wagon " + string(_esw + 1)
                                  + " needs animal but none affordable here.");
                }
            }

        } else if (_cur_loc.type == "VILLAGE") {
            console_print("[AI] Village — no upgrade shop.");
        } else {
            console_print("[AI] Below upgrade gold threshold (" + string(obj_player.gold)
                          + "g < " + string(AI_UPGRADE_GOLD_MIN) + "g) — skipping.");
        }

        // ── STEP 2 : Choose destination ───────────────────────────────────
        console_print("[AI] STEP 2 — Choosing destination");
        var _options = scr_get_travel_options();
        if (array_length(_options) == 0) {
            console_print("[AI] No routes from " + _cur_loc.name + ". Aborting.");
            break;
        }

        var _dest      = undefined;
        var _dest_cost = undefined;
        var _best_score = -999999;

        // Pre-compute total water-carry capacity (barrel max_water fields)
        // Used to skip routes that are physically impossible to complete.
        var _max_water = 0;
        for (var _bw = 0; _bw < array_length(obj_player.caravan.wagons); _bw++) {
            var _equip = obj_player.caravan.wagons[_bw].slots.equipment.contents;
            for (var _be = 0; _be < array_length(_equip); _be++) {
                if (_equip[_be] != undefined
                &&  variable_struct_exists(_equip[_be], "max_water")) {
                    _max_water += _equip[_be].max_water;
                }
            }
        }
        console_print("[AI] Water capacity: " + string(_max_water) + " units");

        for (var _oi = 0; _oi < array_length(_options); _oi++) {
            var _opt = _options[_oi];
            var _c   = scr_calculate_travel_cost(obj_player.current_location, _opt.id);
            if (_c == noone) continue;
            if (_c.water > _max_water) continue; // physically impossible — barrel too small

            // ── Multi-factor scoring ──────────────────────────────────────
            var _sc = 0;

            // 1. Strong bonus for first-ever visit (guarantees full world exploration)
            if (!variable_struct_exists(unique_locs_visited, _opt.id)) {
                _sc += 1000;
            } else {
                // 2. Recency penalty: decays linearly from AI_RECENCY_PENALTY → 0
                //    over AI_RECENCY_TURNS turns after the last visit
                var _turns_since = journeys_done - unique_locs_visited[$ _opt.id].last_turn;
                if (_turns_since < AI_RECENCY_TURNS) {
                    _sc -= AI_RECENCY_PENALTY * (1 - (_turns_since / AI_RECENCY_TURNS));
                }
            }

            // 3. Distance penalty (shorter is slightly better all else equal)
            _sc -= _c.distance;

            // 4. Expected profit: best single-unit margin for any good the current
            //    location has in stock that the destination can absorb profitably
            var _opt_loc = _loc_map[$ _opt.id];
            if (_opt_loc != undefined) {
                var _margin_est = 0;
                var _snames = variable_struct_get_names(_cur_loc.economy.stock_levels);
                for (var _sni = 0; _sni < array_length(_snames); _sni++) {
                    var _sn_gid = _snames[_sni];
                    if (_sn_gid == "provisions") continue;
                    var _sn_com_chk = scr_get_commodity_by_id(_sn_gid);
                    if (_sn_com_chk != undefined && _sn_com_chk.storage_type == "LIVESTOCK_LARGE") continue;
                    if (_cur_loc.economy.stock_levels[$ _sn_gid] <= 0) continue;
                    var _sn_buy  = scr_calculate_buy_price(_cur_loc, _sn_gid, 1);
                    if (_sn_buy <= 0) continue;
                    var _sn_sell = scr_calculate_sell_price(_opt_loc, _sn_gid, 1);
                    var _sn_m    = _sn_sell - _sn_buy;
                    if (_sn_m > _margin_est) _margin_est = _sn_m;
                }
                _sc += _margin_est * AI_MARGIN_BONUS_MULT;
            }

            if (_sc > _best_score) {
                _best_score = _sc;
                _dest       = _opt;
                _dest_cost  = _c;
            }
        }

        if (_dest == undefined) {
            console_print("[AI] No scoreable destination. Aborting.");
            break;
        }
        console_print("[AI] Target: " + _dest.name
                      + "  (" + string(round(_dest_cost.distance)) + " km"
                      + ", " + string(_dest_cost.days) + " day(s)"
                      + ", " + _dest_cost.terrain + ")"
                      + (variable_struct_exists(unique_locs_visited, _dest.id) ? "  [REVISIT]" : "  [NEW]"));

        // ── STEP 3 : Buy provisions if needed ────────────────────────────
        console_print("[AI] STEP 3 — Provisions check");
        var _prov_target = _dest_cost.provisions + AI_PROVISION_BUFFER;
        if (obj_player.provisions < _prov_target) {
            var _prov_buy = _prov_target - obj_player.provisions;
            console_print("[AI] Need " + string(_prov_target) + ", have " + string(obj_player.provisions)
                          + " — buying " + string(_prov_buy) + " provisions...");
            scr_buy_provisions(_cur_loc, _prov_buy);
        } else {
            console_print("[AI] Provisions OK (" + string(obj_player.provisions) + " >= " + string(_prov_target) + ")");
        }

        // scr_buy_provisions fails silently when the town is out of stock.
        // Re-check: if we still can't feed ourselves for this journey, find a
        // shorter route we CAN reach rather than triggering the work path.
        if (obj_player.provisions < _dest_cost.provisions) {
            console_print("[AI] Still short on provisions (" + string(obj_player.provisions)
                          + " have, " + string(_dest_cost.provisions) + " needed) — town may be out of stock.");
            console_print("[AI] Seeking shorter route reachable with current provisions...");

            // _options is already sorted by distance (shortest first)
            var _prov_fallback      = undefined;
            var _prov_fallback_cost = undefined;
            for (var _oi_p = 0; _oi_p < array_length(_options); _oi_p++) {
                var _c_p = scr_calculate_travel_cost(obj_player.current_location, _options[_oi_p].id);
                if (_c_p == noone) continue;
                if (obj_player.provisions >= _c_p.provisions) {
                    _prov_fallback      = _options[_oi_p];
                    _prov_fallback_cost = _c_p;
                    break;
                }
            }

            if (_prov_fallback != undefined) {
                _dest      = _prov_fallback;
                _dest_cost = _prov_fallback_cost;
                console_print("[AI] Switched to shorter route: " + _dest.name
                              + " (needs " + string(_dest_cost.provisions) + " provisions)");
            } else {
                console_print("[AI] No route reachable with only " + string(obj_player.provisions)
                              + " provisions. Aborting.");
                break;
            }
        }

        // ── STEP 4 : Work only if GOLD is short — never for provisions ───
        console_print("[AI] STEP 4 — Affordability check");
        var _afford = scr_can_afford_journey(_dest_cost);

        if (!_afford.can_afford) {
            if (_afford.missing.gold > 0) {
                // Need more gold — work for it
                var _gold_short = _afford.missing.gold;
                var _work_days  = min(AI_MAX_WORK_DAYS, ceil(max(_gold_short, 5) / 8));
                console_print("[AI] Short " + string(_gold_short) + " gold — working " + string(_work_days) + " day(s)...");
                scr_cmd_work(_work_days);

                // Work consumes provisions — top up again if needed (but don't loop back into work)
                if (obj_player.provisions < _dest_cost.provisions) {
                    var _pb2 = _dest_cost.provisions + AI_PROVISION_BUFFER - obj_player.provisions;
                    console_print("[AI] Re-buying " + string(_pb2) + " provisions after working...");
                    scr_buy_provisions(_cur_loc, _pb2);
                }

                // Final gold check — if still short, find the cheapest affordable route
                _afford = scr_can_afford_journey(_dest_cost);
                if (!_afford.can_afford) {
                    console_print("[AI] Still short on gold — finding cheapest affordable route...");
                    var _min_gold = 999999;
                    for (var _oi2 = 0; _oi2 < array_length(_options); _oi2++) {
                        var _c2 = scr_calculate_travel_cost(obj_player.current_location, _options[_oi2].id);
                        if (_c2 == noone) continue;
                        var _chk2 = scr_can_afford_journey(_c2);
                        if (_chk2.can_afford && _c2.gold < _min_gold) {
                            _min_gold  = _c2.gold;
                            _dest      = _options[_oi2];
                            _dest_cost = _c2;
                        }
                    }
                    _afford = scr_can_afford_journey(_dest_cost);
                    if (!_afford.can_afford) {
                        console_print("[AI] Completely stuck — no affordable route. Aborting.");
                        break;
                    }
                    console_print("[AI] Switched destination to: " + _dest.name);
                }
            } else {
                // Water or provisions physically infeasible for chosen route.
                // Attempt to switch to any route we can actually complete.
                console_print("[AI] Route infeasible (prov short: "
                              + string(_afford.missing.provisions)
                              + ", water short: " + string(_afford.missing.water)
                              + ") — seeking alternative...");
                var _fb4      = undefined;
                var _fb4_cost = undefined;
                var _fb4_best = -999999;
                for (var _oi4 = 0; _oi4 < array_length(_options); _oi4++) {
                    var _c4   = scr_calculate_travel_cost(obj_player.current_location, _options[_oi4].id);
                    if (_c4 == noone) continue;
                    if (_c4.water > _max_water) continue;
                    var _chk4 = scr_can_afford_journey(_c4);
                    if (!_chk4.can_afford) continue;
                    // Light score: prefer unvisited, then by distance
                    var _sc4 = variable_struct_exists(unique_locs_visited, _options[_oi4].id)
                               ? -_c4.distance : (1000 - _c4.distance);
                    if (_sc4 > _fb4_best) {
                        _fb4_best = _sc4;
                        _fb4      = _options[_oi4];
                        _fb4_cost = _c4;
                    }
                }
                if (_fb4 != undefined) {
                    _dest      = _fb4;
                    _dest_cost = _fb4_cost;
                    console_print("[AI] Switched to feasible route: " + _dest.name);
                } else {
                    console_print("[AI] No feasible route available. Aborting.");
                    break;
                }
            }
        } else {
            console_print("[AI] Can afford the journey. OK.");
        }

        // ── STEP 5 : Buy trade goods ──────────────────────────────────────
        console_print("[AI] STEP 5 — Trade buying");

        // Resolve destination location struct for margin calculation
        var _dest_loc = _loc_map[$ _dest.id];

        // Count empty cargo slots
        var _empty_slots = 0;
        for (var _w = 0; _w < array_length(obj_player.caravan.wagons); _w++) {
            var _cargo_check = obj_player.caravan.wagons[_w].slots.cargo.contents;
            for (var _s = 0; _s < array_length(_cargo_check); _s++) {
                if (_cargo_check[_s] == undefined) _empty_slots++;
            }
        }

        var _gold_budget = obj_player.gold - _dest_cost.gold - AI_GOLD_BUFFER;

        if (_gold_budget > 0 && _dest_loc != undefined && _empty_slots > 0) {
            console_print("[AI] Trade budget: " + string(_gold_budget) + " gold  |  Empty slots: " + string(_empty_slots));

            // Score every good available at current location
            var _candidates = [];
            var _stock_keys = variable_struct_get_names(_cur_loc.economy.stock_levels);

            for (var _ki = 0; _ki < array_length(_stock_keys); _ki++) {
                var _gid    = _stock_keys[_ki];
                if (_gid == "provisions") continue;

                var _avail = _cur_loc.economy.stock_levels[$ _gid];
                if (_avail <= 0) continue;

                var _trade_com = scr_get_commodity_by_id(_gid);
                if (_trade_com == undefined) continue;

                // Skip livestock goods — scr_cmd_sell cannot sell from livestock_trade slots,
                // so buying them as trade cargo is a dead end (they can never be offloaded).
                if (_trade_com.storage_type == "LIVESTOCK_LARGE") continue;

                var _buy1 = scr_calculate_buy_price(_cur_loc, _gid, 1);
                if (_buy1 <= 0) continue;  // not for sale

                var _sell1  = scr_calculate_sell_price(_dest_loc, _gid, 1);
                var _margin = _sell1 - _buy1;

                // Bonus if destination actively demands this good
                for (var _ddi = 0; _ddi < array_length(_dest_loc.economy.demands); _ddi++) {
                    if (_dest_loc.economy.demands[_ddi].good_id == _gid) {
                        _margin += AI_DEMAND_BONUS;
                        break;
                    }
                }

                // Skip goods that will sell for less than they cost (no demand bonus can save them)
                if (_sell1 <= _buy1 && _margin <= 0) continue;

                array_push(_candidates, {
                    good_id:        _gid,
                    name:           _trade_com.name,
                    buy_price:      _buy1,
                    sell_price:     _sell1,
                    margin:         _margin,
                    qty_avail:      _avail,
                    units_per_slot: _trade_com.units_per_slot
                });
            }

            // Sort best margin first
            array_sort(_candidates, function(a, b) { return b.margin - a.margin; });

            if (array_length(_candidates) == 0) {
                console_print("[AI] Nothing available to buy.");
            }

            // Buy from each candidate until budget or cargo runs out
            for (var _ci = 0; _ci < array_length(_candidates); _ci++) {
                // Recount empty slots dynamically
                _empty_slots = 0;
                for (var _w = 0; _w < array_length(obj_player.caravan.wagons); _w++) {
                    var _cc = obj_player.caravan.wagons[_w].slots.cargo.contents;
                    for (var _s = 0; _s < array_length(_cc); _s++) {
                        if (_cc[_s] == undefined) _empty_slots++;
                    }
                }
                if (_empty_slots <= 0 || _gold_budget <= 0) break;

                var _cand = _candidates[_ci];
                var _max_u = floor(_gold_budget / _cand.buy_price);
                _max_u = min(_max_u, _cand.qty_avail);
                _max_u = min(_max_u, _empty_slots * _cand.units_per_slot);

                if (_max_u <= 0) continue;

                var _margin_display = _cand.sell_price - _cand.buy_price;
                console_print("[AI] Buying " + string(_max_u) + "x " + _cand.name
                              + "  buy@" + string(_cand.buy_price)
                              + "  sell@~" + string(_cand.sell_price)
                              + "  margin " + ((_margin_display >= 0) ? "+" : "") + string(_margin_display) + "/unit");

                scr_cmd_buy(_cand.name, _max_u, true); // confirmed=true bypasses spillover prompt
                _gold_budget -= _cand.buy_price * _max_u;
            }

        } else {
            if (_gold_budget <= 0)
                console_print("[AI] No trade budget left after reserving travel/buffer gold.");
            if (_empty_slots <= 0)
                console_print("[AI] All cargo slots full — no room to buy.");
            if (_dest_loc == undefined)
                console_print("[AI] Destination struct unavailable — skipping trade.");
        }

        // ── STEP 6 : Execute the journey ─────────────────────────────────
        console_print("[AI] STEP 6 — Departing");
        var _final_afford = scr_can_afford_journey(_dest_cost);
        if (!_final_afford.can_afford) {
            console_print("[AI] Pre-departure check failed. Aborting.");
            break;
        }

        var _is_new_dest = !variable_struct_exists(unique_locs_visited, _dest.id);
        console_print("[AI] ▶ DEPARTING for " + _dest.name + " ◀");
        scr_begin_journey(_dest.id, _dest_cost);
        journeys_done++;

        unique_locs_visited[$ _dest.id] = { last_turn: journeys_done };
        array_push(loc_visit_log, {
            name: _dest.name,
            day:  obj_heartbeat.day,
            role: _is_new_dest ? "NEW" : "REVISIT"
        });

        console_print("");
    } // end while

    // ═══════════════════════════════════════════════════════════════════════
    // FINAL SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    var _unique_count = array_length(variable_struct_get_names(unique_locs_visited));

    console_print("");
    console_print("╔══════════════════════════════════════════╗");
    console_print("║         AI AUTOPLAY COMPLETE             ║");
    console_print("╠══════════════════════════════════════════╣");
    console_print("║  Journeys:       " + string(journeys_done) + "/" + string(journey_goal));
    console_print("║  Unique places:  " + string(_unique_count));
    console_print("║  Final gold:     " + string(obj_player.gold));
    console_print("║  Final day:      " + string(obj_heartbeat.day));
    console_print("║  Provisions:     " + string(obj_player.provisions));
    console_print("╠══════════════════════════════════════════╣");
    console_print("║  ROUTE LOG:");
    for (var _vi = 0; _vi < array_length(loc_visit_log); _vi++) {
        var _vl = loc_visit_log[_vi];
        var _tag = "  [" + _vl.role + "]";
        console_print("║    Day " + string(_vl.day) + " — " + _vl.name + _tag);
    }
    console_print("╚══════════════════════════════════════════╝");
    console_print("");
}
