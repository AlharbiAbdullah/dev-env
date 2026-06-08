# Ubuntu PC migration runbook

Moving the Ubuntu dev box to a new machine. `bootstrap.sh` rebuilds everything;
this file covers the **machine-to-machine cutover** — specifically the safe
handoff of the scheduled jobs and the ChromaDB semantic-memory database.

## Repos involved

| Repo | Clones to | Branch | Notes |
|---|---|---|---|
| `AlharbiAbdullah/dev-env` | `~/dev-env` | `main` | This repo. Clone first, run `bootstrap.sh`. |
| `AlharbiAbdullah/helm`    | `~/helm`   | `main` | Obsidian vault + Rai brain. **Carries the ChromaDB seed.** |
| `AlharbiAbdullah/mirsad`  | `~/work/mirsad` | `prod` | Work platform. Clone only — bring-up (Docker/GPU) is out of scope here. |

## ⚠️ The one hard rule: a single ChromaDB writer

`~/helm/03-rai/semantic-memory/chromadb` is a **git-tracked binary** store
(`chroma.sqlite3` + HNSW `.bin` files). Only the `rai-maintenance` job writes it
and pushes helm. If the **old and new Ubuntu both run `rai-maintenance`**, they
race on those binaries → unmergeable git binary conflict + a half-written DB →
**corruption + a stuck pipeline**. The per-machine `.lock` does *not* protect
across two machines — the ordering below is the only safeguard.

> Your Mac keeps its own schedule and is unaffected — the Mac commits the vault
> but never writes ChromaDB. Only one **Ubuntu** may run `rai-maintenance` at a time.

---

## Phase A — on THIS (old) machine, before the move

1. **Quiesce** — make sure no run is in flight:
   ```bash
   systemctl --user list-timers | grep -E 'news|rai'
   ls ~/helm/03-rai/skills/rai/scheduled/.lock 2>/dev/null   # must be absent
   pgrep -af 'claude --chrome'                                # none
   ```
2. **Flush + push helm (the seed)** — the new box clones this, so it must be current,
   including the ChromaDB deltas:
   ```bash
   cd ~/helm
   git add -A && git commit -m "pre-migration snapshot"
   git pull --rebase --autostash origin main
   git push
   ```
3. **Push dev-env** (configs + this migration tooling) and confirm mirsad is pushed:
   ```bash
   cd ~/dev-env && git add -A && git commit -m "migration tooling" && git push
   git -C ~/work/mirsad status   # expect clean on prod, already pushed
   ```
4. **Do NOT disable the old timers yet.** The old box stays the sole writer until
   the new box is fully staged — this keeps exactly one writer the entire time.

## Phase B — on the NEW machine (stage, do not arm)

5. Install git, clone dev-env, run the bootstrap **without arming timers**:
   ```bash
   sudo apt-get update && sudo apt-get install -y git
   git clone https://github.com/AlharbiAbdullah/dev-env.git ~/dev-env
   cd ~/dev-env/linux/ubuntu
   ENABLE_TIMERS=0 ./bootstrap.sh            # add --hyprland-ppa if wanted
   ```
   This installs sudoers, packages, dotfiles, Claude config, clones helm+mirsad,
   and installs (but does **not** enable) the 3 timers.
6. **Carry secrets** (see checklist below) and authenticate:
   ```bash
   cp ~/dev-env/linux/ubuntu/.bashrc.local.example ~/.bashrc.local   # fill in real keys
   claude            # browser login
   gh auth status    # green
   ```
7. **Verify the seed before arming:**
   ```bash
   git -C ~/helm log -1 --oneline                 # matches the old box's Phase A push
   ls -la ~/helm/03-rai/semantic-memory/chromadb  # ~14 MB sqlite + .bin present
   ```
   Optional: run one maintenance pass **manually** (timer still off) to prove the
   pipeline pushes cleanly:
   `~/helm/03-rai/skills/rai/scheduled/run-maintenance-ubuntu.sh`

## Phase C — the switch (exact order; reversing C1/C3 is the corruption window)

8. **OLD box — disable + stop the timers FIRST:**
   ```bash
   systemctl --user disable --now news-daily.timer news-weekly.timer rai-maintenance.timer
   systemctl --user list-timers | grep -E 'news|rai'   # confirm gone
   loginctl disable-linger "$USER"
   ```
9. **OLD box — one final flush** so nothing is stranded; after this it must never push helm again:
   ```bash
   cd ~/helm && git pull --rebase --autostash origin main && git push
   ```
10. **NEW box — absorb that last commit, then arm:**
    ```bash
    git -C ~/helm pull --rebase origin main
    systemctl --user enable --now news-daily.timer news-weekly.timer rai-maintenance.timer
    loginctl enable-linger "$USER"
    systemctl --user list-timers --all | grep -E 'news|rai'
    ```
The new machine is now the sole Ubuntu writer of ChromaDB and sole helm committer.

## Phase D — decommission the old machine

11. Leave the old timers disabled **permanently**. If the old box stays online,
    optionally make a double-write structurally impossible:
    `chmod -R a-w ~/helm` (or remove `~/helm`).
12. `/etc/sudoers.d/ab` is harmless — leave it. Mac is unchanged throughout.

---

## Secrets — carry by hand (never committed)

| Secret | Where | How |
|---|---|---|
| `OPENROUTER_API_KEY` (+ any others) | `~/.bashrc.local` | From your password manager / the Mac's `~/.zshrc.local`. Template: `.bashrc.local.example`. |
| Mirsad service/DB config | `~/work/mirsad/.env` | Create by hand. **Add `.env` to mirsad's `.gitignore` before any commit** — it is not ignored there yet. |
| Claude Code auth token | `~/.claude/.credentials.json` | Do **not** copy — re-auth by running `claude` on the new box. |
| GitHub auth | gh credential helper | `gh auth login`. |
| SSH keys (if you push via SSH) | `~/.ssh/` | Restore from your secure backup; `chmod 700 ~/.ssh && chmod 600 ~/.ssh/*`. |

Never commit: `*.local`, `.env`, `.credentials.json`, `~/.ssh/`.

## Post-cutover smoke test

- `systemctl --user list-timers` shows all 3 timers with future `NEXT` times.
- Hyprland session starts; `theme gruvbox` recolors the UI.
- `uv --version`, `gh auth status`, `claude --version` all work.
- A `rai-maintenance` run commits + pushes helm with no binary conflict.
