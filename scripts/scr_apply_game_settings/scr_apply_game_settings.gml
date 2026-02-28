// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Apply the player's chosen starting gear preset to obj_player.
///       Called once from scr_cmd_setup when the player types START.
///       Preset 1 is the default (obj_player.Create_0 already built it — no change).
///       Presets 2-4 rebuild wagons[0] in-place with a different vehicle and animal.

function scr_apply_game_settings() {
    var _preset = obj_heartbeat.setup_config.gear_preset;
    if (_preset == 1) return;   // Default Handcart + Donkey — no change needed

    var _wagon = obj_player.caravan.wagons[0];

    // ===========================================================
    // PRESET 2 — The Road Merchant: CART + MULE
    // 700g, Cart (6 cargo slots), Mule (3 saddlebag BULK slots)
    // ===========================================================
    if (_preset == 2) {
        obj_player.gold  = 700;
        _wagon.type      = "CART";
        _wagon.condition = 100;

        _wagon.slots.animals.contents = [{
            type:           "MULE",
            hp:             100,
            speed:          0.85,
            capacity:       60,
            feed_cost:      2,
            water_cost:     1,
            wear_reduction: 1.0,
            has_saddlebags: true,
            saddlebag_slots: 3
        }];

        _wagon.slots.cargo.capacity = 6;
        _wagon.slots.cargo.contents = [];
        for (var _i = 0; _i < 6; _i++) {
            array_push(_wagon.slots.cargo.contents, undefined);
        }
        for (var _i = 0; _i < 3; _i++) {
            array_push(_wagon.slots.cargo.contents, {
                slot_type:      "SADDLEBAG_BULK",
                allowed_types:  ["BULK"],
                contents:       undefined
            });
        }
    }

    // ===========================================================
    // PRESET 3 — The Caravan Master: WAGON + OX
    // 2500g, Wagon (8 cargo + 1 livestock slot), Ox (reduces wagon wear)
    // ===========================================================
    if (_preset == 3) {
        obj_player.gold  = 2500;
        _wagon.type      = "WAGON";
        _wagon.condition = 100;

        _wagon.slots.animals.contents = [{
            type:           "OX",
            hp:             100,
            speed:          0.6,
            capacity:       80,
            feed_cost:      3,
            water_cost:     1,
            wear_reduction: 0.7,
            has_saddlebags: false,
            saddlebag_slots: 0
        }];

        _wagon.slots.cargo.capacity = 8;
        _wagon.slots.cargo.contents = [];
        for (var _i = 0; _i < 8; _i++) {
            array_push(_wagon.slots.cargo.contents, undefined);
        }

        // Give the wagon its livestock trade slot
        _wagon.slots.livestock_trade.capacity = 1;
        _wagon.slots.livestock_trade.contents = [];
    }

    // ===========================================================
    // PRESET 4 — The Merchant Prince: MERCHANT_WAGON + HORSE
    // 8000g, Merchant Wagon (12 cargo + 2 livestock slots), Horse (fast travel)
    // ===========================================================
    if (_preset == 4) {
        obj_player.gold  = 8000;
        _wagon.type      = "MERCHANT_WAGON";
        _wagon.condition = 100;

        _wagon.slots.animals.contents = [{
            type:           "HORSE",
            hp:             100,
            speed:          1.2,
            capacity:       0,
            feed_cost:      3,
            water_cost:     2,
            wear_reduction: 1.0,
            has_saddlebags: false,
            saddlebag_slots: 0
        }];

        _wagon.slots.cargo.capacity = 12;
        _wagon.slots.cargo.contents = [];
        for (var _i = 0; _i < 12; _i++) {
            array_push(_wagon.slots.cargo.contents, undefined);
        }

        // Merchant wagon has 2 livestock trade slots
        _wagon.slots.livestock_trade.capacity = 2;
        _wagon.slots.livestock_trade.contents = [];
    }
}
