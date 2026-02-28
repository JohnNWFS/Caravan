// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func cmd_parse(input)
/// @desc Parse and execute a command
/// @param {string} input The command string from the user

function cmd_parse(input) {
    // === SETUP STATE GATE ===
    // During the pre-game setup screen all commands are handled by scr_cmd_setup.
    if (obj_heartbeat.game_state == "SETUP") {
        var _raw = string_upper(string_trim(input));
        var _sp  = string_pos(" ", _raw);
        var _cmd = (_sp > 0) ? string_copy(_raw, 1, _sp - 1) : _raw;
        var _arg = (_sp > 0) ? string_delete(_raw, 1, _sp)   : "";
        scr_cmd_setup(_cmd, _arg);
        return;
    }

    // === GAMEOVER STATE GATE ===
    // After a JOURNEY run ends, only RESTART and QUIT are valid.
    if (obj_heartbeat.game_state == "GAMEOVER") {
        var _raw = string_upper(string_trim(input));
        if (_raw == "RESTART" || _raw == "R") {
            game_restart();
        } else if (_raw == "QUIT" || _raw == "Q" || _raw == "QU") {
            console_print("Farewell, traveler.");
            game_end();
        } else {
            console_print("Game over. Type RESTART to play again or QUIT to exit.");
        }
        return;
    }

    // Convert to uppercase for case-insensitive matching
    var cmd = string_upper(string_trim(input));
    
    // Split into command and arguments (basic version)
    var space_pos = string_pos(" ", cmd);
    var command = (space_pos > 0) ? string_copy(cmd, 1, space_pos - 1) : cmd;
    var args = (space_pos > 0) ? string_delete(cmd, 1, space_pos) : "";
    
    // Command dispatcher
    switch(command) {
        case "HELP":
        case "HE":
        case "H":
        case "?":
            console_print("");
            console_print("AVAILABLE COMMANDS:");
            console_print("  HELP (H, HE, ?)   - Show this help");
            console_print("  STATUS (ST)        - Show caravan status");
            console_print("  INVENTORY (I, IN)  - Show detailed cargo and values");
            console_print("  TRAVEL (T, TR)     - Show available destinations");
            console_print("  GO (G)             - Travel to destination (GO <name> or GO <number>)");
            console_print("  MAP                - Show world map (ESC or click to close)");
            console_print("  MARKET (M, MA)     - Show local market prices");
            console_print("  BUY (B, BU)        - Buy goods (BUY <good> <quantity>)");
            console_print("  SELL (S, SE)       - Sell goods (SELL <good> <quantity>)");
            console_print("  WORK (W, WO)       - Earn gold through day labor (WORK <days>)");
            console_print("  SHOP (SH)          - Buy/sell vehicles & animals (SHOP VEHICLES / SHOP ANIMALS)");
            console_print("  REPAIR (REP)       - Repair all wagons (shows cost, asks YES/NO)");
            console_print("  QUIT (Q, QU)       - Exit game");
            console_print("  GUIDE              - Full game tutorial (typewriter style)");
            console_print("");
            break;

        case "GUIDE":
            console_clear();
            scr_show_game_guide();
            break;

        case "TRAVEL":
        case "TR":
        case "T":
            scr_cmd_travel();
            break;
            
        case "GO":
        case "G":
            if (args != "") {
                scr_cmd_go(args);
            } else {
                console_print("Usage: GO <destination name or number>");
                console_print("Type 'TRAVEL' to see available destinations.");
            }
            break;
    
        case "STATUS":
        case "ST":
            console_print("");
            console_print("=== PLAYER STATUS ===");
            
            // Show current location
            var loc_name = "Unknown";
            var loc_type = "";
            for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
                if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
                    loc_name = obj_heartbeat.world.locations[i].name;
                    loc_type = obj_heartbeat.world.locations[i].type;
                    break;
                }
            }
            console_print("Location: " + loc_name + " (" + loc_type + ")");
            console_print("");
            
            console_print("Gold: " + string(obj_player.gold));
            console_print("Health: " + string(obj_player.hp) + "/" + string(obj_player.max_hp));
            console_print("Reputation: " + string(obj_player.reputation));
            console_print("Provisions: " + string(obj_player.provisions));
            console_print("Water: " + string(scr_get_total_water()) + "/" + string(scr_get_max_water_capacity()));
            console_print("Day: " + string(obj_heartbeat.day));
            console_print("");
            
            console_print("=== CARAVAN ===");
            var wagon_count = array_length(obj_player.caravan.wagons);
            console_print("Wagons: " + string(wagon_count));
            console_print("");
            
            // Show each wagon
            for (var i = 0; i < wagon_count; i++) {
                var wagon = obj_player.caravan.wagons[i];
                console_print("WAGON " + string(i + 1) + ": " + wagon.type);
                console_print("  Condition: " + string(wagon.condition) + "%");
                
// Show animals
var animal_count = array_length(wagon.slots.animals.contents);
if (animal_count > 0) {
    console_print("  Animals:");
    for (var a = 0; a < animal_count; a++) {
        var animal = wagon.slots.animals.contents[a];
        var animal_info = "    - " + animal.type + " (health: " + string(animal.hp) + "%)";
        
        // Show if it has saddlebags
        if (variable_struct_exists(animal, "has_saddlebags") && animal.has_saddlebags) {
            animal_info += " [+" + string(animal.saddlebag_slots) + " BULK slots]";
        }
        
        console_print(animal_info);
    }
}
                
                // Show crew
                var crew_count = array_length(wagon.slots.crew.contents);
                if (crew_count > 0) {
                    console_print("  Crew:");
                    for (var c = 0; c < crew_count; c++) {
                        var crew = wagon.slots.crew.contents[c];
                        console_print("    - " + crew.name + " (" + crew.type + ")");
                    }
                }
                
                // Show equipment (water barrels, etc.)
                if (variable_struct_exists(wagon.slots, "equipment")) {
                    var equipment_count = array_length(wagon.slots.equipment.contents);
                    if (equipment_count > 0) {
                        console_print("  Equipment:");
                        for (var e = 0; e < equipment_count; e++) {
                            var item = wagon.slots.equipment.contents[e];
                            if (item.type == "BARREL" && item.subtype == "WATER") {
                                console_print("    - WATER BARREL (" + string(item.water) + "/" + string(item.max_water) + ")");
                            } else {
                                console_print("    - " + item.type);
                            }
                        }
                    }
                }
                
// Show cargo slots
var cargo_slots = wagon.slots.cargo.contents;
var standard_slots = 0;
var standard_used = 0;
var saddlebag_slots = 0;
var saddlebag_used = 0;
var cargo_list = [];

// Analyze slots
for (var g = 0; g < array_length(cargo_slots); g++) {
    var slot = cargo_slots[g];
    
    if (slot == undefined) {
        // Empty standard slot
        standard_slots++;
        continue;
    } else if (variable_struct_exists(slot, "slot_type")) {
        // It's a special slot (saddlebag, etc.)
        if (slot.slot_type == "SADDLEBAG_BULK") {
            saddlebag_slots++;
            if (slot.contents != undefined) {
                saddlebag_used++;
                array_push(cargo_list, {
                    slot_num: g + 1,
                    slot_type: "SADDLEBAG",
                    data: slot.contents
                });
            }
        }
    } else {
        // Has actual cargo in standard slot
        standard_slots++;
        standard_used++;
        array_push(cargo_list, {
            slot_num: g + 1,
            slot_type: "STANDARD",
            data: slot
        });
    }
}

// Display cargo summary
console_print("  Cargo Slots:");
console_print("    Wagon: " + string(standard_used) + "/" + string(standard_slots) + " used");
if (saddlebag_slots > 0) {
    console_print("    Saddlebags: " + string(saddlebag_used) + "/" + string(saddlebag_slots) + " used");
}

if (array_length(cargo_list) > 0) {
    console_print("  Cargo contents:");
    for (var c = 0; c < array_length(cargo_list); c++) {
        var item = cargo_list[c];
        var slot_label = (item.slot_type == "SADDLEBAG") ? "Saddlebag" : "Slot";
        console_print("    " + slot_label + " " + string(item.slot_num) + ": [trade goods]");
    }
} else {
    console_print("    (empty)");
}
                
                console_print("");
            }
            break;

