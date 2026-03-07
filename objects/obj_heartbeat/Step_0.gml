/// @description Insert description here
// You can write your code in this editor

// === MAP OVERLAY CLOSE ===
// Give the map a brief grace period (map_close_delay frames) so that the
// Enter key that submitted the MAP command doesn't immediately dismiss it.
if (map_open) {
    if (map_close_delay > 0) {
        map_close_delay--;
    } else if (!map_travel_active) {
        if (keyboard_check_pressed(vk_escape)
        ||  mouse_check_button_pressed(mb_right)) {
            // ESC or right-click: close map and clear any pending selection
            map_open             = false;
            selected_location_id = "";
        } else if (mouse_check_button_pressed(mb_left)) {
            if (map_hovered_loc_id != "") {
                // Clicked on a node — select it; keep map open so player can see the highlight
                selected_location_id = map_hovered_loc_id;
            } else {
                // Clicked on empty map space — close map
                map_open = false;
            }
        }
    }
}

// === MAP TRAVEL ANIMATION TICK ===
if (map_travel_active) {
    map_travel_timer++;
    map_travel_progress = map_travel_timer / map_travel_duration;
    if (map_travel_progress >= 1.0) {
        map_travel_progress = 1.0;
        map_open            = false;
        map_travel_active   = false;
        scr_begin_journey(map_travel_dest_id, map_travel_costs);
    }
}

// Main game loop dispatcher
switch(game_state) {
case "BOOT":
    // Initialize console and input references
    if (console == noone) console = instance_find(obj_console, 0);
    if (input   == noone) input   = instance_find(obj_input,   0);

    // Title screen — simple box design works with any font
    // (Set fnt_console to Courier New size 14 in GameMaker for proper column alignment)
    console_print(chr(9484) + string_repeat(chr(9472), 54) + chr(9488));
    console_print(chr(9474) + "                                                      " + chr(9474));
    console_print(chr(9474) + "    C  A  R  A  V  A  N                               " + chr(9474));
    console_print(chr(9474) + "                                                      " + chr(9474));
    console_print(chr(9474) + "    A medieval trade caravan game  --  v1.5.0         " + chr(9474));
    console_print(chr(9474) + "    Buy low. Sell high. Outlast the donkey.           " + chr(9474));
    console_print(chr(9474) + "                                                      " + chr(9474));
    console_print(chr(9492) + string_repeat(chr(9472), 54) + chr(9496));
    console_print("");
    scr_show_setup_menu();
    game_state = "SETUP";
    break;

case "SETUP":
    // All player input during SETUP is handled by cmd_parse -> scr_cmd_setup.
    // World generation happens when the player types START.
    break;
        
    case "TOWN":
        // Town state
        break;
        
    case "TRAVEL":
        // Travel state
        break;

    case "GAMEOVER":
        // End screen already displayed by scr_show_end_screen().
        // Input is gated in cmd_parse -- nothing to do here each frame.
        break;
}