// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Display the end-of-run summary screen for JOURNEY mode.
///       Shows final gold, rank title, rival standings, and a flavour quote.
///       Called from scr_begin_journey when journey_count reaches journey_limit.
///       Sets game_state to "GAMEOVER" before returning.

function scr_show_end_screen() {

    var _gold  = obj_player.gold;
    var _days  = obj_heartbeat.day;
    var _trips = obj_heartbeat.journey_count; // already incremented by caller

    // ----------------------------------------------------------------
    // Rank title
    // ----------------------------------------------------------------
    var _rank = "Humble Peddler";
    if (_gold >= 1000)   _rank = "Road Merchant";
    if (_gold >= 5000)   _rank = "Prosperous Trader";
    if (_gold >= 10000)  _rank = "Merchant of Note";
    if (_gold >= 25000)  _rank = "Caravan Master";
    if (_gold >= 50000)  _rank = "Merchant Prince";
    if (_gold >= 100000) _rank = "Legend of the Road";

    // ----------------------------------------------------------------
    // Flavour quote per rank
    // ----------------------------------------------------------------
    var _quote = "A rough start, merchant. The road is a harsh teacher.";
    if (_rank == "Road Merchant")
        _quote = "Respectable. You kept the donkey fed, at least.";
    if (_rank == "Prosperous Trader")
        _quote = "Your wagon wheels carved profitable ruts into these roads.";
    if (_rank == "Merchant of Note")
        _quote = "Merchants in distant cities have heard of you. They are not scared yet.";
    if (_rank == "Caravan Master")
        _quote = "You built something real out here. The road respects that.";
    if (_rank == "Merchant Prince")
        _quote = "Gold has a way of attracting more gold. You have proven the theorem.";
    if (_rank == "Legend of the Road")
        _quote = "They will name trade routes after you. The donkey gets its own verse.";

    // ----------------------------------------------------------------
    // Build standings: player + all competitors, sorted by gold
    // ----------------------------------------------------------------
    var _standings = [];
    array_push(_standings, { name: "You", gold: _gold, is_player: true });

    var _comps = obj_heartbeat.world.competitors;
    for (var _i = 0; _i < array_length(_comps); _i++) {
        array_push(_standings, {
            name:      _comps[_i].name,
            gold:      _comps[_i].gold,
            is_player: false
        });
    }

    // Sort descending by gold (explicit compare to avoid integer overflow)
    array_sort(_standings, function(a, b) {
        if (a.gold > b.gold) return -1;
        if (a.gold < b.gold) return  1;
        return 0;
    });

    // Find player rank in standings
    var _player_place = 1;
    for (var _i = 0; _i < array_length(_standings); _i++) {
        if (_standings[_i].is_player) {
            _player_place = _i + 1;
            break;
        }
    }
    var _total = array_length(_standings);

    // ----------------------------------------------------------------
    // Winner/loser line
    // ----------------------------------------------------------------
    var _outcome_line = "";
    if (_player_place == 1) {
        _outcome_line = "You finished FIRST.  The rivals are bitter. The donkey is proud.";
    } else if (_player_place == _total) {
        _outcome_line = "You finished last.  The donkey is disappointed in you.  The donkey is wise.";
    } else {
        _outcome_line = "You finished " + string(_player_place) + " of " + string(_total) + ".  Room to grow.";
    }

    // ----------------------------------------------------------------
    // Print the screen
    // ----------------------------------------------------------------
    console_clear();

    console_print("=== CARAVAN: JOURNEY COMPLETE ===");
    console_print("");
    console_print("  Trips completed : " + string(_trips));
    console_print("  Days elapsed    : " + string(_days));
    console_print("  Final gold      : " + string(_gold) + "g");
    console_print("  Your rank       : " + _rank);
    console_print("");
    console_print("  \"" + _quote + "\"");
    console_print("");
    console_print("STANDINGS:");

    for (var _i = 0; _i < array_length(_standings); _i++) {
        var _e      = _standings[_i];
        var _marker = _e.is_player ? "  <-- you" : "";
        var _num    = string(_i + 1) + ".";
        console_print("  " + _num + "  " + _e.name + "   " + string(_e.gold) + "g" + _marker);
    }

    console_print("");
    console_print(_outcome_line);
    console_print("");
    console_print("Type RESTART to start a new run or QUIT to exit.");
    console_print("");
}
