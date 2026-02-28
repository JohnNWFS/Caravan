/// @description Insert description here
// You can write your code in this editor
// Clear background
draw_clear(col_bg);

// Set font
draw_set_font(fnt_console);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === DRAW STATUS LINE (if any) ===
if (status_text != "") {
    draw_set_color(col_status);
    draw_text(0, 0, status_text);
    draw_set_color(col_text); // Reset to default
}

// === DRAW TEXT LINES ===
var start_y = (status_text != "") ? char_height : 0;
var visible_rows = (status_text != "") ? rows - 2 : rows - 1; // Reserve bottom row for input

// Calculate which lines to show (bottom-up, accounting for scroll)
var total_lines = array_length(lines);
var first_visible = max(0, total_lines - visible_rows - scroll_offset);
var last_visible = total_lines - scroll_offset;

for (var i = first_visible; i < last_visible; i++) {
    var row = i - first_visible;
    var y_pos = start_y + (row * char_height);
    
    // Parse for color tags (we'll add this feature later)
    // For now, just draw the line
    draw_set_color(col_text);
    draw_text(0, y_pos, lines[i]);
}

// === DRAW INPUT LINE AT BOTTOM ===
// We'll let obj_input draw its own line