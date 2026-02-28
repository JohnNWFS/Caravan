/// @description Handle typewriter drip and scrolling

// === TYPEWRITER DRIP ===
// One line per typewriter_delay frames is popped from the queue and added to lines[].
// typewriter_paused == true suspends the drip until SPACE is pressed again.
if (array_length(typewriter_queue) > 0 && !typewriter_paused) {
    typewriter_timer--;
    if (typewriter_timer <= 0) {
        array_push(lines, typewriter_queue[0]);
        array_delete(typewriter_queue, 0, 1);
        while (array_length(lines) > max_lines) {
            array_delete(lines, 0, 1);
        }
        scroll_offset    = 0;            // Keep scrolled to the newest line
        typewriter_timer = typewriter_delay;
    }
}

// Calculate max scroll (how far back can we go?)
var total_lines = array_length(lines);
var visible_rows = rows - 1; // Account for input row
var max_scroll = max(0, total_lines - visible_rows);

// Page Up - scroll up (into history)
if (keyboard_check_pressed(vk_pageup) || mouse_wheel_up()) {
    scroll_offset = min(scroll_offset + visible_rows, max_scroll);
}

// Page Down - scroll down (toward present)
if (keyboard_check_pressed(vk_pagedown) || mouse_wheel_down()) {
    scroll_offset = max(scroll_offset - visible_rows, 0);
}

// Home - jump to top
if (keyboard_check_pressed(vk_home)) {
    scroll_offset = max_scroll;
}

// End - jump to bottom
if (keyboard_check_pressed(vk_end)) {
    scroll_offset = 0;
}