// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Check if player has enough resources for a journey
/// @param {Struct} costs The cost struct from scr_calculate_travel_cost
/// @returns {Struct} {can_afford: bool, missing: struct}
/// @desc Check if player has enough resources for a journey
/// @param {Struct} costs The cost struct from scr_calculate_travel_cost
/// @returns {Struct} {can_afford: bool, missing: struct}

function scr_can_afford_journey(costs) {
    var result = {
        can_afford: true,
        missing: {
            provisions: 0,
            water: 0,
            gold: 0
        }
    };
    
    // Check provisions
    if (obj_player.provisions < costs.provisions) {
        result.can_afford = false;
        result.missing.provisions = costs.provisions - obj_player.provisions;
    }
    
    // Check water (now from barrels)
    var available_water = scr_get_total_water();
    if (available_water < costs.water) {
        result.can_afford = false;
        result.missing.water = costs.water - available_water;
    }
    
    // Check gold
    if (obj_player.gold < costs.gold) {
        result.can_afford = false;
        result.missing.gold = costs.gold - obj_player.gold;
    }
    
    return result;
}