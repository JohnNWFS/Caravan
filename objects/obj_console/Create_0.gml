/// @description Insert description here
// You can write your code in this editor
// === DISPLAY SETTINGS ===
char_width = 8;   // Approximate character width in pixels
char_height = 16; // Character height in pixels
cols = 80;        // Characters per row
rows = 25;        // Total rows visible

// === TEXT STORAGE ===
lines = [];       // Array of strings - our scrollback buffer
max_lines = 1000; // Keep last 1000 lines in memory
scroll_offset = 0; // How many lines scrolled up from bottom

// === STATUS PANE (optional for now) ===
status_text = "";  // Top status line

// === COLORS ===
col_bg = c_black;
col_text = c_lime;     // Classic green terminal
col_status = c_yellow;
col_error = c_red;
col_info = c_aqua;

// === TYPEWRITER (drip output) ===
typewriter_queue  = [];   // Lines waiting to be printed one-by-one
typewriter_timer  = 0;    // Countdown frames to next line
typewriter_delay  = 15;   // Frames between lines (~4 lines/sec at 60fps — comfortable reading pace)
typewriter_paused = false; // SPACE key toggles pause on/off

// === MAKE PERSISTENT ===
persistent = true;