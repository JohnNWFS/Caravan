/// @desc Create the master database of all tradeable commodities with slot mechanics
/// @returns {Array} Array of commodity structs

function scr_create_commodity_database() {
    var commodities = [];
    
    // === GRAINS (BULK STORAGE) ===
    array_push(commodities, {
        id: "wheat",
        name: "Wheat",
        aliases: ["grain"],
        category: "GRAIN",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 10,
        weight: 1,
        terrain_affinity: ["PLAINS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "barley",
        name: "Barley",
        aliases: ["grain"],
        category: "GRAIN",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 8,
        weight: 1,
        terrain_affinity: ["PLAINS", "HILLS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "rice",
        name: "Rice",
        aliases: ["grain"],
        category: "GRAIN",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 12,
        weight: 1,
        terrain_affinity: ["PLAINS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "corn",
        name: "Corn",
        aliases: ["maize", "grain"],
        category: "GRAIN",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 9,
        weight: 1,
        terrain_affinity: ["PLAINS"],
        rarity: "COMMON"
    });
    
    // === SPICES (BULK STORAGE) ===
    array_push(commodities, {
        id: "saffron",
        name: "Saffron",
        aliases: ["spice"],
        category: "SPICE",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 150,
        weight: 1,
        terrain_affinity: ["DESERT", "PLAINS"],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "pepper",
        name: "Black Pepper",
        aliases: ["pepper", "peppercorn", "peppercorns", "spice"],
        category: "SPICE",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 60,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "UNCOMMON"
    });
    
    array_push(commodities, {
        id: "cinnamon",
        name: "Cinnamon",
        aliases: ["spice"],
        category: "SPICE",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 80,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "UNCOMMON"
    });
    
    array_push(commodities, {
        id: "salt",
        name: "Salt",
        aliases: ["sea salt", "seasalt", "spice"],
        category: "SPICE",
        storage_type: "BULK",
        units_per_slot: 50,
        can_mix_with: [],
        base_value: 15,
        weight: 2,
        terrain_affinity: ["DESERT", "MOUNTAIN"],
        rarity: "COMMON"
    });
    
    // === TEXTILES (BALE STORAGE) ===
    array_push(commodities, {
        id: "wool",
        name: "Wool",
        aliases: ["fleece", "yarn"],
        category: "TEXTILE",
        storage_type: "BALE",
        units_per_slot: 20,
        can_mix_with: ["wool", "silk", "cotton", "linen"],
        base_value: 25,
        weight: 1,
        terrain_affinity: ["PLAINS", "HILLS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "silk",
        name: "Silk",
        aliases: ["silks", "silk fabric"],
        category: "TEXTILE",
        storage_type: "BALE",
        units_per_slot: 20,
        can_mix_with: ["wool", "silk", "cotton", "linen"],
        base_value: 120,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "cotton",
        name: "Cotton",
        aliases: ["cotton fabric"],
        category: "TEXTILE",
        storage_type: "BALE",
        units_per_slot: 20,
        can_mix_with: ["wool", "silk", "cotton", "linen"],
        base_value: 20,
        weight: 1,
        terrain_affinity: ["PLAINS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "linen",
        name: "Linen",
        aliases: ["flax", "linen fabric"],
        category: "TEXTILE",
        storage_type: "BALE",
        units_per_slot: 20,
        can_mix_with: ["wool", "silk", "cotton", "linen"],
        base_value: 30,
        weight: 1,
        terrain_affinity: ["PLAINS"],
        rarity: "COMMON"
    });
    
    // === METALS (HEAVY CRATE) ===
    array_push(commodities, {
        id: "iron",
        name: "Iron Ore",
        aliases: ["iron", "ore"],
        category: "METAL",
        storage_type: "HEAVY",
        units_per_slot: 10,
        can_mix_with: [],
        base_value: 35,
        weight: 3,
        terrain_affinity: ["MOUNTAIN", "HILLS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "copper",
        name: "Copper Ore",
        aliases: ["copper", "ore"],
        category: "METAL",
        storage_type: "HEAVY",
        units_per_slot: 10,
        can_mix_with: [],
        base_value: 40,
        weight: 3,
        terrain_affinity: ["MOUNTAIN", "HILLS"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "silver",
        name: "Silver",
        aliases: ["silver ore", "ore"],
        category: "METAL",
        storage_type: "LUXURY",
        units_per_slot: 10,
        can_mix_with: ["silver", "gold_ore", "jewelry", "gems"],
        base_value: 200,
        weight: 2,
        terrain_affinity: ["MOUNTAIN"],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "gold_ore",
        name: "Gold Ore",
        aliases: ["gold", "ore"],
        category: "METAL",
        storage_type: "LUXURY",
        units_per_slot: 10,
        can_mix_with: ["silver", "gold_ore", "jewelry", "gems"],
        base_value: 300,
        weight: 2,
        terrain_affinity: ["MOUNTAIN", "DESERT"],
        rarity: "RARE"
    });
    
    // === LUXURY GOODS (STACKABLE) ===
    array_push(commodities, {
        id: "wine",
        name: "Wine",
        aliases: ["wines", "vintage"],
        category: "LUXURY",
        storage_type: "CASK",
        units_per_slot: 10,
        can_mix_with: [],
        base_value: 50,
        weight: 2,
        terrain_affinity: ["PLAINS", "HILLS"],
        rarity: "UNCOMMON"
    });
    
    array_push(commodities, {
        id: "jewelry",
        name: "Jewelry",
        aliases: ["jewellery", "jewels", "trinkets"],
        category: "LUXURY",
        storage_type: "LUXURY",
        units_per_slot: 10,
        can_mix_with: ["jewelry", "silver", "gold_ore", "gems", "perfume"],
        base_value: 250,
        weight: 1,
        terrain_affinity: [],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "perfume",
        name: "Perfume",
        aliases: ["perfumes", "scent", "fragrance"],
        category: "LUXURY",
        storage_type: "LUXURY",
        units_per_slot: 10,
        can_mix_with: ["jewelry", "perfume", "gems"],
        base_value: 180,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "dye",
        name: "Fine Dyes",
        aliases: ["dyes", "dye", "pigment", "pigments"],
        category: "LUXURY",
        storage_type: "CASK",
        units_per_slot: 10,
        can_mix_with: [],
        base_value: 70,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "UNCOMMON"
    });
    
// === LIVESTOCK ===
array_push(commodities, {
    id: "horses",
    name: "Horses",
    aliases: ["horse", "steed", "steeds", "mount", "mounts"],
    category: "LIVESTOCK",
    storage_type: "LIVESTOCK_LARGE", // CHANGED: Large animals need special slots
    units_per_slot: 1,
    can_mix_with: [],
    base_value: 400,
    weight: 10,
    terrain_affinity: ["PLAINS"],
    rarity: "UNCOMMON"
});

array_push(commodities, {
    id: "cattle",
    name: "Cattle",
    aliases: ["cow", "cows", "beef", "ox", "oxen"],
    category: "LIVESTOCK",
    storage_type: "LIVESTOCK_LARGE", // CHANGED: Large animals need special slots
    units_per_slot: 1,
    can_mix_with: [],
    base_value: 200,
    weight: 8,
    terrain_affinity: ["PLAINS"],
    rarity: "COMMON"
});

array_push(commodities, {
    id: "pigs",
    name: "Pigs",
    aliases: ["pig", "swine", "hog", "hogs", "pork"],
    category: "LIVESTOCK",
    storage_type: "LIVESTOCK_SMALL", // CHANGED: Small animals fit in regular slots
    units_per_slot: 2,
    can_mix_with: [],
    base_value: 80,
    weight: 5,
    terrain_affinity: ["PLAINS", "FOREST"],
    rarity: "COMMON"
});
    
    // === TOOLS & GOODS (CRATE STORAGE) ===
    array_push(commodities, {
        id: "weapons",
        name: "Weapons",
        aliases: ["weapon", "arms", "armament", "armaments", "sword", "swords"],
        category: "TOOLS",
        storage_type: "CRATE",
        units_per_slot: 10,
        can_mix_with: ["weapons", "tools"],
        base_value: 120,
        weight: 3,
        terrain_affinity: [],
        rarity: "UNCOMMON"
    });
    
    array_push(commodities, {
        id: "tools",
        name: "Tools",
        aliases: ["tool", "implement", "implements"],
        category: "TOOLS",
        storage_type: "CRATE",
        units_per_slot: 10,
        can_mix_with: ["weapons", "tools", "pottery"],
        base_value: 45,
        weight: 2,
        terrain_affinity: [],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "pottery",
        name: "Pottery",
        aliases: ["pot", "pots", "ceramic", "ceramics", "clay goods"],
        category: "TOOLS",
        storage_type: "CRATE",
        units_per_slot: 10,
        can_mix_with: ["tools", "pottery"],
        base_value: 20,
        weight: 2,
        terrain_affinity: [],
        rarity: "COMMON"
    });
    
    // === SPECIALTY GOODS ===
    array_push(commodities, {
        id: "furs",
        name: "Furs",
        aliases: ["fur", "pelt", "pelts", "hide", "hides"],
        category: "LUXURY",
        storage_type: "BALE",
        units_per_slot: 15,
        can_mix_with: ["furs"],
        base_value: 100,
        weight: 1,
        terrain_affinity: ["FOREST"],
        rarity: "UNCOMMON"
    });
    
    array_push(commodities, {
        id: "timber",
        name: "Timber",
        aliases: ["wood", "lumber", "logs", "planks"],
        category: "MATERIAL",
        storage_type: "HEAVY",
        units_per_slot: 5,
        can_mix_with: [],
        base_value: 15,
        weight: 5,
        terrain_affinity: ["FOREST"],
        rarity: "COMMON"
    });
    
    array_push(commodities, {
        id: "gems",
        name: "Gemstones",
        aliases: ["gems", "gem", "gemstone", "jewel", "jewels", "precious stones"],
        category: "LUXURY",
        storage_type: "LUXURY",
        units_per_slot: 10,
        can_mix_with: ["jewelry", "gems", "silver", "gold_ore"],
        base_value: 500,
        weight: 1,
        terrain_affinity: ["MOUNTAIN"],
        rarity: "RARE"
    });
    
    array_push(commodities, {
        id: "honey",
        name: "Honey",
        aliases: ["mead"],
        category: "FOOD",
        storage_type: "CASK",
        units_per_slot: 10,
        can_mix_with: [],
        base_value: 35,
        weight: 1,
        terrain_affinity: ["FOREST", "PLAINS"],
        rarity: "COMMON"
    });
    
	// === PROVISIONS (ALWAYS AVAILABLE) ===
	array_push(commodities, {
	    id: "provisions",
	    name: "Provisions",
	    aliases: ["food", "rations", "supplies"],
	    category: "FOOD",
	    storage_type: "BULK",
	    units_per_slot: 50,
	    can_mix_with: [],
	    base_value: 2,
	    weight: 1,
	    terrain_affinity: [], // Available everywhere
	    rarity: "COMMON"
	});

	
	
	
    return commodities;
}