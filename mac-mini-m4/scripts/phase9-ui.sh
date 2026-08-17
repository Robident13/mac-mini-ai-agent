#!/bin/bash
set -e

echo "========================================="
echo "Phase 9 — Local AI UI"
echo "========================================="

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UI_DIR="$SCRIPT_DIR/ui"

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "[INSTALL] Installing Node.js via Homebrew..."
  brew install node
fi

echo "[OK] Node.js: $(node --version)"

# Install dependencies
if [ -d "$UI_DIR/node_modules" ]; then
  echo "[OK] Dependencies already installed"
else
  echo "[INSTALL] Installing UI dependencies..."
  cd "$UI_DIR" && npm install
fi

# Build for production
echo "[BUILD] Building production bundle..."
cd "$UI_DIR" && npm run build

echo ""
echo "========================================="
echo "Phase 9 COMPLETE"
echo "========================================="
echo ""
echo "To run the UI:"
echo "  cd $UI_DIR && npm run dev"
echo ""
echo "Then open: http://localhost:5173"
echo ""
echo "Make sure Ollama is running at http://localhost:11434"
echo "========================================="
