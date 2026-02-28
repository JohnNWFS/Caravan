/// @description Insert description here
// You can write your code in this editor
// === INPUT BUFFER ===
input_buffer = "";
cursor_blink = 0;
cursor_visible = true;

// === COMMAND HISTORY ===
history = [];       // Array of past commands
history_index = -1; // -1 means not browsing history
max_history = 50;

// === INPUT STATE ===
input_active = true;  // Can we type?
prompt = "> ";        // Command prompt symbol

// === MAKE PERSISTENT ===
persistent = true;