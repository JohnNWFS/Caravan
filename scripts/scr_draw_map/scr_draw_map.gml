/// @func scr_draw_map()
/// @desc Full-screen world map overlay.  Call from a Draw GUI event.
///       Reads world data from obj_heartbeat.world; player position from
///       obj_player.current_location.
///
/// Rendering layers (back to front):
///   1. Dim overlay + panel background
///   2. Non-reachable routes (very dim, monochrome)
///   3. Reachable routes (bright, terrain-coloured, thicker)
///   4. Location nodes (colour-coded by state)
///   5. Animated player marker (pulsing rings + crosshair)
///   6. Hover tooltip (name / type / status / distance)
///   7. Legend (terrain swatches + location-type key)

function scr_draw_map() {
    if (!instance_exists(obj_heartbeat)) return;
    if (obj_heartbeat.world == noone)    return;

    // -----------------------------------------------------------------------
    // CONSTANTS
    // -----------------------------------------------------------------------
    var _W  = display_get_gui_width();   // typically 640
    var _H  = display_get_gui_height();  // typically 480

    // Panel bounds
    var _px0 = 20;          // left
    var _py0 = 36;          // top
    var _px1 = _W - 20;     // right   (= 620)
    var _py1 = _H - 22;     // bottom  (= 458)

    // Map drawing area (inside panel, with padding + legend band at bottom)
    var _mx0 = _px0 + 20;   // 40
    var _my0 = _py0 + 20;   // 56
    var _mx1 = _px1 - 20;   // 600
    var _my1 = _py1 - 52;   // 406  (leaves 52px for two legend rows)

    var _mw  = _mx1 - _mx0; // 560
    var _mh  = _my1 - _my0; // 350

    // World coordinate ranges (locations are seeded into these bounds)
    var _wx0 = 100.0;  var _wx1 = 900.0;
    var _wy0 = 100.0;  var _wy1 = 700.0;

    // Scale: world unit → screen pixel
    var _sx = _mw / (_wx1 - _wx0);  // 560/800 = 0.700
    var _sy = _mh / (_wy1 - _wy0);  // 350/600 = 0.583

    // Inline helpers (used as expressions throughout)
    // screen x = _mx0 + (wx - _wx0) * _sx
    // screen y = _my0 + (wy - _wy0) * _sy

    // Terrain colours (RGB)
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

    // Subtle grid lines inside the map area
    draw_set_alpha(0.06);
    draw_set_color(make_color_rgb(120, 160, 200));
    var _grid_step = 56; // roughly every 80 world units
    for (var _gx = _mx0; _gx <= _mx1; _gx += _grid_step) {
        draw_line(_gx, _my0, _gx, _my1);
    }
    for (var _gy = _my0; _gy <= _my1; _gy += _grid_step) {
        draw_line(_mx0, _gy, _mx1, _gy);
    }
    draw_set_alpha(1);

    // Map area border
    draw_set_color(make_color_rgb(40, 55, 70));
    draw_rectangle(_mx0, _my0, _mx1, _my1, true);

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
    draw_set_color(make_color_rgb(110, 155, 110));
    draw_text(_W / 2, 22, "You are in: " + _player_loc_name);

    // -----------------------------------------------------------------------
    // CLOSE HINT (below panel)
    // -----------------------------------------------------------------------
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(80, 85, 95));
    draw_text(_W / 2, _py1 + 5, "Press ESC or click to close");

    // -----------------------------------------------------------------------
    // BUILD REACHABLE ROUTE MAP
    // route_map[$ dest_id] = route struct, for tooltip distance/terrain lookup
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

    // Helper: look up a location struct by id
    // (We'll do this inline when needed to avoid a second helper function)

    // -----------------------------------------------------------------------
    // 2. NON-REACHABLE ROUTES — dim, monochrome
    // -----------------------------------------------------------------------
    draw_set_alpha(0.22);
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

        draw_line(
            _mx0 + (_fl.x - _wx0) * _sx,  _my0 + (_fl.y - _wy0) * _sy,
            _mx0 + (_tl.x - _wx0) * _sx,  _my0 + (_tl.y - _wy0) * _sy
        );
    }
    draw_set_alpha(1);

    // -----------------------------------------------------------------------
    // 3. REACHABLE ROUTES — terrain-coloured, slightly thicker
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

        // Subtle glow (wide dim pass behind the bright line)
        draw_set_alpha(0.18);
        draw_set_color(_rcol);
        draw_line_width(_rx1, _ry1, _rx2, _ry2, 6);

        // Main line
        draw_set_alpha(0.88);
        draw_line_width(_rx1, _ry1, _rx2, _ry2, 2);
        draw_set_alpha(1);

        // Distance label at midpoint
        var _mid_x = (_rx1 + _rx2) / 2;
        var _mid_y = (_ry1 + _ry2) / 2;
        var _dist_str = string(round(_rt.distance)) + "km";
        var _angle = point_direction(_rx1, _ry1, _rx2, _ry2);
        // Offset label perpendicular to the line so it doesn't sit on it
        var _offset = 9;
        var _perp = _angle + 90;
        _mid_x += lengthdir_x(_offset, _perp);
        _mid_y += lengthdir_y(_offset, _perp);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_alpha(0.6);
        draw_set_color(make_color_rgb(200, 190, 140));
        draw_text(_mid_x, _mid_y, _dist_str);
        draw_set_alpha(1);
    }

    // -----------------------------------------------------------------------
    // 4. LOCATION NODES
    // -----------------------------------------------------------------------
    // Build node data array (we'll reuse it for hover detection)
    var _nodes = [];
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        var _loc = obj_heartbeat.world.locations[i];

        var _nsx = _mx0 + (_loc.x - _wx0) * _sx;
        var _nsy = _my0 + (_loc.y - _wy0) * _sy;
        var _nr  = 4;
        if (_loc.type == "CITY")  _nr = 9;
        else if (_loc.type == "TOWN") _nr = 6;

        var _is_cur  = (_loc.id == _player_loc_id);
        var _is_reach = false;
        for (var k = 0; k < array_length(_reachable_ids); k++) {
            if (_reachable_ids[k] == _loc.id) { _is_reach = true; break; }
        }
        var _is_vis = (variable_struct_exists(_loc, "economy") && _loc.economy.player_visited);

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

        // Shadow
        draw_set_alpha(0.3);
        draw_set_color(c_black);
        draw_circle(_nsx + 2, _nsy + 2, _nr + 1, false);
        draw_set_alpha(1);

        // Fill + edge
        draw_set_color(_fill);
        draw_circle(_nsx, _nsy, _nr, false);
        draw_set_color(_edge);
        draw_circle(_nsx, _nsy, _nr, true);

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

    var _t = current_time * 0.002; // time driver

    // Two offset pulsing rings
    for (var _p = 0; _p < 2; _p++) {
        var _phase = _t + _p * pi;
        var _pulse = (sin(_phase) + 1) * 0.5;          // 0..1
        var _pr    = 12 + _pulse * 10;                  // radius 12..22
        var _pa    = 0.60 - _pulse * 0.52;              // alpha  0.60..0.08
        draw_set_alpha(_pa);
        draw_set_color(make_color_rgb(70, 230, 188));
        draw_circle(_psx, _psy, _pr, true);
    }

    // Slow-spinning dashed triangular "pointer" ring (three dots orbiting)
    draw_set_alpha(0.85);
    draw_set_color(c_white);
    var _orbit_r = 14;
    for (var _d = 0; _d < 3; _d++) {
        var _da = _t * 60 + _d * 120; // degrees, rotating
        var _ox = _psx + lengthdir_x(_orbit_r, _da);
        var _oy = _psy + lengthdir_y(_orbit_r, _da);
        draw_circle(_ox, _oy, 1.5, false);
    }

    draw_set_alpha(1);

    // Static crosshair at exact position
    draw_set_color(c_white);
    draw_line_width(_psx - 7, _psy,     _psx + 7, _psy,     2);
    draw_line_width(_psx,     _psy - 7, _psx,     _psy + 7, 2);

    // -----------------------------------------------------------------------
    // 6. HOVER TOOLTIP
    // -----------------------------------------------------------------------
    var _mouse_gx = device_mouse_x_to_gui(0);
    var _mouse_gy = device_mouse_y_to_gui(0);

    for (var i = 0; i < array_length(_nodes); i++) {
        var _n = _nodes[i];
        if (point_distance(_mouse_gx, _mouse_gy, _n.sx, _n.sy) > _n.r + 10) continue;

        // Build text lines
        var _t_name   = _n.loc.name;
        var _t_type   = string_lower(_n.loc.type);
        var _t_status = "[ unexplored ]";
        if (_n.is_cur)                        _t_status = "[ you are here ]";
        else if (_n.is_reach && _n.is_vis)    _t_status = "[ visited  |  reachable ]";
        else if (_n.is_reach)                 _t_status = "[ reachable ]";
        else if (_n.is_vis)                   _t_status = "[ visited ]";

        var _t_dist = "";
        if (_n.is_reach && variable_struct_exists(_route_map, _n.loc.id)) {
            var _rt_tip = _route_map[$ _n.loc.id];
            _t_dist = string(round(_rt_tip.distance)) + " km  |  " + string_lower(_rt_tip.terrain);
        }

        // Measure
        var _lh    = string_height("A") + 3;
        var _lines = [_t_name, _t_type, _t_status];
        if (_t_dist != "") array_push(_lines, _t_dist);

        var _tw = 0;
        for (var l = 0; l < array_length(_lines); l++) { _tw = max(_tw, string_width(_lines[l])); }
        _tw += 16;
        var _th = array_length(_lines) * _lh + 10;

        // Position (above node; clamp to panel edges)
        var _tx = _n.sx - _tw / 2;
        var _ty = _n.sy - _n.r - _th - 8;
        _tx = clamp(_tx, _px0 + 4, _px1 - _tw - 4);
        _ty = clamp(_ty, _py0 + 4, _py1 - _th - 4);

        // Background
        draw_set_alpha(0.90);
        draw_set_color(make_color_rgb(6, 10, 20));
        draw_rectangle(_tx, _ty, _tx + _tw, _ty + _th, false);
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(78, 105, 132));
        draw_rectangle(_tx, _ty, _tx + _tw, _ty + _th, true);

        // Text
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _lx = _tx + 8;
        var _ly = _ty + 5;

        // Name
        var _nc = make_color_rgb(210, 188, 88);
        if (_n.is_cur)   _nc = make_color_rgb( 75, 230, 190);
        else if (_n.is_reach) _nc = make_color_rgb(165, 205, 255);
        draw_set_color(_nc);
        draw_text(_lx, _ly, _t_name);  _ly += _lh;

        // Type
        draw_set_color(make_color_rgb(138, 138, 158));
        draw_text(_lx, _ly, _t_type);  _ly += _lh;

        // Status
        draw_set_color(make_color_rgb(98, 158, 98));
        draw_text(_lx, _ly, _t_status);  _ly += _lh;

        // Distance/terrain
        if (_t_dist != "") {
            draw_set_color(make_color_rgb(158, 140, 98));
            draw_text(_lx, _ly, _t_dist);
        }

        break; // one tooltip at a time
    }

    // -----------------------------------------------------------------------
    // 7. LEGEND
    // -----------------------------------------------------------------------
    var _leg_y1 = _py1 - 46; // top of first legend row
    var _leg_y2 = _py1 - 28; // top of second legend row

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // -- Row 1: terrain colour swatches --
    var _lx = _px0 + 8;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y1, "Terrain:");
    _lx += string_width("Terrain:") + 6;

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
        draw_line_width(_lx, _leg_y1 + 6, _lx + 14, _leg_y1 + 6, 2);
        draw_set_color(make_color_rgb(148, 148, 162));
        draw_text(_lx + 16, _leg_y1, _li.label);
        _lx += string_width(_li.label) + 24;
    }

    // -- Row 2: location-state colour dots --
    _lx = _px0 + 8;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y2, "Locations:");
    _lx += string_width("Locations:") + 6;

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
        _lx += string_width(_ki.label) + 22;
    }

    // -- Size guide --
    _lx += 10;
    draw_set_color(make_color_rgb(78, 82, 94));
    draw_text(_lx, _leg_y2, "Size:");
    _lx += string_width("Size:") + 4;
    var _size_items = [
        { label: "City", r: 9  },
        { label: "Town", r: 6  },
        { label: "Vill", r: 4  }
    ];
    for (var i = 0; i < array_length(_size_items); i++) {
        var _si = _size_items[i];
        draw_set_color(make_color_rgb(80, 100, 125));
        draw_circle(_lx + _si.r, _leg_y2 + 6, _si.r, false);
        draw_set_color(make_color_rgb(148, 148, 162));
        draw_text(_lx + _si.r * 2 + 4, _leg_y2, _si.label);
        _lx += _si.r * 2 + string_width(_si.label) + 10;
    }

    // -----------------------------------------------------------------------
    // RESET DRAW STATE
    // -----------------------------------------------------------------------
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
