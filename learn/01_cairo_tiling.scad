// =============================================================================
// Learn 01: The Cairo Pentagonal Tiling
// =============================================================================
//
// A small, standalone version of the tiling algorithm used in ../cairo.scad.
// It draws a flat Cairo tiling and can overlay the square lattice cells the
// tiling is built from, so you can see how the pentagons and hexagons come
// out of a plain grid of squares.
//
// Open this file in OpenSCAD, press F5 (Preview), and view it from the top
// (View > Top, and View > Orthogonal works best). Change the settings below
// and preview again to see what each one does.
//
// -----------------------------------------------------------------------------
// The idea in four steps
// -----------------------------------------------------------------------------
// 1. Start with a grid of square CELLS. Their corners are LATTICE POINTS.
//    Every lattice point becomes a spot where four pentagons meet.
//
// 2. Put one SHORT EDGE through the center of every cell. Neighbouring cells
//    alternate between a horizontal and a vertical short edge, like the
//    colors of a checkerboard.
//
// 3. Join each end of a short edge to the two nearest corners of its cell.
//    These are the LONG EDGES. Short and long edges together are every edge
//    in the tiling.
//
// 4. The edges now enclose pentagons, one straddling every side of every
//    cell. The two pentagons that share a short edge form a HEXAGON. Cells
//    with a horizontal short edge give "horizontal" hexagons, and the rest
//    give "vertical" ones. That alternation is the basket-weave look.
//
// Try this: set color_mode = "orientation", turn on show_cells and
// show_short_edges, and pick a focus_cell. Each hexagon is anchored on one
// cell: four of its six corners are the cell's corners, the cell's short edge
// splits it into its two pentagons, and its last two corners poke out into
// the neighbouring cells.
// =============================================================================

// ---- Tiling -----------------------------------------------------------------
cell        = 50;     // Size of one square lattice cell (mm)
cols        = 6;      // Number of cells across
rows        = 6;      // Number of cells up
gap         = 1.0;    // Space between neighbouring pentagons (mm). 0 = touching.

// The short edge's half-length, as a fraction of the cell size. With
// equilateral = true it is (sqrt(7) - 1) / 6, about 0.274, which makes all
// five sides of every pentagon equal (the classic Cairo tile, as used in
// ../cairo.scad). Set equilateral = false and change custom_c to see the
// shape change:
//   custom_c near 0   -> the short edge shrinks and pentagons become squares
//                        tilted 45 degrees
//   custom_c near 0.5 -> the short edge spans the whole cell and pentagons
//                        flatten into half-cell rectangles
equilateral = true;
custom_c    = 0.15;   // Used only when equilateral = false (0 < custom_c < 0.5)

// ---- What to draw -----------------------------------------------------------
// "diagram": colored, layered drawing for learning (use F5 Preview).
// "2d":      pure 2D tile outlines only, for export to SVG or DXF (use F6).
mode                = "diagram";

show_tiles          = true;   // The pentagons themselves
show_cells          = true;   // Outline the square lattice cells
show_short_edges    = true;   // Highlight each cell's short edge
show_lattice_points = true;   // Dots where four pentagons meet
show_labels         = true;  // Label each cell with its [i, j] index

// How pentagons are colored:
//   "orientation" - by hexagon direction: horizontal vs vertical hexagons
//   "hexagon"     - each hexagon (pentagon pair) a random palette color
//   "pentagon"    - each pentagon a random palette color, like ../cairo.scad
//   "single"      - every pentagon the same color
color_mode = "orientation";

// Highlight one cell and the hexagon built on it, for example [2, 3].
// Cells are numbered from 0 at the bottom-left. [-1, -1] turns this off.
focus_cell = [-1, -1];

// ---- Appearance -------------------------------------------------------------
line_width        = 1.2;        // Width of overlay lines (mm)
color_horizontal  = "#DE4343";  // Horizontal hexagons (orientation mode)
color_vertical    = "#9B9EA0";  // Vertical hexagons (orientation mode)
color_single      = "#B15533";  // Tile color in single mode
palette           = ["#DE4343", "#B15533", "#9B9EA0", "#68724D"];
color_seed        = 7;          // Reshuffles random colors
color_cells       = "#1F3A5F";  // Cell outlines
color_short_edges = "#F7D959";  // Short edges
color_points      = "black";    // Lattice points
color_focus       = "#0078BF";  // Focus cell and its hexagon

