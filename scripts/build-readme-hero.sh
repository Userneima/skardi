#!/usr/bin/env bash
set -euo pipefail

# Builds the four direct README APNG assets from their SVG variants. The SVG
# contains a static mascot only for source-preview convenience; the APNG must
# contain exactly one transparent animated mascot.
readonly hero_pairs=(
  "controlled-db-debugging-hero.svg:controlled-db-debugging-hero.png"
  "controlled-db-debugging-hero-dark.svg:controlled-db-debugging-hero-dark.png"
  "controlled-db-debugging-hero-zh-CN.svg:controlled-db-debugging-hero-zh-CN.png"
  "controlled-db-debugging-hero-zh-CN-dark.svg:controlled-db-debugging-hero-zh-CN-dark.png"
)
readonly mascot_size=320
readonly mascot_x=1220
readonly mascot_y=120

command -v ffmpeg >/dev/null || { echo "ffmpeg is required to build README hero assets." >&2; exit 1; }
command -v sips >/dev/null || { echo "sips is required to rasterize README hero SVGs." >&2; exit 1; }

build_temp_dir="$(mktemp -d /tmp/skardi-readme-hero.XXXXXX)"
trap 'rm -rf "$build_temp_dir"' EXIT

for hero_pair in "${hero_pairs[@]}"; do
  hero_svg="${hero_pair%%:*}"
  hero_apng="${hero_pair#*:}"
  base_svg="$build_temp_dir/$hero_svg"
  base_png="$build_temp_dir/${hero_svg%.svg}-base.png"
  output_apng="$build_temp_dir/$hero_apng"

  sed '/<image href="data:image\/png;base64/d' "asset/$hero_svg" > "$base_svg"
  sips -Z 2880 -s format png "$base_svg" --out "$base_png" >/dev/null
  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate 20 -i "$base_png" \
    -i asset/skardi-flame-mascot-blink.gif \
    -loop 1 -i asset/skardi-flame-mascot-transparent.png \
    -filter_complex "[2:v]scale=300:300:flags=lanczos,format=rgba,alphaextract[mask];[1:v]format=rgba[blink];[blink][mask]alphamerge=shortest=1,scale=${mascot_size}:${mascot_size}:flags=lanczos,pad=2880:730:${mascot_x}:${mascot_y}:color=black@0[mascot];[0:v][mascot]overlay=0:0:shortest=1" \
    -plays 0 -f apng "$output_apng"
  mv "$output_apng" "asset/$hero_apng"
done
