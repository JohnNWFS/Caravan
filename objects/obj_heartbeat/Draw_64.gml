/// @description Draw GUI — world map overlay
// Runs after all regular Draw events; draws on top of everything else.
if (map_open) {
    // Rebuild terrain surface here, BEFORE scr_draw_map starts drawing.
    // Doing it mid-draw (inside scr_draw_map) can leave the GUI render
    // target in a bad state after surface_reset_target() is called.
    if (world != noone && !surface_exists(map_terrain_surface)) {
        scr_build_terrain_surface();
    }
    scr_draw_map();
}
