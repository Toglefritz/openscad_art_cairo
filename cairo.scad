// =============================================================================
// Cairo Pentagonal Tiling Wall Art
// =============================================================================
//
// Step 1: A flat Cairo pentagonal tiling covering a 30 x 30 inch region.
//
// Units are millimeters. Dimensions are specified in inches and converted.
//
// -----------------------------------------------------------------------------
// How the tiling is constructed
// -----------------------------------------------------------------------------
// Start with a square lattice of points (i, j) spaced `cell` apart. These
// become the degree-4 vertices of the tiling. Inside every lattice square we
// place one short edge through the square's center; the edge is horizontal or
// vertical in a checkerboard pattern. Each endpoint of that short edge is
// joined to the two nearest lattice corners.
//
// The result is a Cairo tiling with exactly one pentagon straddling every
// lattice edge (two pentagons per lattice cell). Pairs of pentagons that share
// a short edge form the characteristic hexagons that alternate horizontal and
// vertical, like a basket weave.
//
// With half-length c = (sqrt(7) - 1) / 6 (in cell units) all five sides of
// every pentagon are equal, which gives the classic equilateral Cairo tile.
// =============================================================================

// ---- Units ------------------------------------------------------------------
inch = 25.4;

// ---- Artwork parameters -----------------------------------------------------
region_size    = 30 * inch;   // Width and height of the square artwork region
cell           = 2 * inch;    // Lattice spacing (each cell holds 2 pentagons)
gap            = 1.5;         // Gap between neighbouring tiles (mm)
tile_thickness = 6;           // Thickness of a flat tile (mm)
tiling_angle   = 0;           // Rotate the pattern within the region (degrees)
clip_to_region = true;        // true: trim edge tiles to the square region
                              // false: only keep tiles fully inside the region

// ---- Ring (raised circular section) parameters ------------------------------
ring_outer_diameter = 24 * inch;  // Outer edge of the raised ring
ring_inner_diameter = 8 * inch;   // The "donut hole" in the middle
ring_center         = [0, 0];     // Ring center (mm), relative to region center
show_ring_guides    = false;       // Draw thin guide circles in the preview

// Ring tile heights sweep around the ring center. Starting at
// `ring_start_angle`, heights grow from `ring_height_start_factor` to
// `ring_height_end_factor` (multiples of tile_thickness) over one full turn.
// Angles use the standard math convention: 0 = 3:00, 90 = 12:00, 180 = 9:00.
ring_height_start_factor = 2;     // Height factor at the start angle (9:00)
ring_height_end_factor   = 10;     // Height factor just before returning to start
ring_start_angle         = 180;   // Where the sweep starts (180 = 9:00)
ring_clockwise           = true;  // Direction the heights increase

// Ring tile side walls taper inward (draft) following the same sweep. The
// draft angle is measured from vertical: 0 = straight walls, larger values
// make the top face smaller than the base. Background tiles have no draft.
ring_draft_start_angle = 0;       // Draft angle at the start angle (degrees)
ring_draft_end_angle   = 5;      // Draft angle just before returning to start

// Short-edge half length (in cell units) for an equilateral pentagon.
c = (sqrt(7) - 1) / 6;

// ---- Filament colors (Bambu Lab PLA Matte hex codes) -------------------------
pla_ivory_white     = "#FFFFFF";
pla_bone_white      = "#CBC6B8";
pla_desert_tan      = "#E8DBB7";
pla_latte_brown     = "#D3B7A7";
pla_caramel         = "#AE835B";
pla_terracotta      = "#B15533";
pla_dark_brown      = "#7D6556";
pla_dark_chocolate  = "#4D3324";
pla_lilac_purple    = "#AE96D4";
pla_sakura_pink     = "#E8AFCF";
pla_mandarin_orange = "#F99963";
pla_lemon_yellow    = "#F7D959";
pla_plum            = "#950051";
pla_scarlet_red     = "#DE4343";
pla_dark_red        = "#BB3D43";
pla_dark_green      = "#68724D";
pla_grass_green     = "#61C680";
pla_apple_green     = "#C2E189";
pla_ice_blue        = "#A3D8E1";
pla_sky_blue        = "#56B7E6";
pla_marine_blue     = "#0078BF";
pla_dark_blue       = "#042F56";
pla_ash_gray        = "#9B9EA0";
pla_nardo_gray      = "#757575";
pla_charcoal        = "#000000";

