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
	    world.locations[i].economy   = scr_generate_location_economy(world.locations[i]);
	    world.locations[i].subtype   = "";   // Default: no special type
	}

    // === ASSIGN SPECIAL LOCATION SUBTYPES ===
    // Collect indices by base type for random selection
    var _city_idx    = [];
    var _town_idx    = [];
    var _village_idx = [];
    for (var _si = 0; _si < array_length(world.locations); _si++) {
        var _sl = world.locations[_si];
        if (_sl.type == "CITY")    array_push(_city_idx,    _si);
        if (_sl.type == "TOWN")    array_push(_town_idx,    _si);
        if (_sl.type == "VILLAGE") array_push(_village_idx, _si);
    }

    // Helper: pick and remove a random index from an array
    // (inline: shuffle front element to end, splice it out, return it)

    // --- ARCANE LIBRARY (1 per world, any size) ---
    if (array_length(_city_idx) > 0) {
        var _li  = irandom(array_length(_city_idx) - 1);
        var _loc = world.locations[_city_idx[_li]];
        _loc.subtype = "ARCANE_LIBRARY";
        array_push(_loc.tags, "arcane");
        var _le = _loc.economy;
        _le.produces = [];  _le.demands = [];
        _le.stock_levels = {};  _le.price_modifiers = {};
        array_push(_le.produces, { good_id: "spell_components", stock: 80, base_price_mod: 0.75 });
        array_push(_le.produces, { good_id: "grimoire",         stock: 25, base_price_mod: 0.75 });
        array_push(_le.produces, { good_id: "moonstone",        stock: 40, base_price_mod: 0.80 });
        _le.stock_levels[$ "spell_components"] = 80;
        _le.stock_levels[$ "grimoire"]         = 25;
        _le.stock_levels[$ "moonstone"]        = 40;
        _le.stock_levels[$ "provisions"]       = 200;
        array_push(_le.demands, { good_id: "dragon_scale",  demand_level: 100, base_price_mod: 1.6 });
        array_push(_le.demands, { good_id: "ancient_relic", demand_level: 80,  base_price_mod: 1.5 });
        array_delete(_city_idx, _li, 1);
    }

    // --- RUINED SHRINE (1 on SMALL, 2 on MEDIUM/LARGE) ---
    var _n_shrines = (world_size == "SMALL") ? 1 : 2;
    _n_shrines = min(_n_shrines, array_length(_village_idx));
    for (var _ri = 0; _ri < _n_shrines; _ri++) {
        var _si2 = irandom(array_length(_village_idx) - 1);
        var _shrine = world.locations[_village_idx[_si2]];
        _shrine.subtype = "RUINED_SHRINE";
        array_push(_shrine.tags, "market");   // Give market access so SHOP works
        array_push(_shrine.tags, "shrine");
        // Add rare goods to stock only (no produce entry = no production discount)
        _shrine.economy.stock_levels[$ "ancient_relic"] = irandom_range(5, 12);
        _shrine.economy.stock_levels[$ "moonstone"]     = irandom_range(3, 8);
        array_delete(_village_idx, _si2, 1);
    }

    // --- ELVEN OUTPOST (MEDIUM and LARGE only) ---
    if (world_size != "SMALL" && array_length(_town_idx) > 0) {
        var _ei  = irandom(array_length(_town_idx) - 1);
        var _elv = world.locations[_town_idx[_ei]];
        _elv.subtype = "ELVEN_OUTPOST";
        array_push(_elv.tags, "elven");
        var _ee = _elv.economy;
        _ee.produces = [];  _ee.demands = [];
        _ee.stock_levels = {};  _ee.price_modifiers = {};
        // Small stock → natural scarcity pricing (all < 50 units → up to +50% price)
        array_push(_ee.produces, { good_id: "enchanted_cloth", stock: 22, base_price_mod: 0.75 });
        array_push(_ee.produces, { good_id: "silk",            stock: 18, base_price_mod: 0.75 });
        array_push(_ee.produces, { good_id: "wine",            stock: 16, base_price_mod: 0.80 });
        array_push(_ee.produces, { good_id: "moonstone",       stock: 10, base_price_mod: 0.80 });
        _ee.stock_levels[$ "enchanted_cloth"] = 22;
        _ee.stock_levels[$ "silk"]            = 18;
        _ee.stock_levels[$ "wine"]            = 16;
        _ee.stock_levels[$ "moonstone"]       = 10;
        _ee.stock_levels[$ "provisions"]      = 120;
        array_push(_ee.demands, { good_id: "spell_components", demand_level: 80, base_price_mod: 1.6 });
        array_push(_ee.demands, { good_id: "saffron",          demand_level: 60, base_price_mod: 1.4 });
        array_delete(_town_idx, _ei, 1);
    }

    // --- GOBLIN MARKET (LARGE only) ---
    if (world_size == "LARGE" && array_length(_town_idx) > 0) {
        var _gi2 = irandom(array_length(_town_idx) - 1);
        var _gob = world.locations[_town_idx[_gi2]];
        _gob.subtype = "GOBLIN_MARKET";
        array_push(_gob.tags, "goblin");
        var _ge = _gob.economy;
        _ge.produces = [];  _ge.demands = [];
        _ge.stock_levels = {};  _ge.price_modifiers = {};
        // Pick 4 random goods from a curated chaotic pool
        var _gpool = ["alchemical_reagents", "moonstone", "dye", "furs", "weapons",
                      "pottery", "honey", "copper", "spell_components", "ancient_relic",
                      "dragon_scale", "silver", "gems"];
        for (var _gsi = array_length(_gpool) - 1; _gsi > 0; _gsi--) {
            var _gsj  = irandom(_gsi);
            var _gstmp = _gpool[_gsi];
            _gpool[_gsi] = _gpool[_gsj];
            _gpool[_gsj] = _gstmp;
        }
        for (var _gki = 0; _gki < 4; _gki++) {
            var _gid  = _gpool[_gki];
            var _gstk = irandom_range(8, 40);
            array_push(_ge.produces, { good_id: _gid, stock: _gstk, base_price_mod: 0.75 });
            _ge.stock_levels[$ _gid] = _gstk;
        }
        _ge.stock_levels[$ "provisions"] = 60;
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
                // Bezier ctrl point: subtle curve, ±40 world units perpendicular
                var _rmid_x = (loc_a.x + loc_b.x) * 0.5;
                var _rmid_y = (loc_a.y + loc_b.y) * 0.5;
                var _rdx = loc_b.x - loc_a.x;
                var _rdy = loc_b.y - loc_a.y;
                var _rlen = max(1, sqrt(_rdx*_rdx + _rdy*_rdy));
                var _rperp_x = -_rdy / _rlen;
                var _rperp_y =  _rdx / _rlen;
                var _rcurve = ((loc_a.x * 53 + loc_a.y * 29 + loc_b.x * 17 + loc_b.y * 7) mod 200) - 100;
                var route = {
                    from_id:  loc_a.id,
                    to_id:    loc_b.id,
                    distance: distances[k].dist,
                    danger:   max(loc_a.danger, loc_b.danger),
                    terrain:  scr_determine_terrain_static(loc_a, loc_b, distances[k].dist),
                    ctrl_x:   _rmid_x + _rperp_x * _rcurve * 0.4,
                    ctrl_y:   _rmid_y + _rperp_y * _rcurve * 0.4
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
            var _bmid_x = (_orphan.x + _best_loc.x) * 0.5;
            var _bmid_y = (_orphan.y + _best_loc.y) * 0.5;
            var _bdx = _best_loc.x - _orphan.x;
            var _bdy = _best_loc.y - _orphan.y;
            var _blen = max(1, sqrt(_bdx*_bdx + _bdy*_bdy));
            var _bperp_x = -_bdy / _blen;
            var _bperp_y =  _bdx / _blen;
            var _bcurve = ((_orphan.x * 53 + _orphan.y * 29 + _best_loc.x * 17 + _best_loc.y * 7) mod 200) - 100;
            array_push(world.routes, {
                from_id:  _orphan.id,
                to_id:    _best_loc.id,
                distance: _best_dist,
                danger:   max(_orphan.danger, _best_loc.danger),
                terrain:  scr_determine_terrain_static(_orphan, _best_loc, _best_dist),
                ctrl_x:   _bmid_x + _bperp_x * _bcurve * 0.4,
                ctrl_y:   _bmid_y + _bperp_y * _bcurve * 0.4
            });
        }
    }

    // === GENERATE RIVERS ===
    // Rivers now chain 4-5 locations for cross-map scale.
    // Also rolls for an ocean edge that rivers flow toward.
    // Rivers scale with world size: SMALL=1, MEDIUM=2, LARGE=3
    world.rivers   = [];
    world.has_ocean  = false;
    world.ocean_edge = ""; // "LEFT" | "RIGHT" | "TOP" | "BOTTOM"

    var _n_rivers = 1;
    if (world_size == "MEDIUM") _n_rivers = 2;
    if (world_size == "LARGE")  _n_rivers = 3;

    // --- Ocean edge roll (50% chance) ---
    if (irandom(1) == 0) {
        world.has_ocean = true;
        var _edge_pool = ["LEFT", "RIGHT", "TOP", "BOTTOM"];
        world.ocean_edge = _edge_pool[irandom(3)];
    }

    // --- Build rivers via multi-hop graph walk ---
    // Terrain altitude (higher = better river source; rivers flow downhill)
    // MOUNTAIN=4, HILLS=3, FOREST=2, PLAINS=1, else 0
    var _used_starts = {}; // struct used as visited-set for start locations

    for (var _rvi = 0; _rvi < _n_rivers; _rvi++) {

        // Step 1: Find candidate start locations (prefer those with MOUNTAIN/HILLS routes)
        var _start_candidates = [];
        for (var _sli = 0; _sli < array_length(world.locations); _sli++) {
            var _slid = world.locations[_sli].id;
            if (variable_struct_exists(_used_starts, _slid)) continue;
            var _has_upland = false;
            for (var _sri = 0; _sri < array_length(world.routes); _sri++) {
                var _srr = world.routes[_sri];
                if ((_srr.from_id == _slid || _srr.to_id == _slid) &&
                    (_srr.terrain == "MOUNTAIN" || _srr.terrain == "HILLS")) {
                    _has_upland = true;
                    break;
                }
            }
            if (_has_upland) array_push(_start_candidates, _slid);
        }
        // Fallback: any unused location
        if (array_length(_start_candidates) == 0) {
            for (var _sli = 0; _sli < array_length(world.locations); _sli++) {
                var _slid = world.locations[_sli].id;
                if (!variable_struct_exists(_used_starts, _slid)) {
                    array_push(_start_candidates, _slid);
                }
            }
        }
        if (array_length(_start_candidates) == 0) break;

        // Pick a random start
        var _start_id = _start_candidates[irandom(array_length(_start_candidates) - 1)];
        _used_starts[$ _start_id] = true;

        // Step 2: Walk hops proportional to world size so river spans the map
        // SMALL=7 hops (~25 locs), MEDIUM=10 (~40 locs), LARGE=14 (~60 locs)
        var _max_hops = 7;
        if (world_size == "MEDIUM") _max_hops = 10;
        if (world_size == "LARGE")  _max_hops = 14;

        var _chain_ids  = [_start_id];
        var _rvisited   = {}; // visited set for this river
        _rvisited[$ _start_id] = true;

        for (var _hop = 0; _hop < _max_hops; _hop++) {
            var _cur_id = _chain_ids[array_length(_chain_ids) - 1];

            // Resolve current location position
            var _cur_loc = undefined;
            for (var _li = 0; _li < array_length(world.locations); _li++) {
                if (world.locations[_li].id == _cur_id) { _cur_loc = world.locations[_li]; break; }
            }
            if (_cur_loc == undefined) break;

            // Direction vector from previous hop (for anti-backtrack filter)
            var _dir_x = 0;  var _dir_y = 0;
            var _has_dir = (_hop > 0);
            if (_has_dir) {
                var _prev_id = _chain_ids[array_length(_chain_ids) - 2];
                for (var _li = 0; _li < array_length(world.locations); _li++) {
                    if (world.locations[_li].id == _prev_id) {
                        _dir_x = _cur_loc.x - world.locations[_li].x;
                        _dir_y = _cur_loc.y - world.locations[_li].y;
                        break;
                    }
                }
            }

            // Build candidate list, rejecting backward neighbors after first hop
            var _candidates = [];
            for (var _hri = 0; _hri < array_length(world.routes); _hri++) {
                var _hrr = world.routes[_hri];
                if (_hrr.terrain == "DESERT") continue;
                var _nb_id = "";
                if (_hrr.from_id == _cur_id && !variable_struct_exists(_rvisited, _hrr.to_id)) {
                    _nb_id = _hrr.to_id;
                } else if (_hrr.to_id == _cur_id && !variable_struct_exists(_rvisited, _hrr.from_id)) {
                    _nb_id = _hrr.from_id;
                }
                if (_nb_id == "") continue;

                // Anti-backtrack: skip neighbors with negative dot product (going backwards)
                if (_has_dir) {
                    var _nb_loc = undefined;
                    for (var _li = 0; _li < array_length(world.locations); _li++) {
                        if (world.locations[_li].id == _nb_id) { _nb_loc = world.locations[_li]; break; }
                    }
                    if (_nb_loc != undefined) {
                        var _dot = (_nb_loc.x - _cur_loc.x) * _dir_x + (_nb_loc.y - _cur_loc.y) * _dir_y;
                        if (_dot < 0) continue; // reject — going backward
                    }
                }
                array_push(_candidates, { loc_id: _nb_id, terrain: _hrr.terrain });
            }

            // Fallback: if anti-backtrack filtered everything, allow any unvisited neighbor
            if (array_length(_candidates) == 0 && _has_dir) {
                for (var _hri = 0; _hri < array_length(world.routes); _hri++) {
                    var _hrr = world.routes[_hri];
                    if (_hrr.terrain == "DESERT") continue;
                    var _nb_id = "";
                    if (_hrr.from_id == _cur_id && !variable_struct_exists(_rvisited, _hrr.to_id)) {
                        _nb_id = _hrr.to_id;
                    } else if (_hrr.to_id == _cur_id && !variable_struct_exists(_rvisited, _hrr.from_id)) {
                        _nb_id = _hrr.from_id;
                    }
                    if (_nb_id != "") array_push(_candidates, { loc_id: _nb_id, terrain: _hrr.terrain });
                }
            }
            if (array_length(_candidates) == 0) break;

            // Pick neighbor with lowest terrain altitude (downhill flow)
            var _best = _candidates[0];
            var _best_alt = 4;
            for (var _ci = 0; _ci < array_length(_candidates); _ci++) {
                var _ct = _candidates[_ci].terrain;
                var _ca = 0;
                if (_ct == "MOUNTAIN") _ca = 4;
                else if (_ct == "HILLS")   _ca = 3;
                else if (_ct == "FOREST")  _ca = 2;
                else if (_ct == "PLAINS")  _ca = 1;
                if (_ca < _best_alt) { _best = _candidates[_ci]; _best_alt = _ca; }
            }
            _rvisited[$ _best.loc_id] = true;
            array_push(_chain_ids, _best.loc_id);
        }

        if (array_length(_chain_ids) < 2) continue;

        // Step 3: Flatten chain into waypoints (2 jittered points per segment + junctions)
        var _rwaypoints = [];
        for (var _ci = 0; _ci < array_length(_chain_ids) - 1; _ci++) {
            // Resolve location structs for this segment
            var _lid_a = _chain_ids[_ci];
            var _lid_b = _chain_ids[_ci + 1];
            var _loca  = undefined;  var _locb = undefined;
            for (var _rli = 0; _rli < array_length(world.locations); _rli++) {
                if (world.locations[_rli].id == _lid_a) _loca = world.locations[_rli];
                if (world.locations[_rli].id == _lid_b) _locb = world.locations[_rli];
            }
            if (_loca == undefined || _locb == undefined) continue;

            // Add segment start (skip duplicate at chain junctions)
            if (array_length(_rwaypoints) == 0) {
                array_push(_rwaypoints, { x: _loca.x, y: _loca.y });
            }
            // 2 jittered intermediate waypoints per segment
            for (var _rwi = 1; _rwi <= 2; _rwi++) {
                var _rwt   = _rwi / 3.0;
                var _bx    = lerp(_loca.x, _locb.x, _rwt);
                var _by    = lerp(_loca.y, _locb.y, _rwt);
                var _rjx   = irandom_range(-40, 40);
                var _rjy   = irandom_range(-30, 30);
                array_push(_rwaypoints, {
                    x: clamp(_bx + _rjx, 110, 890),
                    y: clamp(_by + _rjy, 110, 690)
                });
            }
            // Segment end (= next segment start)
            array_push(_rwaypoints, { x: _locb.x, y: _locb.y });
        }

        if (array_length(_rwaypoints) == 0) continue;

        // Step 4: Terminus — ocean extension or inland lake
        var _has_lake = false;
        var _lake_x   = 0;
        var _lake_y   = 0;
        var _last_wp  = _rwaypoints[array_length(_rwaypoints) - 1];

        if (world.has_ocean) {
            // Check if terminal is within 350 world units of the ocean edge
            var _dist_to_edge = 999999;
            var _target_x = _last_wp.x;
            var _target_y = _last_wp.y;
            if (world.ocean_edge == "LEFT") {
                _dist_to_edge = _last_wp.x - 100;  // distance from left wall
                _target_x = 80;
            } else if (world.ocean_edge == "RIGHT") {
                _dist_to_edge = 900 - _last_wp.x;
                _target_x = 920;
            } else if (world.ocean_edge == "TOP") {
                _dist_to_edge = _last_wp.y - 100;
                _target_y = 80;
            } else if (world.ocean_edge == "BOTTOM") {
                _dist_to_edge = 700 - _last_wp.y;
                _target_y = 720;
            }

            if (_dist_to_edge <= 350) {
                // Extend to ocean edge
                array_push(_rwaypoints, {
                    x: lerp(_last_wp.x, _target_x, 0.5),
                    y: lerp(_last_wp.y, _target_y, 0.5)
                });
                array_push(_rwaypoints, { x: _target_x, y: _target_y });
            } else {
                // Too far from ocean — give it a lake instead
                _has_lake = true;
                _lake_x   = _last_wp.x;
                _lake_y   = _last_wp.y;
            }
        } else {
            // No ocean — inland lake at terminus
            _has_lake = true;
            _lake_x   = _last_wp.x;
            _lake_y   = _last_wp.y;
        }

        array_push(world.rivers, {
            waypoints: _rwaypoints,
            has_lake:  _has_lake,
            lake_x:    _lake_x,
            lake_y:    _lake_y
        });
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
