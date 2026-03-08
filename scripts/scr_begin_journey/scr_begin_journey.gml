// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Execute a journey - deduct resources and move player
/// @param {String} destination_id The destination location ID
/// @param {Struct} costs The cost struct from scr_calculate_travel_cost

function scr_begin_journey(destination_id, costs) {

    // === PRE-DEPARTURE: ANIMAL CHECK ===
    // Wagons that require a draft animal cannot travel without one.
    for (var _ai = 0; _ai < array_length(obj_player.caravan.wagons); _ai++) {
        var _aw     = obj_player.caravan.wagons[_ai];
        var _avdata = scr_get_vehicle_data(_aw.type);
        if (_avdata != undefined && _avdata.requires_animal
        &&  array_length(_aw.slots.animals.contents) == 0) {
            console_print("");
            console_print("CANNOT DEPART: Wagon " + string(_ai + 1)
                          + " (" + _aw.type + ") has no draft animal!");
            console_print("A " + _avdata.name + " requires a draft animal to travel.");
            console_print("Buy one with SHOP ANIMALS, or sell the wagon: SHOP SELL VEHICLE "
                          + string(_ai + 1));
            console_print("");
            return;
        }
    }

    // === DEDUCT RESOURCES ===
    // HEDGE_WITCH reduces provisions consumed by 20%
    var _journey_prov_cost = costs.provisions;
    if (variable_struct_exists(obj_player, "hired_crew")) {
        for (var _hwi = 0; _hwi < array_length(obj_player.hired_crew); _hwi++) {
            if (obj_player.hired_crew[_hwi].type == "HEDGE_WITCH") {
                _journey_prov_cost = max(0, floor(_journey_prov_cost * 0.8));
                break;
            }
        }
    }
    obj_player.provisions -= _journey_prov_cost;
    scr_consume_water(costs.water);  // Use barrel system
    obj_player.gold -= costs.gold;

    // === ADVANCE TIME ===
    obj_heartbeat.day += costs.days;

    // === WORLD ECONOMY TICK ===
    // Regenerate all locations the player is NOT visiting so the world stays alive.
    // scr_simulate_ghost_trades handles the destination location separately.
    scr_world_tick(destination_id);

	// === MOVE PLAYER ===
	obj_player.current_location = destination_id;

	// === GET DESTINATION NAME ===
	var dest_name = "Unknown";
	var dest_location = undefined;
	for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
	    if (obj_heartbeat.world.locations[i].id == destination_id) {
	        dest_name = obj_heartbeat.world.locations[i].name;
	        dest_location = obj_heartbeat.world.locations[i];
	        break;
	    }
	}

    // Capture visited flag BEFORE scr_simulate_ghost_trades sets it to true on first visit
    var _was_visited = (dest_location != undefined
                     && variable_struct_exists(dest_location, "economy")
                     && dest_location.economy.player_visited);

    // Clear any map selection so it doesn't linger after the journey
    obj_heartbeat.selected_location_id = "";

	// === SIMULATE GHOST TRADES AT DESTINATION ===
	// Also sets player_visited = true and applies the first-visit catch-up logic.
	if (dest_location != undefined) {
	    scr_simulate_ghost_trades(dest_location);
	}

    // === RUN COMPETITOR TURNS ===
    // Each named rival caravan takes 1-3 turns proportional to the player's journey length.
    scr_run_all_competitors(costs.days);

    // === APPLY WEAR AND TEAR ===
    for (var i = 0; i < array_length(obj_player.caravan.wagons); i++) {
        var wagon = obj_player.caravan.wagons[i];

        // Base wear rate by terrain
        var wear_per_day = 0.5;
        switch (costs.terrain) {
            case "ROAD":     wear_per_day = 0.3; break;
            case "PLAINS":   wear_per_day = 0.5; break;
            case "FOREST":   wear_per_day = 0.7; break;
            case "HILLS":    wear_per_day = 1.0; break;
            case "MOUNTAIN": wear_per_day = 1.5; break;
            case "DESERT":   wear_per_day = 1.2; break;
        }

        // Vehicle wear multiplier (sturdier wagons degrade more slowly)
        var _vdata     = scr_get_vehicle_data(wagon.type);
        var _wear_mult = (_vdata != undefined) ? _vdata.wear_mult : 1.0;

        // Animal wear reduction (OX reduces wear by 30 %)
        var _wear_red = 1.0;
        if (array_length(wagon.slots.animals.contents) > 0) {
            var _ani = wagon.slots.animals.contents[0];
            if (variable_struct_exists(_ani, "wear_reduction")) {
                _wear_red = _ani.wear_reduction;
            }
        }

        var total_wear = wear_per_day * costs.days * _wear_mult * _wear_red;
        wagon.condition = max(0, wagon.condition - total_wear);
    }
    
    // === JOURNEY EVENT ===
    // Roll for a random event (bandit, storm, shortcut, etc.) and apply effects.
    // The event is reported later in the output section.
    var _event = scr_journey_event(costs);
    if (_event != undefined) {
        obj_player.gold       = max(0, obj_player.gold       + _event.gold_delta);
        obj_player.provisions = max(0, obj_player.provisions + _event.prov_delta);
        obj_player.reputation += _event.rep_delta;
        if (_event.cond_delta != 0) {
            for (var _ewi = 0; _ewi < array_length(obj_player.caravan.wagons); _ewi++) {
                obj_player.caravan.wagons[_ewi].condition =
                    clamp(obj_player.caravan.wagons[_ewi].condition + _event.cond_delta, 0, 100);
            }
        }
    }

    // === ALCHEMIST PRODUCTION ===
    // 25% chance per journey to synthesise a random fantasy trade good (placed in first free cargo slot).
    var _alch_good_id   = "";
    var _alch_good_name = "";
    var _alch_placed    = false;
    if (variable_struct_exists(obj_player, "hired_crew")) {
        for (var _ali = 0; _ali < array_length(obj_player.hired_crew); _ali++) {
            if (obj_player.hired_crew[_ali].type == "ALCHEMIST") {
                if (irandom(3) == 0) { // 25% chance
                    var _alch_pool = ["alchemical_reagents", "spell_components", "moonstone",
                                      "enchanted_cloth", "grimoire"];
                    _alch_good_id = _alch_pool[irandom(array_length(_alch_pool) - 1)];
                    // Resolve display name
                    for (var _aci = 0; _aci < array_length(global.commodities); _aci++) {
                        if (global.commodities[_aci].id == _alch_good_id) {
                            _alch_good_name = global.commodities[_aci].name;
                            break;
                        }
                    }
                    // Place in first empty standard cargo slot
                    for (var _awi = 0; _awi < array_length(obj_player.caravan.wagons) && !_alch_placed; _awi++) {
                        var _cargo = obj_player.caravan.wagons[_awi].slots.cargo.contents;
                        for (var _asi = 0; _asi < array_length(_cargo) && !_alch_placed; _asi++) {
                            if (_cargo[_asi] == undefined) {
                                _cargo[_asi] = { good_id: _alch_good_id, quantity: 1 };
                                _alch_placed = true;
                            }
                        }
                    }
                    if (!_alch_placed) _alch_good_id = ""; // no space — nothing produced
                }
                break;
            }
        }
    }

    // === REFILL WATER AT DESTINATION ===
    var refill_info = scr_refill_water();

    // === CHECK CONTRACT COMPLETION ===
    // Resolve active contracts: award gold/rep for successes, penalise failures.
    // Results printed after the resource summary section below.
    var _contract_result = scr_check_contract_completion(destination_id);

    // === JOURNEY COMMENTARY ===
    // Randomly assembled narrative sentence describing the trip.
    // Structure: build a pool of eligible templates, then pick one and fill in variables.
    //
    // HOW TO EXTEND THIS SYSTEM:
    //   - Add general templates to the first block (always eligible)
    //   - Add terrain-specific lines in the switch below
    //   - Add event-specific lines (weather, bandits, etc.) in conditional blocks
    //   - Future: pass an "event" struct here and append event-specific templates
    //     e.g. "A storm slowed progress — what took {days} {day_word} felt like twice that."

    var _d     = costs.days;
    var _dw    = (_d == 1) ? "day" : "days";
    var _dn    = dest_name;

    // --- General templates (always in the pool) ---
    var _pool = [
        "The caravan plodded for {days} {dw} and arrived in {dest}.",
        "After an uneventful {days} {dw} on the road, the caravan rolled into {dest}.",
        "{dest} emerged on the horizon after {days} {dw} of travel.",
        "Dust-covered and road-weary, the caravan finally reached {dest} after {days} {dw}.",
        "Without incident, the caravan made steady progress and arrived in {dest} in {days} {dw}.",
        "The caravan's wheels found {dest} at last, {days} {dw} out from the last stop.",
        "Creaking wagons and tired feet carried the caravan to {dest} over {days} {dw}.",
        "The road stretched long, but {dest} welcomed the caravan after {days} {dw}."
    ];

    // --- Terrain-specific templates ---
    switch (costs.terrain) {
        case "ROAD":
            array_push(_pool, "With a well-kept road underfoot, the caravan made good time and reached {dest} in {days} {dw}.");
            array_push(_pool, "The paved road made for swift travel, and {dest} appeared after just {days} {dw}.");
            break;
        case "PLAINS":
            array_push(_pool, "Across the open plains the caravan traveled, arriving in {dest} after {days} {dw}.");
            array_push(_pool, "The flat plains offered easy going, and the caravan reached {dest} in {days} {dw}.");
            break;
        case "FOREST":
            array_push(_pool, "Threading through dense woodland, the caravan emerged at {dest} after {days} {dw}.");
            array_push(_pool, "The forest paths were slow but passable, and {dest} was reached after {days} {dw}.");
            break;
        case "HILLS":
            array_push(_pool, "The rolling hills slowed progress, but {dest} came into view after {days} {dw}.");
            array_push(_pool, "Up and down the hills the caravan trudged, arriving in {dest} after {days} {dw}.");
            break;
        case "MOUNTAIN":
            array_push(_pool, "The mountain passes were demanding, yet the caravan endured and arrived in {dest} after {days} {dw}.");
            array_push(_pool, "High passes and cold nights tested the caravan, but {dest} rewarded the effort after {days} {dw}.");
            break;
        case "DESERT":
            array_push(_pool, "Under a punishing sun, the caravan pressed through the desert to reach {dest} after {days} {dw}.");
            array_push(_pool, "Sand and heat dogged every step, but {dest} rose from the haze after {days} {dw}.");
            break;
    }

    // --- Duration-specific bonus templates ---
    if (_d == 1) {
        array_push(_pool, "A single day's journey brought the caravan to {dest}.");
        array_push(_pool, "The caravan made short work of the road, arriving in {dest} in a single day.");
    }
    if (_d >= 7) {
        array_push(_pool, "After a long and grueling {days}-{dw} journey, {dest} was a welcome sight.");
        array_push(_pool, "Many days of hard travel finally ended as the caravan limped into {dest} after {days} {dw}.");
    }

    // Event-specific narrative lines (appended to _pool when an event occurred)
    if (_event != undefined) {
        // Blend event into journey narrative for negative events
        switch (_event.type) {
            case "BANDIT":
                array_push(_pool, "Despite trouble on the road, the caravan arrived in {dest} after {days} {dw}.");
                array_push(_pool, "Through bandit-ridden territory, the caravan pressed on and reached {dest} in {days} {dw}.");
                break;
            case "STORM":
            case "DESERT_HEAT":
                array_push(_pool, "Battling harsh conditions, the caravan endured and reached {dest} after {days} {dw}.");
                array_push(_pool, "The weather was unkind, but {dest} welcomed the battered caravan after {days} {dw}.");
                break;
            case "BREAKDOWN":
                array_push(_pool, "After a difficult stretch of road, the caravan limped into {dest} after {days} {dw}.");
                array_push(_pool, "Wagon troubles slowed progress, but the caravan finally rolled into {dest} after {days} {dw}.");
                break;
            case "SHORTCUT":
                array_push(_pool, "Thanks to a fortunate shortcut, the caravan arrived in {dest} ahead of schedule.");
                array_push(_pool, "Good fortune on the road brought the caravan to {dest} faster than expected.");
                break;
            case "FAIR_WEATHER":
                array_push(_pool, "Fine weather blessed the journey and the caravan reached {dest} in good spirits after {days} {dw}.");
                break;
            case "DISCOVERY":
                array_push(_pool, "The journey to {dest} yielded more than expected — {days} {dw} well spent.");
                break;
            case "DRAGON_SIGHTING":
                array_push(_pool, "A dragon's shadow fell over the road, but the caravan pressed on and reached {dest} after {days} {dw}.");
                array_push(_pool, "The caravan weathered a terrifying encounter en route to {dest}, arriving shaken but intact after {days} {dw}.");
                break;
            case "ARCANE_STORM":
                array_push(_pool, "Through magical havoc, the caravan endured and reached {dest} after {days} {dw}.");
                array_push(_pool, "An arcane tempest tested the caravan's resolve, but {dest} was reached after {days} {dw}.");
                break;
            case "WANDERING_MAGE":
                array_push(_pool, "An unexpected encounter on the road made the journey to {dest} memorable — {days} {dw} well spent.");
                array_push(_pool, "Magic touched the road to {dest}. The caravan arrived after {days} {dw} with a story to tell.");
                break;
            case "FAE_CROSSROADS":
                array_push(_pool, "The road to {dest} took a strange turn — the caravan arrived after {days} {dw}, however that happened.");
                array_push(_pool, "Time played tricks on the journey to {dest}. The caravan arrived after {days} {dw}, bewildered but intact.");
                break;
            case "WITCH_CURSE":
                array_push(_pool, "Despite dark forces at work on the road, the caravan limped into {dest} after {days} {dw}.");
                array_push(_pool, "A curse dogged the caravan's steps, but {dest} was reached after {days} {dw}.");
                break;
        }
    }

    // Pick a random line and substitute variables
    var _line = _pool[irandom(array_length(_pool) - 1)];
    _line = string_replace_all(_line, "{dest}", _dn);
    _line = string_replace_all(_line, "{days}", string(_d));
    _line = string_replace_all(_line, "{dw}",   _dw);

    // === REPORT JOURNEY OUTCOME ===
    console_print("");
    console_print(_hdr("JOURNEY COMPLETE"));
    console_print(_line);
    if (_was_visited) {
        console_print(dest_name + " -- you've been here before.");
    }

    // Event report block (printed between narrative and journey summary)
    if (_event != undefined) {
        console_print("");
        console_print(_hdr("EVENT: " + _event.title));
        console_print(_event.narrative);
        // Build a compact effects line
        var _eff = "";
        if (_event.gold_delta != 0) {
            _eff += "  Gold: " + ((_event.gold_delta > 0) ? "+" : "") + string(_event.gold_delta);
        }
        if (_event.prov_delta != 0) {
            if (_eff != "") _eff += "  |";
            _eff += "  Provisions: " + ((_event.prov_delta > 0) ? "+" : "") + string(_event.prov_delta);
        }
        if (_event.cond_delta != 0) {
            if (_eff != "") _eff += "  |";
            _eff += "  Wagon condition: " + ((_event.cond_delta > 0) ? "+" : "") + string(_event.cond_delta) + "%";
        }
        if (_event.rep_delta != 0) {
            if (_eff != "") _eff += "  |";
            _eff += "  Reputation: " + ((_event.rep_delta > 0) ? "+" : "") + string(_event.rep_delta);
        }
        if (_eff != "") console_print(_eff);
    }

    // Alchemist production report
    if (_alch_good_id != "") {
        console_print("");
        console_print(_hdr("ALCHEMIST: " + _alch_good_name + " Produced"));
        console_print("Your alchemist worked through the journey and synthesised 1 unit of "
                      + _alch_good_name + ". It has been added to cargo.");
    }

    console_print("");
    console_print("Journey summary:");
    console_print("  Distance traveled: " + string(round(costs.distance)) + " km");
    console_print("  Time elapsed: " + string(costs.days) + " days");
    console_print("  Terrain: " + string_upper(costs.terrain));
    console_print("");
    console_print("Resources consumed:");
    console_print("  Provisions: " + string(costs.provisions));
    console_print("  Water: " + string(costs.water));
    console_print("  Gold: " + string(costs.gold));
    console_print("");
    
    // Report water refill
    if (refill_info.water > 0) {
        console_print("Water refilled:");
        console_print("  " + string(refill_info.barrels) + " barrel(s) topped off (+"+string(refill_info.water)+" water)");
        console_print("");
    }
    
    console_print("Current resources:");
    console_print("  Provisions: " + string(obj_player.provisions));
    console_print("  Water: " + string(scr_get_total_water()) + "/" + string(scr_get_max_water_capacity()));
    console_print("  Gold: " + string(obj_player.gold));
    console_print("");

    // === CONTRACT OUTCOME REPORT ===
    for (var _cri = 0; _cri < array_length(_contract_result.completed); _cri++) {
        var _cc = _contract_result.completed[_cri];
        console_print(_hdr("CONTRACT COMPLETE: " + _cc.good_name + " Delivery"));
        console_print("Delivered " + string(_cc.quantity) + " " + _cc.good_name
                      + " to " + _cc.dest_name + ".");
        console_print("Reward:  +" + string(_cc.reward_gold) + " gold"
                      + "  |  Reputation: +2  |  Gold total: " + string(obj_player.gold));
        console_print("");
    }
    for (var _crf = 0; _crf < array_length(_contract_result.failed); _crf++) {
        var _cf = _contract_result.failed[_crf];
        console_print(_hdr("CONTRACT FAILED: " + _cf.good_name + " Delivery"));
        if (_cf.fail_reason == "cargo") {
            console_print("Arrived at " + _cf.dest_name + " with only "
                          + string(_cf.in_cargo) + "/" + string(_cf.quantity)
                          + " " + _cf.good_name + " in cargo.");
        } else {
            console_print("Deadline was Day " + string(_cf.deadline_day) + " — contract expired.");
        }
        console_print("Reputation: -1");
        console_print("");
    }

    // Warn if resources are low
    if (obj_player.provisions < 10) {
        console_print("WARNING: Provisions are running low!");
    }
    if (scr_get_total_water() < 10) {
        console_print("WARNING: Water is running low!");
    }
    if (obj_player.gold < 20) {
        console_print("WARNING: Gold reserves are low!");
    }
    
    // === JOURNEY COUNTER ===
    obj_heartbeat.journey_count++;

    if (obj_heartbeat.setup_config.game_mode == "JOURNEY"
    ||  obj_heartbeat.setup_config.game_mode == "BEAT_AI") {
        var _done  = obj_heartbeat.journey_count;
        var _limit = obj_heartbeat.setup_config.journey_limit;
        var _left  = _limit - _done;
        if (_done >= _limit) {
            scr_show_end_screen();
            obj_heartbeat.game_state = "GAMEOVER";
        } else {
            console_print("[Journey " + string(_done) + " / " + string(_limit)
                          + "  --  " + string(_left) + " remaining]");
            console_print("");
            console_print("Type 'TRAVEL' to see destinations from here.");
        }
    } else {
        // ENDLESS mode — no trip limit
        console_print("");
        console_print("Type 'TRAVEL' to see destinations from here.");
    }
}