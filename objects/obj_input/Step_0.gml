/// @description Handle player keyboard input and typewriter skip

// === TYPEWRITER CONTROL ===
// Behaviour when the typewriter queue is non-empty:
//   SPACE              → toggle pause / resume (key is NOT passed to the input buffer)
//   PageUp/Down/Home/End → pass through so the player can scroll without flushing
//   Any other key      → flush all remaining lines instantly, then handle the key normally
if (instance_exists(obj_console) && array_length(obj_console.typewriter_queue) > 0) {
    var _is_nav = keyboard_check_pressed(vk_pageup)
               || keyboard_check_pressed(vk_pagedown)
               || keyboard_check_pressed(vk_home)
               || keyboard_check_pressed(vk_end);

    if (!_is_nav) {
        if (keyboard_check_pressed(vk_space)) {
            // Toggle pause — absorb the key so no space enters the input buffer
            obj_console.typewriter_paused = !obj_console.typewriter_paused;
            keyboard_lastchar = "";
            exit; // Skip the rest of input handling this frame
        } else if (keyboard_check_pressed(vk_anykey)) {
            // Flush queue and unpause — key still falls through to normal handling below
            obj_console.typewriter_paused = false;
            while (array_length(obj_console.typewriter_queue) > 0) {
                array_push(obj_console.lines, obj_console.typewriter_queue[0]);
                array_delete(obj_console.typewriter_queue, 0, 1);
            }
            while (array_length(obj_console.lines) > obj_console.max_lines) {
                array_delete(obj_console.lines, 0, 1);
            }
            obj_console.scroll_offset    = 0;
            obj_console.typewriter_timer = 0;
        }
    }
}

if (!input_active) exit;

// === CURSOR BLINK ===
cursor_blink++;
if (cursor_blink > 30) {
    cursor_visible = !cursor_visible;
    cursor_blink = 0;
}

// === KEYBOARD INPUT ===
if (keyboard_check_pressed(vk_enter)) {
    // Submit command
    if (input_buffer != "") {
        // Add to history
        history[array_length(history)] = input_buffer;
        if (array_length(history) > max_history) {
            array_delete(history, 0, 1);
        }
        history_index = -1;
        
        // Echo command to console
        console_print(prompt + input_buffer);
        
        // Parse and execute command
        cmd_parse(input_buffer);
        
        // Clear buffer
        input_buffer = "";
    }
}

if (keyboard_check_pressed(vk_backspace)) {
    if (string_length(input_buffer) > 0) {
        input_buffer = string_delete(input_buffer, string_length(input_buffer), 1);
    }
}

// === HISTORY NAVIGATION ===
if (keyboard_check_pressed(vk_up)) {
    if (array_length(history) > 0) {
        if (history_index == -1) {
            history_index = array_length(history) - 1;
        } else {
            history_index = max(0, history_index - 1);
        }
        input_buffer = history[history_index];
    }
}

if (keyboard_check_pressed(vk_down)) {
    if (history_index != -1) {
        history_index++;
        if (history_index >= array_length(history)) {
            history_index = -1;
            input_buffer = "";
        } else {
            input_buffer = history[history_index];
        }
    }
}

// === CHARACTER INPUT ===
var key = keyboard_lastchar;
if (key != "") {
    // Filter to printable ASCII
    var char_code = ord(key);
    if (char_code >= 32 && char_code <= 126) {
        input_buffer += key;
    }
    keyboard_lastchar = ""; // Clear so we don't double-input
}