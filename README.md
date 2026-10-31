# Cairo Tiling Wall Art

A 30 × 30 inch relief artwork built from a Cairo pentagonal tiling. A raised
ring in the middle of the piece spirals upward: its tiles grow taller and taper
more steeply as they travel clockwise around the center, starting at the 9:00
position. The model is written in OpenSCAD and split into panels sized for a
Bambu Lab P1S with an AMS.

| File | Purpose |
|---|---|
| `cairo.scad` | The parametric model: tiling, ring, colors, panels, and export modes |
| `export_panels.sh` | Batch exports every panel as one STL per filament color |
| `export/` | Output of `export_panels.sh` |

Tested with OpenSCAD 2021.01 on macOS.

---

## How the model works

### 1. The Cairo tiling

The tiling is built on a square lattice of points spaced `cell` apart:

1. Each lattice point becomes a corner where four pentagons meet.
2. Every lattice square gets one short edge through its center. The edge is
   horizontal or vertical in a checkerboard pattern.
3. Each end of a short edge is joined to the two nearest lattice corners.

This gives exactly one pentagon across every lattice edge, which is two
pentagons per lattice square. Pairs of pentagons that share a short edge form
the alternating "basket weave" hexagons the Cairo tiling is known for. The
short edge half-length is `c = (√7 − 1) / 6` cell units, so all five sides of
every pentagon are equal.

Each tile has an ID `[i, j, dir]`: a lattice point plus a direction (0 =
vertical edge, 1 = horizontal edge). The functions `pentagon(id)`,
`tile_points(id)` and `tile_center(id)` turn an ID into geometry.
`tile_center` uses the true area centroid, not a plain average of the corners.

The pattern is centered on a lattice point, so it is symmetric about the middle
of the artwork. Tiles that cross the outer edge are trimmed to the 30" square
(`clip_to_region = true`).

### 2. The raised ring

A tile belongs to the ring when its center lies between
`ring_inner_diameter` and `ring_outer_diameter`, measured from `ring_center`.

Each ring tile gets a sweep value from 0 to 1. It is 0 at `ring_start_angle`
(180° = 9:00) and rises in the `ring_clockwise` direction until it nearly
reaches 1 just before getting back to the start. Two properties follow this
sweep, interpolated linearly:

| Property | Settings | Defaults |
|---|---|---|
| Height (multiple of `tile_thickness`) | `ring_height_start_factor` → `ring_height_end_factor` | 2× → 10× (12 → 60 mm) |
| Draft angle (degrees from vertical) | `ring_draft_start_angle` → `ring_draft_end_angle` | 0° → 5° |

The sweep produces a sharp step at 9:00, where the tallest tiles sit right
next to the shortest.

Drafted tiles are made as the hull of the base outline and a smaller top
outline. The top is inset by `height × tan(draft)`. Every tile outline is
convex, so all five walls taper evenly. Background tiles are always
`tile_thickness` tall with straight walls.

All height and draft logic lives in `tile_height(id)` and `tile_draft(id)`.
Those are the places to add more detail later.

### 3. Colors

Filament colors are named constants (`pla_terracotta`, `pla_dark_green`, …)
using Bambu Lab PLA Matte hex codes. Background and ring tiles each pick from
their own palette:

```openscad
background_palette = [pla_dark_red, pla_terracotta, pla_terracotta, pla_nardo_gray];
ring_palette       = [pla_dark_red, pla_dark_green, pla_dark_green];
```

- Listing a color more than once makes it appear more often.
- `color_seed` reshuffles which tile gets which color.
- Colors are assigned once, in the `tile_colors` list, so the preview and the
  exported STLs always match.
- To use a new filament, add a `pla_*` constant and a matching entry in
  `filament_table`. The table supplies the names used in export file names.

### 4. Print panels

The P1S plate is 256 × 256 mm and the artwork is 762 mm square, so the piece is
split into a `panels_x` × `panels_y` grid (4 × 4 by default). A 3 × 3 grid
would need 254 mm panels before tiles overhang the panel lines, and that does
not fit.

Tiles are never cut. Each tile belongs to the panel that contains its center,
so panel edges follow the tile outlines and neighboring panels interlock like
puzzle pieces. With the defaults, every panel is between 203 and 215 mm square
and at most 60 mm tall.

`panel_base_thickness` controls how the tiles in a panel are held together:

