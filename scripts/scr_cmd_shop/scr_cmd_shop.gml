// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle SHOP command and all sub-commands.
///       Called from cmd_parse after splitting the first two words off the input.
/// @param {String} sub   Sub-command in UPPER CASE: "", "VEHICLES", "ANIMALS", "BUY", "SELL"
/// @param {String} arg   Remainder of the command string (also upper case)

function scr_cmd_shop(sub, arg) {

    // === FIND CURRENT LOCATION ===
    var _current_loc = undefined;
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == obj_player.current_location) {
            _current_loc = obj_heartbeat.world.locations[_i];
            break;
        }
    }
    if (_current_loc == undefined) {
        console_print("ERROR: Current location not found.");
        return;
    }

    var _loc_type = _current_loc.type; // "VILLAGE", "TOWN", or "CITY"

    switch (sub) {

        // ----------------------------------------------------------------
        case "":
            console_print("");
            console_print("=== SHOP: " + _current_loc.name + " (" + _loc_type + ") ===");
            console_print("  SHOP VEHICLES      — browse available carts and wagons");
            console_print("  SHOP ANIMALS       — browse available draft animals");
            console_print("  SHOP BUY <name>    — purchase a vehicle or animal");
            console_print("  SHOP SELL VEHICLE <n>  — sell wagon #n from your caravan");
            console_print("  SHOP SELL ANIMAL  <n>  — sell animal on wagon #n");
            console_print("");
            break;

        // ----------------------------------------------------------------
        case "V":
        case "VE":
        case "VEHICLE":
        case "VEHICLES":
            _scr_shop_list_vehicles(_current_loc, _loc_type);
            break;

        // ----------------------------------------------------------------
        case "A":
        case "AN":
        case "ANIMAL":
        case "ANIMALS":
            _scr_shop_list_animals(_current_loc, _loc_type);
            break;

        // ----------------------------------------------------------------
        case "BUY":
            if (arg == "") {
                console_print("Usage: SHOP BUY <vehicle or animal name>");
                console_print("Example: SHOP BUY CART   or   SHOP BUY HORSE");
                break;
            }
            _scr_shop_buy(_current_loc, _loc_type, arg);
            break;

        // ----------------------------------------------------------------
        case "SELL":
            // arg = "VEHICLE <n>"  or  "ANIMAL <n>"
            var _sell_sp   = string_pos(" ", arg);
            var _sell_type = (_sell_sp > 0) ? string_copy(arg, 1, _sell_sp - 1) : arg;
            var _sell_num  = (_sell_sp > 0) ? string_trim(string_delete(arg, 1, _sell_sp)) : "";

            if (_sell_type == "VEHICLE" || _sell_type == "V" || _sell_type == "WAGON") {
                if (_sell_num == "") {
                    console_print("Usage: SHOP SELL VEHICLE <wagon number>   e.g. SHOP SELL VEHICLE 1");
                    break;
                }
                _scr_shop_sell_vehicle(_current_loc, real(_sell_num));

            } else if (_sell_type == "ANIMAL" || _sell_type == "A") {
                if (_sell_num == "") {
                    console_print("Usage: SHOP SELL ANIMAL <wagon number>   e.g. SHOP SELL ANIMAL 1");
                    break;
                }
                _scr_shop_sell_animal(_current_loc, real(_sell_num));

            } else {
                console_print("Usage: SHOP SELL VEHICLE <n>   or   SHOP SELL ANIMAL <n>");
            }
            break;

        // ----------------------------------------------------------------
        default:
            console_print("Unknown SHOP sub-command: " + sub);
            console_print("Type SHOP to see available options.");
            break;
    }
}

// ================================================================
// PRIVATE HELPERS — called only from scr_cmd_shop above
// ================================================================

