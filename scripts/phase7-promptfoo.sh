#!/bin/bash
set -e

echo "========================================="
echo "Phase 7 — Promptfoo"
echo "========================================="

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "[INSTALL] Installing Node.js via Homebrew..."
  brew install node
fi

# Install Promptfoo
if command -v promptfoo &>/dev/null; then
  echo "[OK] Promptfoo already installed"
else
  echo "[INSTALL] Installing Promptfoo..."
  npm install -g promptfoo
fi

# Create example config
PROMPTFOO_DIR="$HOME/.promptfoo-examples"
EXAMPLE_CONFIG="$PROMPTFOO_DIR/promptfooconfig.yaml"

if [ -d "$PROMPTFOO_DIR" ]; then
  echo "[OK] Example config directory already exists"
else
  mkdir -p "$PROMPTFOO_DIR"
  cat > "$EXAMPLE_CONFIG" << 'EOF'
# Promptfoo example config — run with: promptfoo eval
# Docs: https://promptfoo.dev/docs/intro

providers:
  - id: ollama:glm4:9b
    config:
      temperature: 0.7
  - id: ollama:qwen2.5-coder:7b
    config:
      temperature: 0.7

prompts:
  - "Summarise this in one paragraph: {{input}}"
  - "TL;DR: {{input}}"

tests:
  - vars:
      input: "Artificial intelligence is transforming how we build software. Large language models can now write code, review pull requests, and debug issues. Local models running on Apple Silicon make this accessible without cloud costs."
    assert:
      - type: contains
        value: "AI"
      - type: llm-rubric
        value: "Response should be concise and accurate"

  - vars:
      input: "The Mac Mini M4 with 24GB unified memory can run 7B-14B parameter models comfortably using Ollama. The unified memory architecture means the GPU and CPU share the same memory pool, eliminating the need for separate VRAM."
    assert:
      - type: contains
        value: "memory"
      - type: llm-rubric
        value: "Response should mention Apple Silicon or Mac"
EOF
  echo "[OK] Example config created at $EXAMPLE_CONFIG"
fi

# Quick test
echo ""
echo "[TEST] Checking Promptfoo version..."
promptfoo --version

echo ""
echo "========================================="
echo "Phase 7 COMPLETE"
echo "========================================="
echo ""
echo "Usage:"
echo "  # Run evals against local model (free)"
echo "  promptfoo eval --provider ollama:glm4:9b"
echo ""
echo "  # Compare two models side by side"
echo "  promptfoo eval --provider ollama:glm4:9b --provider ollama:qwen2.5-coder:7b"
echo ""
echo "  # Run the example config"
echo "  cd $PROMPTFOO_DIR && promptfoo eval"
echo ""
echo "  # Open results in browser"
echo "  promptfoo view"
echo ""
echo "  # Init a new test config in any project"
echo "  promptfoo init"
echo "========================================="