| Value | Result |
|---|---|
| `0` (current) | Loose tiles. Each panel prints as separate tiles in their final positions. |
| `0.6` (for example) | A thin base joins the panel's tiles into one rigid piece. The base fills the gaps between tiles and prints in `base_color`, so it shows in the gaps like grout. The panel's outer edge stays `gap / 2` inside the tile outlines, so panels meet with the same spacing as tiles. |

### 5. Assembly trays

With `trays_enabled = true`, every panel also gets a standalone **assembly
tray**: a flat plate with a shallow pentagonal recess for each of the panel's
tiles. Print the tray first. Then, as each batch of loose tiles comes off the
printer, drop each tile straight into its recess.

- **Outline:** the tray follows the same jagged outline as its panel, so
  neighboring trays interlock, and each tray holds exactly the tiles of its
  own panel.
- **Size:** each tray is `tray_floor + tray_recess_depth` thick (2.4 mm by
  default). Recesses are `tray_recess_depth` deep (1.2 mm).
- **Fit:** recesses are `tray_clearance` (0.15 mm) larger than each tile on
  every side, so tiles drop in without forcing.
- **Walls:** the walls left between recesses are `gap − 2 × clearance` wide
  (1.2 mm). At the seams between trays, each tray keeps a lip of
  `gap / 2 − clearance − tray_seam_gap / 2` (0.5 mm). The console report
  prints both widths and warns if either drops below a 0.4 mm nozzle line.
- **Outer edge:** tiles on the outer edge of the artwork are trimmed flat, so
  their recesses are open on that side.
- **Label:** the panel ID (for example `c1 r1`) is debossed into the
  underside, mirrored so it reads correctly when the tray is flipped over.
- **Joined base:** if `panel_base_thickness > 0`, the tray gets one recess
  shaped like the whole joined panel instead of one per tile.
- **Visible height:** tiles sit `tray_recess_depth` into the tray, so the
  visible part of every tile is that much shorter than its printed height.

Set `preview_trays = true` to see the tiles sitting in their trays in the
preview. Combine it with `preview_spread = 30` to see the trays separately.

---

## Using the model

### Output modes

The `part` variable selects what OpenSCAD produces:

| `part` | Output |
|---|---|
| `"preview"` | The full assembled artwork with a reference backing board. Set `preview_spread = 25` to pull the panels apart and see the split. Set `show_ring_guides = true` to draw the ring boundaries. |
| `"panel"` | One panel, centered on the origin, chosen by `panel_col` and `panel_row`. `export_color` limits it to one filament (`"all"`, `"base"`, or a hex code). |
| `"tray"` | The assembly tray for one panel, centered on the origin, chosen by `panel_col` and `panel_row`. |
| `"info"` | No geometry. Prints the panel report and the export list. |

