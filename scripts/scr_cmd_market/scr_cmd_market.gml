// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Display current location's market (what they buy/sell)

function scr_cmd_market() {
    // Get current location
    var current_loc = undefined;
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
            current_loc = obj_heartbeat.world.locations[i];
            break;
        }
    }
    
    if (current_loc == undefined) {
        console_print("ERROR: Current location not found.");
        return;
    }

    // === SPECIAL LOCATION ENTRY CHECKS ===
    if (variable_struct_exists(current_loc, "subtype")) {

        // Elven Outpost: reputation-gated
        if (current_loc.subtype == "ELVEN_OUTPOST" && obj_player.reputation < 5) {
            console_print("");
            console_print(_hdr("ELVEN OUTPOST: " + string_upper(current_loc.name)));
            console_print("");
            console_print("Elven guards step forward, blocking the market entrance.");
            console_print("\"Your reputation does not inspire trust, merchant. Come back");
            console_print(" when the roads speak better of you.\"");
            console_print("");
            console_print("  Reputation required: 5   (yours: " + string(obj_player.reputation) + ")");
            console_print("");
            return;
        }

        // Goblin Market: 20% chance of flat refusal
        if (current_loc.subtype == "GOBLIN_MARKET" && irandom(4) == 0) {
            console_print("");
            console_print(_hdr("GOBLIN MARKET: " + string_upper(current_loc.name)));
            console_print("");
            var _refuse = [
                "A goblin barkeep slams the shutters. \"No customers today! Come back tomorrow!\"",
                "Goblins scatter as you approach, knocking over stalls. The market is a chaos of fleeing merchants.",
                "A sign goes up: CLOSED. A dozen goblins peer at you from behind it with wide eyes.",
                "The market chief blocks your path. \"We are... reorganising! Yes. Come back later!\""
            ];
            console_print(_refuse[irandom(3)]);
            console_print("");
            return;
        }

    }

    var economy = current_loc.economy;

    // Build market header — use subtype label when available
    var _mkt_label = "MARKET";
    var _mkt_flavor = "";
    if (variable_struct_exists(current_loc, "subtype") && current_loc.subtype != "") {
        if (current_loc.subtype == "ARCANE_LIBRARY") {
            _mkt_label  = "ARCANE LIBRARY";
            _mkt_flavor = "Ancient knowledge and rare arcane wares. They prize dragon scales and relics.";
        } else if (current_loc.subtype == "RUINED_SHRINE") {
            _mkt_label  = "RUINED SHRINE";
            _mkt_flavor = "A caretaker tends to what remains. A few curious relics are for sale.";
        } else if (current_loc.subtype == "ELVEN_OUTPOST") {
            _mkt_label  = "ELVEN OUTPOST";
            _mkt_flavor = "Fine elven crafts — scarce and priced accordingly.";
        } else if (current_loc.subtype == "GOBLIN_MARKET") {
            _mkt_label  = "GOBLIN MARKET";
            _mkt_flavor = "Chaotic. Loud. Somehow open for business today.";
        }
    }

    console_print("");
    console_print(_hdr(_mkt_label + ": " + string_upper(current_loc.name)));
    if (_mkt_flavor != "") {
        console_print(_mkt_flavor);
    }
    console_print("");
    
    // === GOODS FOR SALE ===
    console_print("GOODS FOR SALE:");
    
    var has_goods      = false;
    var _regular_lines = [];
    var _prov_lines    = [];
    var stock_keys = variable_struct_get_names(economy.stock_levels);

    for (var i = 0; i < array_length(stock_keys); i++) {
        var good_id = stock_keys[i];
        var stock = economy.stock_levels[$ good_id];

        if (stock > 0) {
            // Demanded goods are never shown for sale — the town keeps its stock for itself.
            // scr_calculate_buy_price also enforces this, but we filter here so the
            // market listing never suggests the player could buy something they can't.
            var is_demanded = false;
            for (var j = 0; j < array_length(economy.demands); j++) {
                if (economy.demands[j].good_id == good_id) {
                    is_demanded = true;
                    break;
                }
            }
            if (is_demanded) continue;

            var commodity = scr_get_commodity_by_id(good_id);
            if (commodity != undefined) {
                var unit_price = scr_calculate_buy_price(current_loc, good_id, 1);
                var line = "  " + commodity.name
                         + " - " + string(stock) + " available"
                         + " @ " + string(unit_price) + " gold/unit";
                // Provisions are a resupply item — push to bottom so trade goods group together
                if (good_id == "provisions") {
                    array_push(_prov_lines, line);
                } else {
                    array_push(_regular_lines, line);
                }
            }
        }
    }

    // Also show resale stock — goods sold by the player that the local merchant
    // is now reselling.  These have a fixed price independent of normal supply/demand.
    if (variable_struct_exists(economy, "resale_stock")) {
        var _rkeys = variable_struct_get_names(economy.resale_stock);
        for (var i = 0; i < array_length(_rkeys); i++) {
            var _rid    = _rkeys[i];
            var _rentry = economy.resale_stock[$ _rid];
            if (_rentry.qty <= 0) continue;

            // Safety: don't show demanded goods even if they wound up in resale_stock
            var _rdemanded = false;
            for (var j = 0; j < array_length(economy.demands); j++) {
                if (economy.demands[j].good_id == _rid) { _rdemanded = true; break; }
            }
            if (_rdemanded) continue;

            var _rcommodity = scr_get_commodity_by_id(_rid);
            if (_rcommodity != undefined) {
                var _rline = "  " + _rcommodity.name
                           + " - " + string(_rentry.qty) + " available"
                           + " @ " + string(_rentry.unit_price) + " gold/unit";
                if (_rid == "provisions") {
                    array_push(_prov_lines, _rline);
                } else {
                    array_push(_regular_lines, _rline);
                }
            }
        }
    }

    // Print trade goods first, provisions last
    for (var i = 0; i < array_length(_regular_lines); i++) {
        has_goods = true;
        console_print(_regular_lines[i]);
    }
    for (var i = 0; i < array_length(_prov_lines); i++) {
        has_goods = true;
        console_print(_prov_lines[i]);
    }

    if (!has_goods) {
        console_print("  (nothing for sale)");
    }
    
    console_print("");
    
    // === GOODS THEY'RE BUYING ===
    console_print("GOODS THEY'RE BUYING:");
    
    if (array_length(economy.demands) > 0) {
        for (var i = 0; i < array_length(economy.demands); i++) {
            var demand = economy.demands[i];

            // A town that produces a commodity won't also be buying it.
            var is_produced = false;
            for (var j = 0; j < array_length(economy.produces); j++) {
                if (economy.produces[j].good_id == demand.good_id) {
                    is_produced = true;
                    break;
                }
            }
            if (is_produced) continue;

            var commodity = scr_get_commodity_by_id(demand.good_id);

            if (commodity != undefined) {
                var unit_price = scr_calculate_sell_price(current_loc, demand.good_id, 1);

                var line = "  " + commodity.name;
                line += " @ " + string(unit_price) + " gold/unit";

                console_print(line);
            }
        }
    }

    // Show discovered wants (goods they've learned to value, excluding things they produce)
    if (array_length(economy.discovered_wants) > 0) {
        var has_special = false;
        for (var i = 0; i < array_length(economy.discovered_wants); i++) {
            var good_id = economy.discovered_wants[i];

            // Don't list a produced good as a special interest — they make it themselves
            var is_produced = false;
            for (var j = 0; j < array_length(economy.produces); j++) {
                if (economy.produces[j].good_id == good_id) {
                    is_produced = true;
                    break;
                }
            }
            if (is_produced) continue;

            if (!has_special) {
                console_print("");
                console_print("SPECIAL INTEREST (discovered goods):");
                has_special = true;
            }

            var commodity = scr_get_commodity_by_id(good_id);
            if (commodity != undefined) {
                var unit_price = scr_calculate_sell_price(current_loc, good_id, 1);
                console_print("  " + commodity.name + " @ " + string(unit_price) + " gold/unit");
            }
        }
    }
    
    if (array_length(economy.demands) == 0 && array_length(economy.discovered_wants) == 0) {
        console_print("  (not buying anything)");
    }
    
    console_print("");
    console_print("Your gold: " + string(obj_player.gold));
    console_print("");
    console_print("Use 'BUY <good> <quantity>' or 'SELL <good> <quantity>'");
}