// =============================================================================
// The algorithm
// =============================================================================
// All geometry is worked out in "cell units", where one cell is 1 x 1 and
// lattice point (i, j) sits at [i, j]. It is scaled to mm only when drawn.

c = equilateral ? (sqrt(7) - 1) / 6 : custom_c;
assert(c > 0 && c < 0.5, "custom_c must be between 0 and 0.5");

// Non-negative modulo. OpenSCAD's % keeps the sign of the dividend, so
// -1 % 2 is -1. This version always returns 0 or 1 for m = 2.
function pmod(a, m) = ((a % m) + m) % m;

// Step 2: does cell (i, j) have a horizontal short edge? (checkerboard)
function is_horizontal(i, j) = pmod(i + j, 2) == 0;

// The two ends of the short edge in cell (i, j). A horizontal edge uses
// left_pt / right_pt and a vertical edge uses bottom_pt / top_pt. All four
// sit a distance c from the cell's center.
function left_pt(i, j)   = [i + 0.5 - c, j + 0.5];
function right_pt(i, j)  = [i + 0.5 + c, j + 0.5];
function bottom_pt(i, j) = [i + 0.5,     j + 0.5 - c];
function top_pt(i, j)    = [i + 0.5,     j + 0.5 + c];

function short_edge(i, j) =
    is_horizontal(i, j) ? [left_pt(i, j), right_pt(i, j)]
                        : [bottom_pt(i, j), top_pt(i, j)];

// Step 4: one pentagon straddles every side of every cell.
//
// A pentagon's ID is [i, j, dir]:
//   dir = 0: it straddles the VERTICAL cell side from [i, j] to [i, j+1].
//            Its neighbours are cell (i-1, j) on the left and (i, j) on the right.
//   dir = 1: it straddles the HORIZONTAL cell side from [i, j] to [i+1, j].
//            Its neighbours are cell (i, j-1) below and (i, j) above.
//
// Its five corners are the two ends of that cell side, plus the short-edge
// endpoints on either side of it. Whichever neighbour has its short edge
// pointing at the side contributes two points, and the other neighbour
// contributes one.
function pentagon_v(i, j) =
    is_horizontal(i - 1, j)
        ? [[i, j], bottom_pt(i, j), top_pt(i, j), [i, j + 1], right_pt(i - 1, j)]
        : [[i, j], left_pt(i, j), [i, j + 1], top_pt(i - 1, j), bottom_pt(i - 1, j)];

function pentagon_h(i, j) =
    is_horizontal(i, j)
        ? [[i, j], top_pt(i, j - 1), [i + 1, j], right_pt(i, j), left_pt(i, j)]
        : [[i, j], left_pt(i, j - 1), right_pt(i, j - 1), [i + 1, j], bottom_pt(i, j)];

function pentagon(id) =
    id[2] == 0 ? pentagon_v(id[0], id[1]) : pentagon_h(id[0], id[1]);

// The two pentagons that share cell (i, j)'s short edge, which together form
// the hexagon built on that cell. A horizontal short edge is shared by the
// pentagons on the cell's bottom and top sides. A vertical one is shared by
// the pentagons on its left and right sides. Every pentagon has exactly one
// short edge, so each pentagon belongs to exactly one hexagon.
function hexagon(i, j) =
    is_horizontal(i, j) ? [[i, j, 1], [i, j + 1, 1]]
                        : [[i, j, 0], [i + 1, j, 0]];

// Build the tiling cell by cell: each cell contributes its hexagon's two
// pentagons. Hexagons spill a little past the grid on the sides where their
// pentagons point outward, so the tiling has a jagged edge.
cells = [for (i = [0 : cols - 1], j = [0 : rows - 1]) [i, j]];

// Every pentagon as [id, owning cell].
tiles = [for (cl = cells) for (id = hexagon(cl[0], cl[1])) [id, cl]];

