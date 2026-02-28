// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Returns the master draft-animal catalog as an array of structs.
///       Call once at boot and store in global.animals.
///       Companion helper scr_get_animal_data() is defined below.

function scr_create_animal_database() {
    return [

        // ------------------------------------------------------------------
        {
            id:              "DONKEY",
            name:            "Donkey",
            desc:            "Reliable and cheap — the merchant's best friend. Carries saddlebags.",
            price:           50,
            sell_price:      20,
            speed:           0.8,   // Multiplier on vehicle base_speed (requires_animal vehicles only)
            feed_cost:       2,     // Provisions / day
            water_cost:      1,     // Water / day
            saddlebag_slots: 2,     // Extra BULK cargo slots added to wagon
            wear_reduction:  1.0,   // 1.0 = no reduction; 0.7 = 30 % less wear
            exotic:          false,
            available_at:    ["VILLAGE", "TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "MULE",
            name:            "Mule",
            desc:            "Stubborn but dependable — slightly faster than a donkey with extra pack space.",
            price:           120,
            sell_price:      48,
            speed:           0.85,
            feed_cost:       2,
            water_cost:      1,
            saddlebag_slots: 3,
            wear_reduction:  1.0,
            exotic:          false,
            available_at:    ["VILLAGE", "TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "OX",
            name:            "Ox",
            desc:            "Slow and powerful — reduces wagon wear significantly.",
            price:           150,
            sell_price:      60,
            speed:           0.6,
            feed_cost:       3,
            water_cost:      1,
            saddlebag_slots: 0,
            wear_reduction:  0.7,   // Wagon wears 30 % slower
            exotic:          false,
            available_at:    ["TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "HORSE",
            name:            "Horse",
            desc:            "Fast and prestigious — the whole caravan moves at a gallop.",
            price:           300,
            sell_price:      120,
            speed:           1.2,
            feed_cost:       3,
            water_cost:      2,
            saddlebag_slots: 0,
            wear_reduction:  1.0,
            exotic:          false,
            available_at:    ["TOWN", "CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "DRAKE",
            name:            "Drake",
            desc:            "A rare fire-breathing lizard bred for the trade roads — astonishingly swift.",
            price:           800,
            sell_price:      320,
            speed:           1.4,
            feed_cost:       5,
            water_cost:      2,
            saddlebag_slots: 0,
            wear_reduction:  1.0,
            exotic:          true,
            available_at:    ["CITY"],
        },

        // ------------------------------------------------------------------
        {
            id:              "DRAGON",
            name:            "Dragon",
            desc:            "A fully grown dragon — terrifying speed, eye-watering daily upkeep.",
            price:           2000,
            sell_price:      800,
            speed:           1.8,
            feed_cost:       8,
            water_cost:      3,
            saddlebag_slots: 0,
            wear_reduction:  1.0,
            exotic:          true,
            available_at:    ["CITY"],
        },

    ];
}

// ============================================================
/// @desc Look up an animal by type ID from global.animals.
/// @param {String} type_id  e.g. "DONKEY", "HORSE", "DRAGON"
/// @returns {Struct|Undefined}
// ============================================================
function scr_get_animal_data(type_id) {
    for (var _i = 0; _i < array_length(global.animals); _i++) {
        if (global.animals[_i].id == type_id) return global.animals[_i];
    }
    return undefined;
}
