// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func world_generate(seed, world_size, n_rivals, gold_mult)
/// @desc Generate a procedural world with locations and routes.
/// @param {real}   seed        Random seed for reproducibility
/// @param {String} world_size  "SMALL" (25 locs) | "MEDIUM" (40 locs) | "LARGE" (60 locs)
/// @param {Real}   n_rivals    Number of competitor caravans (2 | 3 | 5)
/// @param {Real}   gold_mult   Competitor starting-gold multiplier (1.0 | 2.0)

function world_generate(seed, world_size, n_rivals, gold_mult) {
    // Apply defaults for optional parameters
    world_size = (world_size == undefined) ? "SMALL" : world_size;
    n_rivals   = (n_rivals   == undefined) ? 2       : n_rivals;
    gold_mult  = (gold_mult  == undefined) ? 1.0     : gold_mult;

    // Derive location counts from world size
    var n_cities, n_towns, n_villages;
    if (world_size == "LARGE") {
        n_cities = 12; n_towns = 24; n_villages = 24;
    } else if (world_size == "MEDIUM") {
        n_cities = 8;  n_towns = 16; n_villages = 16;
    } else {
        n_cities = 5;  n_towns = 10; n_villages = 10;
    }

    // Set seed for reproducibility
    random_set_seed(seed);

    // Create world struct
    var world = {
        seed: seed,
        locations: [],
        routes: [],
        start_location_id: ""
    };

    // === LOCATION NAME POOLS ===
    // 15 city names (enough for LARGE which uses 12)
    var city_names = [
        "Millhaven", "Redstone", "Oakshire", "Crossroads", "Silverpeak",
        "Ironforge", "Shadowvale", "Brightwater", "Stonehaven", "Goldmeadow",
        "Thornbury", "Riverbend", "Cloudrest", "Emberfall", "Frostwatch"
    ];

    // 24 town names (enough for LARGE which uses 24)
    var town_names = [
        "Green Hill", "Pine Creek", "Sunset Ridge", "Crystal Lake", "Maple Grove",
        "Rocky Point", "Cedar Valley", "Willow Springs", "Copper Mine", "Harvest Glen",
        "Amber Falls", "Iron Bridge", "Salt Flats", "Clay Cross",
        "Briar Gate", "Dusty Knoll", "River Bend", "Stony Ford", "High Crossing",
        "Pale Meadow", "East Watch", "West Haven", "Half Moon", "Broken Lance"
    ];

    // 24 village names (enough for LARGE which uses 24)
    var village_names = [
        "Smallbrook", "Dusty Corner", "Quiet Hollow", "Last Stand", "Foggy Bottom",
        "Hidden Path", "Lucky Strike", "Windy Gap", "Old Mill", "Sheep's Rest",
        "Cinder Hollow", "Ash Creek", "Mud Gulch", "Rocky Bottom",
        "Bleak Heath", "Short Road", "Lost Wheel", "Empty Barrel", "Cracked Bell",
        "Frost Bite", "Dark Corner", "Thin Air", "Wren's Nest", "Badger's End"
    ];

    // === GENERATE CITIES (Tier 1) ===
    for (var i = 0; i < n_cities; i++) {
        var loc = {
            id: "city_" + string(i),
            name: city_names[i],
            type: "CITY",
            tier: 1,
            danger: 0,  // Cities are safe
            x: random_range(100, 900),
            y: random_range(100, 700),
            tags: ["market", "contracts", "hire"]
        };
        array_push(world.locations, loc);
    }

    // === GENERATE TOWNS (Tier 2) ===
    for (var i = 0; i < n_towns; i++) {
        var loc = {
            id: "town_" + string(i),
            name: town_names[i],
            type: "TOWN",
            tier: 2,
            danger: 1,
            x: random_range(100, 900),
            y: random_range(100, 700),
            tags: ["market", "contracts"]
        };
        array_push(world.locations, loc);
    }

    // === GENERATE VILLAGES (Tier 3) ===
    for (var i = 0; i < n_villages; i++) {
        var loc = {
            id: "village_" + string(i),
            name: village_names[i],
            type: "VILLAGE",
            tier: 3,
            danger: 2,
            x: random_range(100, 900),
            y: random_range(100, 700),
            tags: ["rest"]
        };
        array_push(world.locations, loc);
    }

	// === GENERATE ECONOMIES FOR ALL LOCATIONS ===
	for (var i = 0; i < array_length(world.locations); i++) {
	    world.locations[i].economy = scr_generate_location_economy(world.locations[i]);
	}

    // === CONNECT LOCATIONS ===
    // Connect each location to its 2-3 nearest neighbors
    var location_count = array_length(world.locations);

    for (var i = 0; i < location_count; i++) {
        var loc_a = world.locations[i];

        // Find 2-3 nearest neighbors
        var distances = [];
        for (var j = 0; j < location_count; j++) {
            if (i == j) continue;

            var loc_b = world.locations[j];
            var dist = point_distance(loc_a.x, loc_a.y, loc_b.x, loc_b.y);
            array_push(distances, { index: j, dist: dist });
        }

        // Sort by distance
        array_sort(distances, function(a, b) {
            return a.dist - b.dist;
        });

        // Connect to 2-3 nearest
        var connections = irandom_range(2, 3);
        for (var k = 0; k < min(connections, array_length(distances)); k++) {
            var target_index = distances[k].index;
            var loc_b = world.locations[target_index];

            // Check if route already exists
            var exists = false;
            for (var r = 0; r < array_length(world.routes); r++) {
                var route = world.routes[r];
                if ((route.from_id == loc_a.id && route.to_id == loc_b.id) ||
                    (route.from_id == loc_b.id && route.to_id == loc_a.id)) {
                    exists = true;
                    break;
                }
            }

			if (!exists) {
			    var route = {
			        from_id: loc_a.id,
			        to_id: loc_b.id,
			        distance: distances[k].dist,
			        danger: max(loc_a.danger, loc_b.danger),
			        terrain: scr_determine_terrain_static(loc_a, loc_b, distances[k].dist)
			    };
			    array_push(world.routes, route);
			}
        }
    }

    // === SET STARTING LOCATION (random city) ===
    world.start_location_id = "city_" + string(irandom(n_cities - 1));

    // === GUARANTEE A STAPLE COMMODITY AT THE STARTING CITY ===
    // Ensures new players always have at least one affordable trade good available.
    var staple_ids = ["salt", "wheat", "barley", "corn", "honey"];

    var start_loc = undefined;
    for (var i = 0; i < array_length(world.locations); i++) {
        if (world.locations[i].id == world.start_location_id) {
            start_loc = world.locations[i];
            break;
        }
    }

    if (start_loc != undefined) {
        // Check whether any staple already ended up in the starting city's production
        var has_staple = false;
        for (var i = 0; i < array_length(start_loc.economy.produces); i++) {
            var prod_id = start_loc.economy.produces[i].good_id;
            for (var j = 0; j < array_length(staple_ids); j++) {
                if (prod_id == staple_ids[j]) {
                    has_staple = true;
                    break;
                }
            }
            if (has_staple) break;
        }

        if (!has_staple) {
            var available_staples = [];
            for (var i = 0; i < array_length(staple_ids); i++) {
                var sid = staple_ids[i];
                var already_there = false;
                for (var j = 0; j < array_length(start_loc.economy.produces); j++) {
                    if (start_loc.economy.produces[j].good_id == sid) {
                        already_there = true;
                        break;
                    }
                }
                if (!already_there) {
                    for (var j = 0; j < array_length(start_loc.economy.demands); j++) {
                        if (start_loc.economy.demands[j].good_id == sid) {
                            already_there = true;
                            break;
                        }
                    }
                }
                if (!already_there) array_push(available_staples, sid);
            }

            if (array_length(available_staples) > 0) {
                var chosen_id = available_staples[irandom(array_length(available_staples) - 1)];
                var stock_amt = irandom_range(150, 400);

                array_push(start_loc.economy.produces, {
                    good_id: chosen_id,
                    stock: stock_amt,
                    base_price_mod: 0.7
                });
                start_loc.economy.stock_levels[$ chosen_id] = stock_amt;
                start_loc.economy.price_modifiers[$ chosen_id] = 0.7;
            }
        }
    }

    // === GUARANTEE FULL GRAPH CONNECTIVITY ===
    // Iteratively flood-fill from start, find orphans, and bridge them to the
    // nearest connected location. O(N²) — fine for up to 60 nodes.
    var _conn_iterations = array_length(world.locations);
    for (var _iter = 0; _iter < _conn_iterations; _iter++) {

        // --- BFS flood-fill from start ---
        var _visited = {};
        var _queue   = [world.start_location_id];
        _visited[$ world.start_location_id] = true;
        var _qi = 0;
        while (_qi < array_length(_queue)) {
            var _cur_id = _queue[_qi++];
            for (var _r = 0; _r < array_length(world.routes); _r++) {
                var _rt        = world.routes[_r];
                var _neighbor  = "";
                if (_rt.from_id == _cur_id)      _neighbor = _rt.to_id;
                else if (_rt.to_id == _cur_id)   _neighbor = _rt.from_id;
                if (_neighbor != "" && !variable_struct_exists(_visited, _neighbor)) {
                    _visited[$ _neighbor] = true;
                    array_push(_queue, _neighbor);
                }
            }
        }

        // --- Find the first unreachable location (orphan) ---
        var _orphan = undefined;
        for (var _i = 0; _i < array_length(world.locations); _i++) {
            if (!variable_struct_exists(_visited, world.locations[_i].id)) {
                _orphan = world.locations[_i];
                break;
            }
        }
        if (_orphan == undefined) break; // All locations connected — done

        // --- Find the nearest REACHABLE location to bridge to ---
        var _best_dist = 999999;
        var _best_loc  = undefined;
        var _vkeys     = variable_struct_get_names(_visited);
        for (var _i = 0; _i < array_length(_vkeys); _i++) {
            var _vid = _vkeys[_i];
            for (var _j = 0; _j < array_length(world.locations); _j++) {
                if (world.locations[_j].id == _vid) {
                    var _d = point_distance(_orphan.x, _orphan.y,
                                            world.locations[_j].x, world.locations[_j].y);
                    if (_d < _best_dist) {
                        _best_dist = _d;
                        _best_loc  = world.locations[_j];
                    }
                    break;
                }
            }
        }

        // --- Add bridge route ---
        if (_best_loc != undefined) {
            array_push(world.routes, {
                from_id:  _orphan.id,
                to_id:    _best_loc.id,
                distance: _best_dist,
                danger:   max(_orphan.danger, _best_loc.danger),
                terrain:  scr_determine_terrain_static(_orphan, _best_loc, _best_dist)
            });
        }
    }

    // === CREATE COMPETITOR CARAVANS ===
    // Named rivals start at locations far from the player and run independent
    // turns each time the player travels (via scr_run_all_competitors).
    world.competitors = scr_create_competitors(world.locations,
                                                world.start_location_id,
                                                n_rivals,
                                                gold_mult);

    return world;
}
