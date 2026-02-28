// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate journey time in days based on distance and terrain.
///       Uses the vehicle database for per-wagon base speeds.
///       The caravan's pace is set by its SLOWEST wagon.
/// @param {Real}   distance  Distance in km
/// @param {String} terrain   Terrain type (ROAD, PLAINS, FOREST, HILLS, MOUNTAIN, DESERT)
/// @returns {Real} Number of days for the journey (always rounded up, minimum 1)

function scr_calculate_journey_time(distance, terrain) {

    // === TERRAIN MODIFIER ===
    var terrain_modifier = 1.0;
    switch (terrain) {
        case "ROAD":     terrain_modifier = 1.0; break;  // Full speed on roads
        case "PLAINS":   terrain_modifier = 0.9; break;  // Slightly slower
        case "FOREST":   terrain_modifier = 0.7; break;  // Dense trees slow you down
        case "HILLS":    terrain_modifier = 0.6; break;  // Uphill travel
        case "MOUNTAIN": terrain_modifier = 0.5; break;  // Treacherous paths
        case "DESERT":   terrain_modifier = 0.6; break;  // Heat and sand
        default:         terrain_modifier = 0.8; break;  // Unknown terrain
    }

    // === FIND SLOWEST WAGON ===
    // The whole caravan moves at the speed of its least capable member.
    var slowest_speed = 999999;

    for (var _wi = 0; _wi < array_length(obj_player.caravan.wagons); _wi++) {
        var _w     = obj_player.caravan.wagons[_wi];
        var _vdata = scr_get_vehicle_data(_w.type);
        var _base  = (_vdata != undefined) ? _vdata.base_speed : 50; // fallback 50

        var _speed = _base * terrain_modifier;

        // === ANIMAL SPEED MODIFIER ===
        // Only applied to vehicles that REQUIRE a draft animal.
        // A HANDCART is pushed by the merchant; its attached animal has negligible effect.
        var _needs_animal = (_vdata != undefined) ? _vdata.requires_animal : true;
        if (_needs_animal && array_length(_w.slots.animals.contents) > 0) {
            _speed *= _w.slots.animals.contents[0].speed;
        }

        // === CONDITION PENALTY ===
        // Below 75 % condition, speed starts to suffer.
        var _cond = _w.condition / 100;
        if (_cond < 0.75) {
            _speed *= (0.5 + _cond * 0.5);
        }

        slowest_speed = min(slowest_speed, _speed);
    }

    // Guard: no wagons or degenerate speed should not crash
    if (slowest_speed <= 0 || slowest_speed == 999999) slowest_speed = 1;

    // === DAYS (always rounded up; partial days count as full days) ===
    var days = ceil(distance / slowest_speed);
    if (days < 1) days = 1;

    return days;
}
