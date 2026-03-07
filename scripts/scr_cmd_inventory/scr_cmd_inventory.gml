/// @desc Show a per-vehicle breakdown of the player's caravan inventory.
///       Each wagon gets its own block listing animal, cargo, saddlebags,
///       livestock, equipment, and crew slots with used/capacity counts.

function scr_cmd_inventory() {

    // Locate current location for sell-price display
    var _loc = undefined;
    for (var _i = 0; _i < array_length(obj_heartbeat.world.locations); _i++) {
        if (obj_heartbeat.world.locations[_i].id == obj_player.current_location) {
            _loc = obj_heartbeat.world.locations[_i];
            break;
        }
    }

    console_print("");
    console_print(_hdr("CARAVAN INVENTORY"));
    console_print("");
    console_print("Gold: " + string(obj_player.gold) + "g"
                  + "   Provisions: " + string(obj_player.provisions)
                  + "   Water: " + string(scr_get_total_water())
                  + "/" + string(scr_get_max_water_capacity()));
    console_print("");

    // Running totals for the summary at the bottom
    var _grand_cargo_used  = 0;
    var _grand_cargo_cap   = 0;
    var _grand_sdb_used    = 0;
    var _grand_sdb_cap     = 0;
    var _grand_cargo_value = 0;

    var _num_wagons = array_length(obj_player.caravan.wagons);

    for (var _w = 0; _w < _num_wagons; _w++) {
        var _wagon = obj_player.caravan.wagons[_w];
        var _vdata = scr_get_vehicle_data(_wagon.type);
        var _vname = (_vdata != undefined) ? _vdata.name : _wagon.type;

        // ── Wagon header ──────────────────────────────────
        var _cond_str = string(round(_wagon.condition)) + "%";
        console_print("--- Wagon " + string(_w + 1) + ": " + _vname
                      + "  [Cond: " + _cond_str + "] ---");

        // ── Draft / pack animal ───────────────────────────
        var _animal_name = "(none)";
        if (array_length(_wagon.slots.animals.contents) > 0) {
            var _ani       = _wagon.slots.animals.contents[0];
            var _adata     = scr_get_animal_data(_ani.type);
            _animal_name   = (_adata != undefined) ? _adata.name : _ani.type;
        }
        console_print("  Animal: " + _animal_name);
        console_print("");

        // ── Split cargo contents into standard vs saddlebag ──
        var _std_slots = [];
        var _sdb_slots = [];
        for (var _s = 0; _s < array_length(_wagon.slots.cargo.contents); _s++) {
            var _slot = _wagon.slots.cargo.contents[_s];
            if (_slot != undefined
            &&  variable_struct_exists(_slot, "slot_type")
            &&  _slot.slot_type == "SADDLEBAG_BULK") {
                array_push(_sdb_slots, _slot);
            } else {
                array_push(_std_slots, _slot);   // includes undefined (empty) entries
            }
        }

        // ── CARGO ─────────────────────────────────────────
        var _cargo_cap  = _wagon.slots.cargo.capacity;
        var _cargo_used = 0;
        for (var _s = 0; _s < array_length(_std_slots); _s++) {
            if (_std_slots[_s] != undefined) _cargo_used++;
        }
        _grand_cargo_cap  += _cargo_cap;
        _grand_cargo_used += _cargo_used;

        console_print("  CARGO [" + string(_cargo_used) + "/" + string(_cargo_cap) + " slots]");

        for (var _s = 0; _s < _cargo_cap; _s++) {
            var _slot = (_s < array_length(_std_slots)) ? _std_slots[_s] : undefined;
            if (_slot == undefined) {
                console_print("    [" + string(_s + 1) + "] (empty)");
            } else {
                var _com   = scr_get_commodity_by_id(_slot.good_id);
                var _cname = (_com != undefined) ? _com.name      : _slot.good_id;
                var _uname = (_com != undefined) ? string(_com.units_per_slot) : "?";
                var _line  = "    [" + string(_s + 1) + "] "
                             + _cname + " x" + string(_slot.quantity)
                             + "/" + _uname
                             + " (" + _slot.storage_type + ")";
                if (_loc != undefined) {
                    var _val = scr_calculate_sell_price(_loc, _slot.good_id, _slot.quantity);
                    if (_val > 0) {
                        _line += "  " + string(_val) + "g";
                        _grand_cargo_value += _val;
                    }
                }
                console_print(_line);
            }
        }

        // ── SADDLEBAGS (shown only if animal carries them) ──
        if (array_length(_sdb_slots) > 0) {
            var _sdb_cap  = array_length(_sdb_slots);
            var _sdb_used = 0;
            for (var _s = 0; _s < _sdb_cap; _s++) {
                if (_sdb_slots[_s].contents != undefined) _sdb_used++;
            }
            _grand_sdb_cap  += _sdb_cap;
            _grand_sdb_used += _sdb_used;

            console_print("  SADDLEBAGS [" + _animal_name + " - "
                          + string(_sdb_used) + "/" + string(_sdb_cap)
                          + " slots, BULK only]");

            for (var _s = 0; _s < _sdb_cap; _s++) {
                var _sdb = _sdb_slots[_s];
                if (_sdb.contents == undefined) {
                    console_print("    [S" + string(_s + 1) + "] (empty)");
                } else {
                    var _com   = scr_get_commodity_by_id(_sdb.contents.good_id);
                    var _cname = (_com != undefined) ? _com.name      : _sdb.contents.good_id;
                    var _uname = (_com != undefined) ? string(_com.units_per_slot) : "?";
                    var _line  = "    [S" + string(_s + 1) + "] "
                                 + _cname + " x" + string(_sdb.contents.quantity)
                                 + "/" + _uname;
                    if (_loc != undefined) {
                        var _val = scr_calculate_sell_price(_loc, _sdb.contents.good_id, _sdb.contents.quantity);
                        if (_val > 0) {
                            _line += "  " + string(_val) + "g";
                            _grand_cargo_value += _val;
                        }
                    }
                    console_print(_line);
                }
            }
        }

        // ── LIVESTOCK ─────────────────────────────────────
        var _ls_cap  = _wagon.slots.livestock_trade.capacity;
        var _ls_cont = _wagon.slots.livestock_trade.contents;
        if (_ls_cap > 0 || array_length(_ls_cont) > 0) {
            var _ls_used = 0;
            for (var _s = 0; _s < array_length(_ls_cont); _s++) {
                if (_ls_cont[_s] != undefined) _ls_used++;
            }
            console_print("  LIVESTOCK [" + string(_ls_used) + "/" + string(_ls_cap) + " slots]");
            for (var _s = 0; _s < _ls_cap; _s++) {
                if (_s < array_length(_ls_cont) && _ls_cont[_s] != undefined) {
                    var _ls    = _ls_cont[_s];
                    var _com   = scr_get_commodity_by_id(_ls.good_id);
                    var _cname = (_com != undefined) ? _com.name : _ls.good_id;
                    console_print("    [L" + string(_s + 1) + "] " + _cname
                                  + " x" + string(_ls.quantity));
                } else {
                    console_print("    [L" + string(_s + 1) + "] (empty)");
                }
            }
        }

        // ── EQUIPMENT ─────────────────────────────────────
        if (variable_struct_exists(_wagon.slots, "equipment")) {
            var _eq_cap  = _wagon.slots.equipment.capacity;
            var _eq_cont = _wagon.slots.equipment.contents;
            var _eq_used = array_length(_eq_cont);
            if (_eq_cap > 0 || _eq_used > 0) {
                console_print("  EQUIPMENT [" + string(_eq_used) + "/" + string(_eq_cap) + " slots]");
                var _eq_max = max(_eq_cap, _eq_used);
                for (var _e = 0; _e < _eq_max; _e++) {
                    if (_e < _eq_used) {
                        var _item = _eq_cont[_e];
                        if (_item.type == "BARREL" && _item.subtype == "WATER") {
                            console_print("    [E" + string(_e + 1) + "] Water Barrel ("
                                          + string(_item.water) + "/" + string(_item.max_water) + ")");
                        } else {
                            console_print("    [E" + string(_e + 1) + "] " + _item.type);
                        }
                    } else {
                        console_print("    [E" + string(_e + 1) + "] (empty)");
                    }
                }
            }
        }

        // ── CREW ──────────────────────────────────────────
        var _cr_cap  = _wagon.slots.crew.capacity;
        var _cr_cont = _wagon.slots.crew.contents;
        var _cr_used = array_length(_cr_cont);
        if (_cr_cap > 0 || _cr_used > 0) {
            console_print("  CREW [" + string(_cr_used) + "/" + string(_cr_cap) + " slots]");
            for (var _c = 0; _c < _cr_cap; _c++) {
                if (_c < _cr_used) {
                    var _crew = _cr_cont[_c];
                    console_print("    [C" + string(_c + 1) + "] " + _crew.name
                                  + " (" + _crew.type + ")");
                } else {
                    console_print("    [C" + string(_c + 1) + "] (empty)");
                }
            }
        }

        console_print("");
    }

    // ── HIRED CREW ────────────────────────────────────────
    if (variable_struct_exists(obj_player, "hired_crew")
    &&  array_length(obj_player.hired_crew) > 0) {
        var _n_hc = array_length(obj_player.hired_crew);
        console_print("--- HIRED CREW [" + string(_n_hc) + "/3] ---");
        for (var _hi = 0; _hi < _n_hc; _hi++) {
            var _hc  = obj_player.hired_crew[_hi];
            var _hnp = _hc.name + string_repeat(" ", max(0, 7 - string_length(_hc.name)));
            var _htp = string_repeat(" ", max(0, 7 - string_length(_hc.type)));
            console_print("  [" + string(_hi + 1) + "] " + _hnp
                          + " (" + _hc.type + ")" + _htp
                          + "  " + string(_hc.wage) + "g/day");
        }
        console_print("");
    }

    // ── SUMMARY ───────────────────────────────────────────
    console_print("---");
    console_print("TOTALS  (" + string(_num_wagons)
                  + ((_num_wagons == 1) ? " wagon)" : " wagons)"));

    var _slot_line = "  Cargo: " + string(_grand_cargo_used) + "/" + string(_grand_cargo_cap) + " slots";
    if (_grand_sdb_cap > 0) {
        _slot_line += "   Saddlebags: " + string(_grand_sdb_used) + "/" + string(_grand_sdb_cap);
    }
    console_print(_slot_line);

    if (_grand_cargo_value > 0) {
        console_print("  Cargo value: " + string(_grand_cargo_value) + "g");
        console_print("  Total wealth: " + string(obj_player.gold + _grand_cargo_value) + "g"
                      + "  (gold: " + string(obj_player.gold) + "g)");
    } else {
        console_print("  Gold: " + string(obj_player.gold) + "g");
    }

    console_print("  Provisions: " + string(obj_player.provisions)
                  + "   Water: " + string(scr_get_total_water())
                  + "/" + string(scr_get_max_water_capacity()));
    console_print("");
}
