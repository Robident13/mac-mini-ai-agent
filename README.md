# Mac Mini M4 (24GB) — AI Agent Setup

Automated setup for a hybrid local/cloud AI agent stack on Apple Silicon.

## What This Installs

| Phase | Tool | Purpose | Cost |
|---|---|---|---|
| 1 | Ollama + GLM-4 9B | Local LLM runtime + primary model | Free |
| 1 | qwen2.5-coder:7b | Local coding model | Free |
| 1 | nomic-embed-text | Embedding model for RAG | Free |
| 2 | AnythingLLM | Local document chat / RAG | Free |
| 3 | Aider | Terminal coding agent (Ollama) | Free |
| 3 | Claude Code | Terminal coding agent (Haiku API) | ~$5-10/mo |
| 4 | n8n | Automation / WhatsApp | Free |
| 5 | MCP Servers | File, GitHub, DB access for Claude | Free |
| 5 | SearXNG | Private web search | Free |

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/mac-mini-ai-agent.git
cd mac-mini-ai-agent
chmod +x setup.sh scripts/*.sh
./setup.sh
```

## Prerequisites

- macOS on Apple Silicon (M1/M2/M4)
- [Homebrew](https://brew.sh) installed
- [Docker Desktop](https://docs.docker.com/desktop/mac/) for Phases 4-5
- [Anthropic API key](https://console.anthropic.com) for Claude Code (Phase 3, optional)

## Install Options

The setup script offers three modes:

1. **Full install** — all 5 phases
2. **Pick and choose** — select individual phases
3. **Phases 1-3 only** — no Docker required

## Commands After Install

```bash
source ~/.zshrc

ai-code          # Aider + Ollama GLM-4 (free)
ai-coder         # Aider + qwen2.5-coder (free)
ai-claude        # Claude Code + Haiku API (paid)
ai-aider-claude  # Aider + Haiku API (paid)
```

## Ports

| Service | Port | URL |
|---|---|---|
| Ollama | 11434 | http://localhost:11434 |
| AnythingLLM | 3001 | http://localhost:3001 |
| n8n | 5678 | http://localhost:5678 |
| SearXNG | 8080 | http://localhost:8080 |

## Cost

| Tier | Monthly |
|---|---|
| Free baseline | $0 |
| With Claude Haiku | ~$5-10 |
| Electricity (24/7) | ~$3-5 |

## Security

- API keys stored in macOS Keychain (not plain text)
- All ports local-only by default
- Use [Tailscale](https://tailscale.com) for secure remote access
- Enable FileVault disk encryption
