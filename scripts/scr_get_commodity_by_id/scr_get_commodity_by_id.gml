// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Get commodity data by ID
/// @param {String} good_id The commodity ID
/// @returns {Struct} Commodity struct, or undefined if not found

function scr_get_commodity_by_id(good_id) {
    for (var i = 0; i < array_length(global.commodities); i++) {
        if (global.commodities[i].id == good_id) {
            return global.commodities[i];
        }
    }
    return undefined;
}