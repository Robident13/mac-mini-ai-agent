#!/bin/bash
set -e

echo "========================================="
echo "Phase 3 — Aider + Claude Code + Aliases"
echo "========================================="

# --- 3A: Aider ---
if command -v aider &>/dev/null; then
  echo "[OK] Aider already installed"
else
  echo "[INSTALL] Installing Aider..."
  if command -v pip3 &>/dev/null; then
    pip3 install aider-chat
  elif command -v pip &>/dev/null; then
    pip install aider-chat
  else
    echo "[ERROR] Python pip not found. Install Python first: brew install python"
    exit 1
  fi
fi

# --- 3B: Claude Code ---
if command -v claude &>/dev/null; then
  echo "[OK] Claude Code already installed"
else
  echo "[INSTALL] Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

# --- 3C: Store API Key in Keychain ---
echo ""
echo "Checking for Anthropic API key in Keychain..."
if security find-generic-password -s "anthropic-api-key" -w &>/dev/null 2>&1; then
  echo "[OK] API key already stored in Keychain"
else
  echo ""
  echo "You need a Claude API key from https://console.anthropic.com"
  read -rp "Enter your Anthropic API key (or press Enter to skip): " API_KEY
  if [ -n "$API_KEY" ]; then
    security add-generic-password -a "$USER" -s "anthropic-api-key" -w "$API_KEY"
    echo "[OK] API key stored in macOS Keychain"
  else
    echo "[SKIP] No API key entered. You can add it later with:"
    echo "  security add-generic-password -a \"\$USER\" -s \"anthropic-api-key\" -w \"YOUR_KEY\""
  fi
fi

# --- 3D: Shell Aliases ---
ZSHRC="$HOME/.zshrc"
MARKER="# --- mac-mini-ai-agent aliases ---"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  echo "[OK] Shell aliases already configured"
else
  echo "[CONFIG] Adding shell aliases to ~/.zshrc..."
  cat >> "$ZSHRC" << 'ALIASES'

# --- mac-mini-ai-agent aliases ---

# Aider with local Ollama — free daily driver
alias ai-code='aider --model ollama/glm4:9b'

# Aider with local coding model — free
alias ai-coder='aider --model ollama/qwen2.5-coder:7b'

# Claude Code with Haiku API — paid fallback
alias ai-claude='export ANTHROPIC_API_KEY=$(security find-generic-password -s "anthropic-api-key" -w) && claude --model claude-haiku-4-5-20251001'

# Aider with Claude Haiku — paid fallback
alias ai-aider-claude='export ANTHROPIC_API_KEY=$(security find-generic-password -s "anthropic-api-key" -w) && aider --model claude-haiku-4-5-20251001'

# --- end mac-mini-ai-agent aliases ---
ALIASES

  echo "[OK] Aliases added. Run 'source ~/.zshrc' or open a new terminal."
fi

echo ""
echo "========================================="
echo "Phase 3 COMPLETE"
echo "========================================="
echo ""
echo "Commands available (after 'source ~/.zshrc'):"
echo "  ai-code   — Aider + Ollama (free)"
echo "  ai-coder  — Aider + qwen2.5-coder (free)"
echo "  ai-claude — Claude Code + Haiku API (paid)"
echo ""
echo "Mobile IDE:"
echo "  Install Mobile IDE on your iPhone"
echo "  Connect to your Mac Mini over local network"
echo "========================================="
