// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Find commodity by name or alias (case-insensitive)
/// @param {String} search_name Name to search for
/// @returns {Struct} Commodity or undefined

function scr_find_commodity_by_name(search_name) {
    var search = string_lower(search_name);
    
    for (var i = 0; i < array_length(global.commodities); i++) {
        var commodity = global.commodities[i];
        
        // Check exact ID match
        if (commodity.id == search) {
            return commodity;
        }
        
        // Check name match
        if (string_lower(commodity.name) == search) {
            return commodity;
        }
        
        // Check aliases
        if (variable_struct_exists(commodity, "aliases")) {
            for (var j = 0; j < array_length(commodity.aliases); j++) {
                if (string_lower(commodity.aliases[j]) == search) {
                    return commodity;
                }
            }
        }
    }
    
    return undefined;
}