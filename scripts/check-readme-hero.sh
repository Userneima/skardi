#!/usr/bin/env bash
set -euo pipefail

readonly hero_references=(
  "README.md:asset/controlled-db-debugging-hero.gif"
  "README.md:asset/controlled-db-debugging-hero-dark.gif"
  "README.zh-CN.md:asset/controlled-db-debugging-hero-zh-CN.gif"
  "README.zh-CN.md:asset/controlled-db-debugging-hero-zh-CN-dark.gif"
)
readonly hero_assets=(
  "asset/controlled-db-debugging-hero.gif"
  "asset/controlled-db-debugging-hero-dark.gif"
  "asset/controlled-db-debugging-hero-zh-CN.gif"
  "asset/controlled-db-debugging-hero-zh-CN-dark.gif"
)
readonly mascot_asset="asset/skardi-flame-mascot-blink.gif"

command -v ffprobe >/dev/null || { echo "ffprobe is required to validate animated README assets." >&2; exit 1; }

for reference in "${hero_references[@]}"; do
  readme_file="${reference%%:*}"
  expected_asset="${reference#*:}"
  rg -Fq "$expected_asset" "$readme_file" || {
    echo "README must use the animated hero asset: $readme_file -> $expected_asset" >&2
    exit 1
  }
done

for asset in "${hero_assets[@]}" "$mascot_asset"; do
  [[ -f "$asset" ]] || { echo "Missing hero asset: $asset" >&2; exit 1; }
  frame_count="$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 "$asset")"
  [[ "$frame_count" =~ ^[0-9]+$ && "$frame_count" -gt 1 ]] || {
    echo "Hero asset must remain animated: $asset" >&2
    exit 1
  }
done

echo "README hero contract verified: all light, dark, English, and Chinese variants use animated smile assets."
