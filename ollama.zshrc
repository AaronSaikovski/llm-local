# Add to .zshrc file

# Ollama Local settings
export OLLAMA_USE_MLX=1
export OLLAMA_NUM_GPU=999
export OLLAMA_NUM_PARALLEL=4       # one slot per agent
export OLLAMA_MAX_LOADED_MODELS=4  # allow all 4 agents loaded at once
export OLLAMA_NUM_CTX=65536        # main model context (agents override via Modelfile)
export OLLAMA_KEEP_ALIVE=60m
