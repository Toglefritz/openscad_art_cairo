#!/usr/bin/env bash
# Render the documentation images in docs/images/ from the current models.
#
# Re-run this after changing cairo.scad or the learn/ scripts so the images
# match the code. Each image only overrides the settings it needs with -D, so
# everything else reflects whatever is currently set in the .scad files.
#
# Usage: docs/render_images.sh        (from anywhere inside the project)
# Set OPENSCAD to override the OpenSCAD binary location.

set -euo pipefail

OPENSCAD="${OPENSCAD:-/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/images"
MAIN="$ROOT/cairo.scad"
LEARN="$ROOT/learn/01_cairo_tiling.scad"

if [[ ! -x "$OPENSCAD" ]]; then
    echo "OpenSCAD not found at $OPENSCAD (set OPENSCAD=/path/to/openscad)" >&2
    exit 1
fi

mkdir -p "$OUT"

# render <output name> <scad file> <camera> <size> [extra OpenSCAD args...]
# Camera is OpenSCAD's gimbal form: tx,ty,tz,rx,ry,rz,distance.
render() {
    local name="$1" scad="$2" camera="$3" size="$4"
    shift 4
    echo "Rendering $name"
    "$OPENSCAD" --colorscheme=Tomorrow --camera="$camera" --imgsize="$size" \
        "$@" -o "$OUT/$name" "$scad" >/dev/null 2>&1
}

TOP="0,0,0,0,0,0"   # Straight down
ORTHO="--projection=o"

# ---- Tiling algorithm (learn/01_cairo_tiling.scad) ---------------------------

# Pentagons alone.
render tiling_pentagons.png "$LEARN" "$TOP,820" 900,900 $ORTHO \
    -D 'color_mode="pentagon"' -D show_cells=false -D show_short_edges=false \
    -D show_lattice_points=false -D 'focus_cell=[-1,-1]'

# The square cells, lattice points, and short edges with no tiles.
render tiling_construction.png "$LEARN" "$TOP,820" 900,900 $ORTHO \
    -D show_tiles=false -D 'focus_cell=[-1,-1]'

# Horizontal vs vertical hexagons over the cell grid, one cell highlighted.
render tiling_cells_focus.png "$LEARN" "$TOP,560" 900,900 $ORTHO

# Each hexagon a different color, with cell indices.
render tiling_hexagons_labeled.png "$LEARN" "$TOP,560" 900,900 $ORTHO \
    -D 'color_mode="hexagon"' -D show_labels=true -D 'focus_cell=[-1,-1]'

# A shorter short edge (non-equilateral pentagons).
render tiling_short_c.png "$LEARN" "$TOP,560" 700,700 $ORTHO \
    -D equilateral=false -D custom_c=0.08

# ---- Full artwork (cairo.scad) -----------------------------------------------

# Whole artwork from the front.
render artwork_top.png "$MAIN" "$TOP,2600" 1000,1000 $ORTHO

# Ring boundaries drawn over the artwork.
render artwork_ring_guides.png "$MAIN" "$TOP,2600" 1000,1000 $ORTHO \
    -D show_ring_guides=true

# Angled view showing the height and draft sweep around the ring.
render artwork_angle.png "$MAIN" "0,0,0,55,0,0,1500" 1200,900

# Low angle from the 9:00 side, looking along the step.
render artwork_step.png "$MAIN" "0,0,0,65,0,-60,1300" 1200,800

# Panels pulled apart to show the 4 x 4 split.
render artwork_panels_spread.png "$MAIN" "$TOP,2700" 1000,1000 $ORTHO \
    -D preview_spread=25

# ---- One panel and its tray --------------------------------------------------

# A single panel's tiles, as exported.
render panel_c1_r1.png "$MAIN" "0,0,0,50,0,30,650" 900,800 \
    -D 'part="panel"' -D panel_col=1 -D panel_row=1

# The matching assembly tray from above and below.
render tray_c1_r1_top.png "$MAIN" "$TOP,650" 900,900 $ORTHO \
    -D 'part="tray"' -D panel_col=1 -D panel_row=1
render tray_c1_r1_angle.png "$MAIN" "0,0,0,55,0,20,600" 900,800 \
    -D 'part="tray"' -D panel_col=1 -D panel_row=1
render tray_c1_r1_bottom.png "$MAIN" "0,0,0,0,180,0,650" 800,800 $ORTHO \
    -D 'part="tray"' -D panel_col=1 -D panel_row=1

# Tiles sitting in their trays, with the panels pulled apart.
render artwork_trays_spread.png "$MAIN" "0,0,0,50,0,20,1900" 1200,900 \
    -D preview_trays=true -D preview_spread=40

echo "Images written to $OUT"
