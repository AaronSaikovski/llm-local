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


cat > /tmp/agent1file << 'EOF'
FROM qwen3:14b
PARAMETER num_ctx 16384
SYSTEM "You are Agent 1."
EOF

cat > /tmp/agent2file << 'EOF'
FROM qwen3:14b
PARAMETER num_ctx 16384
SYSTEM "You are Agent 2."
EOF

cat > /tmp/agent3file << 'EOF'
FROM qwen3:14b
PARAMETER num_ctx 16384
SYSTEM "You are Agent 3."
EOF

cat > /tmp/agent4file << 'EOF'
FROM qwen3:14b
PARAMETER num_ctx 16384
SYSTEM "You are Agent 4."
EOF

ollama create agent1 -f /tmp/agent1file
ollama create agent2 -f /tmp/agent2file
ollama create agent3 -f /tmp/agent3file
ollama create agent4 -f /tmp/agent4file