case "MAP":
    obj_heartbeat.map_open        = true;
    obj_heartbeat.map_close_delay = 2; // grace period so Enter doesn't immediately close
    break;

case "MARKET":
case "MA":
case "M":
    scr_cmd_market();
    break;

case "BUY":
case "BU":
case "B":
    if (args != "") {
        // Find the last space to separate arguments
        var last_space = 0;
        for (var i = string_length(args); i >= 1; i--) {
            if (string_char_at(args, i) == " ") {
                last_space = i;
                break;
            }
        }
        
        if (last_space > 0) {
            var part1 = string_copy(args, 1, last_space - 1);
            var part2 = string_copy(args, last_space + 1, string_length(args));
            
            // Determine which is the number
            var good = "";
            var qty = 0;
            
            // Check for MAX/ALL keywords
            var is_max_order = false;
            
            // Check if part1 is a number or MAX/ALL
            if (string_digits(part1) == part1 && part1 != "") {
                // part1 is quantity, part2 is good name
                qty = real(part1);
                good = part2;
            } else if (string_upper(part1) == "MAX" || string_upper(part1) == "ALL") {
                // part1 is MAX/ALL, part2 is good name
                is_max_order = true;
                good = part2;
            } else if (string_digits(part2) == part2 && part2 != "") {
                // part2 is quantity, part1 is good name
                qty = real(part2);
                good = part1;
            } else if (string_upper(part2) == "MAX" || string_upper(part2) == "ALL") {
                // part2 is MAX/ALL, part1 is good name
                is_max_order = true;
                good = part1;
            } else {
                console_print("Usage: BUY <good name> <quantity>");
                console_print("Example: BUY wheat 25 or BUY 25 wheat");
                console_print("Use MAX or ALL to buy maximum: BUY wheat MAX");
                break;
            }
            
            // If MAX/ALL, calculate maximum quantity player can buy
            if (is_max_order) {
                // Get current location for stock check
                var current_loc = undefined;
                for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
                    if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
                        current_loc = obj_heartbeat.world.locations[i];
                        break;
                    }
                }
                
                if (current_loc == undefined) {
                    console_print("ERROR: Current location not found.");
                    break;
                }
                
                // Find the commodity
                var commodity = scr_find_commodity_by_name(good);
                
                if (commodity == undefined) {
                    console_print("Unknown commodity: " + good);
                    break;
                }
                
                // Get available stock — check produced stock first, then resale stock
                var economy = current_loc.economy;
                var available_stock = 0;

                if (variable_struct_exists(economy.stock_levels, commodity.id)) {
                    available_stock = economy.stock_levels[$ commodity.id];
                }

                if (available_stock <= 0
                    && variable_struct_exists(economy, "resale_stock")
                    && variable_struct_exists(economy.resale_stock, commodity.id)) {
                    var _re_max = economy.resale_stock[$ commodity.id];
                    if (_re_max.qty > 0) available_stock = _re_max.qty;
                }

                if (available_stock <= 0) {
                    console_print(current_loc.name + " doesn't have any " + commodity.name + " for sale.");
                    break;
                }
                
                // Calculate max we can afford (binary search for optimal quantity)
                var max_affordable = 0;
                
                for (var test_qty = 1; test_qty <= available_stock; test_qty++) {
                    var test_price = scr_calculate_buy_price(current_loc, commodity.id, test_qty);
                    
                    if (test_price <= obj_player.gold) {
                        max_affordable = test_qty;
                    } else {
                        break; // Can't afford more
                    }
                }
                
                if (max_affordable == 0) {
                    console_print("You can't afford any " + commodity.name + ".");
                    console_print("Unit price: " + string(scr_calculate_buy_price(current_loc, commodity.id, 1)) + " gold");
                    console_print("Your gold: " + string(obj_player.gold));
                    break;
                }
                
                qty = max_affordable;
                console_print("Buying maximum: " + string(qty) + " " + commodity.name);
            }
            
            scr_cmd_buy(good, qty);
        } else {
            console_print("Usage: BUY <good name> <quantity>");
            console_print("Example: BUY wheat 25");
        }
    } else {
        console_print("Usage: BUY <good name> <quantity>");
    }
    break;

