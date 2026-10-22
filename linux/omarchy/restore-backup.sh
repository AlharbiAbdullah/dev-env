#!/usr/bin/env bash
# Restore encrypted snapshots into a NEW staging directory. Never apply to live paths.
# Usage: restore-backup.sh --target /absolute/new/target [--home-snapshot ID] [--machine-snapshot ID]
set -euo pipefail
umask 077
fail(){ echo "FAIL: $*" >&2; exit 1; }
usage(){ fail "usage: $0 --target /absolute/new/target [--home-snapshot ID] [--machine-snapshot ID]"; }
TARGET=""; HOME_SNAPSHOT=""; MACHINE_SNAPSHOT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) [ "$#" -ge 2 ] || usage; TARGET="$2"; shift 2 ;;
    --home-snapshot) [ "$#" -ge 2 ] || usage; HOME_SNAPSHOT="$2"; shift 2 ;;
    --machine-snapshot) [ "$#" -ge 2 ] || usage; MACHINE_SNAPSHOT="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[[ "$TARGET" = /* ]] || usage
[ ! -e "$TARGET" ] && [ ! -L "$TARGET" ] || fail "target already exists"
# Resolve aliases and symlinked parents before creating anything or reading the repo.
[ "$(realpath -m -- "$TARGET")" = "$TARGET" ] || fail "target must be an absolute path without aliases or symlinks"
[ -d "$(dirname -- "$TARGET")" ] || fail "target parent directory must exist"
for id in "$HOME_SNAPSHOT" "$MACHINE_SNAPSHOT"; do
  [ -z "$id" ] || [[ "$id" =~ ^[[:xdigit:]]{8,64}$ ]] || fail "snapshot ID must be 8 to 64 hex characters"
done
source "$HOME/.config/restic/env" || fail "cannot read restic environment"

for kind in home machine; do
  if { [ "$kind" = home ] && [ -z "$HOME_SNAPSHOT" ]; } \
     || { [ "$kind" = machine ] && [ -z "$MACHINE_SNAPSHOT" ]; }; then
    selected=$(restic snapshots --tag "$kind-state" --json | uv run --no-project --python 3.12 python -c '
import datetime, json, sys
snapshots = json.load(sys.stdin)
newest = max(snapshots, key=lambda s: datetime.datetime.fromisoformat(s["time"].replace("Z", "+00:00")), default=None)
print(newest["id"] if newest else "")
') || fail "cannot select $kind-state snapshot"
    [[ "$selected" =~ ^[[:xdigit:]]{8,64}$ ]] || fail "no $kind-state snapshot; specify an explicit snapshot ID if available"
    if [ "$kind" = home ]; then HOME_SNAPSHOT="$selected"; else MACHINE_SNAPSHOT="$selected"; fi
  fi
done

mkdir -m 0700 -- "$TARGET" || fail "cannot create new target"
mkdir -- "$TARGET/home" "$TARGET/archive" "$TARGET/system"
restic restore "$HOME_SNAPSHOT" --verify --target "$TARGET/home" || fail "home restore failed; partial data remains in $TARGET"
restic restore "$MACHINE_SNAPSHOT" --verify --target "$TARGET/archive" || fail "machine-state restore failed; partial data remains in $TARGET"
ARCHIVE="$TARGET/archive/machine-state.tar"
[ -f "$ARCHIVE" ] && [ ! -L "$ARCHIVE" ] || fail "machine-state.tar missing from selected snapshot"
tar --extract --file "$ARCHIVE" --directory "$TARGET/system" --no-same-owner --same-permissions --acls --xattrs \
  || fail "machine-state extraction failed; partial data remains in $TARGET"
echo "restore OK: $TARGET"
