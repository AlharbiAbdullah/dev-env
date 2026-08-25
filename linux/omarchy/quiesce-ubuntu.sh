#!/usr/bin/env bash
# quiesce-ubuntu.sh — the LAST command on the Ubuntu box before rebooting into the Omarchy USB.
# Single-writer rule: the old box must stop writing the vault/ChromaDB before the new one starts.
set -uo pipefail
echo "== disabling scheduled jobs"
systemctl --user disable --now news-daily.timer news-weekly.timer news-x-collect.timer rai-maintenance.timer paper-portfolio.timer
systemctl --user list-timers --all | grep -E 'news|rai|portfolio' || echo "  (none armed)"
echo "== final vault + dev-env push"
( cd ~/helm && git add -A && git -c user.name="Abdullah Alharbi" -c user.email="alharbi.s.abdullah@gmail.com" commit -qm "chore: final commit before Omarchy migration" ; git push origin main )
( cd ~/dev-env && git push origin main )
for r in ~/projects/open-dmo ~/projects/personal-website ~/projects/syaq ~/work/mirsad; do
  ( cd "$r" 2>/dev/null && [ -n "$(git status --porcelain)" ] && echo "  !! $r still dirty (backed up raw on the Mac, commit if you want it in git)" ) || true
done
echo "== final incremental backup (light)"
"$(dirname "$0")/backup-ubuntu.sh" --light
echo "== READY TO REBOOT: sudo reboot, F7/Del for the boot menu, pick the SanDisk USB"
