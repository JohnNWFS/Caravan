// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Advance all competitor caravans by an appropriate number of turns
///       for the number of days the player just traveled.
///       Called once per player journey from scr_begin_journey.
/// @param {Real} days_traveled Number of in-game days the player just spent traveling

function scr_run_all_competitors(days_traveled) {
    if (!variable_struct_exists(obj_heartbeat.world, "competitors")) return;

    // Scale competitor turns to player journey length.
    // floor(days/4): 1-3 days → 1 turn, 4-7 → 1, 8-11 → 2, 12+ → 3 (capped)
    var _n_turns = clamp(floor(days_traveled / 4), 1, 3);

    var _comps = obj_heartbeat.world.competitors;
    for (var _ci = 0; _ci < array_length(_comps); _ci++) {
        for (var _t = 0; _t < _n_turns; _t++) {
            scr_run_competitor_turn(_comps[_ci]);
        }
    }
}
