# llm-local

Local LLM stack for running Claude Code through Ollama, with support for a main model and up to 4 named agents — each in their own git worktree with distinct session colors.

## Install

```bash
# Install scripts to ~/bin (auto-detected, already in PATH)
bash install.sh

# Or install to a custom directory
bash install.sh /usr/local/bin

# Remove installed scripts
bash install.sh --uninstall
```

## Quick start

```bash
# Start the stack (main model, blue session)
llm-start

# Check status
llm-status

# Shut down
llm-stop
```

## Setup

### 1. Configure your shell

Add the Ollama environment variables from `ollama.zshrc` to your `~/.zshrc` (or `~/.bashrc`):

```bash
export OLLAMA_USE_MLX=1
export OLLAMA_NUM_GPU=999
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=4
export OLLAMA_NUM_CTX=65536
export OLLAMA_KEEP_ALIVE=60m
```

Then `source ~/.zshrc`.

### 2. Create agent models

```bash
model-alias
```

Pulls `qwen3:14b` and creates 4 agent models (`agent1`–`agent4`) with 16k context windows.

## Usage

### `llm-start` — Start Ollama + Claude Code

Launches Ollama (if not already running), ensures the model is pulled, optionally creates a git worktree, then launches `claude` with the chosen model and session configuration.

| Command | What it does |
|---|---|
| `llm-start` | Main model (blue), no worktree |
| `llm-start -m gemma4:31b` | Custom model |
| `llm-start -w feature-auth` | Main model + named worktree |
| `llm-start -w` | Main model + auto-named worktree |
| `llm-start -a 1` | Agent 1 (green), auto worktree |
| `llm-start -a 2 -w feature-billing` | Agent 2 (orange) + named worktree |
| `llm-start -a 3 -w feature-tests` | Agent 3 (yellow) + named worktree |
| `llm-start -a 4 -w feature-docs` | Agent 4 (red) + named worktree |
| `llm-start --help` | Full usage info |

### `llm-status` — Show status

Displays Ollama running state, loaded models, available models, and Claude Code setup hints.

```bash
llm-status
```

### `llm-stop` — Stop everything

Unloads all loaded models from memory, then stops the Ollama process.

```bash
llm-stop
```

## Architecture

- **Ollama integration**: Routes Claude Code through `localhost:11434` using `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN=ollama`
- **Worktrees**: Agents (`-a 1-4`) automatically enable worktree mode, giving each agent an isolated copy of the repo on a separate branch
- **Colors**: Each session gets a unique color (blue = main, green/orange/yellow/red = agents 1–4) for easy visual identification in the terminal
- **Logging**: Ollama logs go to `~/.ollama/logs/ollama.log`

## Defaults

| Setting | Value |
|---|---|
| Main model | `qwen3.6:35b-a3b-coding-nvfp4` |
| Agent base | `qwen3:14b` (16k context) |
| Parallel agents | 4 |
| Keep-alive | 60 min |
| Main context | 64k tokens |

## License

MIT © 2026 Aaron Saikovski
