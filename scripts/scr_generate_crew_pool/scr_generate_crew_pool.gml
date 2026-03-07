/// @func scr_generate_crew_pool(location)
/// @desc Generate 3 crew members (one of each type) available for hire at a city.
///       The list refreshes every 7 days to simulate turnover.
///       Results stored on the location struct as:
///         location.available_crew  — array of crew structs
///         location.crew_pool_day   — day the pool was last generated

function scr_generate_crew_pool(location) {

    var _names = [
        "Roland", "Mira",   "Cade",   "Petra",  "Finn",
        "Lena",   "Bram",   "Sasha",  "Tomas",  "Anya",
        "Keel",   "Nora",   "Davan",  "Ilse",   "Cort",
        "Vesper", "Oryn",   "Thalia", "Rusk",   "Elara"
    ];

    // Full roster — city shows 3 random from this pool each refresh
    var _crew_defs = [
        {
            type: "GUARD",
            wage: 8,
            desc: "Halves losses from bandit ambushes."
        },
        {
            type: "DRIVER",
            wage: 6,
            desc: "Cuts travel time by roughly 15%."
        },
        {
            type: "TRADER",
            wage: 10,
            desc: "Improves buy and sell prices by 10%."
        },
        {
            type: "HEDGE_WITCH",
            wage: 9,
            desc: "Uses 20% fewer provisions per journey. Wards off curses and arcane storms."
        },
        {
            type: "MERCENARY_CAPTAIN",
            wage: 14,
            desc: "60% chance to deter bandits outright; otherwise halves losses."
        },
        {
            type: "NAVIGATOR",
            wage: 7,
            desc: "Cuts travel time by ~10%. Improves shortcut odds on wilderness routes."
        },
        {
            type: "ALCHEMIST",
            wage: 11,
            desc: "25% chance each journey to produce a rare alchemical trade good."
        }
    ];

    // Fisher-Yates shuffle of all indices, then take first 3
    var _n   = array_length(_crew_defs);
    var _idx = [];
    for (var _k = 0; _k < _n; _k++) { array_push(_idx, _k); }
    for (var _i = _n - 1; _i > 0; _i--) {
        var _j    = irandom(_i);
        var _tmp  = _idx[_i];
        _idx[_i]  = _idx[_j];
        _idx[_j]  = _tmp;
    }

    location.available_crew = [];
    location.crew_pool_day  = obj_heartbeat.day;

    for (var _i = 0; _i < 3; _i++) {
        var _def  = _crew_defs[_idx[_i]];
        var _name = _names[irandom(array_length(_names) - 1)];
        array_push(location.available_crew, {
            name: _name,
            type: _def.type,
            wage: _def.wage,
            desc: _def.desc
        });
    }
}