// Side lengths, for curiosity. They are equal when equilateral = true.
short_len = 2 * c * cell;
long_len  = norm([0.5 - c, 0.5]) * cell;
echo(str("c = ", c, " | short side = ", short_len, " mm, long side = ", long_len,
         " mm | ", len(cells), " cells, ", len(tiles), " pentagons"));

// =============================================================================
// Drawing
// =============================================================================

// Points in cell units -> mm.
function mm(p) = p * cell;
function mm_list(pts) = [for (p = pts) mm(p)];

function pick(pal, seed) = pal[floor(rands(0, len(pal), 1, seed)[0]) % len(pal)];

function tile_color(id, cl, k) =
    color_mode == "orientation"
        ? (is_horizontal(cl[0], cl[1]) ? color_horizontal : color_vertical)
  : color_mode == "hexagon"  ? pick(palette, color_seed + cl[0] * 1000 + cl[1])
  : color_mode == "pentagon" ? pick(palette, color_seed + k)
  : color_single;

// One pentagon, shrunk by half the gap on every side.
module pentagon_2d(id) {
    offset(delta = -gap / 2) polygon(mm_list(pentagon(id)));
}

// A line segment between two points (mm) with rounded ends.
module seg(a, b, w = line_width) {
    hull() {
        translate(a) circle(d = w, $fn = 16);
        translate(b) circle(d = w, $fn = 16);
    }
}

// Closed outline of a polygon (mm).
module outline(pts, w = line_width) {
    for (k = [0 : len(pts) - 1]) seg(pts[k], pts[(k + 1) % len(pts)], w);
}

// In diagram mode each overlay is a thin slab at its own height, so the
// layers stack cleanly in the preview instead of flickering.
module layer(z) {
    translate([0, 0, z]) linear_extrude(height = 0.2) children();
}

focus_on = focus_cell[0] >= 0 && focus_cell[1] >= 0
        && focus_cell[0] < cols && focus_cell[1] < rows;

// Center the drawing on the origin.
translate([-cols * cell / 2, -rows * cell / 2, 0]) {
    if (mode == "2d") {
        // Pure 2D geometry, ready for File > Export > SVG or DXF after F6.
        for (t = tiles) pentagon_2d(t[0]);
    } else {
        // Pentagons.
        if (show_tiles)
            for (k = [0 : len(tiles) - 1])
                color(tile_color(tiles[k][0], tiles[k][1], k))
                    linear_extrude(height = 1) pentagon_2d(tiles[k][0]);

        // Square lattice cells.
        if (show_cells)
            color(color_cells) layer(1.0) {
                for (i = [0 : cols]) seg(mm([i, 0]), mm([i, rows]));
                for (j = [0 : rows]) seg(mm([0, j]), mm([cols, j]));
            }

        // Short edges, one per cell.
        if (show_short_edges)
            color(color_short_edges) layer(1.2)
                for (cl = cells)
                    let (e = short_edge(cl[0], cl[1]))
                        seg(mm(e[0]), mm(e[1]), line_width * 2);

        // Focus cell: the cell itself and the hexagon built on it.
        if (focus_on) {
            fi = focus_cell[0];
            fj = focus_cell[1];
            color(color_focus) layer(1.4) {
                outline(mm_list([[fi, fj], [fi + 1, fj], [fi + 1, fj + 1], [fi, fj + 1]]),
                        line_width * 2.5);
                for (id = hexagon(fi, fj))
                    outline(mm_list(pentagon(id)), line_width * 1.5);
            }
            color(color_focus, 0.25) layer(0.9)
                translate(mm([fi, fj])) square(cell);
        }

        // Lattice points.
        if (show_lattice_points)
            color(color_points) layer(1.6)
                for (i = [0 : cols], j = [0 : rows])
                    translate(mm([i, j])) circle(d = line_width * 4, $fn = 24);

        // Cell labels, placed just inside each cell's bottom-left corner.
        if (show_labels)
            color("black") layer(1.8)
                for (cl = cells)
                    translate(mm([cl[0] + 0.08, cl[1] + 0.08]))
                        text(str(cl[0], ",", cl[1]), size = cell * 0.11);
    }
}
