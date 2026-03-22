#!/bin/bash
# Run the Meeting Hub on your Mac mini.
# Set these env vars (or create .env and source it):
#   HUB_API_KEY     - API key for client auth (required if set)
#   NOTION_API_KEY  - Notion integration token
#   NOTION_PARENT_PAGE_ID - Page ID to create meeting notes under
#   WHISPER_MODEL   - faster-whisper model (default: base)
#   OLLAMA_MODEL    - Ollama model for formatting (default: llama3.2)

cd "$(dirname "$0")"
source .venv/bin/activate 2>/dev/null || true

# Optional: load from .env
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Default port; use HTTPS in production (e.g. behind Caddy with Tailscale certs)
PORT=${PORT:-8000}
echo "Starting Meeting Hub on port $PORT"
echo "Hub URL: https://$(hostname):$PORT (use your Tailscale hostname)"
exec uvicorn api:app --host 0.0.0.0 --port "$PORT"
