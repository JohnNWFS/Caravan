# Caravan - Design Documentation

**Genre:** Text-based trading/merchant simulation  
**Inspirations:** Oregon Trail, Trade Wars, Merchant Prince  
**Core Appeal:** Risk/reward progression fantasy with emergent economic gameplay

---

## Core Vision

A text-based (initially) merchant caravan game where players start small and build trading empires through strategic decisions. The world features a blend of realistic medieval economics with fantasy elements (disappearing cities, magical encounters, mythical beasts). Success comes from understanding market dynamics, managing resources, and making calculated risks.

---

## Core Game Loop

1. **Accept Contract/Choose Destination** - Evaluate risk vs. reward
2. **Prepare Journey** - Buy provisions, hire guards, manage cargo
3. **Travel** - Face random encounters, resource management challenges
4. **Arrive & Trade** - Buy low, sell high, exploit market opportunities
5. **Reinvest** - Upgrade wagons, hire crew, expand capacity
6. **Repeat** - Progressive difficulty and opportunities

---

## Progression System

### Tier System (Optional Structure for Players)

Players can pursue **sandbox freeform play** OR follow structured **tier goals**:

#### **Tier 1: "Freelancer"** (Starting State)
- Own 1 wagon
- Visit 5 locations
- Complete 3 contracts
- Earn 500 gold profit
- **Unlock:** Can hire guards, access medium-danger routes

#### **Tier 2: "Merchant"**
- Own 2+ wagons OR upgrade to quality wagon
- Visit 15 locations (including 2 medium-danger)
- Complete 15 contracts OR 3 special contracts
- Earn 2000 gold lifetime OR maintain 1000 gold savings
- **Unlock:** Can join merchant guild, access hidden route rumors, romance options appear

#### **Tier 3: "Caravan Master"**
- Own 3+ wagons OR luxury caravan
- Visit 30 locations (including 5 high-danger)
- Complete 1 legendary contract
- Earn 10,000 gold lifetime OR maintain 3000 savings
- **Unlock:** Can hire champion guards, political contracts available, noble patronage

