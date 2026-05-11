#!/bin/bash
# ============================================================
# llm-status.sh — Show Ollama status, loaded models, available models
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     📊 LLM Stack Status              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Ollama ──────────────────────────────────────────────────
echo -e "${YELLOW}Ollama${NC}"
if pgrep -x "ollama" > /dev/null; then
  echo -e "  Status:   ${GREEN}● running${NC}"
  echo -e "  Endpoint: http://localhost:11434"
else
  echo -e "  Status:   ${RED}○ stopped${NC}"
fi

# ── Loaded models ────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Loaded Models${NC}"
LOADED=$(ollama ps 2>/dev/null | tail -n +2)
if [ -n "$LOADED" ]; then
  # Print header
  echo -e "  $(ollama ps 2>/dev/null | head -1)"
  echo "$LOADED" | while read -r line; do
    echo -e "  ${GREEN}●${NC} $line"
  done
else
  echo -e "  ${YELLOW}(none loaded)${NC}"
fi

# ── Available models ─────────────────────────────────────────
echo ""
echo -e "${YELLOW}Available Models${NC}"
ollama list 2>/dev/null | tail -n +2 | while read -r line; do
  echo "  $line"
done

# ── Claude Code setup ────────────────────────────────────────
echo ""
echo -e "${YELLOW}Claude Code${NC}"
echo -e "  Run:  ${CYAN}ollama launch claude --model qwen3-coder:30b${NC}"
echo -e "  Or:   ${CYAN}llm-start.sh [model]${NC}"
echo ""
