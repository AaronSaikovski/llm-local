#!/bin/bash
# ============================================================
# llm-start.sh — Start Ollama + Claude Code (Ollama native API)
#
# Usage:
#   llm-start.sh                           # main model (blue)
#   llm-start.sh -m gemma4:31b             # custom model
#   llm-start.sh -w feature-auth           # main model + named worktree
#   llm-start.sh -w                        # main model + auto worktree
#   llm-start.sh -a 1                      # agent1 green, auto worktree
#   llm-start.sh -a 2 -w feature-billing   # agent2 orange + named worktree
#   llm-start.sh -a 3 -w feature-tests     # agent3 yellow + named worktree
#   llm-start.sh -a 4 -w feature-docs      # agent4 red + named worktree
#   llm-start.sh --help
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="$HOME/.ollama/logs"
OLLAMA_LOG="$LOG_DIR/ollama.log"
DEFAULT_MODEL="qwen3.6:35b-a3b-coding-nvfp4"
MODEL="$DEFAULT_MODEL"
WORKTREE=""
USE_WORKTREE=false
AGENT_NUM=""

# ── Agent colours + emojis ────────────────────────────────────
AGENT_COLOURS=("" "green" "orange" "yellow" "red")
AGENT_EMOJIS=("" "🟢" "🟠" "🟡" "🔴")
MAIN_COLOUR="blue"
MAIN_EMOJI="🔵"

mkdir -p "$LOG_DIR"

# ── Help ─────────────────────────────────────────────────────
usage() {
  echo ""
  echo -e "${CYAN}Usage:${NC}"
  echo "  llm-start.sh [options]"
  echo ""
  echo -e "${CYAN}Options:${NC}"
  echo "  -m, --model <model>       Ollama model to use (default: $DEFAULT_MODEL)"
  echo "  -a, --agent <1-4>         Use agentN model (auto-enables worktree)"
  echo "  -w, --worktree [name]     Create a git worktree (optional name)"
  echo "  -h, --help                Show this help"
  echo ""
  echo -e "${CYAN}Agent colours:${NC}"
  echo "  Main  🔵 blue    — main model"
  echo "  -a 1  🟢 green   — agent1"
  echo "  -a 2  🟠 orange  — agent2"
  echo "  -a 3  🟡 yellow  — agent3"
  echo "  -a 4  🔴 red     — agent4"
  echo ""
  echo -e "${CYAN}Examples:${NC}"
  echo "  llm-start.sh                          # main model"
  echo "  llm-start.sh -w feature-auth          # main model + worktree"
  echo "  llm-start.sh -a 1                     # agent1 green, auto worktree"
  echo "  llm-start.sh -a 2 -w feature-billing  # agent2 orange + named worktree"
  echo "  llm-start.sh -a 3 -w feature-tests    # agent3 yellow + named worktree"
  echo "  llm-start.sh -a 4 -w feature-docs     # agent4 red + named worktree"
  echo ""
  exit 0
}

# ── Parse args ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      MODEL="$2"
      shift 2
      ;;
    -a|--agent)
      AGENT_NUM="$2"
      if ! [[ "$AGENT_NUM" =~ ^[1-4]$ ]]; then
        echo -e "${RED}✗ Agent number must be 1-4 (got: $AGENT_NUM)${NC}"
        exit 1
      fi
      MODEL="agent${AGENT_NUM}"
      USE_WORKTREE=true
      shift 2
      ;;
    -w|--worktree)
      USE_WORKTREE=true
      if [[ -n "${2:-}" && "${2:-}" != -* ]]; then
        WORKTREE="$2"
        shift 2
      else
        shift 1
      fi
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      ;;
  esac
done

# ── Resolve colour + session name ────────────────────────────
if [ -n "$AGENT_NUM" ]; then
  SESSION_COLOUR="${AGENT_COLOURS[$AGENT_NUM]}"
  SESSION_EMOJI="${AGENT_EMOJIS[$AGENT_NUM]}"
  SESSION_NAME="agent${AGENT_NUM}${WORKTREE:+-$WORKTREE}"
