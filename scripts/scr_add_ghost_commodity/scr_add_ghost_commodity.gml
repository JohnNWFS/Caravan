// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Add commodity stock from ghost caravan trade
/// @param {Struct} location The location where trade occurred
/// @param {String} good_id The commodity ID
/// @param {Real} quantity Amount to add

function scr_add_ghost_commodity(location, good_id, quantity) {
    var economy = location.economy;
    
    // Add to stock levels
    if (variable_struct_exists(economy.stock_levels, good_id)) {
        economy.stock_levels[$ good_id] += quantity;
    } else {
        economy.stock_levels[$ good_id] = quantity;
        
        // Initialize price modifier if new commodity
        if (!variable_struct_exists(economy.price_modifiers, good_id)) {
            economy.price_modifiers[$ good_id] = 1.0; // Neutral price
        }
    }
    
    // Record in ghost trade history
    array_push(economy.ghost_trade_history, {
        day: obj_heartbeat.day,
        action: "SELL_TO_CITY",
        good_id: good_id,
        quantity: quantity
    });
}