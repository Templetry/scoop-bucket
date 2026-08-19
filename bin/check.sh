#!/usr/bin/env bash
# Manifest sanity — runs on every push, so a hand edit cannot land broken.
set -euo pipefail

manifest="bucket/templetry.json"
jq empty "$manifest"

version=$(jq -r .version "$manifest")
[ -n "$version" ] && [ "$version" != "null" ] || { echo "::error::no version"; exit 1; }

for arch in 64bit arm64; do
  urls=$(jq -r ".architecture[\"$arch\"].url | length" "$manifest")
  hashes=$(jq -r ".architecture[\"$arch\"].hash | length" "$manifest")
  [ "$urls" = "$hashes" ] || { echo "::error::$arch has $urls urls and $hashes hashes"; exit 1; }
  # An URL pointing at a tag other than the manifest's version installs a
  # binary that does not match what `scoop list` reports.
  jq -r ".architecture[\"$arch\"].url[]" "$manifest" | while read -r u; do
    case "$u" in
      *"/download/v$version/"*) ;;
      *) echo "::error::$arch url does not point at v$version: $u"; exit 1 ;;
    esac
    code=$(curl -fsSL -o /dev/null -w '%{http_code}' "${u%%#*}" || true)
    [ "$code" = "200" ] || { echo "::error::${u%%#*} returned $code"; exit 1; }
  done
  jq -r ".architecture[\"$arch\"].hash[]" "$manifest" | while read -r h; do
    [ ${#h} -eq 64 ] || { echo "::error::hash is not sha256: $h"; exit 1; }
  done
done
echo "manifest ok at v$version"
