#!/usr/bin/env bash
set -euo pipefail

# Auto capture scrolling screenshots from Android, estimate scrollbar thumb
# height/position, then stitch all captures into one long image.
#
# Requirements:
#   adb
#   python3 with Pillow: python3 -m pip install Pillow
#
# Usage:
#   ./scroll_screenshot.sh [count] [output_dir]
#
# Examples:
#   ./scroll_screenshot.sh
#   ./scroll_screenshot.sh 8 screenshots

COUNT="${1:-5}"
OUTPUT_DIR="${2:-scroll_screenshots}"
REMOTE_DIR="/sdcard"
STITCHED_FILE="$OUTPUT_DIR/stitched.png"
REPORT_FILE="$OUTPUT_DIR/scrollbar_report.txt"

mkdir -p "$OUTPUT_DIR"

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Please install Android platform-tools first." >&2
  exit 1
fi

if ! python3 - <<'PY' >/dev/null 2>&1
from PIL import Image
PY
then
  echo "Python Pillow not found. Install it with: python3 -m pip install Pillow" >&2
  exit 1
fi

: > "$REPORT_FILE"

for i in $(seq 1 "$COUNT"); do
  remote_file="$REMOTE_DIR/screen$i.png"
  local_file="$OUTPUT_DIR/screen$i.png"

  echo "[$i/$COUNT] Capture $remote_file"
  adb shell screencap -p "$remote_file"

  echo "[$i/$COUNT] Pull to $local_file"
  adb pull "$remote_file" "$local_file" >/dev/null

  python3 - "$local_file" "$i" "$REPORT_FILE" <<'PY'
from pathlib import Path
import sys
from PIL import Image, ImageStat

image_path = Path(sys.argv[1])
index = sys.argv[2]
report_path = Path(sys.argv[3])

img = Image.open(image_path).convert("RGB")
w, h = img.size

# Android scrollbars are usually near the right edge. Detect a slim vertical
# thumb by finding pixels that stand out from the local right-edge background.
edge_width = max(10, min(36, w // 24))
edge = img.crop((w - edge_width, 0, w, h))
bg = ImageStat.Stat(edge).median

rows = []
for y in range(h):
    strong = 0
    for x in range(edge_width):
        r, g, b = edge.getpixel((x, y))
        diff = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
        brightness = (r + g + b) / 3
        # Most scrollbar thumbs are lighter than the track, but keep a contrast
        # fallback for themed apps.
        if diff > 80 or brightness > 205:
            strong += 1
    if strong >= max(2, edge_width // 8):
        rows.append(y)

ranges = []
if rows:
    start = prev = rows[0]
    for y in rows[1:]:
        if y <= prev + 2:
            prev = y
        else:
            if prev - start >= 12:
                ranges.append((start, prev))
            start = prev = y
    if prev - start >= 12:
        ranges.append((start, prev))

if ranges:
    top, bottom = max(ranges, key=lambda item: item[1] - item[0])
    thumb_h = bottom - top + 1
    percent_top = top / h * 100
    percent_h = thumb_h / h * 100
    line = (
        f"screen{index}.png: scrollbar top={top}px "
        f"height={thumb_h}px top_percent={percent_top:.1f}% "
        f"height_percent={percent_h:.1f}%"
    )
else:
    line = f"screen{index}.png: scrollbar not detected"

with report_path.open("a", encoding="utf-8") as f:
    f.write(line + "\n")
print(line)
PY

  if [ "$i" -lt "$COUNT" ]; then
    echo "[$i/$COUNT] Swipe up"
    adb shell input swipe 500 1500 500 500 500
    sleep 1
  fi
done

echo "Stitch screenshots into $STITCHED_FILE"
python3 - "$OUTPUT_DIR" "$COUNT" "$STITCHED_FILE" <<'PY'
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageStat

output_dir = Path(sys.argv[1])
count = int(sys.argv[2])
stitched_path = Path(sys.argv[3])

images = [
    Image.open(output_dir / f"screen{i}.png").convert("RGB")
    for i in range(1, count + 1)
]

if not images:
    raise SystemExit("No screenshots captured")

w, h = images[0].size
images = [img.resize((w, h)) if img.size != (w, h) else img for img in images]

def crop_compare_area(img, y1, y2):
    # Ignore status/nav bars and right scrollbar; compare central content only.
    left = int(w * 0.06)
    right = int(w * 0.92)
    return img.crop((left, y1, right, y2)).resize((max(1, (right - left) // 4), max(1, (y2 - y1) // 4)))

def mse(a, b):
    diff = ImageChops.difference(a, b)
    stat = ImageStat.Stat(diff)
    return sum(v * v for v in stat.rms) / len(stat.rms)

pieces = [images[0]]
overlaps = []

for prev, curr in zip(images, images[1:]):
    best_overlap = 0
    best_score = float("inf")
    min_overlap = int(h * 0.12)
    max_overlap = int(h * 0.85)
    step = max(4, h // 180)

    for overlap in range(min_overlap, max_overlap, step):
        prev_part = crop_compare_area(prev, h - overlap, h)
        curr_part = crop_compare_area(curr, 0, overlap)
        score = mse(prev_part, curr_part)
        if score < best_score:
            best_score = score
            best_overlap = overlap

    # If overlap matching is weak, fall back to keeping the lower 70%.
    if best_score > 900:
        best_overlap = int(h * 0.30)

    overlaps.append((best_overlap, best_score))
    pieces.append(curr.crop((0, best_overlap, w, h)))

total_h = sum(piece.height for piece in pieces)
stitched = Image.new("RGB", (w, total_h))
y = 0
for piece in pieces:
    stitched.paste(piece, (0, y))
    y += piece.height

stitched.save(stitched_path)

print("Overlap report:")
for idx, (overlap, score) in enumerate(overlaps, start=2):
    print(f"screen{idx - 1}.png -> screen{idx}.png: overlap={overlap}px score={score:.1f}")
print(f"Saved: {stitched_path}")
PY

echo "Done."
echo "Screenshots: $OUTPUT_DIR/screen*.png"
echo "Scrollbar report: $REPORT_FILE"
echo "Stitched image: $STITCHED_FILE"