#### **Tier 4: "Trade Prince"**
- Own 5+ wagons OR own multiple caravan routes
- Visit 50 locations (including all hidden locations)
- Complete 3 legendary contracts
- Earn 50,000 gold lifetime OR control trade monopoly in a region
- **Unlock:** Everything, including end-game content (emperor's favor, magical trade routes, etc.)

### Win Conditions
- **Sandbox Mode:** Play until bored, no formal ending
- **Achievement Mode:** Complete tier goals, unlock ending cutscenes
- **Specific Goals:** Retire with X gold, discover all hidden locations, marry into nobility, etc.

---

## Resource Management

### Four Core Resources

1. **Provisions** - Food for people and animals (consumed daily)
2. **Water** - Water for people and animals (consumed daily)
3. **Gold** - Universal currency for trades and expenses
4. **Cargo Space** - Limited by wagon capacity, animal strength

### Resource Depletion

- **Daily tick** during travel consumes provisions and water
- **Failure states:**
  - No provisions = hunger, HP loss, possible death
  - No water = dehydration, faster HP loss, death
  - No gold + no provisions = stranded (must use WORK command)

---

## Inventory System

### Slot-Based Cargo System

Instead of weight limits, the game uses **slot-based inventory** with stacking rules:

#### **Slot Types:**
1. **Standard Cargo Slots** - Any tradeable commodity (wheat, salt, silk, etc.)
2. **Saddlebag Slots** - BULK goods only (provided by pack animals)
3. **Livestock Slots** - For trading large animals (cattle, horses)
4. **Equipment Slots** - Tools, water barrels, weapons (non-cargo survival items)
5. **Crew Slots** - Hired followers, guards, companions
6. **Animal Slots** - Pack animals that provide additional storage

#### **Stacking Rules:**
- Each slot has a **capacity** (e.g., 100 units of wheat per slot)
- **Partial filling allowed** (can buy 10 wheat in a 100-unit slot)
- **Same commodity stacks** (wheat + wheat = combined)
- **Different commodities don't mix** (wheat + salt = two separate slots)

#### **Storage Type Constraints:**
- **Saddlebag slots:** BULK goods only (grains, salt, basic textiles)
  - *Implementation note: Structural enforcement exists, BUY/SELL validation planned*
- **Livestock slots:** Only living creatures
- **Equipment slots:** Non-tradeable survival gear

---

## Trading Economy

### Commodity Database

**30 commodities** across 7 categories:

1. **Grains:** Wheat, Rice, Barley, Oats
2. **Spices:** Salt, Pepper, Saffron, Cinnamon
3. **Textiles:** Wool, Silk, Cotton, Linen
4. **Metals:** Iron, Copper, Gold, Silver
5. **Luxuries:** Wine, Perfume, Gems, Incense
6. **Livestock:** Chickens, Goats, Cattle, Horses
7. **Tools:** Hammers, Plows, Swords, Shields

Each commodity has:
- **Base price** (foundation for dynamic pricing)
- **Storage requirements** (units per slot)
- **Terrain affinity** (which locations produce it)
- **Rarity level** (common, uncommon, rare, exotic)

### Dynamic Pricing

Prices fluctuate based on:
- **Supply levels** (high stock = lower prices)
- **Demand modifiers** (what locals want)
- **Production bonuses** (terrain produces commodity = cheaper)
- **Market saturation** (recent trades affect prices)

**Formula reference:** See IMPLEMENTATION_NOTES.md <!-- Documented in separate file -->

### Location Economy Structure

Each location has:

```gml
economy: {
    produces: [
        {good_id: "wheat", stock: 500, price_modifier: 0.7}
    ],
    demands: [
        {good_id: "saffron", demand_level: 100, price_modifier: 1.5}
    ],
    discovered_wants: [], // Goods they've learned to value
    last_simulated_day: 0,
    ghost_trade_history: []
}
```

### Ghost Caravan Simulation

Markets evolve even when player isn't present:

**Implementation Note:** Current system runs every frame with random selection (see IMPLEMENTATION_NOTES.md for details). <!-- Documented in separate file -->

**Effects:** 
- Stock levels change dynamically
- Prices shift based on NPC trades
- New goods appear in markets
- Prevents exploitation of single routes

**Future Extension:** Intelligence gathering system to monitor distant markets

---

## Travel System

### Journey Preparation

Players see destination options with:
- **Distance** (in km)
- **Terrain Type** (affects speed and water consumption)
- **Journey Duration** (days based on current caravan speed)
- **Resource Requirements:**
  - Provisions needed
  - Water needed
  - Gold cost (repairs, wages)

### Journey Execution

- **Daily ticks** consume resources
- **Random encounters** (bandits, merchants, weather, magical events)
- **Choices matter** (flee, fight, bribe, negotiate)
- **Failure states** (run out of provisions/water = stranded, must WORK for emergency funds)

### Anti-Exploitation: WORK Command

Emergency income when stranded:
- Provides 30-50 gold per use
- **Cooldown:** 3 days (prevents infinite money)
- **Purpose:** Prevents softlock, not primary income strategy
- Thematic: Odd jobs, manual labor, small trades
- *Can optionally specify days: WORK 3 (implementation detail)*

---

## Combat & Danger (Future Implementation)

### Guard System
- **Quality tiers** (militia, trained, veteran, champion)
- **Cost vs. effectiveness** trade-off
- **Combat as odds** (your guards vs. threat level)

### Threat Types
- **Bandits** - Common, attracted by visible wealth
- **Assassins** - Rare, target high-value/political cargo
- **Monsters** - Fantasy creatures in wilderness
- **Weather** - Storms, sandstorms, blizzards
- **Breakdowns** - Wagon damage, animal injury

### Player Choices During Encounters
- **FLEE** - Success based on speed vs. threat
- **FIGHT** - Odds based on guards vs. enemies
- **BRIBE** - Offer gold to avoid confrontation
- **NEGOTIATE** - Talk your way out (skill/reputation based)

---

## Social & Romance System (Future Implementation)

### Romance Options
- **Trigger:** Appear after reaching Tier 2 (Merchant)
- **Introduction:** Repeated routes, rescued travelers, merchant family alliances
- **Progression:** Meet → Trust → Romance → Marriage
- **Benefits:** Partner manages shop, provides capital, unlocks contracts
- **Flavor:** PG-rated, thematic to setting
- **Gender-neutral:** Options for male/female/non-binary players

### Reputation System
- **Affects:** Encounter frequency, prices, contract availability
- **Built through:** Successful deliveries, helping NPCs, guild membership
- **Consequences:** High reputation = fewer bandit attacks, better contracts
- **Notoriety:** Opposite effect - more danger, worse prices

---

## Political System (Future Implementation)

### Influence Mechanics
- **Guild Memberships** (merchant, thieves, nobility)
- **Political Contracts** (smuggling, espionage, noble escorts)
- **Patronage** (nobles sponsor your ventures for favors)
- **Power Through Commerce** (control trade = political influence)

### End-Game Content
- **Emperor's Favor** - Access to capital city, legendary contracts
- **Magical Trade Routes** - Fantasy elements unlock
- **Legacy** - Children inherit caravan empire

---

## Current Implementation Status

### ✅ Fully Completed Features

**Core Architecture:**
- obj_heartbeat (persistent game orchestrator)
- obj_console (text display with scrolling, mouse wheel support) <!-- Console wrapping documented in IMPLEMENTATION_NOTES.md -->
- obj_input (command processing with history) <!-- History mechanics documented in IMPLEMENTATION_NOTES.md -->
- Player data system (global.player_data struct with nested caravan details)
  - *Note: obj_player deprecated, see Architecture Notes below*

**World Generation:**
- Procedural 30-location world with spatial algorithms
- Minimum spacing constraints (150 units apart)
- Connectivity validation (ensures all locations reachable)
- Terrain-based location types (plains, mountains, desert, forest, coastal)

**Inventory System:**
- Slot-based storage (cargo, livestock, equipment, crew, animals)
- Storage type constraints (saddlebag BULK-only structure exists)
  - *Note: BUY/SELL enforcement planned but not yet active*
- Stacking rules and partial slot usage
- Pack animal saddlebag system <!-- Slot consolidation logic documented in IMPLEMENTATION_NOTES.md -->

**Trading Economy:**
- 30-commodity database with detailed properties
- Dynamic pricing (supply/demand, production bonuses, saturation)
- Location economy generation (produces/demands assignment)
- Ghost caravan NPC simulation (frame-based, see notes) <!-- Documented in IMPLEMENTATION_NOTES.md -->

**Water Management System:**
- Water barrel equipment slots (separate from cargo)
- scr_get_total_water() - Calculate total water across slots
- scr_get_max_water_capacity() - Calculate storage capacity
- scr_consume_water() - Proportional depletion during travel
- scr_refill_water() - Auto-refill at destinations
- Equipment slot architecture prevents accidental water container sales

**Player Commands:**
- HELP (H) - Command reference
- STATUS (ST) - Caravan overview with location details
- TRAVEL (T) - Journey options with resource calculations
- GO (G) <destination> - Execute journey to named location
- MARKET (M) - View buy/sell prices at current location
- BUY (B) <good> <quantity|MAX|ALL> - Purchase commodities
  - Flexible parsing: "BUY wheat 25" OR "BUY 25 wheat"
  - MAX keyword: Auto-calculate maximum affordable quantity
  - ALL keyword: Same as MAX
- SELL (S) <good> <quantity|MAX|ALL> - Sell commodities
  - Flexible parsing: "SELL salt 10" OR "SELL 10 salt"
  - MAX/ALL keywords: Sell entire inventory of commodity
- INVENTORY (I, INV) - Detailed cargo listing with slot breakdown
- WORK (W) [days] - Emergency income with 3-day cooldown
  - Optional days parameter for multi-day work

**Quality of Life:**
- Arrow-up/down for command history navigation <!-- Documented in IMPLEMENTATION_NOTES.md -->
- Console dump debugging (hidden ~ command) <!-- Documented in IMPLEMENTATION_NOTES.md -->
- Flexible command aliases (I, INV, M, T, G, S, B, W, ST, H, Q)
- Smart argument parsing (order-independent commands)

### 🚧 Partially Implemented

**Travel System:**
- Basic journey time calculation ✓
- Resource consumption (water, provisions) ✓
- Random encounters ✗ (planned)
- Event system ✗ (planned)

**Discovery Mechanic:**
- Data structure exists (discovered_wants[] in location.economy) ✓
- Ghost caravan discovery logic ✗ (not yet implemented)
- Status: Structure ready, simulation logic pending

**Storage Type Enforcement:**
- Saddlebag slot structure with allowed_types ✓
- BUY/SELL command validation ✗ (planned)
- Status: Architecture ready, enforcement pending

### ❌ Not Yet Implemented

**Provisions System:**
- Provisions purchasing (scr_buy_provisions exists as placeholder)
- Provisions consumption tracking
- Starvation mechanics

**Contract System:**
- Contract acceptance/tracking
- Timed deliveries with deadlines
- Delivery verification and rewards
- Contract generation system

**Tier Progression:**
- Tier tracking in player data
- Achievement/goal system
- Tier unlock mechanics
- Progress notifications

**Combat & Danger:**
- Guard hiring system
- Combat resolution
- Bandit encounters
- Weather events
- Breakdown mechanics

**Social Systems:**
- Romance options
- Reputation tracking
- NPC relationships

**Political Systems:**
- Guild memberships
- Political contracts
- Influence mechanics

**Advanced Economy:**
- Intelligence gathering (monitor distant markets)
- Price history tracking (PRICES command)
- Discovery event notifications

**Fantasy Elements:**
- Hidden locations (time-gated, quest-locked)
- Magical encounters
- Disappearing cities
- Mythical beasts as animals

---

## Architecture Notes

### Data Structure Decisions

**obj_player Deprecation:**
- **Status:** Legacy object, being phased out
- Originally designed to hold player data
- **Replaced by:** global.player_data struct managed by obj_heartbeat
- **Current state:** Still instantiated in room but unused
- **Future:** May be removed or repurposed
- **Rationale:** Modern GameMaker best practice (structs > DS maps), centralized management

**Global Data Architecture:**
Primary data managed by obj_heartbeat:
- `global.commodity_db` - Master commodity database
- `global.world[]` - Array of location structs (30 locations)
- `global.player_data` - Player/caravan state with nested structs

**Why Global Structs?**
- Modern GameMaker best practice (faster than DS maps)
- Cleaner syntax with named fields
- Better for nested data (economy, inventory)
- Easier debugging and serialization

### Equipment vs. Cargo Separation

**Design Decision:** Water barrels stored in equipment slots, not cargo slots

**Rationale:**
- Prevents accidental selling of survival gear
- Clear mental model separation (equipment = survival, cargo = trade)
- Easier capacity calculations
- Matches real-world understanding
- See IMPLEMENTATION_NOTES.md for architectural details <!-- Documented in separate file -->

---

## Known Issues & TODOs

### High Priority
- [ ] Implement random encounter system during travel
- [ ] Add contract system (timed deliveries with deadlines)
- [ ] Complete provisions purchasing (scr_buy_provisions is placeholder)
- [ ] Implement guard hiring and combat resolution

### Medium Priority
- [ ] Add price history tracking (PRICES command)
- [ ] Create discovery event notifications (when cities learn to want goods)
- [ ] Implement weather effects on travel
- [ ] Add breakdown/repair mechanics
- [ ] Complete storage type enforcement in BUY/SELL commands

### Low Priority
- [ ] Romance system implementation
- [ ] Guild membership mechanics
- [ ] Hidden location discovery system
- [ ] Legendary contracts
- [ ] Tier progression tracking

### Technical Debt
- [ ] Remove or repurpose obj_player (deprecated)
- [ ] Add save/load game functionality
- [ ] Optimize ghost caravan simulation (currently every frame)
- [ ] Document script formulas (see tracking in IMPLEMENTATION_NOTES.md)

---

## Design Decisions & Rationale

### Why Slot-Based Inventory?
**Decision:** Use fixed slots with stacking rules rather than weight-based  
**Rationale:** Creates interesting inventory puzzles, prevents "bag of holding" syndrome, forces meaningful choices about what to carry

### Why Partial Slot Usage?
**Decision:** Allow buying 10 salt in a 50-unit barrel  
**Rationale:** Enables "buy low, sell high" for poor players, creates more strategic options, doesn't punish players who can't afford full slots

### Why Ghost Caravans?
**Decision:** Simulate NPC trading when player isn't present  
**Rationale:** Prevents single-route exploitation, creates realistic economy, adds unpredictability, rewards exploration  
**Implementation:** Frame-based random selection (see IMPLEMENTATION_NOTES.md) <!-- Documented in separate file -->

### Why Work Command Cooldown?
**Decision:** 3-day cooldown on emergency income  
**Rationale:** Prevents infinite money exploit while avoiding softlock (players stuck with no provisions)

### Why Tier System Is Optional?
**Decision:** Allow both sandbox and structured progression  
**Rationale:** Appeals to both "I want goals" and "I want freedom" player types, doesn't force playstyle

### Why Text-Based First?
**Decision:** Start with text interface before adding graphics  
**Rationale:** Faster iteration, focuses on mechanics over presentation, allows testing core gameplay loop, easier to prototype complex systems

### Why Flexible Command Parsing?
**Decision:** Accept "BUY wheat 25" AND "BUY 25 wheat"  
**Rationale:** Natural language flexibility reduces player frustration, discovered during implementation testing  
**Note:** See IMPLEMENTATION_NOTES.md for parsing details <!-- Documented in separate file -->

---

## Future Expansion Ideas

### Short-Term (Next 2-3 Months)
- Contract delivery system with deadlines
- Guard hiring and basic combat
- Weather effects on travel
- More wagon types (requiring draft animals)
- Price history tracking
- Complete provisions system

### Medium-Term (3-6 Months)
- Hidden location discovery
- Romance system basics
- Guild membership
- Reputation tracking
- Special cargo types (living creatures, artifacts)

### Long-Term (6+ Months)
- Political influence system
- Multiple caravan management
- Magical encounters and fantasy elements
- Disappearing cities mechanic
- Legendary contracts and end-game content
- GUI implementation (transition from text to visual)

### Dream Features (If Development Continues)
- Multiplayer trading (shared world, player-to-player trades)
- Mod support (custom commodities, locations, events)
- Dynasty mode (children inherit empire)
- Caravan customization (paint schemes, banners, reputation symbols)
- Voice acting for key events
- Animated encounters (still images with text)

---

## Target Audience

**Primary:** Players who enjoy:
- Oregon Trail-style resource management
- Trading/merchant simulation (Patrician, Port Royale)
- Progressive systems (start small, build empire)
- Risk/reward decision making
- Text-based RPGs (Zork, Anchorhead)

**Secondary:** Players who enjoy:
- Incremental/idle games (but more active)
- Roguelike permadeath challenges
- Fantasy worldbuilding
- Economic simulation

---

## Inspirational References

**Games:**
- **Oregon Trail** - Resource management, journey tension
- **Trade Wars** - Economic simulation, trade routes
- **Merchant Prince (Machiavelli)** - Political trading
- **King of Dragon Pass** - Event-driven narrative with choices
- **FTL: Faster Than Light** - Roguelike progression, meaningful encounters
- **Sunless Sea** - Narrative exploration with resource management

**Literature:**
- **Steven R. Donaldson - The One Tree** - Powerful caravan master concept
- **Medieval trade routes** - Historical inspiration for goods and routes

---

## Development Philosophy

### Core Principles
1. **Systems over content** - Build robust, reusable systems
2. **Emergent gameplay** - Let player decisions create stories
3. **No arbitrary restrictions** - If player can't do something, there should be a thematic reason
4. **Progressive complexity** - Simple to learn, deep to master
5. **Respect player time** - No grind, just meaningful choices

### Anti-Patterns to Avoid
- ❌ Soft-locks (always provide escape valve)
- ❌ Excessive RNG without player agency
- ❌ Punishing experimentation
- ❌ Hidden information that should be visible
- ❌ Grinding as substitute for gameplay

### Quality Standards
- Every system should be fun in isolation
- Every command should have clear feedback
- Every choice should have meaningful consequences
- Every failure should teach the player something

---

## Version History

**v0.1** - Core Architecture (Dec 2025)
- Basic command system
- World generation
- Player data structure

**v0.2** - Trading Economy (Jan 2026)
- Commodity database
- Dynamic pricing
- Ghost caravan simulation
- Market commands (BUY/SELL)

**v0.3** - Inventory & Water Systems (Jan 2026)
- Slot-based storage
- Stacking rules
- Pack animal saddlebags
- Partial slot usage
- Water management system (equipment slots)
- MAX/ALL command keywords
- Flexible argument parsing

**Current:** v0.3 (In Development)

---

## Credits & Acknowledgments

**Developer:** John (hoffe)  
**Engine:** GameMaker Studio 2024.14.2.213  
**Development Start:** December 2025  
**Project Location:** C:\Users\hoffe\GameMakerProjects\Caravan

**Special Thanks:**
- ChatGPT & Claude (AI design consultants)
- Oregon Trail (inspiration)
- All the classic merchant sims that came before

---

*Last Updated: January 17, 2026*
*Companion Documentation: IMPLEMENTATION_NOTES.md*