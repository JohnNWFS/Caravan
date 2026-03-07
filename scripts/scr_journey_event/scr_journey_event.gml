/// @func scr_journey_event(costs)
/// @desc Roll for a random journey event and return an event struct, or undefined.
///       Events resolve automatically — no YES/NO prompt required.
///       The caller (scr_begin_journey) applies the deltas and prints the report.
///
/// @param {Struct} costs  The travel cost struct from scr_calculate_travel_cost
/// @return {Struct|undefined}  Event struct or undefined if no event this trip
///
/// Event struct fields:
///   type        {String}  — "BANDIT", "STORM", "DESERT_HEAT", "BREAKDOWN",
///                           "SHORTCUT", "FAIR_WEATHER", "DISCOVERY"
///   title       {String}  — Short header line  (e.g. "Bandit Ambush")
///   narrative   {String}  — One-sentence description of what happened
///   gold_delta  {Real}    — Gold change (negative = loss; already clamped to available gold)
///   prov_delta  {Real}    — Provision change (negative = consumed; clamped to available)
///   cond_delta  {Real}    — Wagon condition change applied to every wagon (clamped 0–100)
///   rep_delta   {Real}    — Reputation change

function scr_journey_event(costs) {

    // -----------------------------------------------------------------------
    // 1. BASE CHANCE (per terrain) + DISTANCE SCALING
    // -----------------------------------------------------------------------
    var _base = 0;
    switch (costs.terrain) {
        case "ROAD":     _base =  5;  break;
        case "PLAINS":   _base = 12;  break;
        case "FOREST":   _base = 18;  break;
        case "HILLS":    _base = 22;  break;
        case "MOUNTAIN": _base = 28;  break;
        case "DESERT":   _base = 20;  break;
        default:         _base = 10;  break;
    }

    // Longer journeys = more chances for something to happen (capped at 65 %)
    var _chance = min(65, _base + costs.days * 2);

    // Debug override: capture forced type now; clears itself so it fires only once
    var _forced_event = "";
    if (variable_struct_exists(obj_heartbeat, "debug_force_event")
            && obj_heartbeat.debug_force_event != "") {
        _forced_event = obj_heartbeat.debug_force_event;
        obj_heartbeat.debug_force_event = "";
    }

    if (_forced_event == "" && irandom(99) >= _chance) return undefined;  // No event this trip

    // -----------------------------------------------------------------------
    // 2. BUILD WEIGHTED EVENT POOL (based on terrain + caravan state)
    // -----------------------------------------------------------------------
    var _pool = [];
    var _ter  = costs.terrain;

    // Bandit attacks: wilderness terrains
    if (_ter == "MOUNTAIN" || _ter == "HILLS" || _ter == "FOREST") {
        array_push(_pool, "BANDIT");
        array_push(_pool, "BANDIT");  // Double weight — most common threat here
    }

    // Severe weather: open or harsh terrain
    if (_ter == "PLAINS" || _ter == "DESERT") {
        array_push(_pool, "STORM");
        array_push(_pool, "STORM");
    }
    if (_ter == "FOREST") {
        array_push(_pool, "STORM");   // Rain in the forest
    }

    // Desert heat: desert only
    if (_ter == "DESERT") {
        array_push(_pool, "DESERT_HEAT");
    }

    // Wagon breakdown: any terrain; weighted up when condition is low
    var _min_cond = 100;
    for (var _wi = 0; _wi < array_length(obj_player.caravan.wagons); _wi++) {
        _min_cond = min(_min_cond, obj_player.caravan.wagons[_wi].condition);
    }
    if (_min_cond < 40) {
        array_push(_pool, "BREAKDOWN");
        array_push(_pool, "BREAKDOWN");  // Heavily weighted for damaged caravans
        array_push(_pool, "BREAKDOWN");
    } else if (_min_cond < 60) {
        array_push(_pool, "BREAKDOWN");
    }

    // Shortcut: wilderness with passable paths
    if (_ter == "FOREST" || _ter == "HILLS" || _ter == "PLAINS") {
        array_push(_pool, "SHORTCUT");
        // Navigator doubles shortcut odds on wilderness routes
        var _has_nav = false;
        if (variable_struct_exists(obj_player, "hired_crew")) {
            for (var _nvi = 0; _nvi < array_length(obj_player.hired_crew); _nvi++) {
                if (obj_player.hired_crew[_nvi].type == "NAVIGATOR") { _has_nav = true; break; }
            }
        }
        if (_has_nav) array_push(_pool, "SHORTCUT");
    }

    // Favorable conditions: open, road terrain
    if (_ter == "ROAD" || _ter == "PLAINS") {
        array_push(_pool, "FAIR_WEATHER");
        array_push(_pool, "FAIR_WEATHER");
    }

    // Lucky discovery: any terrain (low weight — one entry)
    array_push(_pool, "DISCOVERY");

    // Dragon sighting: mountain and hills (dangerous without protection)
    if (_ter == "MOUNTAIN" || _ter == "HILLS") {
        array_push(_pool, "DRAGON_SIGHTING");
    }

    // Arcane storm: any terrain (magical wild card — one entry)
    array_push(_pool, "ARCANE_STORM");

    // Wandering mage: any terrain (beneficial — low weight, one entry)
    array_push(_pool, "WANDERING_MAGE");

    // Fae crossroads: forest and hills (chaotic 50/50)
    if (_ter == "FOREST" || _ter == "HILLS") {
        array_push(_pool, "FAE_CROSSROADS");
    }

    // Witch's curse: forest and mountain
    if (_ter == "FOREST" || _ter == "MOUNTAIN") {
        array_push(_pool, "WITCH_CURSE");
    }

    if (array_length(_pool) == 0) return undefined;

    // -----------------------------------------------------------------------
    // 3. PICK EVENT TYPE
    // -----------------------------------------------------------------------
    var _type = _pool[irandom(array_length(_pool) - 1)];
    if (_forced_event != "") _type = _forced_event;  // debug override wins

    // -----------------------------------------------------------------------
    // 4. BUILD EVENT RESULT STRUCT
    // -----------------------------------------------------------------------
    var _gold_avail = obj_player.gold;
    var _prov_avail = obj_player.provisions;

    switch (_type) {

        // -------------------------------------------------------------------
        case "BANDIT":
        // -------------------------------------------------------------------
        {
            var _lost = clamp(irandom_range(25, 65), 0, _gold_avail);

            // Check for crew modifiers
            var _has_guard = false;
            var _has_merc  = false;
            if (variable_struct_exists(obj_player, "hired_crew")) {
                for (var _gi = 0; _gi < array_length(obj_player.hired_crew); _gi++) {
                    var _ctype = obj_player.hired_crew[_gi].type;
                    if (_ctype == "GUARD")               _has_guard = true;
                    if (_ctype == "MERCENARY_CAPTAIN")   _has_merc  = true;
                }
            }

            // Mercenary captain: 60% chance to deter the ambush outright
            if (_has_merc && irandom(99) < 60) {
                var _det_titles = [
                    "Bandits Driven Off",
                    "Ambush Foiled",
                    "No Quarter Asked"
                ];
                var _det_lines = [
                    "Your mercenary captain spotted the ambush early and rallied the caravan. The bandits fled without a fight.",
                    "The mercenary captain's stern reputation preceded the caravan. The outlaws thought better of it and melted back into the " + ((_ter == "ROAD") ? "shadows." : (string_lower(_ter) + ".")),
                    "A show of force from your mercenary captain sent the bandits packing before a single coin was demanded."
                ];
                return {
                    type:       "BANDIT",
                    title:      _det_titles[irandom(array_length(_det_titles) - 1)],
                    narrative:  _det_lines[irandom(array_length(_det_lines) - 1)],
                    gold_delta: 0,
                    prov_delta: 0,
                    cond_delta: 0,
                    rep_delta:  1
                };
            }

            // Mercenary captain (40% path) or guard both halve the loss
            if (_has_merc)  _lost = max(0, floor(_lost * 0.5));
            if (_has_guard) _lost = max(0, floor(_lost * 0.5));

            var _titles = [
                "Bandit Ambush",
                "Highway Robbery",
                "Outlaws on the Road"
            ];
            var _lines = [
                "A gang of outlaws blocked the pass. After tense negotiations, the caravan paid " + string(_lost) + " gold to continue unmolested.",
                "Armed bandits sprang from cover demanding tribute. " + string(_lost) + " gold changed hands before the caravan was allowed through.",
                "The caravan was ambushed on the " + ((_ter == "ROAD") ? "road" : (string_lower(_ter) + " road")) + ". " + string(_lost) + " gold in goods was surrendered to avoid a fight."
            ];
            if (_has_guard) {
                array_push(_titles, "Bandit Attack Repelled");
                array_push(_lines, "Bandits ambushed the caravan, but your guard drove them off. Only " + string(_lost) + " gold was lost in the skirmish.");
                array_push(_lines, "Your guard spotted the ambush early and the caravan was ready. The outlaws were repelled; only " + string(_lost) + " gold changed hands.");
            }
            if (_has_merc) {
                array_push(_titles, "Bandit Attack Blunted");
                array_push(_lines, "Your mercenary captain held the line long enough for the caravan to push through. Only " + string(_lost) + " gold was lost.");
                array_push(_lines, "The outlaws weren't deterred, but your mercenary captain's intervention limited the damage to " + string(_lost) + " gold.");
            }
            return {
                type:       "BANDIT",
                title:      _titles[irandom(array_length(_titles) - 1)],
                narrative:  _lines[irandom(array_length(_lines) - 1)],
                gold_delta: -_lost,
                prov_delta: 0,
                cond_delta: -6,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "STORM":
        // -------------------------------------------------------------------
        {
            var _prov_lost = min(irandom_range(8, 20), _prov_avail);
            var _cond_hit  = irandom_range(5, 12);
            var _titles2 = [
                "Violent Storm",
                "Flash Flood",
                "Driving Rain"
            ];
            var _lines2 = [
                "A violent storm caught the caravan on the open " + string_lower(_ter) + ". Animals struggled against the wind and " + string(_prov_lost) + " provisions were ruined by water.",
                "Flash floods turned the road to mud. Progress was slow and " + string(_prov_lost) + " provisions were spoiled.",
                "Persistent rain soaked the caravan for most of the journey, fouling " + string(_prov_lost) + " provisions and grinding the axles raw."
            ];
            return {
                type:       "STORM",
                title:      _titles2[irandom(array_length(_titles2) - 1)],
                narrative:  _lines2[irandom(array_length(_lines2) - 1)],
                gold_delta: 0,
                prov_delta: -_prov_lost,
                cond_delta: -_cond_hit,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "DESERT_HEAT":
        // -------------------------------------------------------------------
        {
            var _prov_lost2 = min(irandom_range(5, 15), _prov_avail);
            return {
                type:       "DESERT_HEAT",
                title:      "Punishing Heat",
                narrative:  "The desert heat was relentless. Water and provisions disappeared faster than expected, and wagon timber cracked in the dry air.",
                gold_delta: 0,
                prov_delta: -_prov_lost2,
                cond_delta: -8,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "BREAKDOWN":
        // -------------------------------------------------------------------
        {
            var _cond_hit2  = irandom_range(10, 20);
            var _prov_hit   = min(irandom_range(3, 8), _prov_avail);
            var _break_t = [
                "Wagon Breakdown",
                "Axle Failure",
                "Wheel Collapse"
            ];
            var _break_l = [
                "A wheel gave way on the roughest section of road. Makeshift repairs took half a day and consumed " + string(_prov_hit) + " provisions.",
                "An axle cracked under the load on the " + string_lower(_ter) + ". Emergency repairs kept the caravan moving but left it worse for wear.",
                "One wagon's front wheel buckled on a rocky stretch. The delay cost " + string(_prov_hit) + " provisions and left the wagon in poor shape."
            ];
            return {
                type:       "BREAKDOWN",
                title:      _break_t[irandom(array_length(_break_t) - 1)],
                narrative:  _break_l[irandom(array_length(_break_l) - 1)],
                gold_delta: 0,
                prov_delta: -_prov_hit,
                cond_delta: -_cond_hit2,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "SHORTCUT":
        // -------------------------------------------------------------------
        {
            var _prov_saved = irandom_range(5, 12);
            var _short_t = [
                "Hidden Path Found",
                "Scout's Discovery",
                "Shepherd's Tip"
            ];
            var _short_l = [
                "The caravan's lead scout found a lesser-known trail that cut the journey short and saved " + string(_prov_saved) + " provisions.",
                "A local shepherd pointed out a shortcut through the " + string_lower(_ter) + ". The caravan arrived ahead of schedule, " + string(_prov_saved) + " provisions to the good.",
                "An overgrown but passable path was found through the terrain, saving time and " + string(_prov_saved) + " provisions."
            ];
            return {
                type:       "SHORTCUT",
                title:      _short_t[irandom(array_length(_short_t) - 1)],
                narrative:  _short_l[irandom(array_length(_short_l) - 1)],
                gold_delta: 0,
                prov_delta: _prov_saved,
                cond_delta: 0,
                rep_delta:  1
            };
        }

        // -------------------------------------------------------------------
        case "FAIR_WEATHER":
        // -------------------------------------------------------------------
        {
            var _prov_saved2 = irandom_range(3, 8);
            var _fair_t = [
                "Favorable Conditions",
                "Clear Skies",
                "Tailwind"
            ];
            var _fair_l = [
                "Clear skies and a gentle tailwind made for excellent travel, conserving " + string(_prov_saved2) + " provisions.",
                "Perfect traveling weather let the animals move at an easy pace, saving " + string(_prov_saved2) + " provisions.",
                "A welcome tailwind pushed the caravan along. Animals and crew arrived fresher than usual, " + string(_prov_saved2) + " provisions to spare."
            ];
            return {
                type:       "FAIR_WEATHER",
                title:      _fair_t[irandom(array_length(_fair_t) - 1)],
                narrative:  _fair_l[irandom(array_length(_fair_l) - 1)],
                gold_delta: 0,
                prov_delta: _prov_saved2,
                cond_delta: 2,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "DISCOVERY":
        // -------------------------------------------------------------------
        {
            var _gold_found = irandom_range(15, 50);
            var _disc_t = [
                "Abandoned Cache",
                "Merchant's Loss",
                "Lucky Find"
            ];
            var _disc_l = [
                "Scouts found an abandoned pack beside the road. After checking for any owner, " + string(_gold_found) + " gold in salvageable goods was recovered.",
                "A wrecked merchant's handcart lay abandoned by the roadside. The caravan recovered " + string(_gold_found) + " gold in undamaged goods.",
                "A sealed chest lay half-buried at a crossroads. Finders keepers — " + string(_gold_found) + " gold added to the treasury."
            ];
            return {
                type:       "DISCOVERY",
                title:      _disc_t[irandom(array_length(_disc_t) - 1)],
                narrative:  _disc_l[irandom(array_length(_disc_l) - 1)],
                gold_delta: _gold_found,
                prov_delta: 0,
                cond_delta: 0,
                rep_delta:  1
            };
        }

        // -------------------------------------------------------------------
        case "DRAGON_SIGHTING":
        // -------------------------------------------------------------------
        {
            // Check for a protector (guard, mercenary captain, or hedge witch keeps animals calm)
            var _has_protector = false;
            if (variable_struct_exists(obj_player, "hired_crew")) {
                for (var _pi = 0; _pi < array_length(obj_player.hired_crew); _pi++) {
                    var _pt = obj_player.hired_crew[_pi].type;
                    if (_pt == "GUARD" || _pt == "MERCENARY_CAPTAIN" || _pt == "HEDGE_WITCH") {
                        _has_protector = true;
                        break;
                    }
                }
            }

            if (_has_protector) {
                var _drag_t_p = ["Dragon Sighting", "Wyrm on the Wing", "Dragon Overhead"];
                var _drag_l_p = [
                    "A great shadow passed over the caravan — a dragon circling high above. Your crew kept the animals calm and the beast moved on without incident. The crew counted themselves lucky.",
                    "A winged wyrm descended toward the road, but the caravan held its nerve. It veered off without incident. The story will be told for years.",
                    "The distant roar of a dragon sent animals skittering — but your protector steadied them before panic set in. A remarkable sight, and everyone lived to tell of it."
                ];
                return {
                    type:       "DRAGON_SIGHTING",
                    title:      _drag_t_p[irandom(array_length(_drag_t_p) - 1)],
                    narrative:  _drag_l_p[irandom(array_length(_drag_l_p) - 1)],
                    gold_delta: 0,
                    prov_delta: 0,
                    cond_delta: 0,
                    rep_delta:  2
                };
            } else {
                var _drag_prov = min(irandom_range(5, 12), _prov_avail);
                var _drag_t = ["Dragon Sighting", "Wyrm on the Wing", "Panic on the Road"];
                var _drag_l = [
                    "A dragon swooped low over the caravan, scattering animals in all directions. It cost precious time and " + string(_drag_prov) + " provisions to collect everything and calm the herd.",
                    "The shadow of a great wyrm fell over the road. Animals bolted and " + string(_drag_prov) + " provisions were lost in the chaos before the caravan could regroup.",
                    "A winged beast the size of a barn circled overhead. The caravan's animals panicked — " + string(_drag_prov) + " provisions lost and the wagons took a battering before order was restored."
                ];
                return {
                    type:       "DRAGON_SIGHTING",
                    title:      _drag_t[irandom(array_length(_drag_t) - 1)],
                    narrative:  _drag_l[irandom(array_length(_drag_l) - 1)],
                    gold_delta: 0,
                    prov_delta: -_drag_prov,
                    cond_delta: -10,
                    rep_delta:  0
                };
            }
        }

        // -------------------------------------------------------------------
        case "ARCANE_STORM":
        // -------------------------------------------------------------------
        {
            var _has_witch = false;
            if (variable_struct_exists(obj_player, "hired_crew")) {
                for (var _awi = 0; _awi < array_length(obj_player.hired_crew); _awi++) {
                    if (obj_player.hired_crew[_awi].type == "HEDGE_WITCH") {
                        _has_witch = true;
                        break;
                    }
                }
            }

            // Chaotic magical effects: gold can go either way
            var _arc_gold = (irandom(1) == 0)
                          ? irandom_range(10, 40)
                          : -min(irandom_range(10, 40), _gold_avail);
            var _arc_prov = -min(irandom_range(5, 15), _prov_avail);
            var _arc_cond = -irandom_range(5, 12);

            if (_has_witch) {
                // Hedge witch halves all bad effects
                _arc_gold = (_arc_gold < 0) ? ceil(_arc_gold * 0.5) : _arc_gold;
                _arc_prov = ceil(_arc_prov * 0.5);
                _arc_cond = ceil(_arc_cond * 0.5);
            }

            var _arc_t = ["Arcane Storm", "Ether Tempest", "Magical Squall"];
            var _arc_l = [
                "An unnatural storm crackled with arcane energy across the " + string_lower(_ter) + ". Goods shifted, animals spooked, and the air smelled of ozone and strange magic.",
                "Purple lightning split the sky as a ley-line storm swept over the road. The caravan weathered it, but nothing came through unscathed.",
                "A wave of magical disturbance rolled through the region — compasses spun, coins rattled, and animals refused to move for an hour."
            ];
            if (_has_witch) {
                array_push(_arc_t, "Storm Warded");
                array_push(_arc_l, "An arcane tempest brewed on the horizon — but your hedge witch read the signs and prepared wards. The worst of the storm passed around the caravan.");
            }
            return {
                type:       "ARCANE_STORM",
                title:      _arc_t[irandom(array_length(_arc_t) - 1)],
                narrative:  _arc_l[irandom(array_length(_arc_l) - 1)],
                gold_delta: _arc_gold,
                prov_delta: _arc_prov,
                cond_delta: _arc_cond,
                rep_delta:  0
            };
        }

        // -------------------------------------------------------------------
        case "WANDERING_MAGE":
        // -------------------------------------------------------------------
        {
            // Roll which boon the mage offers: 0=repair wagons, 1=gold, 2=reputation
            var _mage_boon = irandom(2);
            var _mag_t = ["Wandering Mage", "Road Sorcerer", "Itinerant Wizard"];

            if (_mage_boon == 0) {
                var _mag_l = [
                    "A robed figure flagged the caravan down and offered their services for a meal — the wagons came away repaired and in better shape than when the journey began.",
                    "An elderly mage on the road traded wagon repairs for good company. The caravan's wheels and axles are better than they've been in weeks.",
                    "A wandering sorcerer mended cracked axles and re-tempered iron fittings with a wave of the hand, asking only safe passage to the next town."
                ];
                return {
                    type:       "WANDERING_MAGE",
                    title:      _mag_t[irandom(array_length(_mag_t) - 1)],
                    narrative:  _mag_l[irandom(array_length(_mag_l) - 1)],
                    gold_delta: 0,
                    prov_delta: 0,
                    cond_delta: 15,
                    rep_delta:  0
                };
            } else if (_mage_boon == 1) {
                var _mag_gold = irandom_range(20, 50);
                var _mag_l2 = [
                    "A wandering mage offered a handful of enchanted coins in exchange for a ride to the next village. The coins were legitimate — " + string(_mag_gold) + " gold richer.",
                    "An itinerant wizard paid handsomely (" + string(_mag_gold) + " gold) for the caravan to carry a sealed chest, asking no questions.",
                    "A road-weary sorcerer traded a pouch of spell-infused dust that local merchants bought eagerly for " + string(_mag_gold) + " gold."
                ];
                return {
                    type:       "WANDERING_MAGE",
                    title:      _mag_t[irandom(array_length(_mag_t) - 1)],
                    narrative:  _mag_l2[irandom(array_length(_mag_l2) - 1)],
                    gold_delta: _mag_gold,
                    prov_delta: 0,
                    cond_delta: 0,
                    rep_delta:  0
                };
            } else {
                var _mag_l3 = [
                    "A wandering mage rode with the caravan for a day, sharing tales of distant lands. Word of the encounter spread; the caravan's reputation grew.",
                    "An itinerant wizard offered a public blessing at the next waypoint, drawing a crowd. The caravan's name was spoken well in the region.",
                    "A road sorcerer shared fire and food with the crew. Their tales of the merchants' generosity preceded the caravan into the next city."
                ];
                return {
                    type:       "WANDERING_MAGE",
                    title:      _mag_t[irandom(array_length(_mag_t) - 1)],
                    narrative:  _mag_l3[irandom(array_length(_mag_l3) - 1)],
                    gold_delta: 0,
                    prov_delta: 0,
                    cond_delta: 0,
                    rep_delta:  2
                };
            }
        }

        // -------------------------------------------------------------------
        case "FAE_CROSSROADS":
        // -------------------------------------------------------------------
        {
            var _fae_t = ["Fae Crossroads", "Fairy Path", "Strange Junction"];
            if (irandom(1) == 0) {
                // Bad luck — time slips, lose provisions
                var _fae_prov_lost = min(irandom_range(8, 18), _prov_avail);
                var _fae_l = [
                    "The caravan stumbled onto a faerie crossroads at dusk. Time seemed to slip sideways — the crew arrived a day later than expected, " + string(_fae_prov_lost) + " provisions lighter.",
                    "An eerie stillness fell at a crossroads ringed with pale stones. When the caravan shook free, a day had passed that nobody could account for.",
                    "Strange lights lured part of the crew off the road. It cost a day to find everyone and " + string(_fae_prov_lost) + " provisions to settle their nerves."
                ];
                return {
                    type:       "FAE_CROSSROADS",
                    title:      _fae_t[irandom(array_length(_fae_t) - 1)],
                    narrative:  _fae_l[irandom(array_length(_fae_l) - 1)],
                    gold_delta: 0,
                    prov_delta: -_fae_prov_lost,
                    cond_delta: 0,
                    rep_delta:  0
                };
            } else {
                // Good luck — shortcut, gain provisions
                var _fae_prov_saved = irandom_range(8, 18);
                var _fae_l2 = [
                    "A fork appeared in the road where none had been before. Following a hunch, the caravan took it — arriving ahead of schedule, " + string(_fae_prov_saved) + " provisions to the good.",
                    "Tiny lights danced along an overgrown path at a crossroads. The crew followed them and found a shortcut, saving " + string(_fae_prov_saved) + " provisions.",
                    "At a mossy crossroads, a child pointed to a path on no map. It led straight to the destination — " + string(_fae_prov_saved) + " provisions saved and the crew full of wonder."
                ];
                return {
                    type:       "FAE_CROSSROADS",
                    title:      _fae_t[irandom(array_length(_fae_t) - 1)],
                    narrative:  _fae_l2[irandom(array_length(_fae_l2) - 1)],
                    gold_delta: 0,
                    prov_delta: _fae_prov_saved,
                    cond_delta: 0,
                    rep_delta:  1
                };
            }
        }

        // -------------------------------------------------------------------
        case "WITCH_CURSE":
        // -------------------------------------------------------------------
        {
            var _has_witch2 = false;
            if (variable_struct_exists(obj_player, "hired_crew")) {
                for (var _wi3 = 0; _wi3 < array_length(obj_player.hired_crew); _wi3++) {
                    if (obj_player.hired_crew[_wi3].type == "HEDGE_WITCH") {
                        _has_witch2 = true;
                        break;
                    }
                }
            }

            if (_has_witch2) {
                var _curse_t_w = ["Curse Deflected", "Hex Warded Off", "Witch's Work"];
                var _curse_l_w = [
                    "A hex marker was hidden on the road — your hedge witch spotted it and dismantled it before the caravan passed through. A crisis averted entirely.",
                    "Something dark was laid across the caravan's path. Your hedge witch neutralized it with practiced ease, leaving not so much as a spoiled crust of bread.",
                    "A malevolent charm had been placed at the crossroads ahead. Your hedge witch sensed it from a mile off and broke it. The caravan passed through without incident."
                ];
                return {
                    type:       "WITCH_CURSE",
                    title:      _curse_t_w[irandom(array_length(_curse_t_w) - 1)],
                    narrative:  _curse_l_w[irandom(array_length(_curse_l_w) - 1)],
                    gold_delta: 0,
                    prov_delta: 0,
                    cond_delta: 0,
                    rep_delta:  0
                };
            } else {
                var _curse_prov = min(irandom_range(15, 25), _prov_avail);
                var _curse_t = ["Witch's Curse", "Hex on the Road", "Spoiled Goods"];
                var _curse_l = [
                    "A hex marker hidden in the road went unnoticed. By morning, " + string(_curse_prov) + " provisions had inexplicably spoiled and the wagon timbers had warped.",
                    "A curse seemed to follow the caravan through the " + string_lower(_ter) + ". Provisions rotted overnight and the wagon groaned far worse than the terrain warranted.",
                    "Something malevolent was at work on the road. " + string(_curse_prov) + " provisions turned foul by dawn, and the wagons took mysterious damage that no inspection could explain."
                ];
                return {
                    type:       "WITCH_CURSE",
                    title:      _curse_t[irandom(array_length(_curse_t) - 1)],
                    narrative:  _curse_l[irandom(array_length(_curse_l) - 1)],
                    gold_delta: 0,
                    prov_delta: -_curse_prov,
                    cond_delta: -10,
                    rep_delta:  0
                };
            }
        }
    }

    return undefined;
}
