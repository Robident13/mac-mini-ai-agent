# Mac Mini M4 (24GB) — AI Agent Setup

Automated setup for a hybrid local/cloud AI agent stack on Apple Silicon.

## What This Installs

| Phase | Tool | Purpose | Cost |
|---|---|---|---|
| 1 | Ollama + GLM-4 9B | Local LLM runtime + primary model | Free |
| 1 | qwen2.5-coder:7b | Local coding model | Free |
| 1 | Qwen3.5-27B IQ4_XS | Heavy reasoning model (bartowski, 15.17GB) | Free |
| 1 | nomic-embed-text | Embedding model for RAG | Free |
| 2 | AnythingLLM | Local document chat / RAG | Free |
| 3 | Aider | Terminal coding agent (Ollama) | Free |
| 3 | Claude Code | Terminal coding agent (Haiku API) | ~$5-10/mo |
| 4 | Open WebUI | ChatGPT-style chat UI (Ollama) | Free |
| 5 | n8n | Automation / WhatsApp | Free |
| 6 | MCP Servers | File, GitHub, DB access for Claude | Free |
| 6 | SearXNG | Private web search | Free |
| 7 | Promptfoo | Prompt testing and evaluation | Free |
| 8 | python-docx, pypdf, etc. | Word & PDF document processing + OCR | Free |
| 9 | Local AI UI | React chat interface with animated robot face | Free |
| 10 | Docker Agent | Multi-agent orchestration via YAML | Free |
| 11 | yt-dlp, gallery-dl, OF-Scraper | Secure media downloaders (Keychain creds) | Free |

## Quick Start

```bash
git clone https://github.com/Robident13/mac-mini-ai-agent.git
cd mac-mini-ai-agent
chmod +x setup.sh scripts/*.sh
./setup.sh
```

## Prerequisites

- macOS on Apple Silicon (M1/M2/M4)
- [Homebrew](https://brew.sh) installed
- [Docker Desktop](https://docs.docker.com/desktop/mac/) for Phases 4–6, 10
- [Anthropic API key](https://console.anthropic.com) for Claude Code (Phase 3, optional)

## Install Options

The setup script offers four modes:

1. **Full install** — all 11 phases
2. **Pick and choose** — select individual phases
3. **Phases 1-3 only** — no Docker required
4. **Phases 1-3 + 7-8** — no Docker, includes Promptfoo and document tools

## Models

| Model | Size | Role |
|---|---|---|
| GLM-4 9B | ~6GB | Primary — fast, good tool calling |
| qwen2.5-coder:7b | ~5GB | Coding tasks via Aider |
| Qwen3.5-27B IQ4_XS | ~15GB | Deep reasoning (don't run alongside other large models) |
| nomic-embed-text | ~275MB | Embeddings for RAG |

> Note: Don't run Qwen3.5-27B and GLM-4 9B simultaneously — 24GB isn't enough for both. Use `ollama stop` to unload one before loading the other.

## Commands After Install

```bash
source ~/.zshrc

ai-code          # Aider + Ollama GLM-4 (free, fast)
ai-coder         # Aider + qwen2.5-coder (free, coding)
ai-claude        # Claude Code + Haiku API (paid)
ai-aider-claude  # Aider + Haiku API (paid)

# Deep reasoning with Qwen3.5-27B
aider --model ollama_chat/qwen35-27b

# Prompt testing (free)
promptfoo eval --provider ollama:glm4:9b

# Docker Agent (multi-agent)
docker agent run --config ~/.docker-agents/assistant.yaml
docker agent run --config ~/.docker-agents/coordinator.yaml

# Download tools (Phase 11)
ytdl URL              # download video
ytdl-audio URL        # download audio only (mp3)
gdl URL               # download gallery (Keychain creds)
ofscrape              # run OF-Scraper (Keychain creds)
```

## Ports

| Service | Port | URL |
|---|---|---|
| Ollama | 11434 | http://localhost:11434 |
| Open WebUI | 3000 | http://localhost:3000 |
| AnythingLLM | 3001 | http://localhost:3001 |
| Local AI UI | 5173 | http://localhost:5173 |
| n8n | 5678 | http://localhost:5678 |
| SearXNG | 8080 | http://localhost:8080 |

## Cost

| Tier | Monthly |
|---|---|
| Free baseline (all tools except Claude API) | $0 |
| With Claude Haiku API | ~$5-10 |
| Electricity (Mac Mini 24/7) | ~$3-5 |

## Security

- API keys stored in macOS Keychain (not plain text)
- All ports local-only by default
- Use [Tailscale](https://tailscale.com) for secure remote access
- Enable FileVault disk encryption
- Never install unverified MCP servers
