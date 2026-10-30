#!/bin/bash
# Abdullah runs this on the laptop. Never rebuilds boot files or reboots.
set -euo pipefail
export PATH=/usr/bin:/bin
umask 077

fail() { printf '%s\n' "$*" >&2; exit 1; }
check_hash() {
  local actual
  actual=$(sha256sum -- "$1")
  [[ ${actual%% *} == "$2" ]]
}
root_file() {
  [[ -f $1 && ! -L $1 && $(stat -c %u -- "$1") == 0 ]]
}
root_dir() {
  local mode
  [[ -d $1 && ! -L $1 && $(stat -c %u -- "$1") == 0 ]] || return 1
  mode=$(stat -c %a -- "$1")
  (( (8#$mode & 0022) == 0 ))
}

[[ $EUID == 0 ]] || fail 'Run this script with sudo.'
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
target=/usr/bin/omarchy-apple-silicon-boot-check
patch_file=$source_dir/provider-handoff.patch
handoff=/usr/local/lib/omarchy-m3-handoff/m1n1.bin
backup_dir=/var/lib/omarchy-m3-boot-check-fix
backup=$backup_dir/original.sh
original_hash=92b128ae3c77ae4fb6b6aa8f69ffc74214841fda534a7fa56447a675f5f26cd1
fixed_hash=fb850e4d3eb800da41006661fbfe51f96a8ce1185d2f2ed21e86e54e592fa1a6
patch_hash=7f6e91b1d102ebaca60b222230dac9c7da3ffbc15f9cc5bb3370fd6841b32f13
handoff_hash=396cf3ec1774ca9d15ca1b6f71b5e8a3639b27f80b95d530722b35a5ea35141d

# Read-only preflight. No files are written until every guard below passes.
tr '\0' '\n' </proc/device-tree/compatible | grep -Fxq apple,j514s ||
  fail 'This repair is only for the verified J514S laptop.'
[[ ! -e /var/lib/pacman/db.lck ]] || fail 'A package transaction is active; stopping.'
[[ $(pacman -Q linux-aurora) == 'linux-aurora 7.2.10.aurora1-2' ]] ||
  fail 'The kernel package changed; stopping.'
[[ $(pacman -Q aura) == 'aura 0.1.0.r20261014-2' ]] ||
  fail 'The bootloader package changed; stopping.'
[[ $(pacman -Q omarchy-mac-boot) == 'omarchy-mac-boot 20261020-2' ]] ||
  fail 'The boot support package changed; stopping.'
[[ $(pacman -Qq m1n1-aurora) == aura ]] || fail 'The bootloader provider changed; stopping.'
root_dir /usr/bin || fail 'System binary directory ownership differs; stopping.'
root_dir /var/lib || fail 'System state directory ownership differs; stopping.'
root_file "$target" || fail 'Installed checker is not a root-owned regular file; stopping.'
root_file "$handoff" || fail 'Handoff image is not a root-owned regular file; stopping.'
check_hash "$handoff" "$handoff_hash" ||
  fail 'The known working handoff image changed; stopping.'
[[ -f $patch_file && ! -L $patch_file ]] || fail 'Repair patch is not a regular file; stopping.'
check_hash "$patch_file" "$patch_hash" ||
  fail 'The repair patch changed; stopping.'
if [[ -e $backup_dir || -L $backup_dir ]]; then
  root_dir "$backup_dir" || fail 'Backup directory ownership differs; stopping.'
fi
if [[ -e $backup || -L $backup ]]; then
  root_file "$backup" || fail 'Existing backup is not a root-owned regular file; stopping.'
  check_hash "$backup" "$original_hash" ||
    fail 'Existing backup differs; stopping.'
fi
already_fixed=0
if check_hash "$target" "$fixed_hash"; then
  already_fixed=1
else
  check_hash "$target" "$original_hash" || fail 'Installed checker changed; stopping.'
fi

if (( ! already_fixed )); then
  workdir=$(mktemp -d)
  staged=''
  cleanup() {
    [[ -z $staged ]] || rm -f -- "$staged"
    rm -rf -- "$workdir"
  }
  trap cleanup EXIT
  cp -- "$target" "$workdir/checker"
  cp -- "$patch_file" "$workdir/provider-handoff.patch"
  check_hash "$workdir/checker" "$original_hash" || fail 'Checker changed during staging.'
  check_hash "$workdir/provider-handoff.patch" "$patch_hash" || fail 'Patch changed during staging.'
  patch --batch --fuzz=0 "$workdir/checker" "$workdir/provider-handoff.patch"
  check_hash "$workdir/checker" "$fixed_hash" || fail 'Patched checker differs; stopping.'
  bash -n "$workdir/checker"
  [[ ! -e /var/lib/pacman/db.lck ]] || fail 'A package transaction started; stopping.'
  check_hash "$target" "$original_hash" || fail 'Installed checker changed during staging.'
  install -d -m 700 -- "$backup_dir"
  if [[ ! -e $backup ]]; then
    cp -- "$target" "$workdir/original"
    check_hash "$workdir/original" "$original_hash" || fail 'Backup source changed; stopping.'
    install -o root -g root -m 600 -- "$workdir/original" "$backup"
  fi
  root_file "$backup" || fail 'Existing backup is not a root-owned regular file; stopping.'
  check_hash "$backup" "$original_hash" || fail 'Backup verification failed.'
  staged=$(mktemp /usr/bin/.omarchy-boot-check.XXXXXX)
  install -o root -g root -m 755 -- "$workdir/checker" "$staged"
  check_hash "$staged" "$fixed_hash" || fail 'Staged checker differs; stopping.'
  mv -fT -- "$staged" "$target"
  staged=''
fi
root_file "$target" || fail 'Installed repair is not a root-owned regular file.'
check_hash "$target" "$fixed_hash" || fail 'Installed repair differs.'
env OMARCHY_BOOT_CHECK_ALLOW_PENDING_REBOOT=1 "$target" --boot-chain
printf '%s\n' 'Boot-chain check passed. Run omarchy update again. Do not reboot before it completes.'