/// @ignore
function _scr_shop_list_vehicles(loc, loc_type) {
    console_print("");
    console_print("=== VEHICLES FOR SALE AT " + loc.name + " (" + loc_type + ") ===");

    var _shown = 0;
    for (var _i = 0; _i < array_length(global.vehicles); _i++) {
        var _v = global.vehicles[_i];

        var _avail = false;
        for (var _ai = 0; _ai < array_length(_v.available_at); _ai++) {
            if (_v.available_at[_ai] == loc_type) { _avail = true; break; }
        }
        if (!_avail) continue;

        _shown++;
        var _animal_str = _v.requires_animal ? "requires draft animal" : "no animal needed";
        var _live_str   = (_v.livestock_slots > 0)
                          ? (", " + string(_v.livestock_slots) + " livestock slot(s)") : "";
        console_print("  [" + string(_shown) + "] " + _v.name
                      + "  —  " + string(_v.price) + "g  (sell back: " + string(_v.sell_price) + "g)");
        console_print("       " + string(_v.cargo_slots) + " cargo slots" + _live_str
                      + ", spd " + string(_v.base_speed) + ", " + _animal_str);
        console_print("       " + _v.desc);
    }

    if (_shown == 0) console_print("  (no vehicles available at this location tier)");

    console_print("");
    console_print("Type SHOP BUY <name> to purchase.  e.g. SHOP BUY CART");
    console_print("");
}

/// @ignore
function _scr_shop_list_animals(loc, loc_type) {
    console_print("");
    console_print("=== ANIMALS FOR SALE AT " + loc.name + " (" + loc_type + ") ===");

    var _shown = 0;
    for (var _i = 0; _i < array_length(global.animals); _i++) {
        var _a = global.animals[_i];

        var _avail = false;
        for (var _ai = 0; _ai < array_length(_a.available_at); _ai++) {
            if (_a.available_at[_ai] == loc_type) { _avail = true; break; }
        }
        if (!_avail) continue;

        _shown++;
        var _sb_str  = (_a.saddlebag_slots > 0)
                       ? ("  [+" + string(_a.saddlebag_slots) + " BULK slots]") : "";
        var _ox_str  = (_a.wear_reduction < 1.0)
                       ? ("  [wagon wear -" + string(round((1 - _a.wear_reduction) * 100)) + "%]") : "";
        var _ex_str  = _a.exotic ? "  [EXOTIC]" : "";
        console_print("  [" + string(_shown) + "] " + _a.name
                      + "  —  " + string(_a.price) + "g  (sell back: " + string(_a.sell_price) + "g)");
        console_print("       spd " + string(_a.speed) + "x  feed " + string(_a.feed_cost)
                      + "/day  water " + string(_a.water_cost) + "/day"
                      + _sb_str + _ox_str + _ex_str);
        console_print("       " + _a.desc);
    }

    if (_shown == 0) console_print("  (no animals available at this location tier)");

    console_print("");
    console_print("Type SHOP BUY <name> to purchase.  e.g. SHOP BUY DONKEY");
    console_print("");
}

