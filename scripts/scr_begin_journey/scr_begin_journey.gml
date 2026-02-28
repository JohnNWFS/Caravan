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
    obj_player.provisions -= costs.provisions;
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
    
    // === REFILL WATER AT DESTINATION ===
    var refill_info = scr_refill_water();
    
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

    // --- TODO: Event templates (weather, bandits, discoveries) ---
    // When events are added, append event-specific lines here based on the event result,
    // e.g.: if (journey_event == "STORM") { array_push(_pool, "..."); }

    // Pick a random line and substitute variables
    var _line = _pool[irandom(array_length(_pool) - 1)];
    _line = string_replace_all(_line, "{dest}", _dn);
    _line = string_replace_all(_line, "{days}", string(_d));
    _line = string_replace_all(_line, "{dw}",   _dw);

    // === REPORT JOURNEY OUTCOME ===
    console_print("");
    console_print("=== JOURNEY COMPLETE ===");
    console_print(_line);
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
    
    console_print("");
    console_print("Type 'TRAVEL' to see destinations from here.");
}