// ---- Preview palettes ---------------------------------------------------------
// Background tiles and ring tiles pick from separate palettes. The default
// uses four filaments in total, so everything fits in a single AMS unit.
background_palette = [pla_ash_gray, pla_nardo_gray, pla_caramel];
ring_palette       = [pla_terracotta, pla_dark_red];

// Alternative: print background and ring in separate batches, swapping spools
// between them, to get closer to the reference artwork's blues and peaches.
// background_palette = [pla_scarlet_red, pla_ash_gray, pla_ice_blue];
// ring_palette       = [pla_terracotta, pla_dark_green, pla_scarlet_red, pla_latte_brown];

// Repeat an entry in a palette to make that color appear more often.
color_seed = 42;

// Filament names for export file names. Keep in sync with the colors above.
filament_table = [
    ["ivory_white", pla_ivory_white],         ["bone_white", pla_bone_white],
    ["desert_tan", pla_desert_tan],           ["latte_brown", pla_latte_brown],
    ["caramel", pla_caramel],                 ["terracotta", pla_terracotta],
    ["dark_brown", pla_dark_brown],           ["dark_chocolate", pla_dark_chocolate],
    ["lilac_purple", pla_lilac_purple],       ["sakura_pink", pla_sakura_pink],
    ["mandarin_orange", pla_mandarin_orange], ["lemon_yellow", pla_lemon_yellow],
    ["plum", pla_plum],                       ["scarlet_red", pla_scarlet_red],
    ["dark_red", pla_dark_red],               ["dark_green", pla_dark_green],
    ["grass_green", pla_grass_green],         ["apple_green", pla_apple_green],
    ["ice_blue", pla_ice_blue],               ["sky_blue", pla_sky_blue],
    ["marine_blue", pla_marine_blue],         ["dark_blue", pla_dark_blue],
    ["ash_gray", pla_ash_gray],               ["nardo_gray", pla_nardo_gray],
];

// ---- Printing / export ------------------------------------------------------
// Bambu Lab P1S build plate is 256 x 256 x 256 mm. A 762 mm artwork needs at
// least a 4 x 4 grid once whole tiles overhang the panel lines.
bed_size             = [256, 256];
bed_margin           = 2;              // Clearance kept on each side of the bed
panels_x             = 4;              // Panel columns
panels_y             = 4;              // Panel rows
panel_base_thickness = 0;              // Base joining a panel's tiles (0 = loose tiles)
base_color           = pla_charcoal;   // Filament for the base (shows in the gaps)

// ---- Assembly trays ---------------------------------------------------------
// A standalone flat plate per panel with shallow pentagonal recesses. Print
// the tray first, then drop loose tiles into their recesses as they come off
// the printer. Tray outlines follow the panel outlines, so neighbouring trays
// interlock just like the panels.
trays_enabled       = true;           // Export a tray for every panel
tray_floor          = 1.2;            // Solid plate thickness under the recesses (mm)
tray_recess_depth   = 1.2;            // Depth of each pentagonal recess (mm)
tray_clearance      = 0.15;           // Extra room around each tile in its recess (mm)
tray_seam_gap       = 0.2;            // Gap between neighbouring trays (mm)
tray_color          = pla_nardo_gray; // Preview / suggested filament for trays
tray_label          = true;           // Deboss the panel ID on the tray underside
tray_label_size     = 14;             // Label text height (mm)
tray_label_depth    = 0.4;            // Label deboss depth (mm)
preview_trays       = false;          // Show trays under the tiles in the preview

// What to output:
//   "preview" - the whole artwork (default)
//   "panel"   - one panel for export, chosen by panel_col / panel_row
//   "tray"    - the assembly tray for one panel, chosen by panel_col / panel_row
//   "info"    - no geometry, just the panel report and export manifest
part           = "preview";
panel_col      = 0;      // 0 = left column
panel_row      = 0;      // 0 = bottom row
export_color   = "all";  // "all", "base", or a filament hex code such as pla_terracotta
preview_spread = 0;      // Pull panels apart in the preview (mm) to see the split

// =============================================================================
// Tiling geometry (all in cell units; scaled by `cell` when drawn)
// =============================================================================

// Non-negative modulo, since OpenSCAD's % keeps the sign of the dividend.
function pmod(a, m) = ((a % m) + m) % m;

// True if the short edge in lattice square (i, j) runs horizontally.
function is_horizontal(i, j) = pmod(i + j, 2) == 0;