else
  SESSION_COLOUR="$MAIN_COLOUR"
  SESSION_EMOJI="$MAIN_EMOJI"
  SESSION_NAME="main${WORKTREE:+-$WORKTREE}"
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🦙 LLM Stack Startup             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Ollama ──────────────────────────────────────────────────
echo -e "${YELLOW}▶ Starting Ollama...${NC}"

if pgrep -x "ollama" > /dev/null; then
  echo -e "${GREEN}✓ Ollama already running${NC}"
else
  ollama serve >> "$OLLAMA_LOG" 2>&1 &

  echo -n "  Waiting for Ollama to be ready"
  for i in {1..15}; do
    if curl -s http://localhost:11434 > /dev/null 2>&1; then
      echo ""
      echo -e "${GREEN}✓ Ollama started${NC}"
      break
    fi
    echo -n "."
    sleep 1
  done

  if ! curl -s http://localhost:11434 > /dev/null 2>&1; then
    echo ""
    echo -e "${RED}✗ Ollama failed to start. Check $OLLAMA_LOG${NC}"
    exit 1
  fi
fi

# ── Check model is pulled ────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Checking model: $MODEL${NC}"

if ollama list 2>/dev/null | grep -q "${MODEL}"; then
  echo -e "${GREEN}✓ $MODEL ready${NC}"
else
  if [ -n "$AGENT_NUM" ]; then
    echo -e "${RED}✗ $MODEL not found — create it first:${NC}"
    echo "  cat > /tmp/agentfile << 'EOF'"
    echo "  FROM qwen3:14b"
    echo "  PARAMETER num_ctx 16384"
    echo "  EOF"
    echo "  ollama create agent${AGENT_NUM} -f /tmp/agentfile"
    exit 1
  fi
  echo -e "${YELLOW}  Model not found locally — pulling now...${NC}"
  ollama pull "$MODEL"
  echo -e "${GREEN}✓ $MODEL pulled${NC}"
fi

# ── Show loaded models ───────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Currently loaded models:${NC}"
LOADED=$(ollama ps 2>/dev/null | tail -n +2)
if [ -n "$LOADED" ]; then
  echo "$LOADED" | while read -r line; do
    echo "  $line"
  done
else
  echo -e "  ${CYAN}(none — will lazy-load on first request)${NC}"
fi

# ── Worktree setup ───────────────────────────────────────────
WORKTREE_FLAG=""
if [ "$USE_WORKTREE" = true ]; then
  echo ""
  echo -e "${YELLOW}▶ Worktree mode${NC}"

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Not a git repository — worktree flag ignored${NC}"
    USE_WORKTREE=false
  else
    if [ -n "$WORKTREE" ]; then
      WORKTREE_FLAG="--worktree $WORKTREE"
      echo -e "${GREEN}✓ Worktree: $WORKTREE${NC}"
    else
      WORKTREE_FLAG="--worktree"
      echo -e "${GREEN}✓ Worktree: auto-named${NC}"
    fi
  fi
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ✅ LLM Stack Ready               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  Ollama:   ${GREEN}http://localhost:11434${NC}"
if [ -n "$AGENT_NUM" ]; then
  echo -e "  Mode:     ${SESSION_EMOJI} Agent $AGENT_NUM ($SESSION_COLOUR)"
else
  echo -e "  Mode:     ${SESSION_EMOJI} Main ($SESSION_COLOUR)"
fi
echo -e "  Model:    ${GREEN}$MODEL${NC}"
echo -e "  Session:  ${GREEN}$SESSION_NAME${NC}"
if [ "$USE_WORKTREE" = true ]; then
  echo -e "  Worktree: ${GREEN}${WORKTREE:-auto}${NC}"
fi
echo -e "  Logs:     ${GREEN}$LOG_DIR${NC}"
echo ""
echo -e "${YELLOW}▶ Launching Claude Code...${NC}"
echo ""

# ── Set Ollama env vars (replicates what ollama launch claude does) ──
export ANTHROPIC_BASE_URL="http://localhost:11434"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY=""

# ── Launch Claude Code with colour + session name ─────────────
# /color and /rename are slash commands passed as startup args
# shellcheck disable=SC2086
claude --model "$MODEL" \
  $WORKTREE_FLAG \
  "/color $SESSION_COLOUR" \
  "/rename $SESSION_NAME"