case "SELL":
case "SE":
case "S":
    if (args != "") {
        // Find the last space to separate arguments
        var last_space = 0;
        for (var i = string_length(args); i >= 1; i--) {
            if (string_char_at(args, i) == " ") {
                last_space = i;
                break;
            }
        }
        
        if (last_space > 0) {
            var part1 = string_copy(args, 1, last_space - 1);
            var part2 = string_copy(args, last_space + 1, string_length(args));
            
            // Determine which is the number
            var good = "";
            var qty = 0;
            
            // Check for MAX/ALL keywords
            var is_max_order = false;
            
            // Check if part1 is a number or MAX/ALL
            if (string_digits(part1) == part1 && part1 != "") {
                // part1 is quantity, part2 is good name
                qty = real(part1);
                good = part2;
            } else if (string_upper(part1) == "MAX" || string_upper(part1) == "ALL") {
                // part1 is MAX/ALL, part2 is good name
                is_max_order = true;
                good = part2;
            } else if (string_digits(part2) == part2 && part2 != "") {
                // part2 is quantity, part1 is good name
                qty = real(part2);
                good = part1;
            } else if (string_upper(part2) == "MAX" || string_upper(part2) == "ALL") {
                // part2 is MAX/ALL, part1 is good name
                is_max_order = true;
                good = part1;
            } else {
                console_print("Usage: SELL <good name> <quantity>");
                console_print("Example: SELL salt 10 or SELL 10 salt");
                console_print("Use MAX or ALL to sell all: SELL salt MAX");
                break;
            }
            
            // If MAX/ALL, find how much player has
            if (is_max_order) {
                // Find the commodity
                var commodity = scr_find_commodity_by_name(good);
                
                if (commodity == undefined) {
                    console_print("Unknown commodity: " + good);
                    break;
                }
                
                // Find commodity in player cargo
                var player_has = 0;
                
                for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
                    var wagon = obj_player.caravan.wagons[w];
                    var cargo_slots = wagon.slots.cargo.contents;
                    
                    for (var s = 0; s < array_length(cargo_slots); s++) {
                        var slot = cargo_slots[s];
                        
                        if (slot == undefined) continue;
                        
                        var slot_good_id = undefined;
                        var slot_quantity = 0;
                        
                        // Check standard slot
                        if (variable_struct_exists(slot, "good_id")) {
                            slot_good_id = slot.good_id;
                            slot_quantity = slot.quantity;
                        }
                        // Check special slot
                        else if (variable_struct_exists(slot, "contents") && slot.contents != undefined) {
                            slot_good_id = slot.contents.good_id;
                            slot_quantity = slot.contents.quantity;
                        }
                        
                        if (slot_good_id == commodity.id) {
                            player_has += slot_quantity;
                        }
                    }
                }
                
                if (player_has == 0) {
                    console_print("You don't have any " + commodity.name + " to sell.");
                    break;
                }
                
                qty = player_has;
                console_print("Selling all: " + string(qty) + " " + commodity.name);
            }
            
            scr_cmd_sell(good, qty);
        } else {
            console_print("Usage: SELL <good name> <quantity>");
            console_print("Example: SELL salt 10");
        }
    } else {
        console_print("Usage: SELL <good name> <quantity>");
    }
    break;
	
        case "WORK":
        case "WO":
        case "W":
	    var work_days = 1; // Default to 1 day
    
	    if (args != "") {
	        work_days = real(args);
	    }
    
	    scr_cmd_work(work_days);
	    break;

        // -----------------------------------------------------------------------
        case "SHOP":
        case "SH":
            // Split args into sub-command and remainder
            // e.g. "SHOP BUY CART"  → sub="BUY"  arg="CART"
            //      "SHOP SELL VEHICLE 1" → sub="SELL" arg="VEHICLE 1"
            var shop_sp  = string_pos(" ", args);
            var shop_sub = (shop_sp > 0) ? string_copy(args, 1, shop_sp - 1) : args;
            var shop_arg = (shop_sp > 0) ? string_trim(string_delete(args, 1, shop_sp)) : "";
            scr_cmd_shop(shop_sub, shop_arg);
            break;

        case "REPAIR":
        case "REP":
            scr_cmd_repair();
            break;