// Endpoints of the short edge in lattice square (i, j).
function left_pt(i, j)   = [i + 0.5 - c, j + 0.5];
function right_pt(i, j)  = [i + 0.5 + c, j + 0.5];
function bottom_pt(i, j) = [i + 0.5,     j + 0.5 - c];
function top_pt(i, j)    = [i + 0.5,     j + 0.5 + c];

// Pentagon straddling the vertical lattice edge (i, j)-(i, j+1).
// Its neighbours are lattice squares (i-1, j) on the left and (i, j) on the right.
function pentagon_v(i, j) =
    is_horizontal(i - 1, j)
        ? [[i, j], bottom_pt(i, j), top_pt(i, j), [i, j + 1], right_pt(i - 1, j)]
        : [[i, j], left_pt(i, j), [i, j + 1], top_pt(i - 1, j), bottom_pt(i - 1, j)];

// Pentagon straddling the horizontal lattice edge (i, j)-(i+1, j).
// Its neighbours are lattice squares (i, j-1) below and (i, j) above.
function pentagon_h(i, j) =
    is_horizontal(i, j)
        ? [[i, j], top_pt(i, j - 1), [i + 1, j], right_pt(i, j), left_pt(i, j)]
        : [[i, j], left_pt(i, j - 1), right_pt(i, j - 1), [i + 1, j], bottom_pt(i, j)];

// Pentagon for a tile id [i, j, dir] where dir is 0 (vertical) or 1 (horizontal).
function pentagon(id) =
    id[2] == 0 ? pentagon_v(id[0], id[1]) : pentagon_h(id[0], id[1]);

// Pentagon vertices in mm, rotated by tiling_angle about the region center.
function rot2(p, a) = [p[0] * cos(a) - p[1] * sin(a), p[0] * sin(a) + p[1] * cos(a)];
function tile_points(id) = [for (p = pentagon(id)) rot2(p * cell, tiling_angle)];

function sum_list(v, k = 0) = k >= len(v) ? 0 : v[k] + sum_list(v, k + 1);

// Area centroid of a simple polygon (shoelace formula). Unlike a plain vertex
// average, this is the true geometric center of the tile.
function cross_term(pts, k) =
    let (a = pts[k], b = pts[(k + 1) % len(pts)])
    a[0] * b[1] - b[0] * a[1];
function polygon_area(pts) =
    sum_list([for (k = [0 : len(pts) - 1]) cross_term(pts, k)]) / 2;
function centroid(pts) =
    let (A = polygon_area(pts))
    [
        sum_list([for (k = [0 : len(pts) - 1])
            (pts[k][0] + pts[(k + 1) % len(pts)][0]) * cross_term(pts, k)]) / (6 * A),
        sum_list([for (k = [0 : len(pts) - 1])
            (pts[k][1] + pts[(k + 1) % len(pts)][1]) * cross_term(pts, k)]) / (6 * A),
    ];

// Center of a tile in mm. Uses the full (unclipped) pentagon so that edge
// tiles are classified by where the whole pentagon sits.
function tile_center(id) = centroid(tile_points(id));

// =============================================================================
// Tile selection
// =============================================================================
// The region is centered on the origin, which is a lattice point, so the
// pattern is symmetric about the middle of the artwork.

half = region_size / 2;

// Enough lattice indices to cover the region even when the tiling is rotated.
n_idx = ceil(half * sqrt(2) / cell) + 1;

function inside_region(p) = abs(p[0]) <= half && abs(p[1]) <= half;
function all_inside(pts)  = len([for (p = pts) if (!inside_region(p)) 1]) == 0;
function any_inside(pts)  = len([for (p = pts) if (inside_region(p)) 1]) > 0;

// A tile is kept if it touches the region (clipping) or lies fully within it.
// Note: any_inside uses vertices only; with cell << region_size that is enough.
function keep_tile(id) =
    clip_to_region ? any_inside(tile_points(id)) : all_inside(tile_points(id));

tile_ids = [
    for (i = [-n_idx : n_idx], j = [-n_idx : n_idx], dir = [0, 1])
        let (id = [i, j, dir])
        if (keep_tile(id)) id
];

echo(str("Tile count: ", len(tile_ids)));

// =============================================================================
// Ring classification and tile heights
// =============================================================================

ring_r_outer = ring_outer_diameter / 2;
ring_r_inner = ring_inner_diameter / 2;

