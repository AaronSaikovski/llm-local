#!/bin/bash
# ============================================================
# install.sh — Install llm-* scripts to a bin directory
#
# Usage:
#   bash install.sh                      # install to ~/bin (or ~/Developer/bin)
#   bash install.sh /usr/local/bin       # install to custom path
#   bash install.sh --uninstall          # remove installed scripts
# ============================================================

set -e

SCRIPTS=(llm-start.sh llm-status.sh llm-stop.sh model-alias.sh)

# ── Determine mode ───────────────────────────────────────────
if [ "${1:-}" = "--uninstall" ]; then
  MODE="uninstall"
  TARGET_DIR=""
else
  MODE="install"
  TARGET_DIR="${1:-}"
fi

# ── Uninstall ────────────────────────────────────────────────
if [ "$MODE" = "uninstall" ]; then
  echo "Removing scripts from $TARGET_DIR..."
  for f in "${SCRIPTS[@]}"; do
    name="${f%.sh}"
    if [ -f "$name" ]; then
      rm "$name"
      echo "  Removed $name"
    else
      echo "  Not found: $name"
    fi
  done
  echo "Done."
  exit 0
fi

# ── Resolve target directory ─────────────────────────────────
if [ -z "$TARGET_DIR" ]; then
  # Auto-detect: prefer ~/bin, fall back to ~/Developer/bin
  if [ -d "$HOME/bin" ]; then
    TARGET_DIR="$HOME/bin"
  else
    TARGET_DIR="$HOME/Developer/bin"
  fi
  echo "Installing to $TARGET_DIR (pass a path to override)"
fi

# ── Install ──────────────────────────────────────────────────
mkdir -p "$TARGET_DIR"

# Check if we can write without sudo
if ! touch "$TARGET_DIR/.write-test" 2>/dev/null; then
  echo "Need sudo to write to $TARGET_DIR"
  echo "Running with sudo..."
  for f in "${SCRIPTS[@]}"; do
    name="${f%.sh}"
    sudo cp "$f" "$TARGET_DIR/$name"
    sudo chmod +x "$TARGET_DIR/$name"
    echo "  Installed $name (via sudo)"
  done
else
  rm -f "$TARGET_DIR/.write-test"
  echo "Installing to $TARGET_DIR..."
  for f in "${SCRIPTS[@]}"; do
    name="${f%.sh}"
    cp "$f" "$TARGET_DIR/$name"
    chmod +x "$TARGET_DIR/$name"
    echo "  Installed $name"
  done
fi

echo "Done."
echo "Make sure '$TARGET_DIR' is in your PATH, then run 'llm-start.sh' to get started."
