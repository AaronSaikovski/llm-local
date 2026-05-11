#!/bin/bash
# ============================================================
# llm-stop.sh — Stop Ollama and unload all models
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🛑 LLM Stack Shutdown            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Unload models from memory ────────────────────────────────
echo -e "${YELLOW}▶ Unloading models from memory...${NC}"

LOADED=$(ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}')
if [ -n "$LOADED" ]; then
  echo "$LOADED" | while read -r model; do
    echo "  Unloading $model..."
    ollama stop "$model" 2>/dev/null && echo -e "  ${GREEN}✓ $model unloaded${NC}"
  done
else
  echo -e "  ${YELLOW}No models currently loaded${NC}"
fi

# ── Stop Ollama ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Stopping Ollama...${NC}"

if pgrep -x "ollama" > /dev/null; then
  pkill -x "ollama" 2>/dev/null
  sleep 1
  if pgrep -x "ollama" > /dev/null; then
    pkill -9 -x "ollama" 2>/dev/null
  fi
  echo -e "${GREEN}✓ Ollama stopped${NC}"
else
  echo -e "${YELLOW}  Ollama was not running${NC}"
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ✅ LLM Stack Stopped             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
