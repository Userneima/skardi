#!/usr/bin/env bash
set -euo pipefail

readonly hero_assets=(
  "asset/controlled-db-debugging-hero.svg"
  "asset/controlled-db-debugging-hero-dark.svg"
  "asset/controlled-db-debugging-hero-zh-CN.svg"
  "asset/controlled-db-debugging-hero-zh-CN-dark.svg"
)
readonly mascot_asset="asset/skardi-flame-mascot-blink.gif"

for asset in "${hero_assets[@]}"; do
  [[ -f "$asset" ]] || { echo "Missing hero asset: $asset" >&2; exit 1; }
  rg -Fq 'href="skardi-flame-mascot-blink.gif"' "$asset" || {
    echo "Hero mascot must use the blinking smile GIF: $asset" >&2
    exit 1
  }
done

[[ -f "$mascot_asset" ]] || { echo "Missing blinking mascot GIF: $mascot_asset" >&2; exit 1; }

echo "README hero contract verified: all light, dark, English, and Chinese variants use the blinking smile mascot."
