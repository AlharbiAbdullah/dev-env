#!/bin/bash
# Abdullah runs this on J514S. Restore the signed, previously working kernel pair.
# Never reboots, changes the custom handoff, or exempts boot-chain verification.
set -euo pipefail
export PATH=/usr/bin:/bin
export LC_ALL=C
umask 077
fail() { printf '%s\n' "$*" >&2; exit 1; }
digest() { sha256sum -- "$1" | cut -d ' ' -f 1; }
root_file() { [[ -f $1 && ! -L $1 && $(stat -c %u -- "$1") == 0 ]]; }
root_dir() {
  local mode
  [[ -d $1 && ! -L $1 && $(stat -c %u -- "$1") == 0 ]] || return 1
  mode=$(stat -c %a -- "$1")
  (( (8#$mode & 0022) == 0 ))
}
set_stage() { phase=$1; printf '%s\n' "$phase" >"$state/stage"; }
recovery_exit() {
  local rc=$? unchanged=0 restore transaction_log
  trap - EXIT
  [[ -z ${config_stage:-} ]] || rm -f -- "$config_stage"
  (( rc != 0 )) || return 0
  set +e
  printf 'STOP: stage=%s exit=%s\nRecovery files: %s\n' "$phase" "$rc" "$state" >&2
  if [[ $phase == hold ]]; then
    unchanged=1
  elif [[ $phase == transaction && $(stat -c %s "$pacman_log") -ge $log_size ]] &&
       transaction_log=$(tail -c +"$((log_size + 1))" "$pacman_log") &&
       ! grep -F '[ALPM] transaction started' >/dev/null <<<"$transaction_log"; then
    [[ $(pacman -Q linux-aurora) == 'linux-aurora 7.2.10.aurora1-2' &&
       $(pacman -Q linux-aurora-headers) == 'linux-aurora-headers 7.2.10.aurora1-2' ]] && unchanged=1
  fi
  if (( unchanged )) && [[ $(digest /etc/pacman.conf) == "$hold_hash" ]]; then
    restore=$(mktemp /etc/.pacman-m3-restore.XXXXXX)
    if install -o root -g root -m 644 -- "$state/pacman.conf.before" "$restore" &&
       mv -fT -- "$restore" /etc/pacman.conf; then
      printf '%s\n' 'No package transaction started; the original package configuration was restored.' >&2
    else
      printf '%s\n' 'Package configuration could not be restored. Keep the recovery files.' >&2
    fi
  fi
  printf '%s\n' 'DO NOT REBOOT after this failed repair.' \
    "Read $state/stage and $state/RECOVERY.txt before another repair." \
    'Do not restore /boot alone or roll back the root snapshot alone.' >&2
  exit "$rc"
}
verify_package() {
  local file=$1 expected=$2 version=$3
  [[ -f $file && ! -L $file && -f $file.sig && ! -L $file.sig ]] ||
    fail "Package or detached signature missing: $file"
  [[ $(digest "$file") == "$expected" ]] || fail "Package bytes changed: $file"
  [[ $(pacman -Qp "$file") == "$version" ]] || fail "Package metadata differs: $file"
  gpgv --status-fd 1 --keyring /etc/pacman.d/gnupg/pubring.gpg "$file.sig" "$file" |
    grep -F '[GNUPG:] VALIDSIG 40DFB630FF42BCFFB047046CF0134EE680CAC571 ' >/dev/null ||
    fail "Expected Omarchy signature did not verify: $file"
}
verify_custom() {
  root_file "$handoff" && [[ $(digest "$handoff") == "$handoff_hash" ]] ||
    fail 'The verified custom handoff image changed.'
  [[ $(digest /etc/default/update-m1n1) == "$defaults_hash" ]] ||
    fail 'The handoff configuration changed.'
  [[ $(digest /etc/m1n1.conf) == "$config_hash" ]] || fail 'The GPU handoff options changed.'
  root_file "$checker" && [[ $(digest "$checker") == "$checker_hash" ]] ||
    fail 'The reviewed boot checker changed.'
}

[[ $EUID == 0 ]] || fail 'Run this script with sudo.'
tr '\0' '\n' </proc/device-tree/compatible | grep -Fxq apple,j514s || fail 'Wrong hardware.'
[[ ! -e /var/lib/pacman/db.lck ]] || fail 'A package transaction is active.'
handoff=/usr/local/lib/omarchy-m3-handoff/m1n1.bin
checker=/usr/bin/omarchy-apple-silicon-boot-check
handoff_hash=396cf3ec1774ca9d15ca1b6f71b5e8a3639b27f80b95d530722b35a5ea35141d
checker_hash=fb850e4d3eb800da41006661fbfe51f96a8ce1185d2f2ed21e86e54e592fa1a6
defaults_hash=885f99222a4aeffa0d8339ab7a1eaa9c3550aae5f9c484f7aeeab5f9f2d36c21
config_hash=fde2da38e3a6e5a268ff2dc226f0bbf7522ccba12d735765ec4852434ffd3ca6
verify_custom
if [[ $(pacman -Q linux-aurora) == 'linux-aurora 7.1.12.aurora8-1' &&
      $(pacman -Q linux-aurora-headers) == 'linux-aurora-headers 7.1.12.aurora8-1' ]]; then
  pacman-conf IgnorePkg | grep -Fxq linux-aurora || fail 'Incomplete recovery: kernel hold absent. DO NOT REBOOT. Inspect /var/lib/omarchy-m3-kernel-recovery/.'
  pacman-conf IgnorePkg | grep -Fxq linux-aurora-headers || fail 'Incomplete recovery: headers hold absent. DO NOT REBOOT. Inspect /var/lib/omarchy-m3-kernel-recovery/.'
  if ! env OMARCHY_BOOT_CHECK_ALLOW_PENDING_REBOOT=1 "$checker" --boot-chain; then
    fail 'Incomplete recovery: boot verification failed. DO NOT REBOOT. Inspect /var/lib/omarchy-m3-kernel-recovery/.'
  fi
  printf '%s\n' 'The recovery kernel is already installed and its boot-chain check passed. No package changes made.'
  exit 0
fi
[[ $(pacman -Q linux-aurora) == 'linux-aurora 7.2.10.aurora1-2' &&
   $(pacman -Q linux-aurora-headers) == 'linux-aurora-headers 7.2.10.aurora1-2' ]] ||
  fail 'The installed kernel pair differs from the diagnosed regression.'
[[ $(pacman -Q mesa-m3) == 'mesa-m3 26.1.4.m3.2-5' ]] || fail 'M3 Mesa changed.'
[[ $(pacman -Q aura) == 'aura 0.1.0.r20261014-2' ]] || fail 'The bootloader package changed.'
[[ $(pacman -Q omarchy-aurora-firmware) == 'omarchy-aurora-firmware 20261014-7' ]] ||
  fail 'Firmware dependency constraints changed; re-review the kernel pair.'
pacman -T coreutils kmod initramfs 'm1n1>=1.6.1' pahole 'linux-aurora>=7.1.12.aurora5' ||
  fail 'Required package dependencies are missing.'
root_file /etc/pacman.conf || fail 'Package configuration is not a root-owned regular file.'
[[ $(digest /etc/pacman.conf) == ad50da49102d6274aa752dd0f4edaada52799f03737a0c7dc20a292625aa30da ]] ||
  fail 'Package configuration changed; re-review the narrow hold.'
findmnt -n -o FSTYPE --target /boot | grep -Fxq ext4 || fail 'Unexpected /boot filesystem.'
esp_uuid=$(tr -d '\0' </proc/device-tree/chosen/asahi,efi-system-partition)
esp_device=$(readlink -e "/dev/disk/by-partuuid/$esp_uuid")
[[ -n $esp_device && $(findmnt -n -o SOURCE --mountpoint /boot/efi) == "$esp_device" ]] ||
  fail 'Mounted ESP does not match the system device tree.'
findmnt -n -o FSTYPE --mountpoint /boot/efi | grep -Fxq vfat || fail 'Unexpected ESP filesystem.'
(( $(df -PB1 /boot/efi | awk 'NR==2 {print $4}') > 134217728 )) || fail 'Insufficient ESP space.'
(( $(df -PB1 /boot | awk 'NR==2 {print $4}') > 268435456 )) || fail 'Insufficient /boot space.'
(( $(df -PB1 / | awk 'NR==2 {print $4}') > 2147483648 )) || fail 'Insufficient backup space.'
package_dir=/home/abdullah/Downloads/omarchy-m3-kernel-recovery
kernel=$package_dir/linux-aurora-7.1.12.aurora8-1-aarch64.pkg.tar.zst
headers=$package_dir/linux-aurora-headers-7.1.12.aurora8-1-aarch64.pkg.tar.zst
verify_package "$kernel" 4333b958171b447bd4141f5155e678b1f2848e3cf3795fe481a62425946b415a \
  'linux-aurora 7.1.12.aurora8-1'
verify_package "$headers" 00ecbe438b2d7b72826aa1cf8ddbff52360649e6e31cd12f7c0b72979738dfd6 \
  'linux-aurora-headers 7.1.12.aurora8-1'
current_kernel=/var/cache/pacman/pkg/linux-aurora-7.2.10.aurora1-2-aarch64.pkg.tar.zst
current_headers=/var/cache/pacman/pkg/linux-aurora-headers-7.2.10.aurora1-2-aarch64.pkg.tar.zst
verify_package "$current_kernel" b7d2da14945d0c457c90ee6af1d0aa77f497601ebfdc889e26a6bb3cbb5a3d6c \
  'linux-aurora 7.2.10.aurora1-2'
verify_package "$current_headers" b6c5a8b18749016a840e743aa8c40dc52b6c167ccd166fc4fcb8db4525e7b121 \
  'linux-aurora-headers 7.2.10.aurora1-2'
if [[ -e /var/lib/omarchy-m3-kernel-recovery || -L /var/lib/omarchy-m3-kernel-recovery ]]; then
  root_dir /var/lib/omarchy-m3-kernel-recovery || fail 'Recovery directory ownership differs.'
fi

root_dir /var/lib || fail 'System state directory ownership differs.'
pacman_log=$(pacman-conf LogFile)
[[ $pacman_log == /var/log/pacman.log ]] || fail 'Unexpected package log.'
root_file "$pacman_log" || fail 'Package log ownership differs.'
# Preflight complete. Back up the separate /boot and ESP before the transaction.
state=/var/lib/omarchy-m3-kernel-recovery/$(date +%Y%m%d-%H%M%S)
[[ ! -e $state && ! -L $state ]] || fail 'Recovery record already exists.'
install -d -m 700 -- "$state"
phase=backup
config_stage=''
hold_hash=''
log_size=0
trap recovery_exit EXIT
set_stage backup
printf 'Recovery files: %s\n' "$state"
cat >"$state/RECOVERY.txt" <<EOF
This is a coordinated kernel and boot-chain recovery. Do not reboot after any failed stage.
The stage file names the last operation attempted. system-before.tar includes /boot and the ESP,
configs, custom handoff, checker and the prior cohort's local package metadata.
The signed 7.2.10 kernel/header archives are here for a reviewed reverse transaction.
The root-snapshot.txt file records the snapshot created before package changes.
Do not restore the root snapshot alone: /boot is separate ext4, and ESP is separate VFAT.
Do not extract boot files alone over a different installed kernel cohort.
Keep this directory and the failed command output for Rai to review the next repair.
EOF
cp -p -- /etc/pacman.conf "$state/pacman.conf.before"
cp -- "$current_kernel" "$current_headers" "$current_kernel.sig" "$current_headers.sig" "$state/"
tar --acls --xattrs -cpf "$state/system-before.tar" -C / \
  boot etc/pacman.conf etc/default/update-m1n1 etc/m1n1.conf etc/default/grub \
  etc/mkinitcpio.conf etc/mkinitcpio.d usr/local/lib/omarchy-m3-handoff \
  usr/bin/omarchy-apple-silicon-boot-check \
  var/lib/pacman/local/linux-aurora-7.2.10.aurora1-2 \
  var/lib/pacman/local/linux-aurora-headers-7.2.10.aurora1-2
bsdtar -tf "$state/system-before.tar" >/dev/null
sha256sum "$state/system-before.tar" "$state/"*.pkg.tar.zst >"$state/backup.sha256"
pacman -Q >"$state/packages-before.txt"
set_stage snapshot
snapper -c root create --type single --print-number \
  --description 'Before J514S GPU kernel recovery 2026-10-20' >"$state/root-snapshot.txt"
awk '/^\[options\]$/ {
  print; print "# J514S M3 GPU recovery 2026-10-20: 7.2.10 has no render node; remove this pair hold after validation."
  print "IgnorePkg = linux-aurora linux-aurora-headers"; next
} {print}' /etc/pacman.conf >"$state/pacman.conf.hold"
pacman-conf --config "$state/pacman.conf.hold" IgnorePkg | grep -Fxq linux-aurora || fail 'Invalid kernel hold.'
pacman-conf --config "$state/pacman.conf.hold" IgnorePkg | grep -Fxq linux-aurora-headers || fail 'Invalid headers hold.'
pacman --config "$state/pacman.conf.hold" -U --print --print-format '%n %v' "$kernel" "$headers"
[[ ! -e /var/lib/pacman/db.lck ]] || fail 'A package transaction started.'
verify_custom
set_stage hold
hold_hash=$(digest "$state/pacman.conf.hold")
config_stage=$(mktemp /etc/.pacman-m3-recovery.XXXXXX)
install -o root -g root -m 644 -- "$state/pacman.conf.hold" "$config_stage"
mv -fT -- "$config_stage" /etc/pacman.conf
log_size=$(stat -c %s "$pacman_log")
set_stage transaction
pacman -U "$kernel" "$headers"
[[ $(pacman -Q linux-aurora) == 'linux-aurora 7.1.12.aurora8-1' &&
   $(pacman -Q linux-aurora-headers) == 'linux-aurora-headers 7.1.12.aurora8-1' ]] || fail 'Kernel rollback incomplete.'
verify_custom
set_stage initramfs
/usr/bin/mkinitcpio -P
set_stage m1n1
/usr/bin/update-m1n1
set_stage boot-menu
/usr/bin/omarchy-mac-boot-update
verify_custom
set_stage boot-verification
env OMARCHY_BOOT_CHECK_ALLOW_PENDING_REBOOT=1 "$checker" --boot-chain
set_stage verified
printf '%s\n' "Boot-chain verification passed. Recovery files: $state" \
  'No reboot was performed. The two kernel packages are held until a fixed M3 kernel is verified.' \
  'To release the hold later, remove the dated J514S comment and its IgnorePkg line from /etc/pacman.conf.'
