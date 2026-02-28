// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Reduce commodity stock from ghost caravan buying
/// @param {Struct} location The location where trade occurred
/// @param {Real} quantity Amount to attempt to buy

function scr_reduce_random_commodity(location, quantity) {
    var economy = location.economy;
    
    // Get list of available commodities with stock
    var available = [];
    var stock_keys = variable_struct_get_names(economy.stock_levels);
    
    for (var i = 0; i < array_length(stock_keys); i++) {
        var good_id = stock_keys[i];
        var stock = economy.stock_levels[$ good_id];
        
        if (stock > 0) {
            array_push(available, good_id);
        }
    }
    
    // If nothing available, return
    if (array_length(available) == 0) return;
    
    // Pick random commodity
    var good_id = available[irandom(array_length(available) - 1)];
    
    // Reduce stock (but not below 0)
    var current_stock = economy.stock_levels[$ good_id];
    var amount_bought = min(quantity, current_stock);
    economy.stock_levels[$ good_id] = max(0, current_stock - amount_bought);
    
    // Record in ghost trade history
    array_push(economy.ghost_trade_history, {
        day: obj_heartbeat.day,
        action: "BUY_FROM_CITY",
        good_id: good_id,
        quantity: amount_bought
    });
}