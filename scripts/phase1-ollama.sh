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

# --- Qwen3.5-27B (heavy reasoning model) ---
echo ""
echo "[PULL] Qwen3.5-27B IQ4_XS — heavy reasoning model (15.17GB)"
echo "       Source: bartowski/Qwen_Qwen3.5-27B-GGUF on HuggingFace"
echo "       This is a large download. Skip if bandwidth is limited."
echo ""
read -rp "Install Qwen3.5-27B? [y/n]: " INSTALL_QWEN

if [[ "$INSTALL_QWEN" =~ ^[Yy]$ ]]; then
  GGUF_DIR="$HOME/.ollama-gguf"
  GGUF_FILE="$GGUF_DIR/Qwen_Qwen3.5-27B-IQ4_XS.gguf"
  MODELFILE="$GGUF_DIR/Modelfile.qwen35"
  mkdir -p "$GGUF_DIR"

  if [ -f "$GGUF_FILE" ]; then
    echo "[OK] GGUF file already downloaded"
  else
    echo "[DOWNLOAD] Downloading from HuggingFace (~15.17GB)..."
    if command -v huggingface-cli &>/dev/null; then
      huggingface-cli download bartowski/Qwen_Qwen3.5-27B-GGUF \
        --include "Qwen_Qwen3.5-27B-IQ4_XS.gguf" \
        --local-dir "$GGUF_DIR"
      mv "$GGUF_DIR/Qwen_Qwen3.5-27B-IQ4_XS.gguf" "$GGUF_FILE" 2>/dev/null || true
    else
      echo "[INFO] huggingface-cli not found, using curl..."
      curl -L --progress-bar -o "$GGUF_FILE" \
        "https://huggingface.co/bartowski/Qwen_Qwen3.5-27B-GGUF/resolve/main/Qwen_Qwen3.5-27B-IQ4_XS.gguf"
    fi
  fi

  if [ -f "$GGUF_FILE" ]; then
    echo "[CREATE] Importing into Ollama as 'qwen35-27b'..."
    cat > "$MODELFILE" << 'MEOF'
FROM ./Qwen_Qwen3.5-27B-IQ4_XS.gguf

TEMPLATE """{{- if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{- range .Messages }}{{- if eq .Role "user" }}<|im_start|>user
{{ .Content }}<|im_end|>
{{ else if eq .Role "assistant" }}<|im_start|>assistant
{{ .Content }}<|im_end|>
{{ end }}{{- end }}<|im_start|>assistant
"""

PARAMETER stop "<|im_end|>"
PARAMETER stop "<|im_start|>"
PARAMETER num_ctx 8192
MEOF

    cd "$GGUF_DIR"
    ollama create qwen35-27b -f "$MODELFILE"
    echo "[OK] Qwen3.5-27B available as: qwen35-27b"
    echo "     Use with Aider: aider --model ollama_chat/qwen35-27b"
    echo "     Use in Open WebUI: select qwen35-27b from model list"
  else
    echo "[ERROR] Download failed. Re-run this script to try again."
  fi
else
  echo "[SKIP] Qwen3.5-27B skipped. Install later with:"
  echo "  Re-run: bash scripts/phase1-ollama.sh"
fi

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
