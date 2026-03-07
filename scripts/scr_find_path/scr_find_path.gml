/// @func scr_find_path(from_id, to_id)
/// @desc Dijkstra shortest-distance path through obj_heartbeat.world.routes.
///       Worlds are small (≤ 60 nodes) so a linear-scan priority queue is fine.
/// @param {String} from_id  Starting location ID
/// @param {String} to_id    Target location ID
/// @return {Array<String>}  Ordered location IDs from→to (inclusive),
///                          or undefined if the destination is unreachable.

function scr_find_path(from_id, to_id) {

    if (from_id == to_id) return [from_id];

    var _locs   = obj_heartbeat.world.locations;
    var _routes = obj_heartbeat.world.routes;
    var _n      = array_length(_locs);

    // --- Initialise distance / predecessor / visited structs ---
    var _dist = {};
    var _prev = {};
    var _seen = {};

    for (var _i = 0; _i < _n; _i++) {
        var _id = _locs[_i].id;
        _dist[$ _id] = 999999999;
        _prev[$ _id] = "";
        _seen[$ _id] = false;
    }
    _dist[$ from_id] = 0;

    // --- Main Dijkstra loop (one iteration per node) ---
    repeat (_n) {

        // Find the unseen node with the smallest tentative distance
        var _u  = "";
        var _ud = 999999999;
        for (var _i = 0; _i < _n; _i++) {
            var _id = _locs[_i].id;
            if (!_seen[$ _id] && _dist[$ _id] < _ud) {
                _ud = _dist[$ _id];
                _u  = _id;
            }
        }
        if (_u == "" || _ud == 999999999) break;  // All remaining nodes are unreachable
        _seen[$ _u] = true;
        if (_u == to_id) break;                   // Shortest path to target is final

        // Relax all edges from _u
        for (var _ri = 0; _ri < array_length(_routes); _ri++) {
            var _rt = _routes[_ri];
            var _nb = "";
            if      (_rt.from_id == _u) _nb = _rt.to_id;
            else if (_rt.to_id   == _u) _nb = _rt.from_id;
            if (_nb == "") continue;

            var _nd = _dist[$ _u] + _rt.distance;
            if (_nd < _dist[$ _nb]) {
                _dist[$ _nb] = _nd;
                _prev[$ _nb] = _u;
            }
        }
    }

    // Destination unreachable
    if (_dist[$ to_id] >= 999999999) return undefined;

    // --- Reconstruct path by walking predecessors backwards ---
    var _path_rev = [];
    var _cur = to_id;
    while (_cur != "") {
        array_push(_path_rev, _cur);
        _cur = _prev[$ _cur];
    }

    // Reverse into correct order
    var _path = [];
    for (var _i = array_length(_path_rev) - 1; _i >= 0; _i--) {
        array_push(_path, _path_rev[_i]);
    }
    return _path;
}
