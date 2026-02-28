// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Create named competitor caravans for a new world.
///       Returns an array of n_rivals competitor structs.
/// @param {Array}  locations         world.locations array
/// @param {String} start_location_id Player's starting location id
/// @param {Real}   n_rivals          How many rivals to create (2 | 3 | 5)
/// @param {Real}   gold_mult         Starting gold multiplier (1.0 normal | 2.0 aggressive)

function scr_create_competitors(locations, start_location_id, n_rivals, gold_mult) {
    n_rivals  = (n_rivals  == undefined) ? 2   : n_rivals;
    gold_mult = (gold_mult == undefined) ? 1.0 : gold_mult;

    // === FIND PLAYER START COORDS ===
    var _start_loc = undefined;
    for (var _i = 0; _i < array_length(locations); _i++) {
        if (locations[_i].id == start_location_id) {
            _start_loc = locations[_i];
            break;
        }
    }
    var _sx = (_start_loc != undefined) ? _start_loc.x : 0;
    var _sy = (_start_loc != undefined) ? _start_loc.y : 0;

    // === SORT ALL CITIES BY DISTANCE FROM PLAYER START (descending) ===
    // Used to place Rosa (1st-farthest), Diego (2nd-farthest), Fatima (3rd-farthest)
    var _city_dists = [];
    for (var _i = 0; _i < array_length(locations); _i++) {
        var _loc = locations[_i];
        if (_loc.type != "CITY") continue;
        if (_loc.id == start_location_id) continue;
        array_push(_city_dists, {
            id:   _loc.id,
            dist: point_distance(_loc.x, _loc.y, _sx, _sy)
        });
    }
    array_sort(_city_dists, function(a, b) { return b.dist - a.dist; }); // descending

    // === SORT ALL TOWNS BY DISTANCE FROM PLAYER START (descending) ===
    // Used to place Ibn (1st-farthest town)
    var _town_dists = [];
    for (var _i = 0; _i < array_length(locations); _i++) {
        var _loc = locations[_i];
        if (_loc.type != "TOWN") continue;
        array_push(_town_dists, {
            id:   _loc.id,
            dist: point_distance(_loc.x, _loc.y, _sx, _sy)
        });
    }
    array_sort(_town_dists, function(a, b) { return b.dist - a.dist; }); // descending

    // === SORT ALL VILLAGES BY DISTANCE FROM PLAYER START (descending) ===
    // Used to place Mei Lin (1st-farthest village)
    var _vill_dists = [];
    for (var _i = 0; _i < array_length(locations); _i++) {
        var _loc = locations[_i];
        if (_loc.type != "VILLAGE") continue;
        array_push(_vill_dists, {
            id:   _loc.id,
            dist: point_distance(_loc.x, _loc.y, _sx, _sy)
        });
    }
    array_sort(_vill_dists, function(a, b) { return b.dist - a.dist; }); // descending

    // Resolve starting locations with safe fallbacks (no nested ternaries)
    var _rosa_start_id;
    if (array_length(_city_dists) > 0) {
        _rosa_start_id = _city_dists[0].id;
    } else if (start_location_id == "city_0") {
        _rosa_start_id = "city_1";
    } else {
        _rosa_start_id = "city_0";
    }

    var _ibn_start_id;
    if (array_length(_town_dists) > 0) {
        _ibn_start_id = _town_dists[0].id;
    } else {
        _ibn_start_id = "town_0";
    }

    var _mei_start_id;
    if (array_length(_vill_dists) > 0) {
        _mei_start_id = _vill_dists[0].id;
    } else {
        _mei_start_id = "village_0";
    }

    var _diego_start_id;
    if (array_length(_city_dists) > 1) {
        _diego_start_id = _city_dists[1].id;
    } else if (array_length(_city_dists) > 0) {
        _diego_start_id = _city_dists[0].id;
    } else {
        _diego_start_id = "city_2";
    }

    var _fatima_start_id;
    if (array_length(_city_dists) > 2) {
        _fatima_start_id = _city_dists[2].id;
    } else if (array_length(_city_dists) > 0) {
        _fatima_start_id = _city_dists[0].id;
    } else {
        _fatima_start_id = "city_3";
    }

    // ================================================================
    // COMPETITOR 0 — Rosa Marchetti (EXPLORER)
    // Wanders widely, high explore bonus, ignores short margins.
    // Starts at the city farthest from the player.
    // ================================================================
    var _rosa = {
        id:                  "comp_0",
        name:                "Rosa Marchetti",
        personality:         "EXPLORER",
        gold:                round(600 * gold_mult),
        provisions:          50,
        current_location:    _rosa_start_id,
        cargo:               [],
        cargo_capacity:      150,
        unique_locs_visited: {},
        turn_count:          0,
        recency_penalty:     400,
        recency_turns:       8,
        margin_mult:         3,
        explore_bonus:       2000,
        distance_weight:     0.5,
        max_journey_days:    10,
    };
    _rosa.unique_locs_visited[$ _rosa.current_location] = { last_turn: 0 };

    // ================================================================
    // COMPETITOR 1 — Ibn Rashid (SPECULATOR)
    // Hammers high-margin routes, short journeys, ignores new places.
    // Starts at the town farthest from the player.
    // ================================================================
    var _ibn = {
        id:                  "comp_1",
        name:                "Ibn Rashid",
        personality:         "SPECULATOR",
        gold:                round(400 * gold_mult),
        provisions:          50,
        current_location:    _ibn_start_id,
        cargo:               [],
        cargo_capacity:      100,
        unique_locs_visited: {},
        turn_count:          0,
        recency_penalty:     200,
        recency_turns:       5,
        margin_mult:         10,
        explore_bonus:       500,
        distance_weight:     0.8,
        max_journey_days:    8,
    };
    _ibn.unique_locs_visited[$ _ibn.current_location] = { last_turn: 0 };

    // ================================================================
    // COMPETITOR 2 — Mei Lin Chen (ARBITRAGEUR)  [MEDIUM + LARGE]
    // Plays city-to-city price spreads methodically.
    // Starts at the village farthest from the player.
    // ================================================================
    var _mei = {
        id:                  "comp_2",
        name:                "Mei Lin Chen",
        personality:         "ARBITRAGEUR",
        gold:                round(500 * gold_mult),
        provisions:          50,
        current_location:    _mei_start_id,
        cargo:               [],
        cargo_capacity:      120,
        unique_locs_visited: {},
        turn_count:          0,
        recency_penalty:     400,
        recency_turns:       6,
        margin_mult:         7,
        explore_bonus:       800,
        distance_weight:     0.6,
        max_journey_days:    9,
    };
    _mei.unique_locs_visited[$ _mei.current_location] = { last_turn: 0 };

    // ================================================================
    // COMPETITOR 3 — Diego Torres (OPPORTUNIST)  [LARGE only]
    // Wanders even more than Rosa — extreme explore bonus, ignores distance.
    // Starts at the 2nd-farthest city from the player.
    // ================================================================
    var _diego = {
        id:                  "comp_3",
        name:                "Diego Torres",
        personality:         "OPPORTUNIST",
        gold:                round(350 * gold_mult),
        provisions:          50,
        current_location:    _diego_start_id,
        cargo:               [],
        cargo_capacity:      100,
        unique_locs_visited: {},
        turn_count:          0,
        recency_penalty:     100,
        recency_turns:       4,
        margin_mult:         2,
        explore_bonus:       3000,
        distance_weight:     0.2,
        max_journey_days:    12,
    };
    _diego.unique_locs_visited[$ _diego.current_location] = { last_turn: 0 };

    // ================================================================
    // COMPETITOR 4 — Fatima Al-Rashid (SPECIALIST)  [LARGE only]
    // Focuses on luxury goods with the highest margin multiplier in the game.
    // Very punishing on AGGRESSIVE mode due to double starting gold.
    // Starts at the 3rd-farthest city from the player.
    // ================================================================
    var _fatima = {
        id:                  "comp_4",
        name:                "Fatima Al-Rashid",
        personality:         "SPECIALIST",
        gold:                round(800 * gold_mult),
        provisions:          50,
        current_location:    _fatima_start_id,
        cargo:               [],
        cargo_capacity:      80,
        unique_locs_visited: {},
        turn_count:          0,
        recency_penalty:     300,
        recency_turns:       6,
        margin_mult:         15,
        explore_bonus:       300,
        distance_weight:     1.0,
        max_journey_days:    7,
    };
    _fatima.unique_locs_visited[$ _fatima.current_location] = { last_turn: 0 };

    // === ASSEMBLE OUTPUT ARRAY ===
    var _out = [_rosa, _ibn];
    if (n_rivals >= 3) array_push(_out, _mei);
    if (n_rivals >= 4) array_push(_out, _diego);
    if (n_rivals >= 5) array_push(_out, _fatima);
    return _out;
}
