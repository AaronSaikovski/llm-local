#!/bin/bash
# ============================================================
# llm-status.sh — LLM Stack Status
# Usage:
#   llm-status.sh          # one-shot
#   llm-status.sh -w       # live watch mode (refreshes every 3s)
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

WATCH_MODE=false
INTERVAL=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--watch) WATCH_MODE=true; shift ;;
    *) shift ;;
  esac
done

render() {
  local NOW
  NOW=$(date '+%H:%M:%S')

  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     📊 LLM Stack Status   ${YELLOW}$NOW${CYAN}    ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
  echo ""

  # ── Ollama ────────────────────────────────────────────────
  echo -e "${YELLOW}Ollama${NC}"
  if pgrep -x "ollama" > /dev/null; then
    echo -e "  Status:   ${GREEN}● running${NC}"
    echo -e "  Endpoint: http://localhost:11434"
  else
    echo -e "  Status:   ${RED}○ stopped${NC}"
  fi

  # ── Loaded models ──────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}Loaded Models${NC}"
  LOADED=$(ollama ps 2>/dev/null | tail -n +2)
  if [ -n "$LOADED" ]; then
    printf "  %-25s %-14s %-8s %-12s %-10s %s\n" "NAME" "ID" "SIZE" "PROCESSOR" "CTX" "UNTIL"
    echo "$LOADED" | while IFS= read -r line; do
      name=$(echo "$line"  | awk '{print $1}')
      id=$(echo "$line"    | awk '{print $2}')
      size=$(echo "$line"  | awk '{print $3, $4}')
      proc=$(echo "$line"  | awk '{print $5, $6}')
      ctx=$(echo "$line"   | awk '{print $7}')
      until=$(echo "$line" | awk '{$1=$2=$3=$4=$5=$6=$7=""; print $0}' | xargs)
      case "$name" in
        agent1*) emoji="🟢" ;;
        agent2*) emoji="🟠" ;;
        agent3*) emoji="🟡" ;;
        agent4*) emoji="🔴" ;;
        *)       emoji="🔵" ;;
      esac
      printf "  %s %-24s %-14s %-8s %-12s %-10s %s\n" \
        "$emoji" "$name" "$id" "$size" "$proc" "$ctx" "$until"
    done
  else
    echo -e "  ${YELLOW}(none loaded)${NC}"
  fi

  # ── Active Claude Code agents ──────────────────────────────
  echo ""
  echo -e "${YELLOW}Active Claude Code Agents${NC}"
  AGENTS=$(ps aux | grep '[c]laude --model agent' 2>/dev/null)
  if [ -n "$AGENTS" ]; then
    printf "  %-10s %-10s %-8s %-30s\n" "AGENT" "PID" "CPU%" "WORKTREE"
    echo "$AGENTS" | while IFS= read -r line; do
      pid=$(echo "$line"   | awk '{print $2}')
      cpu=$(echo "$line"   | awk '{print $3}')
      model=$(echo "$line" | grep -o '\-\-model [^ ]*' | awk '{print $2}')
      wt=$(echo "$line"    | grep -o '\-\-worktree [^ ]*' | awk '{print $2}')
      case "$model" in
        agent1) emoji="🟢" ;;
        agent2) emoji="🟠" ;;
        agent3) emoji="🟡" ;;
        agent4) emoji="🔴" ;;
        *)      emoji="🔵" ;;
      esac
      # CPU indicator — claude idles at 0%, briefly spikes when processing
      cpu_int=${cpu%.*}
      if [ "${cpu_int:-0}" -gt 5 ] 2>/dev/null; then
        status="${GREEN}● generating${NC}"
      elif [ "${cpu_int:-0}" -gt 0 ] 2>/dev/null; then
        status="${CYAN}◉ waiting${NC}"
      else
        status="${YELLOW}○ idle${NC}"
      fi
      printf "  %s %-9s %-10s %-8s %-30s " "$emoji" "$model" "$pid" "${cpu}%" "$wt"
      echo -e "$status"
    done
  else
    # Check for main claude process
    MAIN=$(ps aux | grep '[c]laude --model' | grep -v agent 2>/dev/null)
    if [ -n "$MAIN" ]; then
      pid=$(echo "$MAIN" | awk '{print $2}')
      cpu=$(echo "$MAIN" | awk '{print $3}')
      model=$(echo "$MAIN" | grep -o '\-\-model [^ ]*' | awk '{print $2}')
      printf "  🔵 %-9s %-10s %-8s\n" "$model" "$pid" "${cpu}%"
    else
      echo -e "  ${YELLOW}(none running)${NC}"
    fi
  fi

  # ── Ollama request activity ────────────────────────────────
  echo ""
  echo -e "${YELLOW}Recent Activity (last 5 requests)${NC}"
  LOG="$HOME/.ollama/logs/server.log"
  if [ -f "$LOG" ]; then
    grep -i "request\|generate\|agent" "$LOG" 2>/dev/null | tail -5 | while IFS= read -r line; do
      echo "  $line"
    done
  else
    echo -e "  ${YELLOW}(no log file found)${NC}"
  fi

  # ── Memory ────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}Memory${NC}"
  # Use vm_stat to get memory pressure on macOS
  MEM=$(vm_stat 2>/dev/null | awk '
    /Pages free/        { free=$3 }
    /Pages active/      { active=$3 }
    /Pages wired/       { wired=$4 }
    /Pages occupied by compressor/ { compressed=$5 }
    END {
      page=16384
      free_gb=(free*page)/1073741824
      used_gb=((active+wired+compressed)*page)/1073741824
      printf "  Used: %.1fGB  Free: %.1fGB\n", used_gb, free_gb
    }')
  echo -e "$MEM"

  # ── Quick reference ───────────────────────────────────────
  echo ""
  echo -e "${YELLOW}Quick Launch${NC}"
  echo -e "  ${CYAN}llm-start -a 1 -w <name>${NC}  🟢 agent1"
  echo -e "  ${CYAN}llm-start -a 2 -w <name>${NC}  🟠 agent2"
  echo -e "  ${CYAN}llm-start -a 3 -w <name>${NC}  🟡 agent3"
  echo -e "  ${CYAN}llm-start -a 4 -w <name>${NC}  🔴 agent4"
  echo ""
}

if [ "$WATCH_MODE" = true ]; then
  while true; do
    clear
    render
    echo -e "  ${CYAN}Refreshing every ${INTERVAL}s — Ctrl+C to exit${NC}"
    echo ""
    sleep "$INTERVAL"
  done
else
  render
fi