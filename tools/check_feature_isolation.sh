#!/usr/bin/env bash
# Feature isolation (Engineering Handbook §2.4): a feature must not import
# another feature. `auth` is the one sanctioned exception.
#
# Imports that already existed when this check was made real are listed in
# tools/feature_isolation_baseline/<feature>.txt, one per feature so two PRs
# never edit the same file. The check fails on any import that is NOT in its
# baseline, so the list can only shrink. Remove a line when you remove the
# import; a line whose import is not in the code is reported but does not fail
# (it may be an import in a PR that has not merged yet).
#
#   tools/check_feature_isolation.sh                  check (CI runs this)
#   tools/check_feature_isolation.sh --write-baseline rewrite the baselines
#                                                     from the code as it is

set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

baseline_dir=tools/feature_isolation_baseline
write=0
[ "${1:-}" = "--write-baseline" ] && write=1

# "<file> imports <features/...>" for every cross-feature import of one feature,
# without line numbers so an edit above an import does not change its entry.
found() {
  local feature=$1
  { grep -rnE "^import 'package:flutter_template/features/" "lib/features/$feature" || true; } |
    sed -E "s#^([^:]+):[0-9]+:import 'package:flutter_template/(features/[^']+)'.*#\1 imports \2#" |
    { grep -vE " imports features/($feature|auth)/" || true; } |
    sort -u
}

fail=0
stale=0
for dir in lib/features/*/; do
  feature=$(basename "$dir")
  base="$baseline_dir/$feature.txt"
  now=$(found "$feature")

  if [ "$write" -eq 1 ]; then
    if [ -n "$now" ]; then
      mkdir -p "$baseline_dir"
      printf '%s\n' "$now" >"$base"
    else
      rm -f "$base"
    fi
    continue
  fi

  allowed=""
  [ -f "$base" ] && allowed=$(grep -vE '^\s*(#|$)' "$base" | sort -u || true)

  new=$(comm -23 <(printf '%s\n' "$now") <(printf '%s\n' "$allowed") | sed '/^$/d')
  gone=$(comm -13 <(printf '%s\n' "$now") <(printf '%s\n' "$allowed") | sed '/^$/d')

  if [ -n "$new" ]; then
    echo "::error::Cross-feature import in feature '$feature':"
    echo "$new" | sed 's/^/  /'
    fail=1
  fi
  if [ -n "$gone" ]; then
    echo "::warning::Baseline for '$feature' lists imports not in the code here (removed, or in a PR not merged yet). Remove the lines once they are really gone, from $base:"
    echo "$gone" | sed 's/^/  /'
    stale=1
  fi
done

if [ "$write" -eq 1 ]; then
  echo "Baselines rewritten in $baseline_dir/"
  exit 0
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "Features must not import other features (except 'auth'); see the"
  echo "Engineering Handbook §2.4. Move what is shared into lib/shared/, or pass it in."
  exit 1
fi
[ "$stale" -eq 0 ] || echo "(stale baseline lines are not an error)"
echo "✅ No new cross-feature imports."
