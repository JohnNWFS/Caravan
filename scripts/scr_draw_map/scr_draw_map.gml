/// @func scr_draw_map()
/// @desc Full-screen world map overlay.  Call from a Draw GUI event.
///       Reads world data from obj_heartbeat.world; player position from
///       obj_player.current_location.
///
/// Rendering layers (back to front):
///   1.  Dim overlay + panel background
///   1b. Terrain surface (organic ink blob background)
///   2.  Non-reachable routes (dim bezier curves, monochrome)
///   3.  Reachable routes (terrain-coloured bezier curves)
///   4.  Location nodes (icons: castle / house / dot)
///   5.  Animated player marker (pulsing rings + crosshair)
///   5b. Travel dot (bezier path, amber, during GO animation)
///   5c. Rival markers (red triangles with initials)
///   5d. Animated river overlay (bright blue shimmer)
///   6.  Hover tooltip
///   7.  Legend

function scr_draw_map() {
    if (!instance_exists(obj_heartbeat)) return;
    if (obj_heartbeat.world == noone)    return;

    // -----------------------------------------------------------------------
    // CONSTANTS
    // -----------------------------------------------------------------------
    var _W  = display_get_gui_width();   // 640
    var _H  = display_get_gui_height();  // 480

    // Panel bounds
    var _px0 = 20;
    var _py0 = 36;
    var _px1 = _W - 20;   // 620
    var _py1 = _H - 22;   // 458

    // Map drawing area (inside panel, with padding + legend band at bottom)
    var _mx0 = _px0 + 20;   // 40
    var _my0 = _py0 + 20;   // 56
    var _mx1 = _px1 - 20;   // 600
    var _my1 = _py1 - 52;   // 406

    var _mw = _mx1 - _mx0;  // 560
    var _mh = _my1 - _my0;  // 350

    // World coordinate ranges
    var _wx0 = 100.0;  var _wx1 = 900.0;
    var _wy0 = 100.0;  var _wy1 = 700.0;

    // Scale: world unit → screen pixel
    var _sx = _mw / (_wx1 - _wx0);   // 0.700
    var _sy = _mh / (_wy1 - _wy0);   // 0.583

    // Terrain colours (bright, for route lines and legend)
    var _COL_ROAD     = make_color_rgb(215, 215, 215);
    var _COL_PLAINS   = make_color_rgb(105, 195, 105);
    var _COL_FOREST   = make_color_rgb( 25, 115,  45);
    var _COL_HILLS    = make_color_rgb(165, 120,  60);
    var _COL_MOUNTAIN = make_color_rgb( 80, 120, 170);
    var _COL_DESERT   = make_color_rgb(230, 170,  70);

    draw_set_font(fnt_console);

    // -----------------------------------------------------------------------
    // 1. FULL-SCREEN DIM + PANEL
    // -----------------------------------------------------------------------
    draw_set_alpha(0.82);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _W - 1, _H - 1, false);
    draw_set_alpha(1);

    // Panel fill
    draw_set_color(make_color_rgb(10, 14, 22));
    draw_rectangle(_px0, _py0, _px1, _py1, false);

    // Panel border (two-stroke for depth)
    draw_set_color(make_color_rgb(40, 60, 80));
    draw_rectangle(_px0 - 1, _py0 - 1, _px1 + 1, _py1 + 1, true);
    draw_set_color(make_color_rgb(85, 115, 145));
    draw_rectangle(_px0, _py0, _px1, _py1, true);

    // Subtle grid lines
    draw_set_alpha(0.06);
    draw_set_color(make_color_rgb(120, 160, 200));
    var _grid_step = 56;
    for (var _gx = _mx0; _gx <= _mx1; _gx += _grid_step) draw_line(_gx, _my0, _gx, _my1);
    for (var _gy = _my0; _gy <= _my1; _gy += _grid_step) draw_line(_mx0, _gy, _mx1, _gy);
    draw_set_alpha(1);

    // Map area border
    draw_set_color(make_color_rgb(40, 55, 70));
    draw_rectangle(_mx0, _my0, _mx1, _my1, true);

    // -----------------------------------------------------------------------
    // 1b. TERRAIN SURFACE — organic ink blob background
    // Surface is guaranteed to exist by Draw_64.gml which calls
    // scr_build_terrain_surface() before invoking this function.
    // -----------------------------------------------------------------------
    if (surface_exists(obj_heartbeat.map_terrain_surface)) {
        draw_set_alpha(0.68);
        draw_surface(obj_heartbeat.map_terrain_surface, _mx0, _my0);
        draw_set_alpha(1);
    }

    // -----------------------------------------------------------------------
    // TITLE + PLAYER LOCATION SUBTITLE
    // -----------------------------------------------------------------------
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    draw_set_color(make_color_rgb(200, 172, 85));
    draw_text(_W / 2, 8, "=== WORLD MAP ===");

    var _player_loc_id   = obj_player.current_location;
    var _player_loc_name = "Unknown";
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        if (obj_heartbeat.world.locations[i].id == _player_loc_id) {
            _player_loc_name = obj_heartbeat.world.locations[i].name;
            break;
        }
    }
    if (obj_heartbeat.map_travel_active) {
        draw_set_color(make_color_rgb(255, 215, 60));
        draw_text(_W / 2, 22, "Traveling to: " + obj_heartbeat.map_travel_to_name + "...");
    } else {
        draw_set_color(make_color_rgb(110, 155, 110));
        draw_text(_W / 2, 22, "You are in: " + _player_loc_name);
    }

    // Day badge — right-aligned in the header strip
    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(140, 160, 180));
    draw_text(_px1 - 8, 8, "Day " + string(obj_heartbeat.day));
    draw_set_halign(fa_center);

    // -----------------------------------------------------------------------
    // CLOSE HINT
    // -----------------------------------------------------------------------
    draw_set_valign(fa_top);
    if (!obj_heartbeat.map_travel_active) {
        draw_set_color(make_color_rgb(80, 85, 95));
        draw_text(_W / 2, _py1 + 5, "Press ESC or click to close");
    }

    // -----------------------------------------------------------------------
    // BUILD REACHABLE ROUTE MAP (for tooltip distance lookup)
    // -----------------------------------------------------------------------
    var _reachable_ids = [];
    var _route_map     = {};
    for (var i = 0; i < array_length(obj_heartbeat.world.routes); i++) {
        var _rt = obj_heartbeat.world.routes[i];
        var _other_id = "";
        if      (_rt.from_id == _player_loc_id) _other_id = _rt.to_id;
        else if (_rt.to_id   == _player_loc_id) _other_id = _rt.from_id;
        if (_other_id != "") {
            array_push(_reachable_ids, _other_id);
            _route_map[$ _other_id] = _rt;
        }
    }

    // -----------------------------------------------------------------------
    // BEZIER HELPER — draw a quadratic bezier between two screen points
    // using a control point, with given line width and step count.
    // (inlined below for performance; defined here for readability)
    // P0=(x1,y1)  P1=(cx,cy)  P2=(x2,y2)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // 2. NON-REACHABLE ROUTES — dim bezier curves, monochrome
    // -----------------------------------------------------------------------
    draw_set_alpha(0.20);
    draw_set_color(make_color_rgb(65, 70, 80));
    for (var i = 0; i < array_length(obj_heartbeat.world.routes); i++) {
        var _rt = obj_heartbeat.world.routes[i];
        if (_rt.from_id == _player_loc_id || _rt.to_id == _player_loc_id) continue;

        var _fl = undefined;  var _tl = undefined;
        for (var j = 0; j < array_length(obj_heartbeat.world.locations); j++) {
            if (obj_heartbeat.world.locations[j].id == _rt.from_id) _fl = obj_heartbeat.world.locations[j];
            if (obj_heartbeat.world.locations[j].id == _rt.to_id)   _tl = obj_heartbeat.world.locations[j];
        }
        if (_fl == undefined || _tl == undefined) continue;

        var _fx = _mx0 + (_fl.x - _wx0) * _sx;
        var _fy = _my0 + (_fl.y - _wy0) * _sy;
        var _tx = _mx0 + (_tl.x - _wx0) * _sx;
        var _ty = _my0 + (_tl.y - _wy0) * _sy;

        // Control point
        var _cx_w = (_fl.x + _tl.x) * 0.5;
        var _cy_w = (_fl.y + _tl.y) * 0.5;
        if (variable_struct_exists(_rt, "ctrl_x")) { _cx_w = _rt.ctrl_x;  _cy_w = _rt.ctrl_y; }
        var _rcx = _mx0 + (_cx_w - _wx0) * _sx;
        var _rcy = _my0 + (_cy_w - _wy0) * _sy;

        // Draw 12-step bezier
        var _bx_prev = _fx;  var _by_prev = _fy;
        for (var _s = 1; _s <= 12; _s++) {
            var _bt = _s / 12.0;  var _bmt = 1.0 - _bt;
            var _bx = _bmt*_bmt*_fx + 2.0*_bmt*_bt*_rcx + _bt*_bt*_tx;
            var _by = _bmt*_bmt*_fy + 2.0*_bmt*_bt*_rcy + _bt*_bt*_ty;
            draw_line(_bx_prev, _by_prev, _bx, _by);
            _bx_prev = _bx;  _by_prev = _by;
        }
    }
    draw_set_alpha(1);

    // -----------------------------------------------------------------------
    // 3. REACHABLE ROUTES — terrain-coloured bezier curves
    // -----------------------------------------------------------------------
    for (var i = 0; i < array_length(obj_heartbeat.world.routes); i++) {
        var _rt = obj_heartbeat.world.routes[i];
        if (_rt.from_id != _player_loc_id && _rt.to_id != _player_loc_id) continue;

        var _fl = undefined;  var _tl = undefined;
        for (var j = 0; j < array_length(obj_heartbeat.world.locations); j++) {
            if (obj_heartbeat.world.locations[j].id == _rt.from_id) _fl = obj_heartbeat.world.locations[j];
            if (obj_heartbeat.world.locations[j].id == _rt.to_id)   _tl = obj_heartbeat.world.locations[j];
        }
        if (_fl == undefined || _tl == undefined) continue;

        var _rx1 = _mx0 + (_fl.x - _wx0) * _sx;
        var _ry1 = _my0 + (_fl.y - _wy0) * _sy;
        var _rx2 = _mx0 + (_tl.x - _wx0) * _sx;
        var _ry2 = _my0 + (_tl.y - _wy0) * _sy;

        // Control point
        var _cx_w = (_fl.x + _tl.x) * 0.5;
        var _cy_w = (_fl.y + _tl.y) * 0.5;
        if (variable_struct_exists(_rt, "ctrl_x")) { _cx_w = _rt.ctrl_x;  _cy_w = _rt.ctrl_y; }
        var _rcx = _mx0 + (_cx_w - _wx0) * _sx;
        var _rcy = _my0 + (_cy_w - _wy0) * _sy;

        // Terrain colour
        var _rcol = _COL_PLAINS;
        switch (_rt.terrain) {
            case "ROAD":     _rcol = _COL_ROAD;     break;
            case "PLAINS":   _rcol = _COL_PLAINS;   break;
            case "FOREST":   _rcol = _COL_FOREST;   break;
            case "HILLS":    _rcol = _COL_HILLS;     break;
            case "MOUNTAIN": _rcol = _COL_MOUNTAIN;  break;
            case "DESERT":   _rcol = _COL_DESERT;    break;
        }

        // Glow pass (wide, dim)
        draw_set_alpha(0.18);
        draw_set_color(_rcol);
        var _bx_prev = _rx1;  var _by_prev = _ry1;
        for (var _s = 1; _s <= 20; _s++) {
            var _bt = _s / 20.0;  var _bmt = 1.0 - _bt;
            var _bx = _bmt*_bmt*_rx1 + 2.0*_bmt*_bt*_rcx + _bt*_bt*_rx2;
            var _by = _bmt*_bmt*_ry1 + 2.0*_bmt*_bt*_rcy + _bt*_bt*_ry2;
            draw_line_width(_bx_prev, _by_prev, _bx, _by, 6);
            _bx_prev = _bx;  _by_prev = _by;
        }

        // Main line pass
        draw_set_alpha(0.88);
        _bx_prev = _rx1;  _by_prev = _ry1;
        for (var _s = 1; _s <= 20; _s++) {
            var _bt = _s / 20.0;  var _bmt = 1.0 - _bt;
            var _bx = _bmt*_bmt*_rx1 + 2.0*_bmt*_bt*_rcx + _bt*_bt*_rx2;
            var _by = _bmt*_bmt*_ry1 + 2.0*_bmt*_bt*_rcy + _bt*_bt*_ry2;
            draw_line_width(_bx_prev, _by_prev, _bx, _by, 2);
            _bx_prev = _bx;  _by_prev = _by;
        }
        draw_set_alpha(1);

        // Distance label at bezier midpoint (t=0.5)
        var _mid_x = 0.25*_rx1 + 0.5*_rcx + 0.25*_rx2;
        var _mid_y = 0.25*_ry1 + 0.5*_rcy + 0.25*_ry2;
        var _dist_str = string(round(_rt.distance)) + "km";
        var _angle = point_direction(_rx1, _ry1, _rx2, _ry2);
        var _perp  = _angle + 90;
        _mid_x += lengthdir_x(9, _perp);
        _mid_y += lengthdir_y(9, _perp);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_alpha(0.6);
        draw_set_color(make_color_rgb(200, 190, 140));
        draw_text(_mid_x, _mid_y, _dist_str);
        draw_set_alpha(1);
    }

    // -----------------------------------------------------------------------
    // 4. LOCATION NODES — procedural icons (castle / house / dot)
    // -----------------------------------------------------------------------
    var _nodes = [];
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        var _loc = obj_heartbeat.world.locations[i];

        var _nsx = _mx0 + (_loc.x - _wx0) * _sx;
        var _nsy = _my0 + (_loc.y - _wy0) * _sy;
        var _nr  = 4;
        if (_loc.type == "CITY")  _nr = 9;
        else if (_loc.type == "TOWN") _nr = 6;

        var _is_cur   = (_loc.id == _player_loc_id);
        var _is_reach = false;
        for (var k = 0; k < array_length(_reachable_ids); k++) {
            if (_reachable_ids[k] == _loc.id) { _is_reach = true; break; }
        }
        var _is_vis = (variable_struct_exists(_loc, "economy") && _loc.economy.player_visited);

        // Fog of war — nodes that are neither visited nor reachable are barely-visible
        // silhouettes, giving a sense of the world's scale without revealing its secrets.
        var _node_alpha = (!_is_cur && !_is_reach && !_is_vis) ? 0.28 : 1.0;

        // State-based colours
        var _fill, _edge;
        if (_is_cur) {
            _fill = make_color_rgb( 55, 218, 178);
            _edge = make_color_rgb(160, 255, 230);
        } else if (_is_reach && _is_vis) {
            _fill = make_color_rgb(215, 168,  48);
            _edge = make_color_rgb(255, 215,  80);
        } else if (_is_reach) {
            _fill = make_color_rgb( 60, 128, 200);
            _edge = make_color_rgb(120, 175, 250);
        } else if (_is_vis) {
            _fill = make_color_rgb(125, 102,  40);
            _edge = make_color_rgb(175, 142,  55);
        } else {
            _fill = make_color_rgb( 42,  46,  56);
            _edge = make_color_rgb( 75,  80,  95);
        }

        // Destination pulse — reachable nodes emit a slow animated ring when the
        // map is open for travel planning (not during the travel animation itself).
        // Each node is phase-staggered by index so they don't pulse in unison.
        if (_is_reach && !_is_cur && !obj_heartbeat.map_travel_active) {
            var _pulse_t = (sin(current_time * 0.004 + i * 0.9) + 1.0) * 0.5;
            var _pulse_r = _nr + 4 + _pulse_t * 6;
            var _pulse_a = 0.55 - _pulse_t * 0.45;
            draw_set_alpha(_pulse_a);
            draw_set_color(make_color_rgb(120, 175, 250));
            draw_circle(_nsx, _nsy, _pulse_r, true);
        }

        // Shadow
        draw_set_alpha(0.30 * _node_alpha);
        draw_set_color(c_black);
        draw_circle(_nsx + 2, _nsy + 2, _nr + 1, false);

        // Base circle
        draw_set_alpha(_node_alpha);
        draw_set_color(_fill);
        draw_circle(_nsx, _nsy, _nr, false);
        draw_set_color(_edge);
        draw_circle(_nsx, _nsy, _nr, true);

        // === PROCEDURAL ICON (drawn in white over the base circle) ===
        draw_set_color(c_white);
        draw_set_alpha(0.85 * _node_alpha);

        if (_loc.type == "CITY") {
            // Castle silhouette: three merlons + connecting wall + gate hint
            // Merlons (crenellations) across the top
            draw_rectangle(_nsx - 5, _nsy - 8, _nsx - 3, _nsy - 5, false);  // left merlon
            draw_rectangle(_nsx - 1, _nsy - 9, _nsx + 1, _nsy - 5, false);  // centre (tallest)
            draw_rectangle(_nsx + 3, _nsy - 8, _nsx + 5, _nsy - 5, false);  // right merlon
            // Wall body connecting the merlons
            draw_rectangle(_nsx - 5, _nsy - 5, _nsx + 5, _nsy + 2, false);
            // Gate arch (dark rectangle punched out of lower-centre)
            draw_set_color(make_color_rgb(10, 14, 22));
            draw_set_alpha(0.80 * _node_alpha);
            draw_rectangle(_nsx - 1, _nsy - 1, _nsx + 1, _nsy + 2, false);
        } else if (_loc.type == "TOWN") {
            // House silhouette: rectangular body + angled roof
            draw_set_color(c_white);
            draw_set_alpha(0.85 * _node_alpha);
            // Body
            draw_rectangle(_nsx - 3, _nsy - 2, _nsx + 3, _nsy + 3, false);
            // Roof (two lines forming inverted-V)
            draw_line_width(_nsx - 4, _nsy - 2, _nsx,     _nsy - 5, 1.5);
            draw_line_width(_nsx,     _nsy - 5, _nsx + 4, _nsy - 2, 1.5);
        } else {
            // Village: just a small centre dot
            draw_circle(_nsx, _nsy, 1.5, false);
        }

        // === SPECIAL LOCATION OVERLAY ICON ===
        if (variable_struct_exists(_loc, "subtype") && _loc.subtype != "") {
            draw_set_alpha(0.92 * _node_alpha);
            if (_loc.subtype == "ARCANE_LIBRARY") {
                // 8-point starburst: 4 crossing lines at 0°/45°/90°/135°
                draw_set_color(make_color_rgb(190, 140, 255));  // Soft purple
                var _sr = _nr + 4;
                draw_line_width(_nsx - _sr, _nsy,      _nsx + _sr, _nsy,      1);
                draw_line_width(_nsx,       _nsy - _sr, _nsx,       _nsy + _sr, 1);
                var _sd = round(_sr * 0.707);
                draw_line_width(_nsx - _sd, _nsy - _sd, _nsx + _sd, _nsy + _sd, 1);
                draw_line_width(_nsx - _sd, _nsy + _sd, _nsx + _sd, _nsy - _sd, 1);
            } else if (_loc.subtype == "RUINED_SHRINE") {
                // Diamond outline + centre dot
                draw_set_color(make_color_rgb(200, 230, 160));  // Pale green
                var _dr = _nr + 3;
                draw_line_width(_nsx,       _nsy - _dr, _nsx + _dr, _nsy,       1);
                draw_line_width(_nsx + _dr, _nsy,       _nsx,       _nsy + _dr, 1);
                draw_line_width(_nsx,       _nsy + _dr, _nsx - _dr, _nsy,       1);
                draw_line_width(_nsx - _dr, _nsy,       _nsx,       _nsy - _dr, 1);
                draw_circle(_nsx, _nsy, 1, false);
            } else if (_loc.subtype == "ELVEN_OUTPOST") {
                // Upward triangle
                draw_set_color(make_color_rgb(130, 230, 160));  // Soft green
                var _tr = _nr + 3;
                draw_line_width(_nsx,       _nsy - _tr, _nsx + _tr, _nsy + _tr, 1.5);
                draw_line_width(_nsx + _tr, _nsy + _tr, _nsx - _tr, _nsy + _tr, 1.5);
                draw_line_width(_nsx - _tr, _nsy + _tr, _nsx,       _nsy - _tr, 1.5);
            } else if (_loc.subtype == "GOBLIN_MARKET") {
                // X mark in orange
                draw_set_color(make_color_rgb(255, 140, 40));   // Orange
                var _xr = _nr + 3;
                draw_line_width(_nsx - _xr, _nsy - _xr, _nsx + _xr, _nsy + _xr, 1.5);
                draw_line_width(_nsx - _xr, _nsy + _xr, _nsx + _xr, _nsy - _xr, 1.5);
            }
        }

        draw_set_alpha(1);

        // Selection ring — pulsing gold outline drawn on top when this node is selected
        if (_loc.id == obj_heartbeat.selected_location_id) {
            var _sel_t = (sin(current_time * 0.006) + 1.0) * 0.5;  // 0..1 pulse
            draw_set_alpha(0.65 + _sel_t * 0.35);
            draw_set_color(make_color_rgb(255, 240, 120));           // bright gold
            draw_circle(_nsx, _nsy, _nr + 5, true);                 // outline ring
            draw_set_alpha(1);
        }

        array_push(_nodes, {
            loc: _loc,
            sx: _nsx, sy: _nsy, r: _nr,
            is_cur: _is_cur, is_reach: _is_reach, is_vis: _is_vis
        });
    }

    // -----------------------------------------------------------------------
    // 5. ANIMATED PLAYER MARKER
    // -----------------------------------------------------------------------
    var _psx = 0;  var _psy = 0;
    for (var i = 0; i < array_length(_nodes); i++) {
        if (_nodes[i].is_cur) { _psx = _nodes[i].sx;  _psy = _nodes[i].sy;  break; }
    }

    var _t = current_time * 0.002;

    // Two offset pulsing rings
    for (var _p = 0; _p < 2; _p++) {
        var _phase = _t + _p * pi;
        var _pulse = (sin(_phase) + 1.0) * 0.5;
        var _pr    = 12 + _pulse * 10;
        var _pa    = 0.60 - _pulse * 0.52;
        draw_set_alpha(_pa);
        draw_set_color(make_color_rgb(70, 230, 188));
        draw_circle(_psx, _psy, _pr, true);
    }

    // Three orbiting dots
    draw_set_alpha(0.85);
    draw_set_color(c_white);
    var _orbit_r = 14;
    for (var _d = 0; _d < 3; _d++) {
        var _da = _t * 60 + _d * 120;
        draw_circle(_psx + lengthdir_x(_orbit_r, _da), _psy + lengthdir_y(_orbit_r, _da), 1.5, false);
    }

    draw_set_alpha(1);

    // Crosshair
    draw_set_color(c_white);
    draw_line_width(_psx - 7, _psy,     _psx + 7, _psy,     2);
    draw_line_width(_psx,     _psy - 7, _psx,     _psy + 7, 2);

    // -----------------------------------------------------------------------
    // 5b. TRAVEL DOT — bezier path, amber, during GO animation
    // -----------------------------------------------------------------------
    if (obj_heartbeat.map_travel_active) {
        // Smoothstep on raw progress
        var _tp_raw = obj_heartbeat.map_travel_progress;
        var _tp     = _tp_raw * _tp_raw * (3.0 - 2.0 * _tp_raw);

        // Screen coords of from/to/ctrl
        var _from_sx = _mx0 + (obj_heartbeat.map_travel_from_x - _wx0) * _sx;
        var _from_sy = _my0 + (obj_heartbeat.map_travel_from_y - _wy0) * _sy;
        var _to_sx   = _mx0 + (obj_heartbeat.map_travel_to_x   - _wx0) * _sx;
        var _to_sy   = _my0 + (obj_heartbeat.map_travel_to_y   - _wy0) * _sy;
        var _ocx     = _mx0 + (obj_heartbeat.map_travel_ctrl_x  - _wx0) * _sx;
        var _ocy     = _my0 + (obj_heartbeat.map_travel_ctrl_y  - _wy0) * _sy;

        // Bezier position for main dot
        var _bmt  = 1.0 - _tp;
        var _atsx = _bmt*_bmt*_from_sx + 2.0*_bmt*_tp*_ocx + _tp*_tp*_to_sx;
        var _atsy = _bmt*_bmt*_from_sy + 2.0*_bmt*_tp*_ocy + _tp*_tp*_to_sy;

        // Fading trail — 4 dots, each 0.05 progress units behind
        for (var _tri = 4; _tri >= 1; _tri--) {
            var _trt_raw = max(0, _tp_raw - _tri * 0.05);
            var _trt     = _trt_raw * _trt_raw * (3.0 - 2.0 * _trt_raw);
            var _tmt     = 1.0 - _trt;
            var _trx     = _tmt*_tmt*_from_sx + 2.0*_tmt*_trt*_ocx + _trt*_trt*_to_sx;
            var _trsy    = _tmt*_tmt*_from_sy + 2.0*_tmt*_trt*_ocy + _trt*_trt*_to_sy;
            draw_set_alpha((5 - _tri) * 0.12);
            draw_set_color(make_color_rgb(255, 215, 60));
            draw_circle(_trx, _trsy, 3, false);
        }

        // Main travel dot — amber fill, white outline, crosshair
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(255, 215, 60));
        draw_circle(_atsx, _atsy, 7, false);
        draw_set_color(c_white);
        draw_circle(_atsx, _atsy, 7, true);
        draw_line_width(_atsx - 5, _atsy,     _atsx + 5, _atsy,     1.5);
        draw_line_width(_atsx,     _atsy - 5, _atsx,     _atsy + 5, 1.5);
    }

    // -----------------------------------------------------------------------
    // 5c. RIVAL MARKERS — red triangles with first-initial labels
    // -----------------------------------------------------------------------
    if (variable_struct_exists(obj_heartbeat.world, "competitors")) {
        var _rivals = obj_heartbeat.world.competitors;
        var _rival_angle_accum = 0;
        for (var _ri = 0; _ri < array_length(_rivals); _ri++) {
            var _rv = _rivals[_ri];
            if (!variable_struct_exists(_rv, "current_location")) continue;

            // Find rival's location screen coords
            var _rlsx = -1;  var _rlsy = -1;
            for (var _rli = 0; _rli < array_length(obj_heartbeat.world.locations); _rli++) {
                var _rloc = obj_heartbeat.world.locations[_rli];
                if (_rloc.id == _rv.current_location) {
                    _rlsx = _mx0 + (_rloc.x - _wx0) * _sx;
                    _rlsy = _my0 + (_rloc.y - _wy0) * _sy;
                    break;
                }
            }
            if (_rlsx < 0) continue;

            // Stagger rivals using golden angle so they don't stack
            var _rmx = _rlsx + lengthdir_x(18, _rival_angle_accum);
            var _rmy = _rlsy + lengthdir_y(18, _rival_angle_accum);
            _rival_angle_accum += 137.508;

            // Triangle marker (pointing down — rival is "at" the location)
            var _ts = 5;
            draw_set_alpha(0.80);
            draw_set_color(make_color_rgb(220, 70, 70));
            draw_triangle(
                _rmx,        _rmy + _ts,
                _rmx - _ts,  _rmy - _ts,
                _rmx + _ts,  _rmy - _ts,
                false
            );

            // First initial label
            if (variable_struct_exists(_rv, "name") && string_length(_rv.name) > 0) {
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_alpha(0.95);
                draw_set_color(c_white);
                draw_text(_rmx, _rmy - 1, string_char_at(_rv.name, 1));
            }

            draw_set_alpha(1);
        }
    }

    // -----------------------------------------------------------------------
    // 5d. ANIMATED RIVER OVERLAY — midpoint quadratic bezier, teal color
    //     Uses the loop-safe "midpoint smoothing" technique: anchor points
    //     are placed at midpoints between consecutive waypoints, and each
    //     segment is a quadratic bezier through those anchors with the
    //     waypoint as control. Guaranteed no loops or cusps.
    //     Width scales thin (source) → wide (mouth).
    // -----------------------------------------------------------------------
    if (variable_struct_exists(obj_heartbeat.world, "rivers")) {
        var _shimmer   = 0.75 + sin(current_time * 0.003) * 0.20;
        var _river_col = make_color_rgb(55, 190, 210); // teal — reads as water

        for (var _rvi = 0; _rvi < array_length(obj_heartbeat.world.rivers); _rvi++) {
            var _rv   = obj_heartbeat.world.rivers[_rvi];
            var _wpts = _rv.waypoints;
            var _n    = array_length(_wpts);
            if (_n < 2) continue;

            // Build anchor array: A[0]=W[0], A[i]=mid(W[i-1],W[i]) for i=1..n-1, A[n]=W[n-1]
            // Each segment i: quad bezier from A[i] to A[i+1], control = W[i]
            var _total_segs = _n; // n segments for n waypoints

            for (var _wi = 0; _wi < _n; _wi++) {
                // Anchor start
                var _ax0, _ay0;
                if (_wi == 0) {
                    _ax0 = _mx0 + (_wpts[0].x - _wx0) * _sx;
                    _ay0 = _my0 + (_wpts[0].y - _wy0) * _sy;
                } else {
                    _ax0 = _mx0 + ((_wpts[_wi-1].x + _wpts[_wi].x) * 0.5 - _wx0) * _sx;
                    _ay0 = _my0 + ((_wpts[_wi-1].y + _wpts[_wi].y) * 0.5 - _wy0) * _sy;
                }
                // Anchor end
                var _ax1, _ay1;
                if (_wi == _n - 1) {
                    _ax1 = _mx0 + (_wpts[_n-1].x - _wx0) * _sx;
                    _ay1 = _my0 + (_wpts[_n-1].y - _wy0) * _sy;
                } else {
                    _ax1 = _mx0 + ((_wpts[_wi].x + _wpts[_wi+1].x) * 0.5 - _wx0) * _sx;
                    _ay1 = _my0 + ((_wpts[_wi].y + _wpts[_wi+1].y) * 0.5 - _wy0) * _sy;
                }
                // Bezier control = the actual waypoint
                var _bctx = _mx0 + (_wpts[_wi].x - _wx0) * _sx;
                var _bcty = _my0 + (_wpts[_wi].y - _wy0) * _sy;

                // Width scales from 1.5px (source) to 5px (mouth)
                var _seg_w = lerp(1.5, 5.0, _wi / max(1, _total_segs - 1));

                var _sub_steps = 8;
                var _px = _ax0;
                var _py = _ay0;
                for (var _si = 1; _si <= _sub_steps; _si++) {
                    var _t  = _si / _sub_steps;
                    var _mt = 1.0 - _t;
                    var _qx = _mt*_mt*_ax0 + 2.0*_mt*_t*_bctx + _t*_t*_ax1;
                    var _qy = _mt*_mt*_ay0 + 2.0*_mt*_t*_bcty + _t*_t*_ay1;
                    draw_set_color(_river_col);
                    draw_set_alpha(0.55 * _shimmer);
                    draw_line_width(_px, _py, _qx, _qy, _seg_w);
                    _px = _qx;
                    _py = _qy;
                }
            }

            // --- Lake shimmer circle at inland terminus ---
            if (variable_struct_exists(_rv, "has_lake") && _rv.has_lake) {
                var _lsx = _mx0 + (_rv.lake_x - _wx0) * _sx;
                var _lsy = _my0 + (_rv.lake_y - _wy0) * _sy;
                var _lake_shimmer = 0.60 + sin(current_time * 0.002) * 0.25;
                draw_set_color(_river_col);
                draw_set_alpha(0.50 * _lake_shimmer);
                draw_circle(_lsx, _lsy, 10, false);
                draw_set_alpha(0.25 * _lake_shimmer);
                draw_circle(_lsx, _lsy, 16, true); // outline ring
            }
        }

        // --- Animated coastline shimmer along ocean edge ---
        if (variable_struct_exists(obj_heartbeat.world, "has_ocean") &&
            obj_heartbeat.world.has_ocean) {
            var _oedge        = obj_heartbeat.world.ocean_edge;
            var _coast_shimmer = 0.55 + sin(current_time * 0.0025 + 1.2) * 0.30;
            draw_set_color(make_color_rgb(90, 170, 240));
            draw_set_alpha(0.65 * _coast_shimmer);
            if (_oedge == "LEFT")   draw_line_width(_mx0, _my0, _mx0, _my1, 3);
            if (_oedge == "RIGHT")  draw_line_width(_mx1, _my0, _mx1, _my1, 3);
            if (_oedge == "TOP")    draw_line_width(_mx0, _my0, _mx1, _my0, 3);
            if (_oedge == "BOTTOM") draw_line_width(_mx0, _my1, _mx1, _my1, 3);
        }

        draw_set_alpha(1);
    }

    // -----------------------------------------------------------------------
    // 6. HOVER TOOLTIP
    // -----------------------------------------------------------------------
    var _mouse_gx = device_mouse_x_to_gui(0);
    var _mouse_gy = device_mouse_y_to_gui(0);

    // Reset hovered ID each frame; set below when mouse is over a node
    obj_heartbeat.map_hovered_loc_id = "";

    for (var i = 0; i < array_length(_nodes); i++) {
        var _n = _nodes[i];
        if (point_distance(_mouse_gx, _mouse_gy, _n.sx, _n.sy) > _n.r + 10) continue;

        // Mouse is over this node — expose it for click-selection in Step_0
        obj_heartbeat.map_hovered_loc_id = _n.loc.id;

        var _t_name   = _n.loc.name;
        var _t_type   = string_lower(_n.loc.type);
        var _t_status = "[ unexplored ]";
        if (_n.is_cur)                     _t_status = "[ you are here ]";
        else if (_n.is_reach && _n.is_vis) _t_status = "[ visited  |  reachable ]";
        else if (_n.is_reach)              _t_status = "[ reachable ]";
        else if (_n.is_vis)                _t_status = "[ visited ]";
        // Append selection hint if this node is currently selected
        if (_n.loc.id == obj_heartbeat.selected_location_id) {
            _t_status += "  |  selected";
        }

        var _t_dist = "";
        if (_n.is_reach && variable_struct_exists(_route_map, _n.loc.id)) {
            var _rt_tip = _route_map[$ _n.loc.id];
            _t_dist = string(round(_rt_tip.distance)) + " km  |  " + string_lower(_rt_tip.terrain);
        }

        // Build "Buys:" line — cities broadcast their needs via messengers; towns/villages do not
        var _t_wants = "";
        if ((_n.is_vis || _n.is_cur)
        &&  _n.loc.type == "CITY"
        &&  variable_struct_exists(_n.loc, "economy")
        &&  array_length(_n.loc.economy.demands) > 0) {
            var _dem   = _n.loc.economy.demands;
            var _shown = min(array_length(_dem), 3);
            var _wstr  = "";
            for (var _di = 0; _di < _shown; _di++) {
                var _did   = _dem[_di].good_id;
                var _dname = _did; // fallback to raw id
                for (var _ci2 = 0; _ci2 < array_length(global.commodities); _ci2++) {
                    if (global.commodities[_ci2].id == _did) {
                        _dname = global.commodities[_ci2].name;
                        break;
                    }
                }
                if (_di > 0) _wstr += ", ";
                _wstr += _dname;
            }
            if (array_length(_dem) > 3) _wstr += "+";
            _t_wants = "Buys: " + _wstr;
        }

        var _lh    = string_height("A") + 3;
        var _lines = [_t_name, _t_type, _t_status];
        if (_t_dist  != "") array_push(_lines, _t_dist);
        if (_t_wants != "") array_push(_lines, _t_wants);

        var _tw = 0;
        for (var l = 0; l < array_length(_lines); l++) { _tw = max(_tw, string_width(_lines[l])); }
        _tw += 16;
        var _th = array_length(_lines) * _lh + 10;

        var _tx = _n.sx - _tw / 2;
        var _ty = _n.sy - _n.r - _th - 8;
        _tx = clamp(_tx, _px0 + 4, _px1 - _tw - 4);
        _ty = clamp(_ty, _py0 + 4, _py1 - _th - 4);

        draw_set_alpha(0.90);
        draw_set_color(make_color_rgb(6, 10, 20));
        draw_rectangle(_tx, _ty, _tx + _tw, _ty + _th, false);
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(78, 105, 132));
        draw_rectangle(_tx, _ty, _tx + _tw, _ty + _th, true);

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _lx = _tx + 8;
        var _ly = _ty + 5;

        var _nc = make_color_rgb(210, 188, 88);
        if (_n.is_cur)        _nc = make_color_rgb( 75, 230, 190);
        else if (_n.is_reach) _nc = make_color_rgb(165, 205, 255);
        draw_set_color(_nc);
        draw_text(_lx, _ly, _t_name);  _ly += _lh;

        draw_set_color(make_color_rgb(138, 138, 158));
        draw_text(_lx, _ly, _t_type);  _ly += _lh;

        draw_set_color(make_color_rgb(98, 158, 98));
        draw_text(_lx, _ly, _t_status);  _ly += _lh;

        if (_t_dist != "") {
            draw_set_color(make_color_rgb(158, 140, 98));
            draw_text(_lx, _ly, _t_dist);  _ly += _lh;
        }

        if (_t_wants != "") {
            draw_set_color(make_color_rgb(200, 170, 100));
            draw_text(_lx, _ly, _t_wants);
        }

        break;
    }

    // -----------------------------------------------------------------------
    // 7. LEGEND
    // -----------------------------------------------------------------------
    var _leg_y1 = _py1 - 46;
    var _leg_y2 = _py1 - 28;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Row 1: terrain colour swatches (tighter spacing to avoid right-edge clip)
    var _lx = _px0 + 8;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y1, "Terrain:");
    _lx += string_width("Terrain:") + 4;

    var _terrain_items = [
        { label: "Road",     col: _COL_ROAD     },
        { label: "Plains",   col: _COL_PLAINS   },
        { label: "Forest",   col: _COL_FOREST   },
        { label: "Hills",    col: _COL_HILLS    },
        { label: "Mountain", col: _COL_MOUNTAIN },
        { label: "Desert",   col: _COL_DESERT   }
    ];
    for (var i = 0; i < array_length(_terrain_items); i++) {
        var _li = _terrain_items[i];
        draw_set_color(_li.col);
        draw_line_width(_lx, _leg_y1 + 6, _lx + 12, _leg_y1 + 6, 2);
        draw_set_color(make_color_rgb(148, 148, 162));
        draw_text(_lx + 14, _leg_y1, _li.label);
        _lx += string_width(_li.label) + 20;
    }

    // Row 2: location-state dots + size guide (tighter spacing)
    _lx = _px0 + 8;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y2, "Locations:");
    _lx += string_width("Locations:") + 4;

    var _loc_items = [
        { label: "Current",   col: make_color_rgb( 55, 218, 178) },
        { label: "Visited",   col: make_color_rgb(215, 168,  48) },
        { label: "Reachable", col: make_color_rgb( 60, 128, 200) },
        { label: "Unknown",   col: make_color_rgb( 42,  46,  56) }
    ];
    for (var i = 0; i < array_length(_loc_items); i++) {
        var _ki = _loc_items[i];
        draw_set_color(_ki.col);
        draw_circle(_lx + 4, _leg_y2 + 6, 4, false);
        draw_set_color(make_color_rgb(148, 148, 162));
        draw_text(_lx + 12, _leg_y2, _ki.label);
        _lx += string_width(_ki.label) + 18;
    }

    // Size guide — squeezed right after location items
    _lx += 4;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y2, "Size:");
    _lx += string_width("Size:") + 3;
    var _size_items = [
        { label: "City", r: 8 },
        { label: "Town", r: 6 },
        { label: "Vill", r: 4 }
    ];
    for (var i = 0; i < array_length(_size_items); i++) {
        var _si = _size_items[i];
        draw_set_color(make_color_rgb(80, 100, 125));
        draw_circle(_lx + _si.r, _leg_y2 + 6, _si.r, false);
        draw_set_color(make_color_rgb(148, 148, 162));
        draw_text(_lx + _si.r * 2 + 3, _leg_y2, _si.label);
        _lx += _si.r * 2 + string_width(_si.label) + 8;
    }

    // -----------------------------------------------------------------------
    // RESET DRAW STATE
    // -----------------------------------------------------------------------
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
