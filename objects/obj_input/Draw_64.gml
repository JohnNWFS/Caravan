/// @description Insert description here
// You can write your code in this editor
// Draw input line at bottom of screen
draw_set_font(fnt_console);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

var input_y = room_height - obj_console.char_height - 6; // Bottom row with paddingvar input_y = room_height - char_height; // Bottom row
var cursor_char = cursor_visible ? "_" : " ";

draw_text(0, input_y, prompt + input_buffer + cursor_char);