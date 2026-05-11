#!/bin/bash
# ============================================================
# model-alias.sh — Pull base model and create agent models
#
# Usage:
#   bash model-alias.sh
# ============================================================

ollama pull qwen3:14b

# Create the Modelfile
cat > /tmp/agentfile << 'EOF'
FROM qwen3:14b
PARAMETER num_ctx 16384
EOF

# Create the 4 agents from it
for i in 1 2 3 4; do
  ollama create agent$i -f /tmp/agentfile
done

# Clean up
rm /tmp/agentfile

# verify
ollama list | grep agent
