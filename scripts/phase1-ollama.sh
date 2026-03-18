#!/bin/bash
set -e

echo "========================================="
echo "Phase 1 — Ollama + Local Models"
echo "========================================="

# Install Ollama
if command -v ollama &>/dev/null; then
  echo "[OK] Ollama already installed: $(ollama --version)"
else
  echo "[INSTALL] Installing Ollama via Homebrew..."
  brew install ollama
fi

# Start Ollama if not running
if ! pgrep -f "ollama serve" &>/dev/null; then
  echo "[START] Starting Ollama server..."
  ollama serve &>/dev/null &
  sleep 3
fi

# Pull models
echo "[PULL] Pulling GLM-4 9B (primary model)..."
ollama pull glm4:9b

echo "[PULL] Pulling qwen2.5-coder:7b (coding model)..."
ollama pull qwen2.5-coder:7b

echo "[PULL] Pulling nomic-embed-text (embedding model)..."
ollama pull nomic-embed-text

# Set up auto-start on boot
OLLAMA_BIN=$(which ollama)
echo "[CONFIG] Ollama binary at: $OLLAMA_BIN"

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.ollama.server.plist"

mkdir -p "$PLIST_DIR"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.ollama.server</string>
  <key>ProgramArguments</key>
  <array>
    <string>${OLLAMA_BIN}</string>
    <string>serve</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF

launchctl load "$PLIST_FILE" 2>/dev/null || true
echo "[OK] Ollama set to auto-start on boot"

# Verify
echo ""
echo "[TEST] Testing local model..."
RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{"model":"glm4:9b","prompt":"Say hello in one sentence.","stream":false}' | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','ERROR'))" 2>/dev/null)
echo "Model response: $RESPONSE"

echo ""
echo "Installed models:"
ollama list

echo ""
echo "========================================="
echo "Phase 1 COMPLETE"
echo "Ollama running at http://localhost:11434"
echo "========================================="
