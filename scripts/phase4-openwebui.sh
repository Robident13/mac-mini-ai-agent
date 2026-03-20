#!/bin/bash
set -e

echo "========================================="
echo "Phase 4 — Open WebUI"
echo "========================================="

# Check Docker
if ! command -v docker &>/dev/null; then
  echo "[ERROR] Docker not found."
  echo "Install Docker Desktop from: https://docs.docker.com/desktop/mac/"
  echo "Then re-run this script."
  exit 1
fi

if ! docker info &>/dev/null 2>&1; then
  echo "[ERROR] Docker is installed but not running."
  echo "Start Docker Desktop and re-run this script."
  exit 1
fi

# Run Open WebUI
if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
  echo "[OK] Open WebUI container already exists"
  if docker ps --format '{{.Names}}' | grep -q '^open-webui$'; then
    echo "[OK] Open WebUI is running"
  else
    echo "[START] Starting Open WebUI..."
    docker start open-webui
  fi
else
  echo "[INSTALL] Creating Open WebUI container..."
  docker run -d \
    --name open-webui \
    --restart unless-stopped \
    -p 3000:8080 \
    -v open-webui:/app/backend/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    ghcr.io/open-webui/open-webui:main
fi

# Wait for Open WebUI to start
echo "[WAIT] Waiting for Open WebUI to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:3000 &>/dev/null; then
    echo "[OK] Open WebUI is ready"
    break
  fi
  sleep 2
done

echo ""
echo "========================================="
echo "Phase 4 COMPLETE"
echo "========================================="
echo ""
echo "Open WebUI available at: http://localhost:3000"
echo ""
echo "First-time setup:"
echo "  1. Open http://localhost:3000 in your browser"
echo "  2. Create a local admin account (this stays on your machine)"
echo "  3. Your Ollama models will appear automatically"
echo "========================================="