// Distance from the ring center to the center of a tile.
function ring_distance(id) = norm(tile_center(id) - ring_center);

// True if the tile's center falls between the inner and outer circles.
function in_ring(id) =
    let (d = ring_distance(id))
    d >= ring_r_inner && d <= ring_r_outer;

// Angle of a tile's center about the ring center (degrees, -180..180).
function ring_angle(id) =
    let (v = tile_center(id) - ring_center)
    atan2(v[1], v[0]);

// Fraction of a full turn (0..1) traveled from the start angle to the tile,
// measured in the sweep direction. 0 at the start, approaching 1 just before it.
function ring_sweep(id) =
    let (delta = ring_clockwise
                     ? ring_start_angle - ring_angle(id)
                     : ring_angle(id) - ring_start_angle)
    pmod(delta, 360) / 360;

// Height multiplier for a ring tile, interpolated linearly around the ring.
function ring_height_factor(id) =
    ring_height_start_factor
        + (ring_height_end_factor - ring_height_start_factor) * ring_sweep(id);

// Height of each tile. This is the single place to add more detail later.
function tile_height(id) =
    in_ring(id) ? tile_thickness * ring_height_factor(id) : tile_thickness;

// Draft angle for a ring tile, interpolated linearly around the ring.
function ring_draft_angle(id) =
    ring_draft_start_angle
        + (ring_draft_end_angle - ring_draft_start_angle) * ring_sweep(id);

// Draft angle of each tile (degrees from vertical).
function tile_draft(id) = in_ring(id) ? ring_draft_angle(id) : 0;

// Horizontal distance each side wall moves inward from base to top.
function tile_inset(id) = tile_height(id) * tan(tile_draft(id));

ring_heights = [for (id = tile_ids) if (in_ring(id)) tile_height(id)];
ring_drafts  = [for (id = tile_ids) if (in_ring(id)) tile_draft(id)];
ring_insets  = [for (id = tile_ids) if (in_ring(id)) tile_inset(id)];
echo(str("Ring tile count: ", len(ring_heights),
         ", height range: ", min(ring_heights), " to ", max(ring_heights), " mm"));
echo(str("Ring draft range: ", min(ring_drafts), " to ", max(ring_drafts),
         " deg, max top inset: ", max(ring_insets), " mm"));

// =============================================================================
// Rendering
// =============================================================================

// 2D outline of a single tile, shrunk by half the gap and clipped if enabled.
module tile_2d(id) {
    intersection() {
        offset(delta = -gap / 2) polygon(tile_points(id));
        if (clip_to_region)
            square(region_size, center = true);
    }
}

// A single tile. With a draft angle, the top face is the base outline offset
// inward by height * tan(draft), and the solid is the hull of base and top.
// Every tile outline is convex (a pentagon, possibly clipped by the square),
// so the hull gives exact planar, evenly tapered side walls.
module tile(id, height = tile_thickness, draft = 0) {
    inset = height * tan(draft);
    eps   = 0.01;
    if (inset <= 0) {
        linear_extrude(height = height) tile_2d(id);
    } else {
        hull() {
            linear_extrude(height = eps) tile_2d(id);
            translate([0, 0, height - eps])
                linear_extrude(height = eps)
                    offset(delta = -inset) tile_2d(id);
        }
    }
}

// Deterministic pick from a palette for tile number k.
function pick_color(pal, k) =
    pal[floor(rands(0, len(pal), 1, color_seed + k)[0]) % len(pal)];

// Color per tile: ring tiles use ring_palette, the rest use background_palette.
function tile_color(id, k) =
    pick_color(in_ring(id) ? ring_palette : background_palette, k);

// Colors are fixed once here so preview and export always agree.
tile_colors = [for (k = [0 : len(tile_ids) - 1]) tile_color(tile_ids[k], k)];

// Human-readable filament name for a hex code (used in export file names).
function filament_name(hex) =
    let (m = [for (e = filament_table) if (e[1] == hex) e[0]])
    len(m) > 0 ? m[0] : hex;

// =============================================================================
// Print panels
// =============================================================================
// The artwork is divided into a grid of panels that each fit on the print bed.
// Tiles are never cut: each tile belongs to the panel that contains its
// center, so panel edges follow the tile outlines and neighbouring panels
// interlock like puzzle pieces.

panel_w = region_size / panels_x;
panel_h = region_size / panels_y;

function clampv(v, lo, hi) = max(lo, min(hi, v));

