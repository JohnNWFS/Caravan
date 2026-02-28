/// @description Initialize player and caravan with hybrid slot system

// === PERSONAL STATS ===
gold = 150;
hp = 100;
max_hp = 100;
reputation = 0;
current_location = noone;  // Will be set by world gen

// === RESOURCES ===
provisions = 50;  // Food for people and animals

// === RELATIONSHIPS ===
relationships = {};

// === PENDING ACTION (for multi-step confirmations) ===
pending_action = undefined;

// === PERSONAL INVENTORY ===
inventory = [];

// === CARAVAN ===
caravan = {
    wagons: [],
    followers: [],
    total_capacity: 0,
    total_speed: 0,
    total_defense: 0
};

// === CREATE STARTING WAGON (HANDCART) ===
var starting_wagon = {
    id: "wagon_001",
    type: "HANDCART",
    condition: 100,
    
    slots: {
        // NEW: Slot-based cargo system
        cargo: {
            capacity: 4,  // 4 cargo slots for trade goods
            contents: []  // Array of slot structs (or undefined for empty)
        },
        // NEW: Livestock slots for large animals (cattle, horses)
        livestock_trade: {
            capacity: 0,  // HANDCART has NO livestock slots (too small)
            contents: []  // Large livestock for trading
        },
        // KEPT: Animals slot (pack animals like donkeys)
        animals: {
            capacity: 1,
            contents: []
        },
        // KEPT: Crew slot
        crew: {
            capacity: 1,
            contents: []
        },
        // KEPT: Passengers slot
        passengers: {
            capacity: 0,
            contents: []
        },
        // KEPT: Magic slot (for future use)
        magic: {
            capacity: 0,
            contents: []
        },
        // NEW: Equipment slot for water barrels (separate from trade cargo)
        equipment: {
            capacity: 1,
            contents: []
        }
    },
    
    speed_modifier: 1.0,
    defense_modifier: 0.5,
    breakdown_chance: 0.05
};

// Add the wagon to our caravan
array_push(caravan.wagons, starting_wagon);

// === CREATE STARTING ANIMAL (DONKEY WITH SADDLEBAGS) ===
var starting_animal = {
    type: "DONKEY",
    hp: 100,
    speed: 0.8,
    capacity: 50,
    feed_cost: 2,
    water_cost: 1,         // Water / day (used by scr_calculate_daily_consumption)
    wear_reduction: 1.0,   // Wagon-wear multiplier (OX = 0.7 = 30% less wear)
    has_saddlebags: true,
    saddlebag_slots: 2     // Adds 2 BULK cargo slots
};

// Add animal to the wagon's animal slot
array_push(caravan.wagons[0].slots.animals.contents, starting_animal);

// === CREATE STARTING WATER BARREL ===
var starting_barrel = {
    type: "BARREL",
    subtype: "WATER",  // NEW: Distinguish from trade barrels
    water: 50,
    max_water: 50,
    weight: 1
};

// Add barrel to EQUIPMENT slot (not cargo - keeps it separate from trade goods)
array_push(caravan.wagons[0].slots.equipment.contents, starting_barrel);

// === ADD PLAYER TO CREW ===
var player_crew = {
    name: "Player",
    type: "MERCHANT",
    hp: 100,
    skills: []
};

array_push(caravan.wagons[0].slots.crew.contents, player_crew);


// === INITIALIZE CARGO SLOTS (4 empty + 2 saddlebag = 6 total) ===
// Main wagon slots
for (var i = 0; i < 4; i++) {
    array_push(caravan.wagons[0].slots.cargo.contents, undefined);
}

// Saddlebag slots (BULK only)
for (var i = 0; i < 2; i++) {
    array_push(caravan.wagons[0].slots.cargo.contents, {
        slot_type: "SADDLEBAG_BULK",  // Special: can only hold BULK goods
        allowed_types: ["BULK"],
        contents: undefined  // null = empty, or commodity struct
    });
}

// === INITIALIZE LIVESTOCK TRADE SLOTS ===
// Handcart has 0 capacity, so no slots to initialize
// (Future wagons will have livestock_trade.capacity > 0 and will need initialization)


// === MAKE PERSISTENT ===
persistent = true;