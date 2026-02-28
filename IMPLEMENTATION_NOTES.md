# Caravan - Implementation Notes

**Purpose:** Technical documentation for implementation details, architectural decisions, and system internals  
**Audience:** Developers, contributors, future maintainers  
**Companion to:** DESIGN.md (high-level design and feature documentation)

---

## Table of Contents

1. [Console Wrapping System](#console-wrapping-system)
2. [Command History Mechanics](#command-history-mechanics)
3. [Cargo Slot Consolidation Logic](#cargo-slot-consolidation-logic)
4. [Economic System Formulas](#economic-system-formulas)
5. [Ghost Caravan Simulation](#ghost-caravan-simulation)
6. [Equipment Slot Architecture](#equipment-slot-architecture)
7. [Command Parsing System](#command-parsing-system)
8. [Debug Tools](#debug-tools)
9. [Script Design Context](#script-design-context)

---

## Console Wrapping System

### Overview
The console output system in `console_print()` implements **pixel-perfect word wrapping** to ensure text never exceeds visible boundaries while maintaining readable line breaks.

### Implementation Details

**File:** `scripts/console_print.gml`

**Key Components:**

1. **Width Calculation:**
```gml
draw_set_font(fnt_console);
var max_width = 630; // 640px window - 10px margin
```

2. **Pixel-Based Wrapping:**
- Uses `string_width()` to measure actual rendered width
- Character count is **not** used (proportional font support)
- Ensures no text overflow regardless of character variety

3. **Smart Line Breaking:**
```gml
// Break at spaces for clean wrapping
if (string_char_at(chunk, test_len) != " ") {
    for (var i = test_len; i > max(1, test_len - 20); i--) {
        if (string_char_at(remaining, i) == " ") {
            test_len = i;
            chunk = string_copy(remaining, 1, test_len);
            break;
        }
    }
}
```
- Searches backwards up to 20 characters for a space
- Prevents mid-word breaks when possible
- Falls back to hard break if no space found

4. **Indentation Preservation:**
```gml
// Count leading spaces in original
var spaces = 0;
for (var i = 1; i <= string_length(text); i++) {
    if (string_char_at(text, i) == " ") {
        spaces++;
    } else {
        break;
    }
}

// Add same indent to wrapped lines
var indent = string_repeat(" ", spaces);
if (string_length(remaining) > 0 && string_char_at(remaining, 1) != " ") {
    remaining = indent + remaining;
}
```
- Detects leading spaces in first line
- Applies same indentation to continuation lines
- Maintains visual hierarchy in wrapped output

5. **Auto-Scroll:**
```gml
// Auto-scroll to bottom
obj_console.scroll_offset = 0;
```
- Always shows newest content
- User can scroll up manually via mouse wheel

### Performance Considerations

- **Complexity:** O(n) where n = string length
- **Optimization:** Backward space search limited to 20 characters
- **Typical case:** Single-pass for short lines, multi-pass for long text

### Edge Cases Handled

| Case | Behavior |
|------|----------|
| No spaces in 20-char window | Hard break at test_len |
| Single character too wide | Renders anyway (degrades gracefully) |
| Empty string | Adds blank line to console |
| Very long word (>630px) | Breaks mid-word |

---

## Command History Mechanics

### Overview
The input system maintains a **circular buffer** of previously entered commands, navigable with Up/Down arrow keys.

### Implementation Details

**File:** `objects/obj_input/Step_0.gml`

**Data Structure:**
```gml
history = []          // Array of command strings
history_index = -1    // Current position (-1 = not browsing)
max_history = 50      // Maximum stored commands
```

### Navigation Logic

**UP Arrow Pressed:**
```gml
if (keyboard_check_pressed(vk_up)) {
    if (array_length(history) > 0) {
        if (history_index == -1) {
            // Start browsing from most recent
            history_index = array_length(history) - 1;
        } else {
            // Move to older command
            history_index = max(0, history_index - 1);
        }
        input_buffer = history[history_index];
    }
}
```

**DOWN Arrow Pressed:**
```gml
if (keyboard_check_pressed(vk_down)) {
    if (history_index != -1) {
        history_index++;
        if (history_index >= array_length(history)) {
            // Reached end, return to input mode
            history_index = -1;
            input_buffer = "";
        } else {
            // Move to newer command
            input_buffer = history[history_index];
        }
    }
}
```

### Command Addition

**On Enter Key:**
```gml
if (keyboard_check_pressed(vk_enter)) {
    if (input_buffer != "") {
        // Add to history
        history[array_length(history)] = input_buffer;
        
        // Enforce max limit
        if (array_length(history) > max_history) {
            array_delete(history, 0, 1);
        }
        
        // Reset browsing state
        history_index = -1;
    }
}
```

### UX Benefits

- **Repeat commands** without retyping
- **Fix typos** by recalling and editing
- **Experimentation** encouraged (easy to retry variations)
- **No lost work** if accidentally cleared input

### Design Rationale

**Why Circular Buffer?**
- Prevents infinite memory growth
- 50 commands = ~5-10 minutes of gameplay history
- Old commands rarely needed beyond this window

**Why -1 for "Not Browsing"?**
- Clear sentinel value
- Allows index 0 to be valid history position
- Simple state check: `if (history_index == -1)`

---

## Cargo Slot Consolidation Logic

### Overview
The STATUS command analyzes cargo slots and **separates standard wagon slots from saddlebag slots**, providing clear usage statistics.

### Implementation Details

**File:** `scripts/cmd_parse.gml` (STATUS case)

**Analysis Algorithm:**

```gml
var cargo_slots = wagon.slots.cargo.contents;
var standard_slots = 0;
var standard_used = 0;
var saddlebag_slots = 0;
var saddlebag_used = 0;
var cargo_list = [];

// Analyze each slot
for (var g = 0; g < array_length(cargo_slots); g++) {
    var slot = cargo_slots[g];
    
    if (slot == undefined) {
        // Empty standard slot
        standard_slots++;
        continue;
    } else if (variable_struct_exists(slot, "slot_type")) {
        // Special slot (saddlebag, etc.)
        if (slot.slot_type == "SADDLEBAG_BULK") {
            saddlebag_slots++;
            if (slot.contents != undefined) {
                saddlebag_used++;
                array_push(cargo_list, {
                    slot_num: g + 1,
                    slot_type: "SADDLEBAG",
                    data: slot.contents
                });
            }
        }
    } else {
        // Standard slot with cargo
        standard_slots++;
        standard_used++;
        array_push(cargo_list, {
            slot_num: g + 1,
            slot_type: "STANDARD",
            data: slot
        });
    }
}
```

### Slot Type Detection

**Three Slot States:**

1. **Empty Standard Slot:** `slot == undefined`
2. **Special Slot:** `variable_struct_exists(slot, "slot_type")`
3. **Filled Standard Slot:** Neither of the above

### Display Output

```gml
console_print("  Cargo Slots:");
console_print("    Wagon: " + string(standard_used) + "/" + string(standard_slots) + " used");
if (saddlebag_slots > 0) {
    console_print("    Saddlebags: " + string(saddlebag_used) + "/" + string(saddlebag_slots) + " used");
}
```

**Example Output:**
```
Cargo Slots:
  Wagon: 2/4 used
  Saddlebags: 1/2 used
Cargo contents:
  Slot 1: [trade goods]
  Slot 3: [trade goods]
  Saddlebag 5: [trade goods]
```

### Design Rationale

**Why Separate Counting?**
- **Clarity:** Players need to know which slots are limited (saddlebags = BULK only)
- **Capacity Planning:** Understanding wagon vs. animal capacity aids decision-making
- **Future Proofing:** Supports additional slot types (livestock, equipment)

**Why cargo_list Array?**
- Allows sorting/grouping before display
- Can add value calculations later
- Supports future filtering/search

---

## Economic System Formulas

### Overview
The pricing system uses **dynamic calculations** based on supply, demand, and market conditions to create a realistic trading economy.

### Price Calculation Scripts

#### **scr_calculate_buy_price(location, commodity_id, quantity)**

**Purpose:** Calculate player's purchase price (includes merchant markup)

**Formula:**
```gml
base_price = commodity.base_price
demand_modifier = location.economy.demand_for[commodity_id]
production_bonus = location.economy.produces[commodity_id] ? 0.7 : 1.0
markup = 0.2  // 20% merchant markup

buy_price = base_price * demand_modifier * production_bonus * (1.0 + markup)
```

**Components:**
- **base_price:** Commodity's inherent value (from database)
- **demand_modifier:** How much location wants this good (0.5 - 2.0 typical range)
- **production_bonus:** 30% discount if location produces the commodity
- **markup:** Merchants buy wholesale, sell retail (20% difference)

**Example Calculation:**
```
Wheat at Farmton:
  base_price = 10
  demand_modifier = 0.8 (low local demand)
  production_bonus = 0.7 (Farmton produces wheat)
  markup = 0.2

buy_price = 10 * 0.8 * 0.7 * 1.2 = 6.72 gold per unit
```

---

#### **scr_calculate_sell_price(location, commodity_id, quantity)**

**Purpose:** Calculate player's sale price (includes merchant markdown)

**Formula:**
```gml
base_price = commodity.base_price
demand_modifier = location.economy.demand_for[commodity_id]
production_bonus = location.economy.produces[commodity_id] ? 0.7 : 1.0
markdown = 0.2  // 20% merchant markdown

sell_price = base_price * demand_modifier * production_bonus * (1.0 - markdown)
```

**Components:**
- **markdown:** Merchants need profit margin (20% spread)

**Example Calculation:**
```
Saffron at Desert Outpost:
  base_price = 100
  demand_modifier = 1.5 (high demand for luxury spice)
  production_bonus = 1.0 (doesn't produce saffron)
  markdown = 0.2

sell_price = 100 * 1.5 * 1.0 * 0.8 = 120 gold per unit
```

---

### Buy/Sell Spread

**Key Economic Principle:** Merchants must **buy low, sell high** to profit.

```
Buy Price = Base × Demand × Production × (1 + markup)
Sell Price = Base × Demand × Production × (1 - markdown)

Spread = Buy Price - Sell Price
       = Base × Demand × Production × (markup + markdown)
       = Base × Demand × Production × 0.4
```

**Example:**
```
Wheat at neutral market:
  Buy: 10 × 1.0 × 1.0 × 1.2 = 12 gold
  Sell: 10 × 1.0 × 1.0 × 0.8 = 8 gold
  Spread: 4 gold (33% difference)
```

**Player Strategy:** Find locations where:
- Sell price in City A > Buy price in City B
- Margin covers travel costs
- Volume justifies cargo space

---

### Supply/Demand Dynamics

**Stock Levels Affect Pricing:**

```gml
// When player buys, stock decreases
stock_levels[commodity_id] -= quantity

// When player sells, stock increases
stock_levels[commodity_id] += quantity

// Future: Demand modifier recalculates based on stock
demand_modifier = calculate_demand_from_stock(stock_levels[commodity_id])
```

**Planned Enhancement:** Dynamic demand_modifier that:
- Decreases when stock is high (oversupply)
- Increases when stock is low (scarcity)
- Creates feedback loop preventing infinite arbitrage

---

### Ghost Caravan Impact

**NPC Trades Modify Markets:**

```gml
// Ghost caravan adds commodity (NPC selling)
scr_add_ghost_commodity(location)
  → stock_levels[random_commodity] += random(1, 20)
  → Lowers future buy prices (oversupply)

// Ghost caravan removes commodity (NPC buying)
scr_reduce_random_commodity(location)
  → stock_levels[random_commodity] -= random(1, 20)
  → Raises future buy prices (scarcity)
```

**Effect:** Markets evolve organically, preventing exploitation of fixed prices.

---

### Production Bonus Deep Dive

**Why 30% Discount?**
- Represents local production efficiency
- Farmland produces wheat → cheaper wheat
- Desert oasis → expensive wheat (import costs)

**Implementation:**
```gml
if (location.terrain == commodity.terrain_affinity) {
    production_bonus = 0.7;  // 30% off
} else {
    production_bonus = 1.0;  // No discount
}
```

**Strategic Implications:**
- Buy commodities where they're produced
- Sell in locations that don't produce them
- Terrain knowledge = profit opportunity

---

## Ghost Caravan Simulation

### Overview
**Design Intent:** Markets should evolve when player isn't present  
**Implementation:** Frame-based random simulation instead of day-based intervals

### Design vs. Implementation

**Original Design (DESIGN.md lines 4948-4951):**
```
- First Visit: Simulate 1 NPC trade per 10 game-days (70% chance)
- Return Visits: Simulate 1 NPC trade per 20 game-days (40% chance)
```

**Actual Implementation:**
```gml
// obj_heartbeat Step Event (runs EVERY FRAME at 60 FPS)
scr_simulate_ghost_trades()
```

### Current Algorithm

**File:** `scripts/scr_simulate_ghost_trades.gml`

```gml
function scr_simulate_ghost_trades() {
    // Pick 1-2 random locations per frame
    var num_trades = irandom_range(1, 2);
    
    for (var i = 0; i < num_trades; i++) {
        var random_location = global.world[irandom(array_length(global.world) - 1)];
        
        // 50/50 chance: add or reduce commodity
        if (random(1) > 0.5) {
            scr_add_ghost_commodity(random_location);
        } else {
            scr_reduce_random_commodity(random_location);
        }
    }
}
```

### Trade Operations

**Add Commodity (NPC Selling):**
```gml
function scr_add_ghost_commodity(location) {
    var random_commodity = scr_pick_random_commodity(location);
    var quantity = irandom_range(1, 20);
    
    location.economy.stock_levels[$ random_commodity] += quantity;
}
```

**Reduce Commodity (NPC Buying):**
```gml
function scr_reduce_random_commodity(location) {
    var random_commodity = scr_pick_random_commodity(location);
    var quantity = irandom_range(1, 20);
    
    location.economy.stock_levels[$ random_commodity] -= quantity;
    location.economy.stock_levels[$ random_commodity] = max(0, stock_levels[$ random_commodity]);
}
```

### Frequency Analysis

**Per Second (60 FPS):**
- 60 frames × 1.5 avg trades per frame = **90 ghost trades/second**
- Across 30 locations = **3 trades per location per second**

**Comparison to Design:**
- Design: 1 trade per 10-20 game-days
- Implementation: Hundreds of trades per game-day

### Why This Works

**Advantages:**
1. **Simplicity:** No day-tracking logic needed
2. **Constant Evolution:** Prices never static, prevents exploitation
3. **Lightweight:** Random number generation is cheap
4. **Emergent Behavior:** Creates realistic market fluctuations

**Trade-offs:**
1. **Higher Frequency:** Much more dynamic than designed
2. **No Historical Simulation:** Doesn't "catch up" past days
3. **Pure Randomness:** No intelligent NPC trading patterns

### Performance Impact

**Computational Cost Per Frame:**
```
2 random location picks
2 random commodity picks  
2 random quantity calculations
2-4 struct property modifications
= ~10 basic operations
```

**Negligible Impact:** Modern hardware handles this trivially at 60 FPS.

### Future Optimization Considerations

If performance becomes an issue:
- Reduce frequency (every 10 frames instead of every frame)
- Batch operations (process all 30 locations once per second)
- Add sleep timer (only simulate when player is idle)

**Current Assessment:** No optimization needed, system is performant.

---

## Equipment Slot Architecture

### Overview
Water barrels and survival gear are stored in **equipment slots**, not cargo slots, to prevent accidental trade/sale and maintain clear separation of concerns.

### Design Decision Rationale

**Problem:** Early design had water barrels in cargo slots:
- Risk of selling water containers by accident
- Confusion between "cargo for trade" and "cargo for survival"
- Capacity calculations complicated by mixed use

**Solution:** Create dedicated equipment slot category.

### Slot Structure

```gml
equipment: {
    capacity: 1,  // Starting wagon has 1 equipment slot
    contents: [
        {
            type: "BARREL",
            subtype: "WATER",
            water: 50,
            max_water: 50,
            weight: 1
        }
    ]
}
```

### Equipment vs. Cargo Comparison

| Property | Cargo Slots | Equipment Slots |
|----------|-------------|-----------------|
| **Purpose** | Trade goods for profit | Survival gear |
| **Sellable** | Yes (primary mechanic) | No (not tradeable) |
| **Capacity** | Per-wagon, expandable | Fixed per wagon type |
| **Stacking** | Same commodity stacks | Each item separate |
| **Examples** | Wheat, salt, silk, gems | Water barrels, tools, weapons |

### Implementation in STATUS Command

```gml
if (variable_struct_exists(wagon.slots, "equipment")) {
    var equipment_count = array_length(wagon.slots.equipment.contents);
    if (equipment_count > 0) {
        console_print("  Equipment:");
        for (var e = 0; e < equipment_count; e++) {
            var item = wagon.slots.equipment.contents[e];
            if (item.type == "BARREL" && item.subtype == "WATER") {
                console_print("    - WATER BARREL (" + string(item.water) + "/" + string(item.max_water) + ")");
            } else {
                console_print("    - " + item.type);
            }
        }
    }
}
```

**Output Example:**
```
Equipment:
  - WATER BARREL (50/50)
```

### Water Management Functions

All water functions operate on equipment slots:

```gml
// Get total water across all equipment slots
scr_get_total_water()
  → Iterates wagon.slots.equipment.contents
  → Sums water from all WATER barrels

// Get maximum capacity
scr_get_max_water_capacity()
  → Iterates wagon.slots.equipment.contents
  → Sums max_water from all WATER barrels

// Consume water during travel
scr_consume_water(amount)
  → Proportionally drains water from all barrels
  → Never touches cargo slots

// Refill at destinations
scr_refill_water()
  → Sets all barrel.water = barrel.max_water
  → Called automatically on arrival
```

### Benefits Realized

✅ **Prevents Accidental Sale:** Water never appears in SELL commodity list  
✅ **Clear Mental Model:** Equipment = survival, Cargo = profit  
✅ **Simpler Capacity Math:** Don't subtract water barrels from cargo space  
✅ **Matches Player Expectations:** Aligns with real-world understanding  
✅ **Future-Proof:** Can add tools, weapons, armor without cargo conflicts  

### Future Extensions

Planned equipment types:
- **Tools:** Repair kits (reduce breakdown chance)
- **Weapons:** Personal defense (combat bonus)
- **Armor:** Damage reduction (guard protection)
- **Specialty Gear:** Climbing equipment, desert gear (terrain bonuses)

---

## Command Parsing System

### Overview
The command parser implements **flexible argument order** and **smart keyword detection** to improve user experience.

### Flexible Argument Parsing

**Problem:** Players naturally use different word orders:
- "BUY wheat 25"
- "BUY 25 wheat"

**Solution:** Detect number position dynamically.

### BUY/SELL Parsing Algorithm

**File:** `scripts/cmd_parse.gml`

```gml
// Find the last space to separate arguments
var last_space = 0;
for (var i = string_length(args); i >= 1; i--) {
    if (string_char_at(args, i) == " ") {
        last_space = i;
        break;
    }
}

if (last_space > 0) {
    var part1 = string_copy(args, 1, last_space - 1);
    var part2 = string_copy(args, last_space + 1, string_length(args));
    
    var good = "";
    var qty = 0;
    
    // Check if part1 is a number
    if (string_digits(part1) == part1 && part1 != "") {
        qty = real(part1);
        good = part2;
    }
    // Check if part2 is a number
    else if (string_digits(part2) == part2 && part2 != "") {
        qty = real(part2);
        good = part1;
    }
    // Neither is a number - check for MAX/ALL
    else if (string_upper(part1) == "MAX" || string_upper(part1) == "ALL") {
        is_max_order = true;
        good = part2;
    }
    else if (string_upper(part2) == "MAX" || string_upper(part2) == "ALL") {
        is_max_order = true;
        good = part1;
    }
}
```

### MAX/ALL Keyword Implementation

**BUY MAX Logic:**
```gml
// Calculate max affordable quantity
var max_affordable = 0;

for (var test_qty = 1; test_qty <= available_stock; test_qty++) {
    var test_price = scr_calculate_buy_price(current_loc, commodity.id, test_qty);
    
    if (test_price <= obj_player.gold) {
        max_affordable = test_qty;
    } else {
        break; // Can't afford more
    }
}

if (max_affordable > 0) {
    qty = max_affordable;
    console_print("Buying maximum: " + string(qty) + " " + commodity.name);
}
```

**SELL ALL Logic:**
```gml
// Find total quantity in player cargo
var player_has = 0;

for (var w = 0; w < array_length(obj_player.caravan.wagons); w++) {
    var wagon = obj_player.caravan.wagons[w];
    var cargo_slots = wagon.slots.cargo.contents;
    
    for (var s = 0; s < array_length(cargo_slots); s++) {
        var slot = cargo_slots[s];
        
        // Sum quantities across all slots containing this commodity
        if (slot.good_id == commodity.id) {
            player_has += slot.quantity;
        }
    }
}

qty = player_has;
console_print("Selling all: " + string(qty) + " " + commodity.name);
```

### Supported Command Patterns

**BUY Command:**
- `BUY wheat 25` ✓
- `BUY 25 wheat` ✓
- `BUY wheat MAX` ✓
- `BUY MAX wheat` ✓
- `BUY wheat ALL` ✓ (synonym for MAX)

**SELL Command:**
- `SELL salt 10` ✓
- `SELL 10 salt` ✓
- `SELL salt MAX` ✓
- `SELL salt ALL` ✓

### Error Handling

```gml
if (commodity == undefined) {
    console_print("Unknown commodity: " + good);
    break;
}

if (max_affordable == 0) {
    console_print("You can't afford any " + commodity.name + ".");
    console_print("Unit price: " + string(scr_calculate_buy_price(...)) + " gold");
    console_print("Your gold: " + string(obj_player.gold));
    break;
}
```

### Design Benefits

✅ **Natural Language:** Matches how players think  
✅ **Reduced Frustration:** No "wrong order" errors  
✅ **Discovered UX Improvement:** Not in original design, emerged during testing  
✅ **Minimal Code Complexity:** Simple swap detection  
✅ **MAX/ALL Convenience:** No mental math for maximum purchases  

---

## Debug Tools

### Console Dump Command (~)

**Purpose:** Export console history to GameMaker debug output window for analysis/debugging.

### Usage

```
~           // Dump all console lines
~ 50        // Dump last 50 lines
~ 100       // Dump last 100 lines
```

### Implementation

**File:** `scripts/cmd_parse.gml`

```gml
case "~":
    var dump_count = -1; // -1 = all lines
    
    if (args != "") {
        dump_count = real(args);
    }
    
    var lines = obj_console.lines;
    var total_lines = array_length(lines);
    
    if (dump_count == -1 || dump_count >= total_lines) {
        // Dump all lines
        show_debug_message("=== CONSOLE DUMP (ALL " + string(total_lines) + " LINES) ===");
        for (var i = 0; i < total_lines; i++) {
            show_debug_message(lines[i]);
        }
    } else {
        // Dump most recent X lines
        var start_index = max(0, total_lines - dump_count);
        show_debug_message("=== CONSOLE DUMP (LAST " + string(dump_count) + " LINES) ===");
        for (var i = start_index; i < total_lines; i++) {
            show_debug_message(lines[i]);
        }
    }
    
    show_debug_message("=== END DUMP ===");
    console_print("Console dumped to output window.");
    break;
```

### Output Format

```
=== CONSOLE DUMP (LAST 50 LINES) ===
> STATUS
=== PLAYER STATUS ===
Location: Sandport (coastal)
Gold: 150
...
=== END DUMP ===
```

### Use Cases

1. **Bug Reports:** Players can dump console and share output
2. **Testing:** Verify command sequences during development
3. **Analysis:** Review trade history or decision chains
4. **Documentation:** Capture example gameplay sessions

### Why Hidden?

- Not a "gameplay" command
- Prevents clutter in HELP menu
- Developer/advanced user feature
- Tilde (~) is common debug key convention

---

## Script Design Context

### Overview
This section documents scripts that need additional design context beyond their code comments.

---

### Commodity Lookup & Filtering

#### **scr_find_commodity_by_name(name_string)**

**Purpose:** Fuzzy search for commodities by name (case-insensitive, partial matching)

**Algorithm:**
```gml
1. Convert search string to uppercase
2. Iterate all commodity categories (grains, spices, etc.)
3. For each commodity, check if search string is contained in name
4. Return first match found
5. Return undefined if no match
```

**Matching Rules:**
- **Case-insensitive:** "wheat" = "WHEAT" = "Wheat"
- **Partial match:** "whe" matches "wheat"
- **First match wins:** If "s" matches both "salt" and "silk", returns first found

**Example:**
```gml
scr_find_commodity_by_name("SALT")    → returns commodity.id "spices.salt"
scr_find_commodity_by_name("salt")    → returns commodity.id "spices.salt"
scr_find_commodity_by_name("sa")      → returns commodity.id "spices.salt" OR "spices.saffron" (first in category order)
scr_find_commodity_by_name("gold")    → returns commodity.id "metals.gold"
scr_find_commodity_by_name("xyz")     → returns undefined
```

**Improvement Opportunity:** Could implement ranked matching (exact > starts-with > contains).

---

#### **scr_filter_commodities_by_terrain(terrain_type)**

**Purpose:** Get list of commodities that spawn in a specific terrain

**Terrain Affinity System:**

Each commodity has a `terrain_affinity` array defining where it's produced:

```gml
commodity: {
    id: "grains.wheat",
    name: "Wheat",
    terrain_affinity: ["plains", "forest"],
    ...
}
```

**Algorithm:**
```gml
1. Initialize empty result array
2. Iterate all commodities in database
3. For each commodity, check if terrain_type is in terrain_affinity array
4. If match found, add commodity.id to result array
5. Return filtered array
```

**Terrain → Commodity Mapping:**

| Terrain | Typical Commodities |
|---------|---------------------|
| **Plains** | Wheat, barley, oats, cattle |
| **Mountains** | Iron, copper, gold, stone |
| **Desert** | Salt, dates, camels |
| **Forest** | Lumber, furs, game |
| **Coastal** | Fish, salt, pearls |

**Used By:**
- `scr_generate_location_economy()` - Determines what each location can produce
- World generation - Creates realistic regional specialization

---

### World Generation

#### **scr_determine_terrain_static(x, y, index)**

**Purpose:** Assign terrain type to a location based on its position in the world

**Current Implementation:** Static assignment (not using x/y coordinates)

**Algorithm:**
```gml
// Simplified version:
var terrains = ["plains", "mountains", "desert", "forest", "coastal"];
var terrain_index = index mod 5;
return terrains[terrain_index];
```

**Effect:** Creates even distribution of terrain types across 30 locations:
- Locations 0, 5, 10, 15, 20, 25 → plains
- Locations 1, 6, 11, 16, 21, 26 → mountains
- Locations 2, 7, 12, 17, 22, 27 → desert
- Locations 3, 8, 13, 18, 23, 28 → forest
- Locations 4, 9, 14, 19, 24, 29 → coastal

**Improvement Opportunity:** Could use noise functions for clustered terrain:
```gml
// Perlin noise-based terrain (concept)
var noise_value = perlin_noise(x / 1000, y / 1000);
if (noise_value < 0.2) return "coastal";
if (noise_value < 0.4) return "plains";
if (noise_value < 0.6) return "forest";
if (noise_value < 0.8) return "mountains";
return "desert";
```

---

### Travel Mechanics

#### **scr_calculate_journey_time(from_index, to_index)**

**Purpose:** Calculate number of days required to travel between two locations

**Current Formula:**
```gml
var from_loc = global.world[from_index];
var to_loc = global.world[to_index];

var dx = to_loc.x - from_loc.x;
var dy = to_loc.y - from_loc.y;
var distance = sqrt(dx*dx + dy*dy);

// Base speed: 100 distance units per day
var days = ceil(distance / 100);

return max(1, days); // Minimum 1 day
```

**Example:**
```
Location A: (100, 200)
Location B: (400, 600)

dx = 300
dy = 400
distance = sqrt(300^2 + 400^2) = 500

days = ceil(500 / 100) = 5 days
```

**Factors NOT Yet Implemented:**
- Caravan speed modifiers (wagon quality, animal speed)
- Terrain difficulty (mountains slower than plains)
- Weather effects (storms slow travel)
- Road quality (established routes faster)

**Future Enhancement:**
```gml
var base_speed = 100;
var terrain_modifier = get_terrain_difficulty(from_loc.terrain, to_loc.terrain);
var caravan_speed = calculate_caravan_speed(global.player_data.caravan);

var adjusted_speed = base_speed * terrain_modifier * caravan_speed;
var days = ceil(distance / adjusted_speed);
```

---

### Recommended Documentation Priority

| Script | Priority | Reason |
|--------|----------|--------|
| `scr_calculate_buy_price()` | ✅ DONE | Core economic formula |
| `scr_calculate_sell_price()` | ✅ DONE | Core economic formula |
| `scr_find_commodity_by_name()` | ✅ DONE | UX-critical fuzzy matching |
| `scr_filter_commodities_by_terrain()` | ✅ DONE | World generation logic |
| `scr_determine_terrain_static()` | ✅ DONE | World generation logic |
| `scr_calculate_journey_time()` | ✅ DONE | Travel system core |
| `scr_simulate_ghost_trades()` | ✅ DONE | Economy simulation |
| `scr_get_total_water()` | Low | Self-explanatory utility |
| `scr_consume_water()` | Low | Straightforward depletion |
| `scr_pick_random_commodity()` | Low | Simple random selection |

---

## Appendix: Quick Reference Tables

### Command Aliases

| Full Command | Aliases | Purpose |
|--------------|---------|---------|
| HELP | H | Show command list |
| STATUS | ST | Player/caravan info |
| INVENTORY | I, INV | Cargo details |
| TRAVEL | T | Destination list |
| GO | G | Execute journey |
| MARKET | M | Price display |
| BUY | B | Purchase goods |
| SELL | S | Sell goods |
| WORK | W | Emergency income |
| QUIT | Q | Exit game |

### Slot Type Reference

| Slot Type | Allowed Contents | Capacity Source | Tradeable |
|-----------|------------------|-----------------|-----------|
| Standard Cargo | Any commodity | Wagon base | Yes |
| Saddlebag | BULK only | Pack animals | Yes |
| Livestock | Animals only | Wagon type | Yes |
| Equipment | Gear only | Wagon type | No |
| Crew | People only | Wagon type | No |
| Animal | Mounts/pack | Wagon type | No |

### Terrain Affinity Map

| Commodity Category | Plains | Mountains | Desert | Forest | Coastal |
|--------------------|--------|-----------|--------|--------|---------|
| Grains | ✓ | | | ✓ | |
| Spices | | | ✓ | | ✓ |
| Textiles | ✓ | | | ✓ | |
| Metals | | ✓ | | | |
| Luxuries | | | ✓ | | ✓ |
| Livestock | ✓ | | ✓ | | |
| Tools | | ✓ | | ✓ | |

---

*Last Updated: January 17, 2026*  
*Companion Document: DESIGN.md*