// [column, row] of the panel that owns a tile. [0, 0] is the bottom-left.
function tile_panel(id) =
    let (p = tile_center(id))
    [clampv(floor((p[0] + half) / panel_w), 0, panels_x - 1),
     clampv(floor((p[1] + half) / panel_h), 0, panels_y - 1)];

tile_panels = [for (id = tile_ids) tile_panel(id)];

// Indices (into tile_ids) of the tiles in a panel.
function panel_tiles(col, row) =
    [for (k = [0 : len(tile_ids) - 1]) if (tile_panels[k] == [col, row]) k];

// Bounding box [[xmin, ymin], [xmax, ymax]] of a panel's tiles, in mm.
function panel_bbox(col, row) =
    let (pts = [for (k = panel_tiles(col, row))
                    for (p = tile_points(tile_ids[k]))
                        [clampv(p[0], -half, half), clampv(p[1], -half, half)]],
         xs = [for (p = pts) p[0]],
         ys = [for (p = pts) p[1]])
    [[min(xs), min(ys)], [max(xs), max(ys)]];

function panel_size(col, row)   = let (b = panel_bbox(col, row)) b[1] - b[0];
function panel_center(col, row) = let (b = panel_bbox(col, row)) (b[0] + b[1]) / 2;
function panel_fits(col, row) =
    let (s = panel_size(col, row))
    s[0] <= bed_size[0] - 2 * bed_margin && s[1] <= bed_size[1] - 2 * bed_margin;

// Unique entries of a list, in order of first appearance.
function index_of(v, x, i = 0) =
    i >= len(v) ? -1 : v[i] == x ? i : index_of(v, x, i + 1);
function unique(v) = [for (i = [0 : len(v) - 1]) if (index_of(v, v[i]) == i) v[i]];

function panel_colors(col, row) = unique([for (k = panel_tiles(col, row)) tile_colors[k]]);

// Height of the tallest piece in a panel, including the base.
function panel_max_height(col, row) =
    panel_base_thickness + max([for (k = panel_tiles(col, row)) tile_height(tile_ids[k])]);

// Thin base under a panel that fills the gaps between its tiles and holds them
// in position. Its outer edge follows the tile outlines, so neighbouring
// panels keep the same `gap` between them as tiles within a panel.
module panel_base(col, row) {
    linear_extrude(height = panel_base_thickness)
        panel_outline_2d(col, row, gap / 2);
}

// Outline of a panel: the union of its full pentagons, pulled in by `shrink`
// and trimmed to the artwork square.
module panel_outline_2d(col, row, shrink) {
    intersection() {
        offset(delta = -shrink)
            union()
                for (k = panel_tiles(col, row))
                    polygon(tile_points(tile_ids[k]));
        square(region_size, center = true);
    }
}

// The tiles of a panel, optionally limited to one filament color, raised by z.
module panel_tile_set(col, row, only_color = "all", z = 0) {
    for (k = panel_tiles(col, row))
        if (only_color == "all" || tile_colors[k] == only_color)
            color(tile_colors[k])
                translate([0, 0, z + panel_base_thickness])
                    tile(tile_ids[k], tile_height(tile_ids[k]), tile_draft(tile_ids[k]));
}

// One panel in artwork coordinates. `part_color` selects what to include:
// "all" (base and tiles), "base" (base only), or a filament hex code.
module panel(col, row, part_color = "all", z = 0) {
    if (panel_base_thickness > 0 && (part_color == "all" || part_color == "base"))
        color(base_color) translate([0, 0, z]) panel_base(col, row);
    if (part_color != "base")
        panel_tile_set(col, row, part_color, z);
}

// -----------------------------------------------------------------------------
// Assembly trays
// -----------------------------------------------------------------------------

tray_thickness = tray_floor + tray_recess_depth;

// Wall widths left between recesses, reported so they can be checked against
// the nozzle width (0.4 mm on a stock P1S).
tray_inner_wall = gap - 2 * tray_clearance;
tray_seam_wall  = gap / 2 - tray_clearance - tray_seam_gap / 2;

// Text label for a tray, mirrored so it reads correctly from underneath.
module tray_label_2d(col, row) {
    mirror([1, 0, 0])
        text(str("c", col, " r", row), size = tray_label_size,
             halign = "center", valign = "center");
}