/// @ignore
function _scr_shop_buy(loc, loc_type, item_name) {
    var _upper = string_upper(item_name);

    // --- Search vehicle database first ---
    var _vdata = undefined;
    for (var _i = 0; _i < array_length(global.vehicles); _i++) {
        var _v = global.vehicles[_i];
        if (string_upper(_v.id) == _upper || string_upper(_v.name) == _upper
        ||  string_replace_all(string_upper(_v.name), " ", "_") == _upper) {
            _vdata = _v;
            break;
        }
    }

    if (_vdata != undefined) {

        // Availability at this tier
        var _avail = false;
        for (var _ai = 0; _ai < array_length(_vdata.available_at); _ai++) {
            if (_vdata.available_at[_ai] == loc_type) { _avail = true; break; }
        }
        if (!_avail) {
            console_print(_vdata.name + " is not sold here (" + loc_type + ").");
            var _where = _vdata.available_at[array_length(_vdata.available_at) - 1];
            console_print("You need to visit a " + _where + " to purchase one.");
            return;
        }

        // Gold check
        if (obj_player.gold < _vdata.price) {
            console_print("Not enough gold. " + _vdata.name
                          + " costs " + string(_vdata.price) + "g  (you have "
                          + string(obj_player.gold) + "g).");
            return;
        }

        // Build wagon struct matching the existing caravan format
        obj_player.gold -= _vdata.price;

        var _num = array_length(obj_player.caravan.wagons) + 1;
        var _nid = "wagon_";
        if (_num < 10)       _nid += "00" + string(_num);
        else if (_num < 100) _nid += "0"  + string(_num);
        else                 _nid += string(_num);

        var _new_wagon = {
            id:        _nid,
            type:      _vdata.id,
            condition: 100,
            slots: {
                cargo:           { capacity: _vdata.cargo_slots,    contents: [] },
                livestock_trade: { capacity: _vdata.livestock_slots, contents: [] },
                animals:         { capacity: 1, contents: [] },
                crew:            { capacity: 1, contents: [] },
                passengers:      { capacity: 0, contents: [] },
                magic:           { capacity: 0, contents: [] },
                equipment:       { capacity: 1, contents: [] }
            },
            speed_modifier:   1.0,
            defense_modifier: 0.5,
            breakdown_chance: 0.05
        };

        // Initialise empty cargo slots
        for (var _ci = 0; _ci < _vdata.cargo_slots; _ci++) {
            array_push(_new_wagon.slots.cargo.contents, undefined);
        }
        // Initialise empty livestock slots
        for (var _li = 0; _li < _vdata.livestock_slots; _li++) {
            array_push(_new_wagon.slots.livestock_trade.contents, undefined);
        }

        array_push(obj_player.caravan.wagons, _new_wagon);

        console_print("");
        console_print("PURCHASE COMPLETE");
        console_print("Bought: " + _vdata.name);
        console_print("Cost: "   + string(_vdata.price) + " gold");
        console_print("Gold remaining: " + string(obj_player.gold));
        console_print("");
        console_print("Wagon " + string(array_length(obj_player.caravan.wagons))
                      + " added to your caravan.");
        console_print("  Cargo slots: " + string(_vdata.cargo_slots));
        if (_vdata.livestock_slots > 0) {
            console_print("  Livestock slots: " + string(_vdata.livestock_slots));
        }
        if (_vdata.requires_animal) {
            console_print("  NOTE: This wagon requires a draft animal before it can travel.");
            console_print("        Type SHOP ANIMALS to see what is available here.");
        }
        console_print("");
        return;
    }

    // --- Search animal database ---
    var _adata = undefined;
    for (var _i = 0; _i < array_length(global.animals); _i++) {
        var _a = global.animals[_i];
        if (string_upper(_a.id) == _upper || string_upper(_a.name) == _upper) {
            _adata = _a;
            break;
        }
    }

    if (_adata != undefined) {

        // Availability at this tier
        var _avail = false;
        for (var _ai = 0; _ai < array_length(_adata.available_at); _ai++) {
            if (_adata.available_at[_ai] == loc_type) { _avail = true; break; }
        }
        if (!_avail) {
            console_print(_adata.name + " is not sold here (" + loc_type + ").");
            return;
        }

        // Find a wagon with an empty animal slot
        var _target_wagon = -1;
        for (var _wi = 0; _wi < array_length(obj_player.caravan.wagons); _wi++) {
            if (array_length(obj_player.caravan.wagons[_wi].slots.animals.contents) == 0) {
                _target_wagon = _wi;
                break;
            }
        }

        if (_target_wagon == -1) {
            console_print("All your wagons already have a draft animal.");
            console_print("Buy a new wagon first (SHOP VEHICLES), or sell an existing animal.");
            return;
        }

        // Gold check
        if (obj_player.gold < _adata.price) {
            console_print("Not enough gold. " + _adata.name
                          + " costs " + string(_adata.price) + "g  (you have "
                          + string(obj_player.gold) + "g).");
            return;
        }

        obj_player.gold -= _adata.price;

        var _new_animal = {
            type:            _adata.id,
            hp:              100,
            speed:           _adata.speed,
            feed_cost:       _adata.feed_cost,
            water_cost:      _adata.water_cost,
            saddlebag_slots: _adata.saddlebag_slots,
            has_saddlebags:  (_adata.saddlebag_slots > 0),
            wear_reduction:  _adata.wear_reduction
        };

        array_push(obj_player.caravan.wagons[_target_wagon].slots.animals.contents, _new_animal);

        // Add saddlebag slots to this wagon's cargo if applicable
        if (_adata.saddlebag_slots > 0) {
            for (var _si = 0; _si < _adata.saddlebag_slots; _si++) {
                array_push(obj_player.caravan.wagons[_target_wagon].slots.cargo.contents, {
                    slot_type:     "SADDLEBAG_BULK",
                    allowed_types: ["BULK"],
                    contents:      undefined
                });
            }
            obj_player.caravan.wagons[_target_wagon].slots.cargo.capacity += _adata.saddlebag_slots;
        }

        console_print("");
        console_print("PURCHASE COMPLETE");
        console_print("Bought: " + _adata.name);
        console_print("Cost: "   + string(_adata.price) + " gold");
        console_print("Gold remaining: " + string(obj_player.gold));
        console_print("");
        console_print(_adata.name + " assigned to wagon " + string(_target_wagon + 1) + ".");
        if (_adata.saddlebag_slots > 0) {
            console_print("  +" + string(_adata.saddlebag_slots)
                          + " BULK saddlebag slot(s) added to wagon " + string(_target_wagon + 1) + ".");
        }
        console_print("");
        return;
    }

    console_print("Unknown vehicle or animal: " + item_name);
    console_print("Type SHOP VEHICLES or SHOP ANIMALS to see what is available here.");
}

