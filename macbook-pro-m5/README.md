# MacBook Pro M5 — Local Agent Stack

A local-first AI agent stack built on Apple Silicon (M5, 32GB unified
memory): a local model served by Ollama, [Hermes
Agent](https://github.com/NousResearch/hermes-agent) as the orchestrator,
private web search via SearXNG, and a custom animated status face used in
both a browser dashboard and a native floating desktop widget.

This folder documents and hosts the custom pieces of that setup — the
actual install (Ollama, Hermes, SearXNG, the model weights) lives outside
git; what's checked in here is the configuration and the two custom apps
built on top of it.

---

## The 30-second mental model

- **Ollama** serves the model over a local HTTP API.
- **Hermes Agent** is the orchestrator — the thing you actually talk to. It
  calls Ollama for reasoning, SearXNG for web search, and has browser +
  Mac-GUI control tools.
- **The floating desktop widget** (`face-widget/`) is the on/off switch for
  the whole stack. At rest, nothing is running and no RAM is used. Click
  the face to wake everything; right-click to put it back to sleep.
- **The dashboard** (`dashboard/`) is a browser-based status page for
  watching what Ollama/SearXNG are doing live.

---

## Core model

| | |
|---|---|
| Model | `qwen3.6-moe-64k` (Qwen3.6-35B-A3B, MoE, Q4_K_M quant) |
| Served by | Ollama, `http://localhost:11434` |
| Context | 65,536 tokens — baked into the model via [`ollama/Modelfile-moe-64k`](ollama/Modelfile-moe-64k). Ollama's default context is much smaller, and Hermes hard-requires ≥64K. |
| Decode speed | ~34.8 tok/s |
| RAM when loaded | ~22-23GB (auto-unloads after 5 min idle) |

**Why this model, specifically** — benchmarked head-to-head against two
alternatives on this exact hardware:

1. **Dense Qwen3.6-27B** — only 7.0 tok/s. Made every Hermes turn painfully
   slow (a one-line reply took over 2 minutes end-to-end).
2. **This MoE model via Ollama** — 34.8 tok/s, ~5x faster than the dense
   model, for barely more RAM. **This is what's active.**
3. **Same MoE model via Unsloth Studio with MTP speculative decoding** —
   faster still (46.65 tok/s), but only left ~2.2GB of RAM free at the real
   64K context size — too tight to safely run Hermes's browser/search
   tools alongside it, so it was dropped. Raw model speed isn't the only
   variable that matters when the goal is running an orchestrator *and*
   tools at the same time.

---

## Hermes Agent (the orchestrator)

Installed to a custom location (`~/LocalLLM/hermes`, not the default
`~/.hermes`) to keep the whole stack under one folder. Relocating an app
that wasn't designed to move took three separate fixes:

1. **`HERMES_HOME` environment variable**, set two ways — once in
   `~/.zshrc` for Terminal use, and once via a login LaunchAgent
   ([`launchagents/local.llm.hermes-env.plist`](launchagents/local.llm.hermes-env.plist))
   that runs `launchctl setenv` at login. GUI apps like Hermes's Electron
   desktop app do **not** read `.zshrc` — they only see `launchctl`-level
   session variables. General macOS gotcha, not Hermes-specific.
2. **The CLI launcher scripts** (`hermes`, `hermes-agent`, `hermes-acp`)
   had the Python interpreter path hardcoded by the original installer —
   a separate thing from `HERMES_HOME`. Rewritten to resolve dynamically
   off `$HERMES_HOME`.
3. **The desktop widget** resolves `HERMES_HOME` the same way, to find
   Hermes's config and read which model is active.

**Config** (`config.yaml`, not checked in — see below):
```yaml
model:
  default: qwen3.6-moe-64k
  provider: ollama
  base_url: http://localhost:11434/v1
  context_length: 65536
browser:
  backend: "off"   # see the bug writeup below
```

**A real bug that was found and fixed:** Hermes's browser tool defaults to
"Browser Use" mode, which shells out to an external `browser-use` CLI.
That CLI was never actually installed (only its dependency, `uvx`, was) —
and separately, GUI apps don't inherit your shell's `PATH` at all, so even
tools that *are* installed become invisible to a Finder/Dock-launched app.
Result: the desktop app couldn't read any webpage, and would flail
through curl commands trying to work around it.

**Fix:** `browser.backend: "off"` forces Hermes's own *built-in*
Playwright/Chromium tools instead — self-contained under
`~/Library/Caches/ms-playwright`, no PATH dependency. Verified by fetching
a real page through Hermes and checking the returned content matched.

`config.yaml` isn't checked into this repo since it can carry API keys for
fallback cloud providers — the two settings that actually matter for this
setup are reproduced above.

---

## SearXNG (private web search)

Installed natively (no Docker) specifically to avoid a permanent VM daemon
competing with the model for RAM. Runs on `http://127.0.0.1:8899` as a
LaunchAgent ([`launchagents/com.searxng.local.plist`](launchagents/com.searxng.local.plist)).
Rate-limiting is disabled — unnecessary for a single-user localhost
instance. Wired into Hermes as its web-search backend.

---

## Dashboard (`dashboard/`)

React 19 + Vite + the [Astryx](https://github.com/facebook/astryx) design
system. Shows **live** data polled every 2 seconds — whether a model is
resident, its context/architecture/quantization, a live unload countdown,
service reachability, and real unified-memory usage. Nothing on this page
is mocked. A Vite proxy (`/svc/ollama`, `/svc/searxng` in
[`vite.config.ts`](dashboard/vite.config.ts)) routes API calls through the
dev server since SearXNG sends no CORS headers of its own.

```bash
cd dashboard
pnpm install
pnpm dev --port 5175
```

Includes the **Local LLM Face** — the same animated status face used in
the desktop widget, as a React component
([`src/LocalLLMFace.tsx`](dashboard/src/LocalLLMFace.tsx)). Its floating
action button can load/unload the model and open SearXNG, but — unlike the
native widget — it can't launch or quit apps. That's a hard browser
sandboxing limit, not a missing feature.

---

## The floating desktop widget (`face-widget/`)

A small Swift/AppKit app: always-on-top, transparent, draggable, no Dock
icon. Shows the same face animation, reflecting real system state (polls
Ollama, and checks `llama-server`'s own CPU usage to tell "idle" apart
from "actively generating").

**This is the on/off switch for the whole stack:**

- **At rest** — both Ollama and Hermes's desktop app are fully quit, not
  just idle. Confirmed via process list: ~86% RAM free with nothing
  loaded. Face shows idle (white), not an error — being asleep is the
  normal resting state, not a failure.
- **Click the face** → wakes Ollama (launched without stealing focus, ~3s
  to become API-ready) → preloads the configured model → opens Hermes's
  desktop app with focus. If Ollama's already awake, a click just brings
  Hermes forward.
- **Right-click → "Put to Sleep Now"** → force-quits both apps
  immediately, reclaiming the RAM on demand instead of waiting for the
  5-minute auto-unload.
- **Right-click → "Quit Widget"** — quits just the widget.

One thing worth knowing if you build on this: **Ollama's own menu-bar app
doesn't respond to a plain graceful quit** — confirmed two ways during
testing (AppleScript's `quit` and a direct
`NSRunningApplication.terminate()` both left it running). "Sleep" always
escalates to a force-terminate after a 2-second grace period, or it
silently fails to free anything.

```bash
cd face-widget
./build.sh
launchctl bootout gui/$(id -u)/local.llm.facewidget 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.llm.facewidget.plist
```

The animation itself (`Resources/face.html`) has 13 states — 8
conversational + 5 system/transport + error — built around one idea: *a
bracketed face, not a sparkle*. Two chamfered brackets, two dots. White is
the resting identity; blue appears only for system/hardware work; red only
on genuine failure. Nothing rotates, glows, or uses gradients for
decoration — motion is the only thing that changes state, so it stays
legible at a glance.

---

## Security tooling

| Tool | Status | Notes |
|---|---|---|
| **AgentGG** (agentic SAST) | Configured against local Ollama | Real limitations found under test: correctly caught a command injection with legitimate reachability reasoning, but its own regex-based triage layer completely missed an obvious SQL injection and a hardcoded secret in the same file — a gap in AgentGG's agent-selection rules, not model quality. ~11 minutes for one 12-line file. |
| **Nuclei** | Installed, templates pulled | Tested only against the local SearXNG instance — no external targets scanned. |
| **LuLu** (outbound firewall) | Installed, running | Substitute for Portmaster, which doesn't exist for macOS. Confirmed running; not yet confirmed to actually intercept a real connection. |
| **cua-driver / Computer Use** | Working | Bundled with Hermes for native macOS GUI control. |
| **Browser automation** | Working (Playwright/Chromium, built into Hermes) | See the bug writeup above — this is what actually works, not the originally-planned external CLI. |

---

## Still open

- **LuLu** — installed and running, never confirmed it actually intercepts
  a real outbound connection.
- **Dashboard dev server isn't persistent** — manual-start only, no
  LaunchAgent yet.
- A Kali Linux VM under UTM is on hold: it hangs very early in boot
  (`PCI: OF: of_root node is NULL, cannot create PCI host bridge node`)
  regardless of CPU model, GPU device, UTM's guest-type preset, or Kali
  release — four independent variables changed with no effect, pointing at
  a QEMU/HVF compatibility issue with very new Apple Silicon rather than
  any of those settings specifically.

---

## Quick reference

```
Model serving:       Ollama, http://localhost:11434
Hermes data:          ~/LocalLLM/hermes
Hermes CLI:            hermes chat  /  hermes -z "..."
SearXNG:              http://127.0.0.1:8899
Dashboard (manual):    http://localhost:5175
Desktop widget:        click = wake, right-click = sleep/quit

Persistent services (LaunchAgents, auto-start at login):
  com.ollama.ollama       — Ollama daemon (stopped by widget sleep, restarted by widget wake)
  com.searxng.local       — SearXNG
  local.llm.facewidget    — the floating widget
  local.llm.hermes-env    — sets HERMES_HOME for GUI apps
```
