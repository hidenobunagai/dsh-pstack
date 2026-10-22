#!/usr/bin/env bash
# Link this repo's skills into a DSH skills root so the harness discovers them.
#
# DSH scans a skills root one level deep for <dir>/SKILL.md. The link target is this repo, so an
# edit here shows up in the catalog without reinstalling.
#
# Usage:
#   scripts/link-skills.sh                  link into $DSH_HOME/skills (default ~/.dsh/skills)
#   scripts/link-skills.sh --unlink         remove every link this script made
#   scripts/link-skills.sh --root <dir>     link into another skills root
#   scripts/link-skills.sh --copy           copy instead of symlink (for hosts without symlinks)
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
skills_src="$repo_root/skills"
root="${DSH_HOME:-$HOME/.dsh}/skills"
mode=link

while [ $# -gt 0 ]; do
  case "$1" in
    --unlink) mode=unlink; shift ;;
    --copy) mode=copy; shift ;;
    --root) root="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$root"

removed=0
for link in "$root"/*; do
  [ -L "$link" ] || continue
  target=$(readlink -f "$link" 2>/dev/null || true)
  case "$target" in
    "$skills_src"/*) rm -f "$link"; removed=$((removed + 1)) ;;
  esac
done

if [ "$mode" = unlink ]; then
  echo "removed $removed link(s) from $root"
  exit 0
fi

linked=0
for dir in "$skills_src"/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue
  dest="$root/$name"
  if [ "$mode" = copy ]; then
    rm -rf "$dest"
    cp -R "$dir" "$dest"
  else
    rm -rf "$dest"
    ln -s "${dir%/}" "$dest"
  fi
  linked=$((linked + 1))
done

echo "$mode: $linked skill(s) into $root"
echo "DSH picks these up on its own. A running web host may need a reload to refresh the catalog."
