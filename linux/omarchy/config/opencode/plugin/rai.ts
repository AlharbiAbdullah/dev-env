// Rai brain — GLOBAL OpenCode plugin. Loads in EVERY folder (like Claude Code's
// global SessionStart hook), and injects context that is cwd-aware:
//   inside ~/helm  -> full recent memory (capped) + that folder's codemap
//   anywhere else  -> last 7 days of memory + that folder's codemap
// Identity itself loads via `instructions` in opencode.jsonc (global, every dir).
// The Python hook logic is never rewritten — this only relocates where it fires.
// Built against @opencode-ai/plugin 1.1.30 Hooks interface.
import type { Plugin } from "@opencode-ai/plugin"

const HELM = "/home/abdullah/helm"
const HOOKS = `${HELM}/03-rai/hooks`
const PYC = `${HELM}/03-rai/semantic-memory/scripts/py-chroma.sh`
const DUMP = "/home/abdullah/.config/opencode/rai/dump_memories.py"
const MAP = `${HELM}/03-rai/skills/map-updater/scripts`

export const RaiPlugin: Plugin = async ({ $, directory }) => {
  const dir = directory || process.cwd()
  const inHelm = dir.startsWith(HELM)
  let ctxCache: string | null = null // computed once per session (cwd is fixed)

  async function run(script: string, payload: unknown, interp: "py" | "venv" = "py") {
    const json = JSON.stringify(payload)
    const cmd = interp === "venv"
      ? $`echo ${json} | bash ${PYC} ${script}`
      : $`echo ${json} | python3 ${script}`
    return await cmd.cwd(dir).nothrow().quiet()
  }

  async function buildContext(): Promise<string> {
    if (ctxCache !== null) return ctxCache
    const parts: string[] = []
    // cwd-aware memory: helm = full recent (capped ~30k tok); elsewhere = 7 days
    const env = inHelm ? "RAI_MEM_DAYS=0 RAI_MEM_MAXCHARS=120000" : "RAI_MEM_DAYS=7"
    try {
      const r = await $`/bin/sh -c ${`${env} bash ${PYC} ${DUMP}`}`.cwd(dir).nothrow().quiet()
      const t = r.stdout?.toString().trim()
      if (t) parts.push(t)
    } catch (e: any) { console.error("[rai] memory load:", e?.message) }
    // current folder's codemap, if present
    try {
      const cm = await $`cat ${dir}/.codemap/codemap.md`.nothrow().quiet()
      const t = cm.stdout?.toString().trim()
      if (t) parts.push(`## Codemap (${dir})\n${t}`)
    } catch {}
    ctxCache = parts.join("\n\n")
    return ctxCache
  }

  return {
    // ---- inject memory + codemap into the system prompt (cwd-aware) ----
    "experimental.chat.system.transform": async (_input, output) => {
      try {
        const ctx = await buildContext()
        if (ctx) output.system.push(ctx)
      } catch (e: any) { console.error("[rai] inject error:", e?.message) }
    },

    // ---- pre-tool gating: security-validator.py was retired 2026-06-27; gating is now
    //      handled by the permission allow-list (same as Claude Code), no Python shim. ----

    // ---- per-prompt side effects (session-name) ----
    "chat.message": async (input, output) => {
      try {
        if (process.env.RAI_SMOKE_TEST === "1") return
        const text = (output.parts || []).filter((p: any) => p.type === "text").map((p: any) => p.text).join("\n").trim()
        if (!text) return
        const payload = { hook_event_name: "UserPromptSubmit", prompt: text, session_id: input.sessionID, cwd: dir }
        await run(`${HOOKS}/session-auto-name.py`, payload)
      } catch (e: any) { console.error("[rai] chat.message shim error:", e?.message) }
    },

    // ---- codemap regen after edits/bash ----
    "tool.execute.after": async (input) => {
      try {
        if (input.tool === "write" || input.tool === "edit" || input.tool === "patch") {
          await $`bash ${MAP}/auto-update-codemap.sh`.cwd(dir).nothrow().quiet()
        } else if (input.tool === "bash") {
          await $`bash ${MAP}/codemap-on-bash.sh`.cwd(dir).nothrow().quiet()
        }
      } catch (e: any) { console.error("[rai] codemap shim error:", e?.message) }
    },

    // ---- SessionEnd cluster (needs transcript adapter for the parsing ones) ----
    event: async ({ event }) => {
      try {
        const t = (event as any)?.type || ""
        if (process.env.RAI_SMOKE_TEST === "1") return
        if (t === "session.idle" || t === "session.deleted" || t === "session.completed") {
          const sid = (event as any)?.properties?.sessionID || (event as any)?.properties?.info?.id || ""
          const payload = { hook_event_name: "SessionEnd", session_id: sid, cwd: dir }
          await run(`${HOOKS}/update-counts.py`, payload)
          await run(`${HOOKS}/save-memory.py`, payload, "venv")
          await run(`${HOOKS}/session-summary.py`, payload, "venv")
        }
      } catch (e: any) { console.error("[rai] event shim error:", e?.message) }
    },
  }
}
