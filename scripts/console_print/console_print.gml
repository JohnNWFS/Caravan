// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// ============================================================
/// @func _console_wrap_lines(text)
/// @desc Split text into an array of strings that each fit within
///       max_width pixels using the current fnt_console font.
///       Word-breaks at spaces where possible; preserves leading-space
///       indent on continuation lines.
///       Returns an array with at least one element (may be the
///       original string untouched if it already fits).
// ============================================================
function _console_wrap_lines(text) {
    var _result = [];
    if (!instance_exists(obj_console)) return _result;

    draw_set_font(fnt_console);
    var max_width = 630; // Leave 10px margin on 640px window

    // Fast path — already fits
    if (string_width(text) <= max_width) {
        array_push(_result, text);
        return _result;
    }

    // Count leading spaces so we can indent continuation lines
    var _leading = 0;
    for (var _k = 1; _k <= string_length(text); _k++) {
        if (string_char_at(text, _k) == " ") _leading++;
        else break;
    }
    var _indent = string_repeat(" ", _leading);

    var remaining = text;
    while (string_length(remaining) > 0) {
        var test_len = string_length(remaining);
        var chunk    = remaining;

        // Shrink chunk until it fits within max_width
        while (string_width(chunk) > max_width && test_len > 1) {
            test_len--;
            chunk = string_copy(remaining, 1, test_len);

            // Try to break at a space for cleaner wrapping
            if (string_char_at(chunk, test_len) != " ") {
                for (var i = test_len; i > max(1, test_len - 20); i--) {
                    if (string_char_at(remaining, i) == " ") {
                        test_len = i;
                        chunk    = string_copy(remaining, 1, test_len);
                        break;
                    }
                }
            }
        }

        array_push(_result, chunk);

        // Remainder after the break point
        remaining = string_copy(remaining, test_len + 1, string_length(remaining));

        // Apply indentation to continuation lines (if the original was indented)
        if (_leading > 0
            && string_length(remaining) > 0
            && string_char_at(remaining, 1) != " ") {
            remaining = _indent + remaining;
        }
    }

    return _result;
}


// ============================================================
/// @func console_print(text)
/// @desc Add a line of text to the console with automatic word-wrap.
// ============================================================
function console_print(text) {
    if (!instance_exists(obj_console)) return;

    // Write the original (un-wrapped) text once to the debug log
    if (global.debug_log_enabled && global.debug_log_file != -1) {
        file_text_write_string(global.debug_log_file, text);
        file_text_writeln(global.debug_log_file);
    }

    var _lines = _console_wrap_lines(text);
    for (var _i = 0; _i < array_length(_lines); _i++) {
        array_push(obj_console.lines, _lines[_i]);
    }

    // Trim oldest lines if over the scrollback limit
    while (array_length(obj_console.lines) > obj_console.max_lines) {
        array_delete(obj_console.lines, 0, 1);
    }

    // Auto-scroll to bottom
    obj_console.scroll_offset = 0;
}


// ============================================================
/// @func console_clear()
/// @desc Wipe all lines from the console and empty any pending typewriter queue.
// ============================================================
function console_clear() {
    if (!instance_exists(obj_console)) return;
    obj_console.lines            = [];
    obj_console.typewriter_queue = [];
    obj_console.scroll_offset    = 0;
    obj_console.typewriter_paused = false;
}


// ============================================================
/// @func console_print_slow(text)
/// @desc Queue a line for typewriter-style drip output.
///       The text is word-wrapped NOW (before queuing) so each
///       chunk that drips onto the screen is already guaranteed
///       to fit within the console width.
///       Lines are added to obj_console.typewriter_queue and
///       printed one per typewriter_delay frames in Step_0.
///       SPACE pauses the drip; any other key flushes the queue.
// ============================================================
function console_print_slow(text) {
    if (!instance_exists(obj_console)) return;

    // Write to debug log immediately (not delayed — log stays clean)
    if (global.debug_log_enabled && global.debug_log_file != -1) {
        file_text_write_string(global.debug_log_file, text);
        file_text_writeln(global.debug_log_file);
    }

    // Pre-wrap so every queue entry fits on screen
    var _lines = _console_wrap_lines(text);
    for (var _i = 0; _i < array_length(_lines); _i++) {
        array_push(obj_console.typewriter_queue, _lines[_i]);
    }
}
