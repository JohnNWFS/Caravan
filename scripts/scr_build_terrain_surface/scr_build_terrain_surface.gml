/// @func scr_build_terrain_surface()
/// @desc Bakes a 560×350 surface with terrain ink blobs and river underpainting.
///       Two rendering passes:
///         1. Ink blobs  — organic circles stamped along each route's bezier curve
///         2. River base — wide soft strokes for each river through waypoints
///       The result is stored in obj_heartbeat.map_terrain_surface and drawn
///       as a semi-transparent overlay over the map panel background.
///       Call whenever surface_exists(obj_heartbeat.map_terrain_surface) is false.

function scr_build_terrain_surface() {

    // Map drawing area dimensions (must match scr_draw_map constants exactly)
    var _mw  = 560;   // _mx1 - _mx0  (600 - 40)
    var _mh  = 350;   // _my1 - _my0  (406 - 56)

    // World coordinate ranges and scale factors
    var _wx0 = 100.0;
    var _wy0 = 100.0;
    var _sx  = _mw / 800.0;   // 0.700  world→screen x
    var _sy  = _mh / 600.0;   // 0.583  world→screen y

    // Terrain ink colours (darker/more saturated than route line colours)
    var _TCOL_ROAD     = make_color_rgb(160, 155, 135);
    var _TCOL_PLAINS   = make_color_rgb( 80, 130,  60);
    var _TCOL_FOREST   = make_color_rgb( 30,  80,  35);
    var _TCOL_HILLS    = make_color_rgb(120,  90,  50);
    var _TCOL_MOUNTAIN = make_color_rgb( 65,  90, 120);
    var _TCOL_DESERT   = make_color_rgb(175, 130,  55);

    // Free any stale surface before creating a fresh one
    if (surface_exists(obj_heartbeat.map_terrain_surface)) {
        surface_free(obj_heartbeat.map_terrain_surface);
    }
    obj_heartbeat.map_terrain_surface = -1;

    // Create a fresh surface and make it the render target
    var _surf = surface_create(_mw, _mh);
    surface_set_target(_surf);

    // Clear surface to fully transparent black using write-all blend mode.
    // draw_clear_alpha() has compatibility issues on some GML versions;
    // this approach reliably writes RGBA(0,0,0,0) to every pixel.
    gpu_set_blendmode_ext(bm_one, bm_zero);
    draw_set_alpha(0);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _mw, _mh, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);

    // -----------------------------------------------------------------------
    // PASS 1 — INK BLOBS along each route bezier
    // -----------------------------------------------------------------------
    // For every route, walk the quadratic bezier from endpoint to endpoint,
    // stamping 3 overlapping circles with deterministic jitter at each step.
    // The blobs accumulate to create an organic patchwork of terrain colour.

    for (var _ri = 0; _ri < array_length(obj_heartbeat.world.routes); _ri++) {
        var _rt = obj_heartbeat.world.routes[_ri];

        // Look up the from/to location structs
        var _fl = undefined;  var _tl = undefined;
        for (var _li = 0; _li < array_length(obj_heartbeat.world.locations); _li++) {
            var _loc = obj_heartbeat.world.locations[_li];
            if (_loc.id == _rt.from_id) _fl = _loc;
            if (_loc.id == _rt.to_id)   _tl = _loc;
        }
        if (_fl == undefined || _tl == undefined) continue;

        // Convert endpoints to surface-local coords (no _mx0/_my0 offset)
        var _rx1 = (_fl.x - _wx0) * _sx;
        var _ry1 = (_fl.y - _wy0) * _sy;
        var _rx2 = (_tl.x - _wx0) * _sx;
        var _ry2 = (_tl.y - _wy0) * _sy;

        // Bezier control point (world → surface-local)
        var _cx, _cy;
        if (variable_struct_exists(_rt, "ctrl_x")) {
            _cx = (_rt.ctrl_x - _wx0) * _sx;
            _cy = (_rt.ctrl_y - _wy0) * _sy;
        } else {
            _cx = (_rx1 + _rx2) * 0.5;
            _cy = (_ry1 + _ry2) * 0.5;
        }

        // Pick terrain colour
        var _tcol;
        switch (_rt.terrain) {
            case "ROAD":     _tcol = _TCOL_ROAD;     break;
            case "PLAINS":   _tcol = _TCOL_PLAINS;   break;
            case "FOREST":   _tcol = _TCOL_FOREST;   break;
            case "HILLS":    _tcol = _TCOL_HILLS;     break;
            case "MOUNTAIN": _tcol = _TCOL_MOUNTAIN;  break;
            case "DESERT":   _tcol = _TCOL_DESERT;    break;
            default:         _tcol = _TCOL_PLAINS;    break;
        }

        // Walk the bezier — stamp every ~14px
        var _dist_px = point_distance(_rx1, _ry1, _rx2, _ry2);
        var _steps   = max(3, ceil(_dist_px / 14));

        for (var _s = 0; _s <= _steps; _s++) {
            var _bt  = _s / _steps;
            var _bmt = 1.0 - _bt;

            // Quadratic bezier position
            var _bx = _bmt*_bmt*_rx1 + 2.0*_bmt*_bt*_cx + _bt*_bt*_rx2;
            var _by = _bmt*_bmt*_ry1 + 2.0*_bmt*_bt*_cy + _bt*_bt*_ry2;

            // Deterministic per-stamp seed (avoids random() to keep it reproducible)
            var _seed = (_ri * 7919 + _s * 131) mod 10000;

            // Coarse position jitter (shifts the cluster off the route line)
            var _jx = ((_seed * 37) mod 25) - 12;
            var _jy = ((_seed * 61) mod 25) - 12;

            // Three overlapping circles per stamp
            for (var _layer = 0; _layer < 3; _layer++) {
                var _ls  = (_seed + _layer * 97) mod 10000;
                var _r   = 10 + (_ls mod 23);              // radius 10..32
                var _jx2 = ((_ls * 41) mod 21) - 10;       // fine jitter
                var _jy2 = ((_ls * 67) mod 21) - 10;
                var _a   = 0.12 + (_ls mod 20) * 0.01;     // alpha 0.12..0.31

                draw_set_alpha(_a);
                draw_set_color(_tcol);
                draw_circle(_bx + _jx + _jx2, _by + _jy + _jy2, _r, false);
            }
        }
    }

    // -----------------------------------------------------------------------
    // PASS 2 — RIVER UNDERPAINTING (midpoint quadratic bezier, wide strokes)
    // -----------------------------------------------------------------------
    if (variable_struct_exists(obj_heartbeat.world, "rivers")) {
        var _river_col = make_color_rgb(45, 160, 180); // teal matches overlay
        for (var _rvi = 0; _rvi < array_length(obj_heartbeat.world.rivers); _rvi++) {
            var _rv   = obj_heartbeat.world.rivers[_rvi];
            var _wpts = _rv.waypoints;
            var _n    = array_length(_wpts);
            if (_n < 2) continue;

            for (var _wi = 0; _wi < _n; _wi++) {
                // Anchor start (surface-local coords, no _mx0/_my0 offset)
                var _ax0s, _ay0s;
                if (_wi == 0) {
                    _ax0s = (_wpts[0].x - _wx0) * _sx;
                    _ay0s = (_wpts[0].y - _wy0) * _sy;
                } else {
                    _ax0s = ((_wpts[_wi-1].x + _wpts[_wi].x) * 0.5 - _wx0) * _sx;
                    _ay0s = ((_wpts[_wi-1].y + _wpts[_wi].y) * 0.5 - _wy0) * _sy;
                }
                // Anchor end
                var _ax1s, _ay1s;
                if (_wi == _n - 1) {
                    _ax1s = (_wpts[_n-1].x - _wx0) * _sx;
                    _ay1s = (_wpts[_n-1].y - _wy0) * _sy;
                } else {
                    _ax1s = ((_wpts[_wi].x + _wpts[_wi+1].x) * 0.5 - _wx0) * _sx;
                    _ay1s = ((_wpts[_wi].y + _wpts[_wi+1].y) * 0.5 - _wy0) * _sy;
                }
                var _bctxs = (_wpts[_wi].x - _wx0) * _sx;
                var _bctys = (_wpts[_wi].y - _wy0) * _sy;

                var _sub_steps = 6;
                var _ppx = _ax0s;  var _ppy = _ay0s;
                for (var _si = 1; _si <= _sub_steps; _si++) {
                    var _t  = _si / _sub_steps;
                    var _mt = 1.0 - _t;
                    var _cx = _mt*_mt*_ax0s + 2.0*_mt*_t*_bctxs + _t*_t*_ax1s;
                    var _cy = _mt*_mt*_ay0s + 2.0*_mt*_t*_bctys + _t*_t*_ay1s;
                    draw_set_color(_river_col);
                    draw_set_alpha(0.30);
                    draw_line_width(_ppx, _ppy, _cx, _cy, 10);
                    draw_set_alpha(0.12);
                    draw_line_width(_ppx, _ppy, _cx, _cy, 18);
                    _ppx = _cx;  _ppy = _cy;
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // PASS 3 — OCEAN GRADIENT STRIP (if world has a coastal edge)
    // -----------------------------------------------------------------------
    // Draws 5 overlapping semi-transparent rectangles from the ocean edge
    // inward, each 20px wide with decreasing alpha, creating a soft fade.
    if (variable_struct_exists(obj_heartbeat.world, "has_ocean") &&
        obj_heartbeat.world.has_ocean) {
        var _oedge  = obj_heartbeat.world.ocean_edge;
        var _ocol   = make_color_rgb(40, 80, 150);
        var _oalphas = [0.35, 0.25, 0.16, 0.10, 0.06];
        draw_set_color(_ocol);
        for (var _osi = 0; _osi < 5; _osi++) {
            draw_set_alpha(_oalphas[_osi]);
            var _odist = (_osi + 1) * 20; // 20, 40, 60, 80, 100 px from edge
            if (_oedge == "LEFT")   draw_rectangle(0,          0,          _odist,     _mh,   false);
            if (_oedge == "RIGHT")  draw_rectangle(_mw-_odist, 0,          _mw,        _mh,   false);
            if (_oedge == "TOP")    draw_rectangle(0,           0,          _mw,        _odist, false);
            if (_oedge == "BOTTOM") draw_rectangle(0,           _mh-_odist, _mw,        _mh,   false);
        }
    }

    // -----------------------------------------------------------------------
    // PASS 4 — LAKE CIRCLES (soft filled circles at inland river termini)
    // -----------------------------------------------------------------------
    if (variable_struct_exists(obj_heartbeat.world, "rivers")) {
        var _lake_col = make_color_rgb(50, 110, 185);
        draw_set_color(_lake_col);
        for (var _lki = 0; _lki < array_length(obj_heartbeat.world.rivers); _lki++) {
            var _lkrv = obj_heartbeat.world.rivers[_lki];
            if (!variable_struct_exists(_lkrv, "has_lake") || !_lkrv.has_lake) continue;
            var _lsx = (_lkrv.lake_x - _wx0) * _sx;
            var _lsy = (_lkrv.lake_y - _wy0) * _sy;
            // Three concentric circles: outer glow, mid fill, bright core
            draw_set_alpha(0.18); draw_circle(_lsx, _lsy, 22, false);
            draw_set_alpha(0.30); draw_circle(_lsx, _lsy, 16, false);
            draw_set_alpha(0.45); draw_circle(_lsx, _lsy, 10, false);
        }
    }

    // Done — restore normal render target
    surface_reset_target();
    draw_set_alpha(1);
    draw_set_color(c_white);

    obj_heartbeat.map_terrain_surface = _surf;
}