Panels are numbered from the bottom-left: `c0_r0` is the bottom-left panel and
`c3_r3` is the top-right. See [Panel layout](#panel-layout) for the full map.

### Console report

Every preview prints a summary to the console:

```
Tile count: 512
Ring tile count: 200, height range: 12.2191 to 59.7322 mm
Ring draft range: 0.0228227 to 4.97211 deg, max top inset: 5.1966 mm
Panel c0 r3: 36 tiles, 203 x 203 x 17 mm, 4 colors, fits
...
```

Check this after changing settings:

- **Bed fit:** if any panel says `TOO LARGE FOR BED`, increase `panels_x` or
  `panels_y`, or reduce `cell`.
- **Top inset:** if the "max top inset" gets close to half a tile's width, the
  tallest tiles will taper to a point. Reduce the end height or the draft.

---

## Exporting

### Batch export (recommended)

From the project folder:

```bash
./export_panels.sh                    # uses cairo.scad, writes to ./export/
./export_panels.sh cairo.scad out     # custom input and output
OPENSCAD=/path/to/openscad ./export_panels.sh   # different OpenSCAD binary
```

The script:

1. Runs OpenSCAD in `info` mode and saves the console output to
   `export/panel_info.echo`.
2. Prints the panel report. It stops if any panel is too large for the bed.
3. Reads the `EXPORT_PART <col> <row> <hex> <name>` lines. Each line is one
   panel/color combination that actually has tiles. It also adds a `base`
   part when `panel_base_thickness > 0` and a `tray` part when
   `trays_enabled = true`.
4. Exports each tile color and base in `panel` mode, and each tray in `tray`
   mode, as its own STL:

```
export/
  panel_info.echo
  panel_c0_r0/
    panel_c0_r0_dark_red.stl
    panel_c0_r0_nardo_gray.stl
    panel_c0_r0_terracotta.stl
    panel_c0_r0_tray.stl
  panel_c1_r0/
    ...
```

With the current settings this produces 78 STLs (62 tile files and 16 trays),
which takes about a minute and a half. Re-run the script after any change to the model. Old files are
overwritten, but files for color/panel combinations that no longer exist are
not removed, so clear `export/` first if you change palettes.

### Why one STL per color?

OpenSCAD 2021.01 cannot write color information to 3MF files. Exporting each
color as its own STL is a reliable way to bring a multi-color model into Bambu
Studio. All the STLs for a panel share one coordinate frame, so they line up
exactly when loaded together.

### Exporting a single panel by hand

```bash
OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
$OPENSCAD -D 'part="panel"' -D panel_col=1 -D panel_row=2 \
          -D 'export_color="#B15533"' -o panel_c1_r2_terracotta.stl cairo.scad
```

---

## Printing on a Bambu Lab P1S

### Print the tray first

Each `panel_cX_rY_tray.stl` is a separate print. Load it on its own, in any
single filament (`tray_color` suggests Nardo Gray), and print it before that
panel's tiles.

| Setting | Suggestion |
|---|---|
| Layer height | 0.2 mm (the 1.2 mm floor and 1.2 mm recesses are 6 layers each) |
| Walls | 2 or more, with *Detect thin wall* enabled so the 0.5 mm seam lips print |
| Top / bottom layers | 4 or more, so the recess floors are solid |
| Orientation | Flat, label side down, as exported |

Each tray is about 215 × 215 × 2.4 mm. Check the first tray by dropping in a
test tile. If tiles are too tight, increase `tray_clearance`. If they rattle,
reduce it. Then re-export.

### Load a panel's tiles

1. Open Bambu Studio and start a new project.
2. Select all the **tile** STLs in one panel folder (every file except
   `_tray.stl`, for example in `export/panel_c1_r1/`) and drag them onto the
   plate together.
3. When Bambu Studio asks whether to load the files as a single object with
   multiple parts, choose **Yes**. This keeps every tile in its correct
   position.
4. In the object list, assign each part the filament named in its file name.
   Load those filaments into the AMS first.
5. Leave the object where Bambu Studio places it. Do not scale or rotate
   individual parts.

### Suggested settings

| Setting | Suggestion |
|---|---|
| Filament | Bambu PLA Matte, in the colors from the palettes |
| Plate | Textured PEI. It holds small tile footprints well, and the textured bottom does not show once glued. |
| Layer height | 0.2 mm |
| Walls / infill | 3 walls, 10 to 15% infill. The tiles are decorative, not structural. |
| Supports | None. Background tiles are flat and ring tiles taper inward. |
| Brim | Worth adding on panels with tall ring tiles (about 40 to 60 mm), since each tile has a small footprint |
| Prime tower | Required for multi-color plates. Bambu Studio adds it automatically. |

### Filament changes and waste

Every layer that contains more than one color needs an AMS swap and purge:

- **Background panels:** about 6 mm tall, so roughly 30 layers. Swaps are
  manageable.
- **Ring panels:** up to 60 mm tall (about 300 layers) with 2 to 4 colors.
  These need hundreds of swaps and produce a lot of purge waste.

Ways to reduce this:

- **Single-color plates.** Tiles are loose (`panel_base_thickness = 0`), so
  a panel does not need to print in one go. Load just one color's STL as its
  own plate. That plate prints with no swaps at all, and the tiles still come
  off in their correct layout for that panel.
- **Flush into infill.** Enable *Flush into objects' infill* in the object
  settings to reuse some purge material.
- **Fewer colors in tall areas.** A smaller `ring_palette` means fewer colors
  per layer above the background height.

If you switch to a joined base (`panel_base_thickness > 0`), the base and
tiles of a panel must print together on one multi-color plate.

### Keeping track of tiles

With loose tiles, each panel is a few dozen separate pieces. To keep them in
order:

- Print the panel's assembly tray first. As each batch of tiles comes off
  the plate, place every tile straight into its matching recess. A finished
  tray is a complete, ready-to-glue panel.
- The panel ID is debossed on the underside of each tray. Also mark it on
  the backing board in pencil before gluing.
- The preview with `preview_spread = 25` makes a handy assembly map. Screenshot
  it from the top view (View → Top, orthographic).

---

## Assembly

### Panel layout

Each export folder is one panel. Its position on the artwork, viewed from the
front with the artwork hanging upright, is:

|            | Left column       | Column 2          | Column 3          | Right column      |
|---|---|---|---|---|
| **Top row**    | `panel_c0_r3` | `panel_c1_r3` | `panel_c2_r3` | `panel_c3_r3` |
| **Row 3**      | `panel_c0_r2` | `panel_c1_r2` | `panel_c2_r2` | `panel_c3_r2` |
| **Row 2**      | `panel_c0_r1` | `panel_c1_r1` | `panel_c2_r1` | `panel_c3_r1` |
| **Bottom row** | `panel_c0_r0` | `panel_c1_r0` | `panel_c2_r0` | `panel_c3_r0` |

- `c` is the column, counted from the left starting at 0.
- `r` is the row, counted from the bottom starting at 0.
- The four center panels (`c1_r1`, `c2_r1`, `c1_r2`, `c2_r2`) meet at the
  center of the artwork, inside the ring's donut hole.
- The tallest tiles, at the step just before 9:00, are in `c0_r1` and `c1_r1`.

This table matches the default 4 × 4 grid. If you change `panels_x` or
`panels_y`, the same rule applies: column numbers run left to right and row
numbers run bottom to top.

### Steps

1. Cut a 30 × 30 inch backing board (¼" MDF or plywood works well) and paint
   it a dark neutral. It will show through the gaps between tiles.
2. Draw a center mark and a 4 × 4 reference grid of 7.5" squares.
3. Glue each tile into its recess in the assembly tray with a small drop of CA
   glue, so each tray becomes one rigid panel.
4. Start with a center panel and work outward. Glue each tray to the backing
   board with construction adhesive. Tray edges interlock, so each new tray
   locks against the ones already placed, and the tiles keep a consistent
   1.5 mm `gap`. Without trays, glue tiles straight to the board and keep the
   gap even by eye.
5. Let it cure flat, then frame. The tallest tiles are about 60 mm (2⅜"), so
   use a shadow box frame with at least 2½" of interior depth.

---

## Settings reference

| Setting | Default | Description |
|---|---|---|
| `region_size` | 30" | Width and height of the artwork |
| `cell` | 2" | Lattice spacing. Each cell holds two pentagons. |
| `gap` | 1.5 mm | Space between tiles |
| `tile_thickness` | 6 mm | Background tile height and the unit for ring height factors |
| `tiling_angle` | 0° | Rotate the pattern within the square |
| `clip_to_region` | `true` | Trim edge tiles (`false` keeps only whole tiles) |
| `ring_outer_diameter` / `ring_inner_diameter` | 24" / 8" | Ring boundaries |
| `ring_center` | `[0, 0]` | Ring center in mm |
| `ring_start_angle` | 180 | Where the sweep starts (0 = 3:00, 90 = 12:00, 180 = 9:00) |
| `ring_clockwise` | `true` | Direction the sweep increases |
| `ring_height_start_factor` / `_end_factor` | 2 / 10 | Ring height range, as multiples of `tile_thickness` |
| `ring_draft_start_angle` / `_end_angle` | 0° / 5° | Ring draft range |
| `background_palette` / `ring_palette` | see file | Filament colors |
| `color_seed` | 42 | Reshuffles color assignment |
| `bed_size` / `bed_margin` | 256 × 256 / 2 mm | Printer bed and clearance |
| `panels_x` / `panels_y` | 4 / 4 | Panel grid |
| `panel_base_thickness` | 0 | Joining base under each panel (0 = loose tiles) |
| `base_color` | Nardo Gray | Filament for the joining base |
| `trays_enabled` | `true` | Export an assembly tray for every panel |
| `tray_floor` / `tray_recess_depth` | 1.2 / 1.2 mm | Tray plate thickness under the recesses, and recess depth |
| `tray_clearance` | 0.15 mm | Extra room around each tile in its recess |
| `tray_seam_gap` | 0.2 mm | Gap between neighboring trays |
| `tray_color` | Nardo Gray | Preview color and suggested tray filament |
| `tray_label` / `tray_label_size` / `tray_label_depth` | `true` / 14 / 0.4 mm | Panel ID debossed on the tray underside |
| `preview_trays` | `false` | Shows the tiles sitting in their trays in the preview |
| `part` | `"preview"` | `"preview"`, `"panel"`, `"tray"`, or `"info"` |
| `panel_col` / `panel_row` / `export_color` | 0 / 0 / `"all"` | Panel export selection |
| `preview_spread` | 0 | Pulls panels apart in the preview |
| `show_ring_guides` | `false` | Draws the ring boundary circles in the preview |
