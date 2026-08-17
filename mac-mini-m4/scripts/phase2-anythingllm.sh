#!/bin/bash
set -e

echo "========================================="
echo "Phase 2 — AnythingLLM"
echo "========================================="

# Install AnythingLLM
if [ -d "/Applications/AnythingLLM.app" ]; then
  echo "[OK] AnythingLLM already installed"
else
  echo "[INSTALL] Installing AnythingLLM via Homebrew..."
  brew install --cask anythingllm
fi

echo ""
echo "========================================="
echo "Phase 2 COMPLETE"
echo "========================================="
echo ""
echo "Manual steps required:"
echo "  1. Open AnythingLLM from Applications"
echo "  2. Go to Settings and configure:"
echo "     - LLM Provider: Ollama"
echo "     - Ollama Base URL: http://localhost:11434"
echo "     - Model: glm4:9b"
echo "     - Embedding Model: nomic-embed-text"
echo "  3. Create workspaces:"
echo "     - Files — drag in folders to reference"
echo "     - Research — for web content and PDFs"
echo "     - Code — point at project directories"
echo ""
echo "AnythingLLM will be available at http://localhost:3001"
echo "========================================="
