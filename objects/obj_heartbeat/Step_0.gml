/// @description Insert description here
// You can write your code in this editor

// === MAP OVERLAY CLOSE ===
// Give the map a brief grace period (map_close_delay frames) so that the
// Enter key that submitted the MAP command doesn't immediately dismiss it.
if (map_open) {
    if (map_close_delay > 0) {
        map_close_delay--;
    } else {
        if (keyboard_check_pressed(vk_escape)
            || mouse_check_button_pressed(mb_left)
            || mouse_check_button_pressed(mb_right)) {
            map_open = false;
        }
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
    console_print("+------------------------------------------------------+");
    console_print("|                                                      |");
    console_print("|    C  A  R  A  V  A  N                               |");
    console_print("|                                                      |");
    console_print("|    A medieval trade caravan game  --  v1.5.0         |");
    console_print("|    Buy low. Sell high. Outlast the donkey.           |");
    console_print("|                                                      |");
    console_print("+------------------------------------------------------+");
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