#!/usr/bin/env bash
# Track the upstream pstack so a port can be kept honest.
#
# Vendors the upstream skills this repo ports into .upstream-snapshot/, so a later diff shows what
# moved upstream without touching the ported files. It never rewrites skills/.
#
# Usage:
#   scripts/sync-upstream.sh           fetch upstream and refresh .upstream-snapshot
#   scripts/sync-upstream.sh --check   fetch and report changed files, write nothing
#   scripts/sync-upstream.sh --ref <r> use another ref (default: main)
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
snapshot="$repo_root/.upstream-snapshot"
upstream_url="https://github.com/cursor/plugins.git"
ref=main
check=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) check=1; shift ;;
    --ref) ref="$2"; shift 2 ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "fetching $upstream_url at $ref"
git clone --depth 1 --filter=blob:none --sparse --branch "$ref" "$upstream_url" "$work/src" >/dev/null 2>&1
git -C "$work/src" sparse-checkout set pstack >/dev/null 2>&1

# The directories this repo ports. Keep in step with skills/.
ported=$(cd "$repo_root/skills" && ls -d */ | tr -d '/' | grep -v -E '^(no-comments|show-me-your-work)$' || true)

upstream_version=$(node -e 'const p=require(process.argv[1]);console.log(p.version)' "$work/src/pstack/plugin.json")

fresh="$work/fresh"
mkdir -p "$fresh"
missing=0
for name in $ported; do
  if [ -d "$work/src/pstack/skills/$name" ]; then
    cp -R "$work/src/pstack/skills/$name" "$fresh/$name"
  else
    echo "  not upstream (local addition): $name"
    missing=$((missing + 1))
  fi
done
# The two skills that come from agents/ and references/ rather than skills/.
cp -R "$work/src/pstack/agents" "$fresh/agents" 2>/dev/null || true

if [ "$check" = 1 ]; then
  echo
  echo "upstream pstack $upstream_version"
  changed=0
  if [ -d "$snapshot" ]; then
    while IFS= read -r line; do
      echo "  $line"
      changed=$((changed + 1))
    done < <(diff -rq "$snapshot" "$fresh" 2>/dev/null | grep -v '^Only in .*agents' || true)
  else
    echo "  no snapshot yet; run without --check to create one"
    changed=1
  fi
  [ "$changed" = 0 ] && echo "  no upstream drift" || echo "  $changed difference(s); review which ports to redo"
  exit 0
fi

rm -rf "$snapshot"
mv "$fresh" "$snapshot"
printf 'upstream: %s\nref: %s\nversion: %s\nfetched: %s\n' \
  "$upstream_url" "$ref" "$upstream_version" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$snapshot/UPSTREAM.txt"

echo "snapshot refreshed at pstack $upstream_version ($(find "$snapshot" -type f | wc -l) files)"
echo "local-only skills kept out of the snapshot: $missing"
