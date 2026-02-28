// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Pick a random commodity weighted by rarity
/// @returns {Struct} A commodity from the database

function scr_pick_random_commodity() {
    // Weight commodities by rarity
    // COMMON = 60% chance, UNCOMMON = 30%, RARE = 10%
    
    var common_pool = [];
    var uncommon_pool = [];
    var rare_pool = [];
    
    for (var i = 0; i < array_length(global.commodities); i++) {
        var commodity = global.commodities[i];
        
        switch(commodity.rarity) {
            case "COMMON":
                array_push(common_pool, commodity);
                break;
            case "UNCOMMON":
                array_push(uncommon_pool, commodity);
                break;
            case "RARE":
                array_push(rare_pool, commodity);
                break;
        }
    }
    
    // Roll for rarity tier
    var roll = random(1);
    var selected_pool;
    
    if (roll < 0.6) {
        // 60% - Common
        selected_pool = common_pool;
    } else if (roll < 0.9) {
        // 30% - Uncommon
        selected_pool = uncommon_pool;
    } else {
        // 10% - Rare
        selected_pool = rare_pool;
    }
    
    // Pick random from selected pool
    if (array_length(selected_pool) == 0) {
        // Fallback to common if pool is empty
        selected_pool = common_pool;
    }
    
    var index = irandom(array_length(selected_pool) - 1);
    return selected_pool[index];
}