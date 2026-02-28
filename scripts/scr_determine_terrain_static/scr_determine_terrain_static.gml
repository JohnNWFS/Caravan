// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Get available travel destinations from current location
/// @returns Array of destination structs

/// @desc Determine terrain type between two locations (deterministic)
/// @param {Struct} from_location
/// @param {Struct} to_location
/// @param {Real} distance
/// @returns {String} terrain type

function scr_determine_terrain_static(from_loc, to_loc, distance) {
    // Use location properties to deterministically choose terrain
    // This ensures the same route always has the same terrain
    
    // Cities tend to have roads between them
    if (from_loc.type == "CITY" && to_loc.type == "CITY") {
        return "ROAD";
    }
    
    // At least one city connected = likely road
    if (from_loc.type == "CITY" || to_loc.type == "CITY") {
        if (distance < 150) return "ROAD";
    }
    
    // Use position hash to get consistent "random" value
    // This creates a deterministic pseudo-random based on coordinates
    var seed_val = (from_loc.x * 73 + from_loc.y * 37 + to_loc.x * 19 + to_loc.y * 11) mod 100;
    var terrain_roll = seed_val / 100;
    
    // Short distances likely have established paths
    if (distance < 100) {
        if (terrain_roll < 0.5) return "ROAD";
        if (terrain_roll < 0.8) return "PLAINS";
        return "FOREST";
    }
    
    // Medium distances have varied terrain
    if (distance < 200) {
        if (terrain_roll < 0.2) return "ROAD";
        if (terrain_roll < 0.5) return "PLAINS";
        if (terrain_roll < 0.75) return "FOREST";
        return "HILLS";
    }
    
    // Long distances are more treacherous
    if (terrain_roll < 0.15) return "PLAINS";
    if (terrain_roll < 0.35) return "FOREST";
    if (terrain_roll < 0.55) return "HILLS";
    if (terrain_roll < 0.75) return "MOUNTAIN";
    return "DESERT";
}