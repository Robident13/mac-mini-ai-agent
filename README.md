# mac-ai-agent

Local-first AI agent setups for Apple Silicon Macs. Each machine gets its
own folder — the tools, models, and constraints differ enough (RAM ceiling,
chip generation, what's already installed) that a single shared script
stopped making sense.

## Setups

- **[`mac-mini-m4/`](mac-mini-m4/)** — Mac Mini M4, 24GB. Phased
  install script (Ollama, Aider, Claude Code, n8n, AnythingLLM, MCP
  servers, and more) plus a standalone React chat UI with an animated
  robot face.
- **[`macbook-pro-m5/`](macbook-pro-m5/)** — MacBook Pro M5, 32GB. Ollama +
  [Hermes Agent](https://github.com/NousResearch/hermes-agent) as
  orchestrator, SearXNG for private search, a live-data browser dashboard,
  and a native floating desktop widget — both built around the same
  animated status face, one as a React component and one as a native Swift
  app.

Start with whichever folder matches your hardware.
