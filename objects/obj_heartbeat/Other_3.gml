/// @description Game End event — force-close the debug log if still open.
/// Fires whenever the game process ends, whether through the QUIT command,
/// the window being closed, or any other exit path. The QUIT command calls
/// scr_debug_log_close() itself first, so this is belt-and-suspenders for
/// every non-QUIT exit route (window X button, OS kill, crash after game_end, etc.).

scr_debug_log_close("GAME_END");
