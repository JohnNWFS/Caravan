/// @func scr_debug_log_close(reason)
/// @desc Flush, mark, and close the debug log. Safe to call even if logging is
///       not currently active (does nothing in that case). Used by:
///         - DEBUG command (voluntary toggle-off)
///         - QUIT command  (explicit exit)
///         - Game End event on obj_heartbeat (forced close / crash-safety)
/// @param {String} reason Short label written to the log footer, e.g. "USER", "QUIT", "GAME_END"
///
/// GML file API note: file_text_writeln(handle) writes ONLY a newline.
/// Text must be written first with file_text_write_string(handle, string).

function scr_debug_log_close(reason) {
    if (!global.debug_log_enabled || global.debug_log_file == -1) return;

    var _now = string(current_year)   + "-"
             + string(current_month)  + "-"
             + string(current_day)    + " "
             + string(current_hour)   + ":"
             + string(current_minute) + ":"
             + string(current_second);

    var _fh = global.debug_log_file; // shorthand

    file_text_writeln(_fh);
    file_text_write_string(_fh, "================================================================================"); file_text_writeln(_fh);
    file_text_write_string(_fh, "=== SESSION ENDED: " + _now + "  [" + reason + "] ==="); file_text_writeln(_fh);
    file_text_write_string(_fh, "================================================================================"); file_text_writeln(_fh);
    file_text_writeln(_fh);

    file_text_close(_fh);
    global.debug_log_file    = -1;
    global.debug_log_enabled = false;
}
