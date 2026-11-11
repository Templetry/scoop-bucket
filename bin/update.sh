#!/usr/bin/env bash
# Rewrites bucket/templetry.json to the latest engine release.
#
# Scoop's own `autoupdate` block is a bucket-maintainer mechanism: something
# has to run the excavator. Nothing did, and the manifest sat seven minors
# behind the engine while the README promised it tracked releases. This is
# that something, and it needs no PowerShell and no Scoop checkout.
set -euo pipefail

manifest="bucket/templetry.json"
repo="Templetry/engine"

# Unauthenticated calls share one rate limit per runner IP, so the daily job can get a
# 403 (curl exit 22; it failed that way on 2026-11-09). Use the token when the workflow
# provides one, like the homebrew tap does.
auth=()
[ -n "${GITHUB_TOKEN-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
tag=$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
[ -n "$tag" ] && [ "$tag" != "null" ] || { echo "::error::no latest release for $repo"; exit 1; }
version="${tag#v}"

current=$(jq -r .version "$manifest")
if [ "$current" = "$version" ]; then
  echo "already at $version"
  exit 0
fi
echo "$current -> $version"

sums=$(curl -fsSL "https://github.com/$repo/releases/download/$tag/SHA256SUMS")

hash_of() {
  # A missing asset must stop the run: a manifest with an empty hash makes
  # every `scoop install` fail the integrity check.
  local h
  h=$(printf '%s\n' "$sums" | awk -v f="$1" '$2 == f { print $1 }')
  [ -n "$h" ] || { echo "::error::$1 not listed in SHA256SUMS for $tag"; exit 1; }
  printf '%s' "$h"
}

base="https://github.com/$repo/releases/download/$tag"
tmp=$(mktemp)
jq \
  --arg v "$version" \
  --arg u64a "$base/templetry-windows-amd64.exe#/templetry.exe" \
  --arg u64b "$base/templetry-mcp-windows-amd64.exe#/templetry-mcp.exe" \
  --arg ua64a "$base/templetry-windows-arm64.exe#/templetry.exe" \
  --arg ua64b "$base/templetry-mcp-windows-arm64.exe#/templetry-mcp.exe" \
  --arg h64a "$(hash_of templetry-windows-amd64.exe)" \
  --arg h64b "$(hash_of templetry-mcp-windows-amd64.exe)" \
  --arg ha64a "$(hash_of templetry-windows-arm64.exe)" \
  --arg ha64b "$(hash_of templetry-mcp-windows-arm64.exe)" \
  '.version = $v
   | .architecture["64bit"].url  = [$u64a, $u64b]
   | .architecture["64bit"].hash = [$h64a, $h64b]
   | .architecture["arm64"].url  = [$ua64a, $ua64b]
   | .architecture["arm64"].hash = [$ha64a, $ha64b]' \
  "$manifest" > "$tmp"

mv "$tmp" "$manifest"
echo "updated=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "version=$version" >> "${GITHUB_OUTPUT:-/dev/null}"
