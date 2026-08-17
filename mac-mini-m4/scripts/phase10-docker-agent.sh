#!/bin/bash
set -e

echo "========================================="
echo "Phase 10 — Docker Agent"
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

echo "[OK] Docker: $(docker --version)"

# Install Docker Agent CLI
echo ""
echo "[INSTALL] Installing Docker Agent..."
if docker agent version &>/dev/null 2>&1; then
  echo "[OK] Docker Agent already available"
else
  echo "[INFO] Pulling Docker Agent image..."
  docker pull docker/agent
fi

# Create example agent configs
AGENT_DIR="$HOME/.docker-agents"
mkdir -p "$AGENT_DIR"

# --- General assistant agent ---
cat > "$AGENT_DIR/assistant.yaml" << 'EOF'
name: assistant
description: General-purpose local AI assistant
model:
  provider: ollama
  model: glm4:9b
  base_url: http://host.docker.internal:11434
tools:
  - name: shell
    description: Run shell commands
  - name: filesystem
    description: Read and write files
  - name: memory
    description: Remember facts across sessions
system_prompt: |
  You are a helpful local AI assistant running on a Mac Mini M4.
  You have access to the filesystem and shell.
  Be concise and practical.
EOF

# --- Coding agent ---
cat > "$AGENT_DIR/coder.yaml" << 'EOF'
name: coder
description: Specialist coding agent
model:
  provider: ollama
  model: qwen2.5-coder:7b
  base_url: http://host.docker.internal:11434
tools:
  - name: shell
    description: Run shell commands and tests
  - name: filesystem
    description: Read, write, and edit code files
system_prompt: |
  You are a specialist coding agent. You write clean, well-tested code.
  Always explain your changes. Run tests when available.
EOF

# --- Reasoning agent (if qwen35-27b is installed) ---
cat > "$AGENT_DIR/reasoning.yaml" << 'EOF'
name: reasoning
description: Deep reasoning agent using Qwen3.5-27B
model:
  provider: ollama
  model: qwen35-27b
  base_url: http://host.docker.internal:11434
tools:
  - name: shell
    description: Run shell commands
  - name: filesystem
    description: Read and write files
  - name: memory
    description: Remember facts across sessions
system_prompt: |
  You are a deep reasoning agent. Think step by step.
  Break complex problems into smaller parts.
  Consider multiple perspectives before answering.
EOF

# --- Coordinator agent (multi-agent) ---
cat > "$AGENT_DIR/coordinator.yaml" << 'EOF'
name: coordinator
description: Routes tasks to specialist agents
model:
  provider: ollama
  model: glm4:9b
  base_url: http://host.docker.internal:11434
agents:
  - name: coder
    config: coder.yaml
    description: Handles coding tasks
  - name: reasoning
    config: reasoning.yaml
    description: Handles complex reasoning
  - name: assistant
    config: assistant.yaml
    description: Handles general questions
system_prompt: |
  You are a coordinator agent. Route tasks to the right specialist:
  - Coding tasks → coder
  - Complex reasoning → reasoning
  - General questions → assistant
  Choose the best agent for each task.
EOF

echo "[OK] Agent configs created in $AGENT_DIR"

echo ""
echo "========================================="
echo "Phase 10 COMPLETE"
echo "========================================="
echo ""
echo "Agent configs: $AGENT_DIR"
echo ""
echo "Usage:"
echo "  # Run the general assistant"
echo "  docker agent run --config $AGENT_DIR/assistant.yaml"
echo ""
echo "  # Run the coding agent"
echo "  docker agent run --config $AGENT_DIR/coder.yaml"
echo ""
echo "  # Run the deep reasoning agent (needs qwen35-27b model)"
echo "  docker agent run --config $AGENT_DIR/reasoning.yaml"
echo ""
echo "  # Run the multi-agent coordinator"
echo "  docker agent run --config $AGENT_DIR/coordinator.yaml"
echo ""
echo "All agents use local Ollama — no API keys, no cost."
echo "========================================="
