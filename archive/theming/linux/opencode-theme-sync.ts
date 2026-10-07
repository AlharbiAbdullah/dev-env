// theme-sync — OpenCode TUI plugin. Makes an ALREADY-OPEN session follow the
// system theme switch live.
//
// The `theme` switcher (~/.local/bin/theme) repoints
// ~/.config/themes/current.lua and regenerates ~/.config/opencode/themes/<name>.json
// on every switch. On launch OpenCode reads tui.json/kv.json, so a FRESH session
// already matches. The only gap is a running TUI: OpenCode binds the theme at
// startup and its config watcher reloads agents/skills — never the theme.
//
// This plugin closes that gap. It polls the current.lua symlink (one readlink/sec,
// negligible) and calls api.theme.set() when the target changes, which repaints
// the live TUI. The 10 system theme dirs map 1:1 to the OpenCode theme JSON names,
// so the symlinked dir name IS the OpenCode theme name.
//
// Built against @opencode-ai/plugin 1.17.9 (TuiPlugin interface).
import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { readlinkSync } from "node:fs"
import { basename, dirname } from "node:path"

const CURRENT = "/home/abdullah/.config/themes/current.lua"
const THEMES_DIR = "/home/abdullah/.config/opencode/themes"
const POLL_MS = 1000

// current.lua -> /home/abdullah/.config/opencode/themes/<name>/theme.lua  =>  <name>
function currentThemeName(): string | null {
  try {
    return basename(dirname(readlinkSync(CURRENT)))
  } catch {
    return null
  }
}

const tui: TuiPlugin = async (api) => {
  let last = api.theme.selected

  async function apply(name: string) {
    if (!name || name === last) return
    try {
      if (!api.theme.has(name)) {
        await api.theme.install(`${THEMES_DIR}/${name}.json`)
      }
      // set() returns false when the theme still isn't loadable; leave `last`
      // untouched so the next tick retries rather than going silently stale.
      if (api.theme.set(name)) last = name
    } catch {
      /* transient (e.g. switcher mid-write) — retry next tick */
    }
  }

  // Reconcile once at startup: if tui.json/kv.json drifted from current.lua
  // (e.g. a prior session clobbered kv.json on exit), snap to the live theme.
  const initial = currentThemeName()
  if (initial && initial !== api.theme.selected) await apply(initial)
  else if (initial) last = initial

  const timer = setInterval(() => {
    const name = currentThemeName()
    if (name) void apply(name)
  }, POLL_MS)

  api.lifecycle.onDispose(() => clearInterval(timer))
}

const plugin: TuiPluginModule & { id: string } = {
  id: "rai.theme-sync",
  tui,
}

export default plugin
