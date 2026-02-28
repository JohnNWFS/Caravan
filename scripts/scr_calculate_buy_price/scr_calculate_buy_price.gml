// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Calculate price for player buying FROM a city
/// @param {Struct} location The location selling goods
/// @param {String} good_id The commodity ID
/// @param {Real} quantity How many units player wants to buy
/// @returns {Real} Total price, or -1 if not available
///
/// Uses floor() so the displayed per-unit price (quantity=1) is the exact
/// per-unit cost — players will never pay more than (displayed price × quantity).

function scr_calculate_buy_price(location, good_id, quantity) {
    var economy = location.economy;

    // === DEMANDED GOODS ARE NOT FOR SALE ===
    // A town that needs a commodity keeps any stock it holds for its own use.
    // It will pay a premium to BUY more, but it won't sell what it has.
    for (var i = 0; i < array_length(economy.demands); i++) {
        if (economy.demands[i].good_id == good_id) {
            return -1; // Not available for purchase
        }
    }

    // === RESALE STOCK (player-sold goods) ===
    // These carry a fixed price set at the time of sale and bypass normal
    // supply/demand calculation entirely.
    if (variable_struct_exists(economy, "resale_stock")
        && variable_struct_exists(economy.resale_stock, good_id)) {
        var _resale = economy.resale_stock[$ good_id];
        if (_resale.qty > 0) {
            var _actual_qty = min(quantity, _resale.qty);
            return _resale.unit_price * _actual_qty; // Already an integer; no rounding needed
        }
    }

    // === CHECK NORMAL (PRODUCED) STOCK ===
    var available_stock = 0;
    if (variable_struct_exists(economy.stock_levels, good_id)) {
        available_stock = economy.stock_levels[$ good_id];
    }

    if (available_stock <= 0) {
        return -1; // Not available
    }

    // Get commodity base value
    var commodity = undefined;
    for (var i = 0; i < array_length(global.commodities); i++) {
        if (global.commodities[i].id == good_id) {
            commodity = global.commodities[i];
            break;
        }
    }

    if (commodity == undefined) {
        return -1; // Invalid commodity
    }

    var base_value    = commodity.base_value;
    var final_modifier = 1.0;

    // === PRODUCTION BONUS ===
    // If they produce it, they sell it cheaper
    for (var i = 0; i < array_length(economy.produces); i++) {
        if (economy.produces[i].good_id == good_id) {
            final_modifier *= 0.7; // 30% discount
            break;
        }
    }

    // === SUPPLY MODIFIER ===
    // Price rises as stock depletes; oversupply yields a small discount
    if (available_stock < 50) {
        var scarcity = 1.0 - (available_stock / 50); // 0 to 1
        final_modifier *= (1.0 + (scarcity * 0.5));  // up to +50%
    } else if (available_stock > 300) {
        final_modifier *= 0.9; // 10% oversupply discount
    }

    // NOTE: discovered_wants does NOT affect what the town charges the player to BUY.
    // A town that has discovered a taste for something will PAY MORE for it (sell-side),
    // but they don't inflate the price of their own supply.  The premium is in
    // scr_calculate_sell_price only.

    // === QUANTITY MODIFIER ===
    // Bulk orders get a small discount
    if (quantity >= 20) {
        final_modifier *= 0.95; // 5% discount
    }
    if (quantity >= 50) {
        final_modifier *= 0.93; // Additional 7% (total ~12% off)
    }

    // Can't buy more than they have
    var actual_quantity = min(quantity, available_stock);

    // floor() keeps the displayed per-unit price (qty=1) equal to the exact per-unit
    // transaction cost, so "X gold/unit" in the market × qty always equals the bill.
    var unit_price  = base_value * final_modifier;
    var total_price = unit_price * actual_quantity;
    return floor(total_price);
}
