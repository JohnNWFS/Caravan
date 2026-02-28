// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Returns the master vehicle (wagon / cart) catalog as an array of structs.
///       Call once at boot and store in global.vehicles.
///       Companion helper scr_get_vehicle_data() is defined below.

function scr_create_vehicle_database() {
    return [

        // ------------------------------------------------------------------
        {
            id:              "HANDCART",
            name:            "Handcart",
            desc:            "A sturdy two-wheeled push cart — no animal needed, but cargo is limited.",
            price:           25,
            sell_price:      10,    // ~40 % of buy
            requires_animal: false,
            base_speed:      40,    // km / day (human-pushed; animal speed NOT applied)
            cargo_slots:     4,
            livestock_slots: 0,
            wear_mult:       1.0,   // Wears fastest — cheapest build
            repair_rate:     3,     // Gold per condition-point of damage
            maintenance:     2,     // Gold / day operating cost
            available_at:    ["VILLAGE", "TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "CART",
            name:            "Cart",
            desc:            "A two-wheeled draft cart well-suited for light trade runs.",
            price:           200,
            sell_price:      80,
            requires_animal: true,
            base_speed:      50,    // km / day (scaled by animal.speed)
            cargo_slots:     6,
            livestock_slots: 0,
            wear_mult:       0.9,
            repair_rate:     5,
            maintenance:     3,
            available_at:    ["VILLAGE", "TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "WAGON",
            name:            "Wagon",
            desc:            "A four-wheeled workhorse with a livestock pen for live trade.",
            price:           500,
            sell_price:      200,
            requires_animal: true,
            base_speed:      50,
            cargo_slots:     8,
            livestock_slots: 1,
            wear_mult:       0.8,
            repair_rate:     8,
            maintenance:     5,
            available_at:    ["TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "COVERED_WAGON",
            name:            "Covered Wagon",
            desc:            "A canvas-roofed wagon that protects perishable and fragile goods.",
            price:           900,
            sell_price:      360,
            requires_animal: true,
            base_speed:      45,
            cargo_slots:     10,
            livestock_slots: 1,
            wear_mult:       0.6,
            repair_rate:     12,
            maintenance:     6,
            available_at:    ["TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "MERCHANT_WAGON",
            name:            "Merchant Wagon",
            desc:            "A purpose-built trade wagon — maximum cargo and two livestock pens.",
            price:           1800,
            sell_price:      720,
            requires_animal: true,
            base_speed:      45,
            cargo_slots:     12,
            livestock_slots: 2,
            wear_mult:       0.7,
            repair_rate:     15,
            maintenance:     8,
            available_at:    ["CITY"],
        },

    ];
}

// ============================================================
/// @desc Look up a vehicle by type ID from global.vehicles.
/// @param {String} type_id  e.g. "CART", "WAGON", "HANDCART"
/// @returns {Struct|Undefined}
// ============================================================
function scr_get_vehicle_data(type_id) {
    for (var _i = 0; _i < array_length(global.vehicles); _i++) {
        if (global.vehicles[_i].id == type_id) return global.vehicles[_i];
    }
    return undefined;
}
