// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func  scr_ai_player(journey_goal)
/// @desc  Simulate an AI trader completing [journey_goal] journeys.
///        Every decision is printed to the console so the debug log captures a
///        full play-through.  Tweak the CONFIG block below to adjust behaviour.
/// @param {Real} [journey_goal]  Number of journeys to attempt (default: 10)

function scr_ai_player(journey_goal = 10) {

    // ═══════════════════════════════════════════════════════════════════════
    // CONFIG  -change these numbers to tune AI behaviour
    // ═══════════════════════════════════════════════════════════════════════
    var AI_PROVISION_BUFFER        = 10;    // extra provisions to keep beyond journey cost
    var AI_GOLD_BUFFER             = 50;    // gold kept in reserve (not spent on goods)
    var AI_MAX_WORK_DAYS           = 7;     // max days the AI will work at one stop
    var AI_DEMAND_BONUS            = 100;   // scoring bonus when destination actively demands a good
    var AI_REPAIR_THRESHOLD        = 70;    // auto-repair when worst wagon drops below this % condition
    var AI_UPGRADE_GOLD_MIN        = 3000;  // minimum gold surplus before attempting any upgrade
    var AI_RECENCY_PENALTY         = 800;   // max score deducted for a recently-visited location
    var AI_RECENCY_TURNS           = 10;    // turns over which the recency penalty fades to zero
    var AI_MARGIN_BONUS_MULT       = 5;     // score added per gold of estimated trade margin on a route
    var AI_HIRE_GOLD_MIN           = 600;   // minimum gold surplus before hiring crew
    var AI_DISMISS_GOLD_FLOOR      = 120;   // dismiss crew when gold falls below this
    var AI_MAX_ACTIVE_CONTRACTS    = 2;     // don't overcommit on contracts
    var AI_CONTRACT_REWARD_MIN     = 60;    // minimum reward gold to accept a contract
    var AI_CONTRACT_URGENCY_BASE   = 1500;  // destination scoring bonus per active contract
    var AI_CONTRACT_DEADLINE_PANIC = 3000;  // extra bonus when deadline < 5 days away
    var AI_SAVE_INTERVAL           = 100;   // save to disk every N journeys
    var AI_CODE_VERSION            = "v1.7.0";

    // ═══════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════
    var journeys_done        = 0;
    var unique_locs_visited  = {};   // struct used as a visited-set
    var loc_visit_log        = [];   // ordered list of {name, day, role} for the summary

    // ── New stat counters ────────────────────────────────────────────────────
    var contracts_accepted   = 0;
    var contracts_resolved   = 0;   // completed + failed combined
    var crew_hired           = 0;
    var crew_dismissed       = 0;
    var saves_done           = 0;
    var total_wages_paid     = 0;
    var _rep_start           = obj_player.reputation;

    // ═══════════════════════════════════════════════════════════════════════
    // OPENING BANNER
    // ═══════════════════════════════════════════════════════════════════════
    console_print("");
    console_print(string_repeat(chr(9552), 42));
    console_print("         AI AUTOPLAY STARTING");
    console_print("  [DEBUG] tags mark AI reasoning - not shown in normal play");
    console_print("------------------------------------------");
    console_print("  Goal journeys : " + string(journey_goal));
    console_print("  Prov. buffer  : " + string(AI_PROVISION_BUFFER));
    console_print("  Gold reserve  : " + string(AI_GOLD_BUFFER));
    console_print("  Version       : " + AI_CODE_VERSION);
    console_print(string_repeat(chr(9552), 42));
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

        console_print("------------------------------------------------------");
        console_print("[AI] TURN " + string(journeys_done + 1) + "/" + string(journey_goal)
                      + "  |  Day "   + string(obj_heartbeat.day)
                      + "  |  "       + _cur_loc.name + " (" + _cur_loc.type + ")"
                      + "  |  Gold: " + string(obj_player.gold)
                      + "  |  Prov: " + string(obj_player.provisions));
        console_print("------------------------------------------------------");

        // ── STEP 1 : Sell all cargo ───────────────────────────────────────
        console_print("[AI] STEP 1 - Selling cargo");
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
        console_print("[AI] STEP 1.5 - Wagon condition check");
        var _worst_cond = 100;
        for (var _rw = 0; _rw < array_length(obj_player.caravan.wagons); _rw++) {
            if (obj_player.caravan.wagons[_rw].condition < _worst_cond) {
                _worst_cond = obj_player.caravan.wagons[_rw].condition;
            }
        }

        if (_worst_cond < AI_REPAIR_THRESHOLD) {
            console_print("[AI] Worst wagon at " + string(floor(_worst_cond))
                          + "% -requesting repair...");
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
                              + "g -all wagons restored to 100%.");
            } else {
                console_print("[AI] Cannot afford repairs right now.");
            }
        } else {
            console_print("[AI] Wagons OK (worst: " + string(floor(_worst_cond)) + "%).");
        }

        // ── STEP 1.6 : Auto-upgrade vehicles and animals ─────────────────
        console_print("[AI] STEP 1.6 - Upgrade check");

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
                    if (_cheapest_ani == 999999) continue; // no animal sold here -skip this vehicle
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
                console_print("[AI] UPGRADE - Buying " + _upgrade_veh.name
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
                        console_print("[AI] WARNING: No animal available for new wagon - journey may be blocked.");
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
            console_print("[AI] Village - no upgrade shop.");
        } else {
            console_print("[AI] Below upgrade gold threshold (" + string(obj_player.gold)
                          + "g < " + string(AI_UPGRADE_GOLD_MIN) + "g) -skipping.");
        }

        // ── Pre-compute travel options (needed by Steps 1.55, 1.7, and 2) ──
        var _options = scr_get_travel_options();
        if (array_length(_options) == 0) {
            console_print("[AI] No routes from " + _cur_loc.name + ". Aborting.");
            break;
        }

        // ── STEP 1.55 : Crew management ───────────────────────────────────
        console_print("[AI] STEP 1.55 - Crew management");

        // ── A. DISMISS: if gold is below floor, release highest-wage crew ──
        if (obj_player.gold < AI_DISMISS_GOLD_FLOOR
        &&  array_length(obj_player.hired_crew) > 0) {
            var _dismiss_idx  = 0;
            var _dismiss_wage = obj_player.hired_crew[0].wage;
            for (var _di = 1; _di < array_length(obj_player.hired_crew); _di++) {
                if (obj_player.hired_crew[_di].wage > _dismiss_wage) {
                    _dismiss_wage = obj_player.hired_crew[_di].wage;
                    _dismiss_idx  = _di;
                }
            }
            var _gone = obj_player.hired_crew[_dismiss_idx];
            console_print("[DEBUG] Dismiss: " + _gone.name + " (" + _gone.type + ") "
                          + string(_gone.wage) + "g/day"
                          + " -- gold=" + string(obj_player.gold)
                          + " below floor=" + string(AI_DISMISS_GOLD_FLOOR));
            scr_cmd_hire("DISMISS " + string(_dismiss_idx + 1));
            crew_dismissed++;
        }

        // ── B. HIRE: only at locations tagged "hire", with gold surplus ────
        var _loc_has_hire = false;
        if (variable_struct_exists(_cur_loc, "tags")) {
            for (var _ht = 0; _ht < array_length(_cur_loc.tags); _ht++) {
                if (_cur_loc.tags[_ht] == "hire") { _loc_has_hire = true; break; }
            }
        }

        if (_loc_has_hire
        &&  obj_player.gold > AI_HIRE_GOLD_MIN
        &&  array_length(obj_player.hired_crew) < 3) {

            // scr_cmd_hire("") prints menu and generates/refreshes available_crew
            scr_cmd_hire("");

            if (variable_struct_exists(_cur_loc, "available_crew")
            &&  array_length(_cur_loc.available_crew) > 0) {

                // Priority order: GUARD first (bandit defence), then profit/efficiency
                var _hire_priority = [
                    "GUARD", "TRADER", "DRIVER",
                    "HEDGE_WITCH", "NAVIGATOR",
                    "MERCENARY_CAPTAIN", "ALCHEMIST"
                ];

                // Build set of already-hired types
                var _have_types = {};
                for (var _hci = 0; _hci < array_length(obj_player.hired_crew); _hci++) {
                    _have_types[$ obj_player.hired_crew[_hci].type] = true;
                }

                // Find highest-priority pool member not already hired
                var _hire_pool_idx  = -1;
                var _hire_best_rank = 999;
                for (var _api = 0; _api < array_length(_cur_loc.available_crew); _api++) {
                    var _ac = _cur_loc.available_crew[_api];
                    if (variable_struct_exists(_have_types, _ac.type)) continue;
                    for (var _pri = 0; _pri < array_length(_hire_priority); _pri++) {
                        if (_hire_priority[_pri] == _ac.type && _pri < _hire_best_rank) {
                            _hire_best_rank = _pri;
                            _hire_pool_idx  = _api;
                            break;
                        }
                    }
                }

                if (_hire_pool_idx >= 0) {
                    var _to_hire = _cur_loc.available_crew[_hire_pool_idx];
                    console_print("[DEBUG] Crew at " + _cur_loc.name + ": "
                                  + _to_hire.type + " " + _to_hire.name
                                  + " " + string(_to_hire.wage) + "g/day -> HIRE");
                    scr_cmd_hire(string(_hire_pool_idx + 1));
                    crew_hired++;
                } else {
                    console_print("[DEBUG] Crew at " + _cur_loc.name
                                  + ": no new type available (all types already hired).");
                }
            }

        } else {
            if (!_loc_has_hire) {
                console_print("[AI] No hire market here.");
            } else if (obj_player.gold <= AI_HIRE_GOLD_MIN) {
                console_print("[AI] Below hire gold threshold ("
                              + string(obj_player.gold) + "g) - skipping hire.");
            } else {
                console_print("[AI] Crew full (3/3).");
            }
        }

        // Log daily crew wage for observability
        var _daily_crew_wage = 0;
        for (var _cwi = 0; _cwi < array_length(obj_player.hired_crew); _cwi++) {
            _daily_crew_wage += obj_player.hired_crew[_cwi].wage;
        }
        if (_daily_crew_wage > 0) {
            console_print("[DEBUG] Crew wages: "
                          + string(array_length(obj_player.hired_crew))
                          + " crew, " + string(_daily_crew_wage) + "g/day total");
        }

        // ── STEP 1.7 : Contract management ───────────────────────────────
        console_print("[AI] STEP 1.7 - Contracts check");

        var _loc_has_contracts = false;
        if (variable_struct_exists(_cur_loc, "tags")) {
            for (var _ct = 0; _ct < array_length(_cur_loc.tags); _ct++) {
                if (_cur_loc.tags[_ct] == "contracts") { _loc_has_contracts = true; break; }
            }
        }

        if (_loc_has_contracts) {

            // scr_cmd_contracts("") generates/refreshes pool and prints the board
            scr_cmd_contracts("");

            var _avail_raw = variable_struct_exists(_cur_loc, "available_contracts")
                             ? array_length(_cur_loc.available_contracts) : 0;
            var _exp_count  = 0;
            var _tkn_count  = 0;
            for (var _cti = 0; _cti < _avail_raw; _cti++) {
                var _raw_c = _cur_loc.available_contracts[_cti];
                if (_raw_c.deadline_day <= obj_heartbeat.day) { _exp_count++; continue; }
                var _is_taken = false;
                for (var _tai = 0; _tai < array_length(obj_player.active_contracts); _tai++) {
                    if (obj_player.active_contracts[_tai].id == _raw_c.id) {
                        _is_taken = true; break;
                    }
                }
                if (_is_taken) _tkn_count++;
            }
            console_print("[DEBUG] Contracts at " + _cur_loc.name + ": "
                          + string(_avail_raw - _exp_count - _tkn_count) + " available ("
                          + string(_exp_count) + " expired, "
                          + string(_tkn_count) + " already accepted)");

            // Build display list that EXACTLY matches scr_cmd_accept_contract's indexing
            var _display_contracts = [];
            for (var _dci = 0; _dci < _avail_raw; _dci++) {
                var _dc = _cur_loc.available_contracts[_dci];
                if (_dc.deadline_day <= obj_heartbeat.day) continue;
                var _dc_taken = false;
                for (var _dta = 0; _dta < array_length(obj_player.active_contracts); _dta++) {
                    if (obj_player.active_contracts[_dta].id == _dc.id) {
                        _dc_taken = true; break;
                    }
                }
                if (!_dc_taken) array_push(_display_contracts, {
                    contract:      _dc,
                    display_index: array_length(_display_contracts) + 1  // 1-based
                });
            }

            // Evaluate and accept profitable contracts
            for (var _dli = 0; _dli < array_length(_display_contracts); _dli++) {
                if (array_length(obj_player.active_contracts) >= AI_MAX_ACTIVE_CONTRACTS) break;

                var _entry   = _display_contracts[_dli];
                var _cand_c  = _entry.contract;
                var _days_left = _cand_c.deadline_day - obj_heartbeat.day;

                // Destination must be in direct travel options
                var _dest_reachable = false;
                for (var _rci = 0; _rci < array_length(_options); _rci++) {
                    if (_options[_rci].id == _cand_c.dest_id) {
                        _dest_reachable = true; break;
                    }
                }

                var _skip_reason = "";
                if (_cand_c.reward_gold < AI_CONTRACT_REWARD_MIN) {
                    _skip_reason = "reward " + string(_cand_c.reward_gold)
                                   + "g < min " + string(AI_CONTRACT_REWARD_MIN) + "g";
                } else if (!_dest_reachable) {
                    _skip_reason = "dest " + _cand_c.dest_name + " not directly reachable";
                }

                // Good must be purchasable here in sufficient quantity — no point accepting
                // a contract for goods we cannot actually load onto the caravan.
                var _cg_id    = "";   // good_id for the contract cargo
                var _cg_stock = 0;   // units in stock at this location
                var _cg_uslot = 1;   // units that stack per cargo slot
                if (_skip_reason == ""
                &&  variable_struct_exists(_cur_loc, "economy")
                &&  variable_struct_exists(_cur_loc.economy, "stock_levels")) {
                    var _cgkeys = variable_struct_get_names(_cur_loc.economy.stock_levels);
                    for (var _cgki = 0; _cgki < array_length(_cgkeys); _cgki++) {
                        var _cgid  = _cgkeys[_cgki];
                        var _cgcom = scr_get_commodity_by_id(_cgid);
                        if (_cgcom != undefined && _cgcom.name == _cand_c.good_name) {
                            var _cgbp = scr_calculate_buy_price(_cur_loc, _cgid, 1);
                            if (_cgbp > 0) {
                                _cg_id    = _cgid;
                                _cg_stock = _cur_loc.economy.stock_levels[$ _cgid];
                                _cg_uslot = _cgcom.units_per_slot;
                            }
                            break;
                        }
                    }
                    if (_cg_id == "") {
                        _skip_reason = _cand_c.good_name + " not purchasable here";
                    } else if (_cg_stock < _cand_c.quantity) {
                        _skip_reason = "only " + string(_cg_stock) + "/"
                                       + string(_cand_c.quantity) + " " + _cand_c.good_name + " in stock";
                    }
                }

                var _decision = (_skip_reason == "") ? "ACCEPT" : "SKIP";
                console_print("[DEBUG] Contract #" + string(_entry.display_index) + ": "
                              + _cand_c.good_name + " x" + string(_cand_c.quantity)
                              + " -> " + _cand_c.dest_name
                              + "  reward=" + string(_cand_c.reward_gold) + "g"
                              + "  deadline=day" + string(_cand_c.deadline_day)
                              + " (" + string(_days_left) + "d left)"
                              + "  -> " + _decision
                              + (_skip_reason != "" ? " (" + _skip_reason + ")" : ""));

                if (_decision == "ACCEPT") {
                    scr_cmd_accept_contract(string(_entry.display_index));
                    contracts_accepted++;

                    // ── Immediately buy the required cargo ───────────────────
                    // Budget: gold minus rough travel cost to destination minus buffer.
                    // Step 5 will then fill remaining slots with profit goods.
                    var _rough_tc     = scr_calculate_travel_cost(obj_player.current_location, _cand_c.dest_id);
                    var _rough_travel = (_rough_tc != noone) ? _rough_tc.gold : 0;
                    var _cargo_budget = max(0, obj_player.gold - _rough_travel - AI_GOLD_BUFFER);
                    var _cg_bp        = scr_calculate_buy_price(_cur_loc, _cg_id, 1);

                    // Count empty cargo slots now
                    var _cg_slots = 0;
                    for (var _cgw = 0; _cgw < array_length(obj_player.caravan.wagons); _cgw++) {
                        var _cgc = obj_player.caravan.wagons[_cgw].slots.cargo.contents;
                        for (var _cgs = 0; _cgs < array_length(_cgc); _cgs++) {
                            if (_cgc[_cgs] == undefined) _cg_slots++;
                        }
                    }

                    var _can_buy = floor(_cargo_budget / max(1, _cg_bp));
                    _can_buy     = min(_can_buy, _cg_stock);
                    _can_buy     = min(_can_buy, _cg_slots * _cg_uslot);
                    _can_buy     = min(_can_buy, _cand_c.quantity);  // don't over-buy

                    if (_can_buy > 0) {
                        console_print("[AI] CONTRACT CARGO: Buying " + string(_can_buy) + "x "
                                      + _cand_c.good_name + " @" + string(_cg_bp) + "g  ("
                                      + string(_can_buy) + "/" + string(_cand_c.quantity) + " needed)");
                        scr_cmd_buy(_cand_c.good_name, _can_buy, true);
                    } else {
                        console_print("[DEBUG] CONTRACT CARGO: No budget/space for "
                                      + _cand_c.good_name + " right now");
                    }
                }
            }

            console_print("[DEBUG] Active contracts: "
                          + string(array_length(obj_player.active_contracts))
                          + " -- deadline urgency will influence routing");

        } else {
            console_print("[AI] No contract board here.");
        }

        // ── STEP 2 : Choose destination ───────────────────────────────────
        console_print("[AI] STEP 2 - Choosing destination");

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
            if (_c.water > _max_water) continue; // physically impossible -barrel too small

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

            // 5. Contract deadline urgency: bonus when this destination fulfils a contract
            var _contract_bonus = 0;
            for (var _aci = 0; _aci < array_length(obj_player.active_contracts); _aci++) {
                var _ac = obj_player.active_contracts[_aci];
                if (_ac.dest_id == _opt.id) {
                    var _days_rem = _ac.deadline_day - obj_heartbeat.day;
                    var _urgency  = AI_CONTRACT_URGENCY_BASE * (1 + 1 / max(1, _days_rem));
                    _contract_bonus += _urgency;
                    if (_days_rem < 5) _contract_bonus += AI_CONTRACT_DEADLINE_PANIC;
                    console_print("[DEBUG] Contract urgency: " + _opt.name
                                  + " +" + string(round(_urgency))
                                  + (_days_rem < 5 ? " [PANIC]" : "")
                                  + " (deadline in " + string(_days_rem) + " days)");
                }
            }
            _sc += _contract_bonus;

            // DEBUG: show full scoring breakdown for this destination
            var _novelty_dbg = !variable_struct_exists(unique_locs_visited, _opt.id) ? 1000 : 0;
            console_print("[DEBUG] Route score: " + _opt.name
                          + "  novelty=" + string(_novelty_dbg)
                          + "  dist=" + string(-round(_c.distance))
                          + "  contract=" + string(round(_contract_bonus))
                          + "  total=" + string(round(_sc)));

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
        console_print("[AI] STEP 3 - Provisions check");
        var _prov_target = _dest_cost.provisions + AI_PROVISION_BUFFER;
        if (obj_player.provisions < _prov_target) {
            var _prov_buy = _prov_target - obj_player.provisions;
            console_print("[AI] Need " + string(_prov_target) + ", have " + string(obj_player.provisions)
                          + " -buying " + string(_prov_buy) + " provisions...");
            scr_buy_provisions(_cur_loc, _prov_buy);
        } else {
            console_print("[AI] Provisions OK (" + string(obj_player.provisions) + " >= " + string(_prov_target) + ")");
        }

        // scr_buy_provisions fails silently when the town is out of stock.
        // Re-check: if we still can't feed ourselves for this journey, find a
        // shorter route we CAN reach rather than triggering the work path.
        if (obj_player.provisions < _dest_cost.provisions) {
            console_print("[AI] Still short on provisions (" + string(obj_player.provisions)
                          + " have, " + string(_dest_cost.provisions) + " needed) -town may be out of stock.");
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

        // ── STEP 4 : Work only if GOLD is short -never for provisions ───
        console_print("[AI] STEP 4 - Affordability check");
        var _afford = scr_can_afford_journey(_dest_cost);

        if (!_afford.can_afford) {
            if (_afford.missing.gold > 0) {
                // Need more gold -work for it
                var _gold_short = _afford.missing.gold;
                var _work_days  = min(AI_MAX_WORK_DAYS, ceil(max(_gold_short, 5) / 8));
                console_print("[AI] Short " + string(_gold_short) + " gold - working " + string(_work_days) + " day(s)...");
                scr_cmd_work(_work_days);

                // Work consumes provisions -top up again if needed (but don't loop back into work)
                if (obj_player.provisions < _dest_cost.provisions) {
                    var _pb2 = _dest_cost.provisions + AI_PROVISION_BUFFER - obj_player.provisions;
                    console_print("[AI] Re-buying " + string(_pb2) + " provisions after working...");
                    scr_buy_provisions(_cur_loc, _pb2);
                }

                // Final gold check -if still short, find the cheapest affordable route
                _afford = scr_can_afford_journey(_dest_cost);
                if (!_afford.can_afford) {
                    console_print("[AI] Still short on gold - finding cheapest affordable route...");
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
                        console_print("[AI] Completely stuck - no affordable route. Aborting.");
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
                              + ") -seeking alternative...");
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
        console_print("[AI] STEP 5 - Trade buying");

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

        // Crew wages are already embedded in _dest_cost.gold by scr_calculate_travel_cost.
        // Log separately for observability.
        if (variable_struct_exists(_dest_cost, "crew_wage") && _dest_cost.crew_wage > 0) {
            var _journey_wages = _dest_cost.crew_wage * _dest_cost.days;
            console_print("[DEBUG] Crew wages: " + string(_dest_cost.crew_wage)
                          + "g/day x " + string(_dest_cost.days) + " days = "
                          + string(_journey_wages) + "g (included in journey cost)");
            total_wages_paid += _journey_wages;
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

                // Skip livestock goods -scr_cmd_sell cannot sell from livestock_trade slots,
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
                console_print("[AI] All cargo slots full - no room to buy.");
            if (_dest_loc == undefined)
                console_print("[AI] Destination struct unavailable - skipping trade.");
        }

        // ── STEP 6 : Execute the journey ─────────────────────────────────
        console_print("[AI] STEP 6 - Departing");
        var _final_afford = scr_can_afford_journey(_dest_cost);
        if (!_final_afford.can_afford) {
            console_print("[AI] Pre-departure check failed. Aborting.");
            break;
        }

        var _is_new_dest = !variable_struct_exists(unique_locs_visited, _dest.id);
        var _contracts_before = array_length(obj_player.active_contracts);
        console_print("[AI] ▶ DEPARTING for " + _dest.name + " ◀");
        scr_begin_journey(_dest.id, _dest_cost);
        journeys_done++;

        // Track contracts resolved (completed or failed) during this journey
        contracts_resolved += max(0, _contracts_before - array_length(obj_player.active_contracts));

        unique_locs_visited[$ _dest.id] = { last_turn: journeys_done };
        array_push(loc_visit_log, {
            name: _dest.name,
            day:  obj_heartbeat.day,
            role: _is_new_dest ? "NEW" : "REVISIT"
        });

        // Periodic save + log-flush checkpoint
        if (journeys_done mod AI_SAVE_INTERVAL == 0) {
            console_print("[DEBUG] Checkpoint (turn " + string(journeys_done) + "): saving...");
            scr_cmd_save();
            saves_done++;

            // Flush debug log to disk: GML only writes the buffer on file_text_close().
            // Close and immediately reopen so progress is safe even if the game is force-quit.
            if (global.debug_log_enabled
            &&  global.debug_log_file != -1
            &&  global.debug_log_path != "") {
                file_text_close(global.debug_log_file);
                global.debug_log_file = file_text_open_append(global.debug_log_path);
                if (global.debug_log_file == -1) {
                    // Lost the log handle — disable to avoid crashes
                    global.debug_log_enabled = false;
                } else {
                    console_print("[DEBUG] Log flushed to disk at turn " + string(journeys_done));
                }
            }
        }

        console_print("");
    } // end while

    // ═══════════════════════════════════════════════════════════════════════
    // FINAL SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    var _unique_count = array_length(variable_struct_get_names(unique_locs_visited));

    console_print("");
    console_print(string_repeat(chr(9552), 42));
    console_print("         AI AUTOPLAY COMPLETE");
    console_print("------------------------------------------");
    var _rep_final     = obj_player.reputation;
    var _rep_delta     = _rep_final - _rep_start;
    var _rep_delta_str = (_rep_delta >= 0 ? "+" : "") + string(_rep_delta);

    console_print("  Journeys:       " + string(journeys_done) + "/" + string(journey_goal));
    console_print("  Unique places:  " + string(_unique_count));
    console_print("  Final gold:     " + string(obj_player.gold));
    console_print("  Final day:      " + string(obj_heartbeat.day));
    console_print("  Provisions:     " + string(obj_player.provisions));
    console_print("------------------------------------------");
    console_print("  Reputation:     " + string(_rep_start) + " -> "
                  + string(_rep_final) + " (" + _rep_delta_str + ")");
    console_print("  Contracts:      " + string(contracts_accepted)
                  + " accepted, " + string(contracts_resolved) + " resolved");
    console_print("  Crew:           " + string(crew_hired) + " hired, "
                  + string(crew_dismissed) + " dismissed");
    console_print("  Crew wages pd:  " + string(total_wages_paid) + "g total");
    console_print("  Saves:          " + string(saves_done) + " checkpoints");
    console_print("------------------------------------------");
    console_print("  ROUTE LOG:");
    for (var _vi = 0; _vi < array_length(loc_visit_log); _vi++) {
        var _vl = loc_visit_log[_vi];
        var _tag = "  [" + _vl.role + "]";
        console_print("  Day " + string(_vl.day) + " - " + _vl.name + _tag);
    }
    console_print(string_repeat(chr(9552), 42));
    console_print("");
}
