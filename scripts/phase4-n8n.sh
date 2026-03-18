#!/bin/bash
set -e

echo "========================================="
echo "Phase 4 — Docker + n8n"
echo "========================================="

# Check Docker
if command -v docker &>/dev/null; then
  echo "[OK] Docker installed: $(docker --version)"
else
  echo "[ERROR] Docker not found."
  echo "Install Docker Desktop from: https://docs.docker.com/desktop/mac/"
  echo "Then re-run this script."
  exit 1
fi

# Check Docker is running
if ! docker info &>/dev/null 2>&1; then
  echo "[ERROR] Docker is installed but not running."
  echo "Start Docker Desktop and re-run this script."
  exit 1
fi

# Run n8n
if docker ps -a --format '{{.Names}}' | grep -q '^n8n$'; then
  echo "[OK] n8n container already exists"
  if docker ps --format '{{.Names}}' | grep -q '^n8n$'; then
    echo "[OK] n8n is running"
  else
    echo "[START] Starting n8n..."
    docker start n8n
  fi
else
  echo "[INSTALL] Creating n8n container..."
  docker run -d \
    --name n8n \
    --restart unless-stopped \
    -p 5678:5678 \
    -v ~/.n8n:/home/node/.n8n \
    n8nio/n8n
fi

# Wait for n8n to start
echo "[WAIT] Waiting for n8n to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:5678 &>/dev/null; then
    echo "[OK] n8n is ready"
    break
  fi
  sleep 2
done

echo ""
echo "========================================="
echo "Phase 4 COMPLETE"
echo "========================================="
echo ""
echo "n8n available at: http://localhost:5678"
echo ""
echo "To set up WhatsApp integration:"
echo "  1. You need a WhatsApp Business API provider or bridge (e.g. Evolution API)"
echo "  2. In n8n, create a workflow:"
echo "     - Trigger: WhatsApp message received"
echo "     - HTTP Request: POST to http://host.docker.internal:11434/api/chat"
echo "       Body: {\"model\":\"glm4:9b\",\"messages\":[{\"role\":\"user\",\"content\":\"{{ \$json.message }}\"}],\"stream\":false}"
echo "     - WhatsApp node: send response back"
echo ""
echo "Note: Use host.docker.internal (not localhost) to reach Ollama from Docker."
echo "========================================="
