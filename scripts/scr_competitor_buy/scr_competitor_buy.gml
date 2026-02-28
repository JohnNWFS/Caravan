// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Buy a commodity on behalf of a competitor caravan.
///       Depletes location stock, charges comp.gold, merges into comp.cargo.
/// @param {Struct} comp         The competitor struct
/// @param {Struct} location     The location struct being bought from
/// @param {String} commodity_id The commodity id to buy
/// @param {Real}   quantity     Number of units to buy
/// @returns {Real} Actual units purchased (0 if nothing bought)

function scr_competitor_buy(comp, location, commodity_id, quantity) {
    if (quantity <= 0) return 0;

    // Calculate total price using the same function the player uses
    var _price = scr_calculate_buy_price(location, commodity_id, quantity);
    if (_price <= 0) return 0;   // Not for sale (demanded good or out of stock)

    // Deplete location stock (floor at 0 — never go negative)
    location.economy.stock_levels[$ commodity_id] =
        max(0, location.economy.stock_levels[$ commodity_id] - quantity);

    // Charge the competitor
    comp.gold -= _price;

    // Merge into cargo: add to existing entry if present, else push new entry
    var _found = false;
    for (var _ci = 0; _ci < array_length(comp.cargo); _ci++) {
        if (comp.cargo[_ci].good_id == commodity_id) {
            comp.cargo[_ci].quantity += quantity;
            _found = true;
            break;
        }
    }
    if (!_found) {
        array_push(comp.cargo, { good_id: commodity_id, quantity: quantity });
    }

    return quantity;
}
