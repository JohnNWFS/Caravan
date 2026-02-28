// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate price for player selling TO a city
/// @param {Struct} location The location buying goods
/// @param {String} good_id The commodity ID
/// @param {Real} quantity How many units player wants to sell
/// @returns {Real} Total price player receives

function scr_calculate_sell_price(location, good_id, quantity) {
    var economy = location.economy;
    
    // Get commodity base value
    var commodity = undefined;
    for (var i = 0; i < array_length(global.commodities); i++) {
        if (global.commodities[i].id == good_id) {
            commodity = global.commodities[i];
            break;
        }
    }
    
    if (commodity == undefined) {
        return 0; // Invalid commodity
    }
    
    var base_value = commodity.base_value;
    var final_modifier = 1.0;
    
    // === DEMAND MODIFIER ===
    // If they demand it, they pay more
    var is_demanded = false;
    for (var i = 0; i < array_length(economy.demands); i++) {
        if (economy.demands[i].good_id == good_id) {
            is_demanded = true;
            final_modifier *= 1.5; // 50% bonus
            break;
        }
    }
    
    // === SATURATION PENALTY ===
    // If they already have a lot, they pay less
    var current_stock = 0;
    if (variable_struct_exists(economy.stock_levels, good_id)) {
        current_stock = economy.stock_levels[$ good_id];
    }
    
    if (current_stock > 100) {
        // Already saturated
        var saturation = min((current_stock - 100) / 200, 0.5); // 0 to 0.5
        final_modifier *= (1.0 - saturation); // Up to 50% penalty
    }
    
    // === DISCOVERED WANTS BONUS ===
    // If they've discovered they want this, they pay more
    for (var i = 0; i < array_length(economy.discovered_wants); i++) {
        if (economy.discovered_wants[i] == good_id) {
            final_modifier *= 1.4; // 40% bonus
            break;
        }
    }
    
    // === PRODUCTION PENALTY ===
    // If they produce it themselves, they pay less for yours
    for (var i = 0; i < array_length(economy.produces); i++) {
        if (economy.produces[i].good_id == good_id) {
            final_modifier *= 0.6; // 40% penalty (they have their own)
            break;
        }
    }
    
    // === BULK SELLING PENALTY ===
    // Selling huge amounts? They negotiate down
    if (quantity >= 50) {
        final_modifier *= 0.95; // 5% penalty for flooding market
    }
    if (quantity >= 100) {
        final_modifier *= 0.90; // Additional 10% penalty (total ~15% off)
    }
    
    // Calculate final price
    var unit_price = base_value * final_modifier;
    var total_price = unit_price * quantity;
    
    return floor(total_price); // Round down (player gets slightly less)
}