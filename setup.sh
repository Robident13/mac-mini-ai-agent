#!/bin/bash
set -e

echo ""
echo "  Mac Mini M4 (24GB) — AI Agent Setup"
echo "  ====================================="
echo ""
echo "  This will install and configure:"
echo "    Phase 1: Ollama + local models (GLM-4 9B, qwen2.5-coder, embeddings)"
echo "    Phase 2: AnythingLLM (local RAG / document chat)"
echo "    Phase 3: Aider + Claude Code + shell aliases"
echo "    Phase 4: Docker + n8n (automation / WhatsApp)"
echo "    Phase 5: MCP servers + SearXNG (private search)"
echo ""
echo "  Prerequisites:"
echo "    - macOS on Apple Silicon (M1/M2/M4)"
echo "    - Homebrew installed (https://brew.sh)"
echo "    - Docker Desktop installed for Phases 4-5 (https://docs.docker.com/desktop/mac/)"
echo ""

# Check prerequisites
if [[ "$(uname)" != "Darwin" ]]; then
  echo "[ERROR] This script is for macOS only."
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "[ERROR] Homebrew not found. Install from https://brew.sh"
  exit 1
fi

echo "[OK] macOS detected: $(sw_vers -productVersion)"
echo "[OK] Architecture: $(uname -m)"
echo "[OK] Homebrew: $(brew --version | head -1)"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

# --- Menu ---
run_phase() {
  local phase=$1
  local script="$SCRIPT_DIR/phase${phase}-*.sh"

  # Expand glob
  local script_path
  script_path=$(ls $script 2>/dev/null | head -1)

  if [ -z "$script_path" ]; then
    echo "[ERROR] Script not found for phase $phase"
    return 1
  fi

  chmod +x "$script_path"
  bash "$script_path"
}

echo "How would you like to install?"
echo ""
echo "  1) Full install (all 5 phases)"
echo "  2) Phase by phase (choose which to run)"
echo "  3) Phases 1-3 only (no Docker required)"
echo ""
read -rp "Choice [1/2/3]: " CHOICE

case "$CHOICE" in
  1)
    echo ""
    echo "Running full install..."
    echo ""
    for phase in 1 2 3 4 5; do
      run_phase $phase
      echo ""
    done
    ;;
  2)
    echo ""
    echo "Select phases to run:"
    echo "  1 — Ollama + Models"
    echo "  2 — AnythingLLM"
    echo "  3 — Aider + Claude Code"
    echo "  4 — Docker + n8n"
    echo "  5 — MCP + SearXNG"
    echo ""
    read -rp "Enter phase numbers (e.g. 1 3 5): " PHASES
    for phase in $PHASES; do
      run_phase "$phase"
      echo ""
    done
    ;;
  3)
    echo ""
    echo "Running Phases 1-3 (no Docker required)..."
    echo ""
    for phase in 1 2 3; do
      run_phase $phase
      echo ""
    done
    ;;
  *)
    echo "[ERROR] Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "========================================="
echo "  SETUP COMPLETE"
echo "========================================="
echo ""
echo "  Services:"
echo "    Ollama:       http://localhost:11434"
echo "    AnythingLLM:  http://localhost:3001"
echo "    n8n:          http://localhost:5678   (if Phase 4 ran)"
echo "    SearXNG:      http://localhost:8080   (if Phase 5 ran)"
echo ""
echo "  Commands (run 'source ~/.zshrc' first):"
echo "    ai-code   — Aider + Ollama (free)"
echo "    ai-coder  — Aider + qwen2.5-coder (free)"
echo "    ai-claude — Claude Code + Haiku (paid)"
echo ""
echo "  Security reminders:"
echo "    - Enable FileVault: System Settings > Privacy & Security"
echo "    - Keep ports local only — don't expose to the internet"
echo "    - Use Tailscale for remote access: https://tailscale.com"
echo ""
echo "========================================="
