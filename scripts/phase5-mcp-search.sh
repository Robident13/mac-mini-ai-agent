#!/bin/bash
set -e

echo "========================================="
echo "Phase 5 — MCP Servers + SearXNG"
echo "========================================="

# --- Node.js (required for MCP servers) ---
if command -v node &>/dev/null; then
  echo "[OK] Node.js installed: $(node --version)"
else
  echo "[INSTALL] Installing Node.js via Homebrew..."
  brew install node
fi

# --- MCP Config for Claude Code ---
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_SOURCE="$(cd "$(dirname "$0")/../configs" && pwd)/claude-settings.json"

mkdir -p "$CLAUDE_DIR"

if [ -f "$SETTINGS_FILE" ]; then
  echo "[OK] Claude settings already exist at $SETTINGS_FILE"
  echo "     Review and merge MCP config manually from: $CONFIG_SOURCE"
else
  # Replace placeholder with actual username
  sed "s|YOUR_USERNAME|$USER|g" "$CONFIG_SOURCE" > "$SETTINGS_FILE"
  echo "[OK] Claude Code MCP config written to $SETTINGS_FILE"
  echo "     Edit to add your GitHub token and database path."
fi

# --- SearXNG ---
if ! command -v docker &>/dev/null; then
  echo "[SKIP] Docker not installed — skipping SearXNG"
else
  if ! docker info &>/dev/null 2>&1; then
    echo "[SKIP] Docker not running — skipping SearXNG"
  elif docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
    echo "[OK] SearXNG container already exists"
    if docker ps --format '{{.Names}}' | grep -q '^searxng$'; then
      echo "[OK] SearXNG is running"
    else
      echo "[START] Starting SearXNG..."
      docker start searxng
    fi
  else
    echo "[INSTALL] Creating SearXNG container..."
    docker run -d \
      --name searxng \
      --restart unless-stopped \
      -p 8080:8080 \
      searxng/searxng
  fi
fi

# --- Verify MCP servers ---
echo ""
echo "[TEST] Testing MCP filesystem server..."
if npx -y @modelcontextprotocol/server-filesystem --help &>/dev/null 2>&1; then
  echo "[OK] MCP filesystem server works"
else
  echo "[WARN] MCP filesystem server test failed — check Node.js installation"
fi

echo ""
echo "========================================="
echo "Phase 5 COMPLETE"
echo "========================================="
echo ""
echo "Services:"
echo "  SearXNG:    http://localhost:8080"
echo "  MCP config: $SETTINGS_FILE"
echo ""
echo "Remaining manual steps:"
echo "  1. Add your GitHub token to $SETTINGS_FILE"
echo "  2. Update the SQLite database path if needed"
echo "  3. Verify with: claude mcp list"
echo "========================================="
