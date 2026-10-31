#!/usr/bin/env bash
# Export every print panel of cairo.scad as one STL per filament color.
#
# Output layout:
#   export/panel_c<col>_r<row>/panel_c<col>_r<row>_<filament>.stl
#
# Each folder holds all the parts of one panel, sharing one coordinate frame.
# In Bambu Studio, select every STL in a folder and drag them in together, then
# answer "Yes" to loading them as a single object with multiple parts. Assign
# a filament to each part and slice.
#
# Usage: ./export_panels.sh [scad_file] [output_dir]
# Set OPENSCAD to override the OpenSCAD binary location.

set -euo pipefail

OPENSCAD="${OPENSCAD:-/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD}"
SCAD="${1:-cairo.scad}"
OUT="${2:-export}"

if [[ ! -x "$OPENSCAD" ]]; then
    echo "OpenSCAD not found at $OPENSCAD (set OPENSCAD=/path/to/openscad)" >&2
    exit 1
fi

mkdir -p "$OUT"
info="$OUT/panel_info.echo"

# Ask the model which panels exist, which colors each one uses, and whether
# every panel fits on the bed.
"$OPENSCAD" -D 'part="info"' -o "$info" "$SCAD" 2>/dev/null

grep '"Panel ' "$info" | sed 's/^ECHO: "\(.*\)"$/\1/'

if grep -q 'TOO LARGE FOR BED' "$info"; then
    echo "One or more panels do not fit the bed. Increase panels_x / panels_y." >&2
    exit 1
fi

count=0
while read -r col row key name; do
    dir="$OUT/panel_c${col}_r${row}"
    mkdir -p "$dir"
    file="$dir/panel_c${col}_r${row}_${name}.stl"
    echo "Exporting $file"
    "$OPENSCAD" \
        -D 'part="panel"' \
        -D "panel_col=${col}" \
        -D "panel_row=${row}" \
        -D "export_color=\"${key}\"" \
        -o "$file" "$SCAD" 2>/dev/null
    count=$((count + 1))
done < <(sed -n 's/^ECHO: "EXPORT_PART \(.*\)"$/\1/p' "$info")

echo "Exported $count STL files to $OUT/"
