// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Filter commodities that make sense for a location
/// @param {Struct} location The location to filter for
/// @returns {Array} Array of suitable commodities

function scr_filter_commodities_by_terrain(location) {
    var suitable = [];
    
    // Determine likely terrain based on location properties
    // This is a simplified version - you can enhance with actual terrain data
    var likely_terrains = [];
    
    if (location.type == "CITY") {
        // Cities can produce manufactured goods and trade goods
        likely_terrains = ["", "PLAINS"]; // Empty string = manufactured/anywhere
    } else if (location.type == "TOWN") {
        // Towns have mixed production
        likely_terrains = ["PLAINS", "FOREST", ""];
    } else { // VILLAGE
        // Villages focus on local resources
        likely_terrains = ["PLAINS", "FOREST", "MOUNTAIN", "HILLS", "DESERT"];
    }
    
    // Filter commodities
    for (var i = 0; i < array_length(global.commodities); i++) {
        var commodity = global.commodities[i];
        
        // Check if commodity matches location
        var is_suitable = false;
        
        // If commodity has no terrain affinity, cities/towns can make it
        if (array_length(commodity.terrain_affinity) == 0) {
            if (location.type == "CITY" || location.type == "TOWN") {
                is_suitable = true;
            }
        } else {
            // Check if any of the commodity's terrains match likely terrains
            for (var j = 0; j < array_length(commodity.terrain_affinity); j++) {
                var terrain = commodity.terrain_affinity[j];
                
                for (var k = 0; k < array_length(likely_terrains); k++) {
                    if (terrain == likely_terrains[k] || likely_terrains[k] == "") {
                        is_suitable = true;
                        break;
                    }
                }
                
                if (is_suitable) break;
            }
        }
        
        // Apply rarity filter (less likely to produce rare items in villages)
        if (is_suitable) {
            if (commodity.rarity == "RARE" && location.type == "VILLAGE") {
                if (random(1) > 0.2) { // Only 20% chance
                    is_suitable = false;
                }
            }
        }
        
        if (is_suitable) {
            array_push(suitable, commodity);
        }
    }
    
    return suitable;
}