/// @func scr_debug_log_open()
/// @desc Enable debug logging. Opens caravan_debug.log in append mode, writes a
///       session header, then dumps the entire current console history so you have
///       full context from before the command was entered. Subsequent calls to
///       console_print() will write each line to the file automatically.
///       Does nothing if logging is already active.
///
/// GML file API note: file_text_writeln(handle) writes ONLY a newline.
/// Text must be written first with file_text_write_string(handle, string).

function scr_debug_log_open() {
    if (global.debug_log_enabled) {
        console_print("[DEBUG] Logging is already active.");
        return;
    }

    var _path = working_directory + "caravan_debug.log";

    // Append mode — previous sessions are preserved in the same file.
    global.debug_log_file = file_text_open_append(_path);

    if (global.debug_log_file == -1) {
        console_print("[DEBUG] ERROR: Could not open log file for writing.");
        console_print("[DEBUG] Path: " + _path);
        return;
    }

    global.debug_log_enabled = true;

    // --- Session header ---
    var _now = string(current_year)   + "-"
             + string(current_month)  + "-"
             + string(current_day)    + " "
             + string(current_hour)   + ":"
             + string(current_minute) + ":"
             + string(current_second);

    var _fh = global.debug_log_file; // shorthand

    file_text_writeln(_fh);
    file_text_write_string(_fh, "================================================================================"); file_text_writeln(_fh);
    file_text_write_string(_fh, "=== CARAVAN DEBUG SESSION STARTED: " + _now + " ==="); file_text_writeln(_fh);
    file_text_write_string(_fh, "================================================================================"); file_text_writeln(_fh);
    file_text_writeln(_fh);

    // --- Dump full console history so context is available from the start ---
    var _history = obj_console.lines;
    var _count   = array_length(_history);

    if (_count > 0) {
        file_text_write_string(_fh, "--- CONSOLE HISTORY (" + string(_count) + " lines) ---"); file_text_writeln(_fh);
        for (var i = 0; i < _count; i++) {
            file_text_write_string(_fh, _history[i]);
            file_text_writeln(_fh);
        }
        file_text_write_string(_fh, "--- END HISTORY ---"); file_text_writeln(_fh);
        file_text_writeln(_fh);
    }

    // Confirm to the player (this line itself will be logged via console_print's hook)
    console_print("[DEBUG] Logging ON  >>  " + _path);
    if (_count > 0) {
        console_print("[DEBUG] " + string(_count) + " lines of history written.");
    }
}
