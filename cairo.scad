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

// Short-edge half length (in cell units) for an equilateral pentagon.
c = (sqrt(7) - 1) / 6;

// Preview palette, loosely matched to the reference artwork.
palette = [
    "#E2533F",   // red
    "#C96F55",   // terracotta
    "#9A9EA3",   // gray
    "#7C9FB5",   // dusty blue
];
color_seed = 42;

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

function centroid(pts) = [
    sum_list([for (p = pts) p[0]]) / len(pts),
    sum_list([for (p = pts) p[1]]) / len(pts),
];
function sum_list(v, k = 0) = k >= len(v) ? 0 : v[k] + sum_list(v, k + 1);

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

// A single flat tile.
module tile(id, height = tile_thickness) {
    linear_extrude(height = height) tile_2d(id);
}

// Deterministic preview color per tile.
function tile_color(k) =
    palette[floor(rands(0, len(palette), 1, color_seed + k)[0]) % len(palette)];

// The full flat tiling.
module cairo_tiling() {
    for (k = [0 : len(tile_ids) - 1])
        color(tile_color(k)) tile(tile_ids[k]);
}

// Thin backing board outline, for reference only.
module backing_board() {
    color("#EDEDED")
        translate([0, 0, -3])
            linear_extrude(height = 3)
                square(region_size, center = true);
}

backing_board();
cairo_tiling();