case "~":
    // Hidden debug command - dump console to output window
    var dump_count = -1; // -1 = all lines
    
    if (args != "") {
        dump_count = real(args);
    }
    
    var lines = obj_console.lines;
    var total_lines = array_length(lines);
    
    if (dump_count == -1 || dump_count >= total_lines) {
        // Dump all lines
        show_debug_message("=== CONSOLE DUMP (ALL " + string(total_lines) + " LINES) ===");
        for (var i = 0; i < total_lines; i++) {
            show_debug_message(lines[i]);
        }
    } else {
        // Dump most recent X lines
        var start_index = max(0, total_lines - dump_count);
        show_debug_message("=== CONSOLE DUMP (LAST " + string(dump_count) + " LINES) ===");
        for (var i = start_index; i < total_lines; i++) {
            show_debug_message(lines[i]);
        }
    }
    
    show_debug_message("=== END DUMP ===");
    console_print("Console dumped to output window.");
    break;
	

        case "INVENTORY":
        case "INV":
        case "IN":
        case "I":
            scr_cmd_inventory();
		    break;
			
        case "QUIT":
        case "QU":
        case "Q":
            console_print("Farewell, traveler.");
            scr_debug_log_close("QUIT");   // Flush + close log before the process dies
            game_end();
            break;

        case "YES":
        case "YE":
        case "Y":
            if (obj_player.pending_action != undefined) {
                var pa = obj_player.pending_action;

                if (pa.type == "buy") {
                    // ── Confirm a cargo spillover purchase ──
                    scr_cmd_buy(pa.good_name, pa.quantity, true);

                } else if (pa.type == "repair") {
                    // ── Execute wagon repairs ──
                    obj_player.gold -= pa.cost;
                    for (var _ri = 0; _ri < array_length(obj_player.caravan.wagons); _ri++) {
                        obj_player.caravan.wagons[_ri].condition = 100;
                    }
                    console_print("");
                    console_print("REPAIRS COMPLETE");
                    console_print("All wagons restored to 100% condition.");
                    console_print("Gold spent: "     + string(pa.cost) + " gold");
                    console_print("Gold remaining: " + string(obj_player.gold) + " gold");
                    console_print("");
                    obj_player.pending_action = undefined;

                } else if (pa.type == "sell_vehicle") {
                    // ── Execute vehicle sale (wagon + optional animal) ──
                    var _total_gold = pa.sell_price + pa.animal_price;
                    obj_player.gold += _total_gold;

                    // Remove the wagon from the caravan array
                    var _new_wagons = [];
                    for (var _swi = 0; _swi < array_length(obj_player.caravan.wagons); _swi++) {
                        if (_swi != pa.wagon_index) {
                            array_push(_new_wagons, obj_player.caravan.wagons[_swi]);
                        }
                    }
                    obj_player.caravan.wagons = _new_wagons;

                    console_print("");
                    console_print("SALE COMPLETE");
                    if (pa.sell_animal && pa.animal_name != "") {
                        console_print("Sold: Wagon + " + pa.animal_name);
                    } else {
                        console_print("Sold: Wagon");
                    }
                    console_print("Earned: "       + string(_total_gold) + " gold");
                    console_print("Gold total: "   + string(obj_player.gold) + " gold");
                    if (pa.is_last) {
                        console_print("");
                        console_print("You have no vehicles left. WORK to earn gold and buy a new one.");
                    }
                    console_print("");
                    obj_player.pending_action = undefined;

                } else if (pa.type == "sell_animal") {
                    // ── Execute animal sale ──
                    var _sell_w   = obj_player.caravan.wagons[pa.wagon_index];
                    var _sold_ani = _sell_w.slots.animals.contents[0];

                    // How many saddlebag slots did this animal provide?
                    var _adata_sell  = scr_get_animal_data(_sold_ani.type);
                    var _sb_to_rm    = (_adata_sell != undefined) ? _adata_sell.saddlebag_slots
                                       : (variable_struct_exists(_sold_ani, "saddlebag_slots")
                                          ? _sold_ani.saddlebag_slots : 0);

                    // Remove saddlebag cargo slots for this animal
                    if (_sb_to_rm > 0) {
                        var _cargo_arr  = _sell_w.slots.cargo.contents;
                        var _new_cargo  = [];
                        var _sb_done    = 0;
                        var _lost_cargo = false;
                        for (var _ci = 0; _ci < array_length(_cargo_arr); _ci++) {
                            var _cslot = _cargo_arr[_ci];
                            if (_sb_done < _sb_to_rm
                            &&  _cslot != undefined
                            &&  variable_struct_exists(_cslot, "slot_type")
                            &&  _cslot.slot_type == "SADDLEBAG_BULK") {
                                _sb_done++;
                                if (_cslot.contents != undefined) _lost_cargo = true;
                            } else {
                                array_push(_new_cargo, _cslot);
                            }
                        }
                        _sell_w.slots.cargo.contents  = _new_cargo;
                        _sell_w.slots.cargo.capacity -= _sb_done;
                        if (_lost_cargo) {
                            console_print("WARNING: Cargo in removed saddlebag slots was lost.");
                        }
                    }

                    // Remove the animal
                    _sell_w.slots.animals.contents = [];
                    obj_player.gold += pa.sell_price;

                    console_print("");
                    console_print("SALE COMPLETE");
                    console_print("Sold: "        + _sold_ani.type);
                    console_print("Earned: "      + string(pa.sell_price) + " gold");
                    console_print("Gold total: "  + string(obj_player.gold) + " gold");

                    // If this wagon required an animal it is now stranded — abandon it
                    if (pa.req_animal) {
                        var _new_wagons2 = [];
                        for (var _swi2 = 0; _swi2 < array_length(obj_player.caravan.wagons); _swi2++) {
                            if (_swi2 != pa.wagon_index) {
                                array_push(_new_wagons2, obj_player.caravan.wagons[_swi2]);
                            }
                        }
                        obj_player.caravan.wagons = _new_wagons2;
                        console_print("Wagon " + string(pa.wagon_index + 1)
                                      + " has been abandoned (no draft animal).");
                    }
                    console_print("");
                    obj_player.pending_action = undefined;

                } else {
                    console_print("Nothing to confirm.");
                }
            } else {
                console_print("Nothing to confirm.");
            }
            break;

        case "NO":
        case "N":
            if (obj_player.pending_action != undefined) {
                var _pa_type = obj_player.pending_action.type;
                if (_pa_type == "buy") {
                    console_print("Purchase cancelled.");
                } else if (_pa_type == "repair") {
                    console_print("Repair cancelled.");
                } else if (_pa_type == "sell_vehicle" || _pa_type == "sell_animal") {
                    console_print("Sale cancelled.");
                } else {
                    console_print("Action cancelled.");
                }
                obj_player.pending_action = undefined;
            } else {
                console_print("Nothing to cancel.");
            }
            break;

        // -----------------------------------------------------------------------
        // UNDOCUMENTED / DEVELOPER COMMANDS
        // Not listed in HELP. No shortcuts. Keep these below all player commands.
        // -----------------------------------------------------------------------

        case "DEBUG":
            // Toggle file logging of all console output.
            // ON:  Opens caravan_debug.log (append), dumps full console history,
            //      then logs every subsequent console_print() call until toggled off.
            // OFF: Writes a session-end marker and closes the file cleanly.
            if (!global.debug_log_enabled) {
                scr_debug_log_open();
            } else {
                scr_debug_log_close("USER");
                console_print("[DEBUG] Logging OFF.");
            }
            break;

        case "AUTOPLAY":
        case "AP":
            // Run the AI player simulation.
            // Optional argument: number of journeys (default 10).
            // Recommended workflow:
            //   1. Type DEBUG   (opens the log file)
            //   2. Type AUTOPLAY 10   (AI plays 10 journeys)
            //   3. Type DEBUG   (closes the log, flushes to disk)
            // Then examine caravan_debug.log.
            var _ap_goal = 10;
            if (args != "") {
                var _ap_parsed = real(args);
                if (_ap_parsed > 0) _ap_goal = _ap_parsed;
            }
            console_print("[AUTOPLAY] Starting AI simulation for " + string(_ap_goal) + " journeys...");
            scr_ai_player(_ap_goal);
            break;

        default:
            console_print("Unknown command: " + input);
            console_print("Type HELP for available commands.");
            break;
    }
}