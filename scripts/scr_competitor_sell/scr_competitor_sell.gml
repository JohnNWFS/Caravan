// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Sell all cargo for a competitor caravan at their current location.
///       Adds earnings to comp.gold and clears comp.cargo.
///       NOTE: Does NOT modify location stock — competition pressure is buy-side only.
/// @param {Struct} comp     The competitor struct
/// @param {Struct} location The location struct being sold at
/// @returns {Real} Total gold earned

function scr_competitor_sell(comp, location) {
    var _earned = 0;

    for (var _i = 0; _i < array_length(comp.cargo); _i++) {
        var _item = comp.cargo[_i];
        if (_item.quantity <= 0) continue;
        _earned += scr_calculate_sell_price(location, _item.good_id, _item.quantity);
    }

    comp.gold += _earned;
    comp.cargo  = [];   // Clear all cargo

    return _earned;
}