// The tray for one panel, in artwork coordinates.
module tray(col, row) {
    c0 = panel_center(col, row);
    difference() {
        linear_extrude(height = tray_thickness)
            panel_outline_2d(col, row, tray_seam_gap / 2);

        // Pentagonal recesses (a single recess for a joined panel base).
        translate([0, 0, tray_floor])
            linear_extrude(height = tray_recess_depth + 1)
                if (panel_base_thickness > 0)
                    offset(delta = tray_clearance) panel_outline_2d(col, row, gap / 2);
                else
                    for (k = panel_tiles(col, row))
                        offset(delta = tray_clearance) tile_2d(tile_ids[k]);

        // Panel ID debossed into the underside.
        if (tray_label)
            translate([c0[0], c0[1], -1])
                linear_extrude(height = tray_label_depth + 1)
                    tray_label_2d(col, row);
    }
}

// Print a summary of every panel so bed fit can be checked at a glance.
module panel_report() {
    for (row = [panels_y - 1 : -1 : 0], col = [0 : panels_x - 1]) {
        s = panel_size(col, row);
        echo(str("Panel c", col, " r", row, ": ",
                 len(panel_tiles(col, row)), " tiles, ",
                 round(s[0]), " x ", round(s[1]), " x ",
                 round(panel_max_height(col, row)), " mm, ",
                 len(panel_colors(col, row)), " colors, ",
                 panel_fits(col, row) ? "fits" : "TOO LARGE FOR BED"));
    }
    if (trays_enabled)
        echo(str("Trays: ", tray_thickness, " mm thick, ",
                 tray_recess_depth, " mm recesses, walls ",
                 tray_inner_wall, " mm between tiles and ",
                 tray_seam_wall, " mm at tray seams",
                 min(tray_inner_wall, tray_seam_wall) < 0.4
                     ? " (WARNING: thinner than a 0.4 mm nozzle line)" : ""));
}

// Machine-readable list of every STL to export (read by export_panels.sh).
module export_manifest() {
    for (row = [0 : panels_y - 1], col = [0 : panels_x - 1]) {
        if (panel_base_thickness > 0)
            echo(str("EXPORT_PART ", col, " ", row, " base base"));
        for (hex = panel_colors(col, row))
            echo(str("EXPORT_PART ", col, " ", row, " ", hex, " ", filament_name(hex)));
        if (trays_enabled)
            echo(str("EXPORT_PART ", col, " ", row, " tray tray"));
    }
}

// The full assembled artwork, optionally with panels pulled apart. With
// preview_trays, each panel's tiles sit in their recesses on its tray.
module cairo_tiling(spread = 0) {
    for (row = [0 : panels_y - 1], col = [0 : panels_x - 1])
        translate([(col - (panels_x - 1) / 2) * spread,
                   (row - (panels_y - 1) / 2) * spread, 0]) {
            if (preview_trays) {
                color(tray_color) tray(col, row);
                panel(col, row, z = tray_floor);
            } else {
                panel(col, row);
            }
        }
}

// Thin guide circles marking the ring boundaries, for preview only.
module ring_guides(width = 2) {
    color("black")
        translate([ring_center[0], ring_center[1], 0])
            linear_extrude(height = tile_thickness
                                    * max(ring_height_start_factor, ring_height_end_factor) + 1)
                for (r = [ring_r_inner, ring_r_outer])
                    difference() {
                        circle(r = r + width / 2, $fn = 180);
                        circle(r = r - width / 2, $fn = 180);
                    }
}

// Thin backing board outline, for reference only.
module backing_board() {
    color("#EDEDED")
        translate([0, 0, -3])
            linear_extrude(height = 3)
                square(region_size, center = true);
}

// =============================================================================
// Output selection
// =============================================================================

if (part == "preview") {
    panel_report();
    backing_board();
    cairo_tiling(spread = preview_spread);
    if (show_ring_guides) %ring_guides();
} else if (part == "panel") {
    // A single panel (or one color of it), centered on the origin for export.
    // Every color of a panel uses the same offset, so the STLs line up when
    // loaded together as parts of one object in Bambu Studio.
    c0 = panel_center(panel_col, panel_row);
    translate([-c0[0], -c0[1], 0])
        panel(panel_col, panel_row, export_color);
} else if (part == "tray") {
    // A single panel's assembly tray, centered on the origin for export.
    c0 = panel_center(panel_col, panel_row);
    translate([-c0[0], -c0[1], 0])
        tray(panel_col, panel_row);
} else if (part == "info") {
    panel_report();
    export_manifest();
}
