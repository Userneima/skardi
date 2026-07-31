#!/usr/bin/env bash
set -euo pipefail

readonly hero_references=(
  "README.md:asset/controlled-db-debugging-hero.png"
  "README.md:asset/controlled-db-debugging-hero-dark.png"
  "README.zh-CN.md:asset/controlled-db-debugging-hero-zh-CN.png"
  "README.zh-CN.md:asset/controlled-db-debugging-hero-zh-CN-dark.png"
)
readonly hero_assets=(
  "asset/controlled-db-debugging-hero.png"
  "asset/controlled-db-debugging-hero-dark.png"
  "asset/controlled-db-debugging-hero-zh-CN.png"
  "asset/controlled-db-debugging-hero-zh-CN-dark.png"
)
readonly mascot_asset="asset/skardi-flame-mascot-blink.gif"

command -v ffprobe >/dev/null || { echo "ffprobe is required to validate animated README assets." >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg is required to validate animated README assets." >&2; exit 1; }

for reference in "${hero_references[@]}"; do
  readme_file="${reference%%:*}"
  expected_asset="${reference#*:}"
  rg -Fq "$expected_asset" "$readme_file" || {
    echo "README must use the animated hero asset: $readme_file -> $expected_asset" >&2
    exit 1
  }
done

for asset in "${hero_assets[@]}"; do
  [[ -f "$asset" ]] || { echo "Missing hero asset: $asset" >&2; exit 1; }
  codec_name="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$asset")"
  [[ "$codec_name" == "apng" ]] || {
    echo "Hero asset must be a full-colour APNG: $asset" >&2
    exit 1
  }
  frame_count="$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 "$asset")"
  [[ "$frame_count" =~ ^[0-9]+$ && "$frame_count" -gt 1 ]] || {
    echo "Hero asset must remain animated: $asset" >&2
    exit 1
  }
done

[[ -f "$mascot_asset" ]] || { echo "Missing blink mascot source: $mascot_asset" >&2; exit 1; }
mascot_frame_count="$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 "$mascot_asset")"
[[ "$mascot_frame_count" =~ ^[0-9]+$ && "$mascot_frame_count" -gt 1 ]] || {
  echo "Blink mascot source must remain animated: $mascot_asset" >&2
  exit 1
}

flow_check_dir="$(mktemp -d /tmp/skardi-readme-flow-check.XXXXXX)"
trap 'rm -rf "$flow_check_dir"' EXIT
for asset in "${hero_assets[@]}"; do
  first_frame="$flow_check_dir/$(basename "$asset")-first.png"
  later_frame="$flow_check_dir/$(basename "$asset")-later.png"
  ffmpeg -y -hide_banner -loglevel error -i "$asset" -frames:v 1 "$first_frame"
  ffmpeg -y -hide_banner -loglevel error -ss 0.45 -i "$asset" -frames:v 1 "$later_frame"
  cmp -s "$first_frame" "$later_frame" || continue
  echo "Hero data-flow dashes must move within the animation: $asset" >&2
  exit 1
done

echo "README hero contract verified: all light, dark, English, and Chinese variants use animated full-colour APNG assets with moving data-flow dashes."