/// @ignore
function _scr_shop_sell_vehicle(loc, wagon_num) {
    var _wagon_count = array_length(obj_player.caravan.wagons);
    var _idx         = wagon_num - 1;

    if (_idx < 0 || _idx >= _wagon_count) {
        console_print("Invalid wagon number. You have " + string(_wagon_count)
                      + " wagon(s). Use 1-" + string(_wagon_count) + ".");
        return;
    }

    var _w          = obj_player.caravan.wagons[_idx];
    var _vdata      = scr_get_vehicle_data(_w.type);
    var _base_price = (_vdata != undefined) ? _vdata.price : 100;
    var _sell_price = floor(_base_price * 0.4 * (_w.condition / 100));
    var _is_last    = (_wagon_count == 1);

    console_print("");
    console_print("=== SELL WAGON " + string(wagon_num) + ": " + _w.type + " ===");
    console_print("  Condition:  " + string(floor(_w.condition)) + "%");
    console_print("  Sell price: " + string(_sell_price) + " gold");

    if (_is_last) {
        console_print("");
        console_print("  *** WARNING: This is your LAST vehicle! ***");
        console_print("  Selling it leaves you stranded here.");
        console_print("  You will only be able to WORK until you can afford a new one.");
    }

    var _has_animal   = (array_length(_w.slots.animals.contents) > 0);
    var _animal_price = 0;
    var _animal_name  = "";

    if (_has_animal) {
        var _ani      = _w.slots.animals.contents[0];
        var _adata    = scr_get_animal_data(_ani.type);
        var _ani_base = (_adata != undefined) ? _adata.price : 50;
        _animal_price = floor(_ani_base * 0.4);
        _animal_name  = _ani.type;
        console_print("  Includes animal: " + _animal_name
                      + "  (+" + string(_animal_price) + " gold)");
        console_print("  Total payout:    " + string(_sell_price + _animal_price) + " gold");
    }

    console_print("");
    console_print("Type YES to confirm, or NO to cancel.");
    console_print("");

    obj_player.pending_action = {
        type:         "sell_vehicle",
        wagon_index:  _idx,
        sell_price:   _sell_price,
        animal_price: _animal_price,
        sell_animal:  _has_animal,
        animal_name:  _animal_name,
        is_last:      _is_last
    };
}

/// @ignore
function _scr_shop_sell_animal(loc, wagon_num) {
    var _wagon_count = array_length(obj_player.caravan.wagons);
    var _idx         = wagon_num - 1;

    if (_idx < 0 || _idx >= _wagon_count) {
        console_print("Invalid wagon number. You have " + string(_wagon_count)
                      + " wagon(s). Use 1-" + string(_wagon_count) + ".");
        return;
    }

    var _w = obj_player.caravan.wagons[_idx];

    if (array_length(_w.slots.animals.contents) == 0) {
        console_print("Wagon " + string(wagon_num) + " has no animal to sell.");
        return;
    }

    var _ani        = _w.slots.animals.contents[0];
    var _adata      = scr_get_animal_data(_ani.type);
    var _ani_base   = (_adata != undefined) ? _adata.price : 50;
    var _sell_price = floor(_ani_base * 0.4);

    var _vdata    = scr_get_vehicle_data(_w.type);
    var _req_anim = (_vdata != undefined && _vdata.requires_animal);

    console_print("");
    console_print("=== SELL ANIMAL: " + _ani.type
                  + "  (on wagon " + string(wagon_num) + ") ===");
    console_print("  Sell price: " + string(_sell_price) + " gold");

    if (_req_anim) {
        console_print("");
        console_print("  *** WARNING: " + _w.type + " cannot travel without a draft animal! ***");
        console_print("  Selling this animal will permanently ABANDON wagon " + string(wagon_num) + ".");
        console_print("  Any cargo on that wagon will be LOST.");
    }

    console_print("");
    console_print("Type YES to confirm, or NO to cancel.");
    console_print("");

    obj_player.pending_action = {
        type:        "sell_animal",
        wagon_index: _idx,
        sell_price:  _sell_price,
        req_animal:  _req_anim
    };
}
