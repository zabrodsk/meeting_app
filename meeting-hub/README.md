# Meeting Hub

Mac mini inference service: Whisper ASR → local LLM formatting → Notion API.

Runs on your Mac mini; clients (iOS/Mac app) upload audio via Tailscale.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
```

## ASR spike (transcribe.py)

Transcribe audio locally with faster-whisper (multi-language, auto-detect or explicit):

```bash
python transcribe.py path/to/audio.wav
python transcribe.py audio.m4a --model base --language es
```

Models: `tiny`, `base`, `small`, `medium`, `large-v2`, `large-v3`. Use `base` for Mac mini; `tiny` for quick tests.

## Notion spike (notion_client.py)

Create a Notion page from formatted markdown. Requires a Notion integration token and a parent page you've shared with it.

1. Create an integration at https://www.notion.so/my-integrations
2. Share the target parent page with the integration
3. Set `NOTION_API_KEY` and `NOTION_PARENT_PAGE_ID`:

```bash
export NOTION_API_KEY="secret_..."
export NOTION_PARENT_PAGE_ID="<page-id-from-url>"
echo "# Meeting Notes\n\nSummary here.\n\n## Action items\n- [ ] Task 1" | python notion_client.py "$NOTION_PARENT_PAGE_ID"
```

Or pass markdown as argument or from file:

```bash
python notion_client.py "$NOTION_PARENT_PAGE_ID" --file formatted_note.md
```

## Hub API (api.py)

Run the full pipeline: upload → transcribe → format → Notion.

```bash
pip install -r requirements.txt
export HUB_API_KEY="your-secret"
export NOTION_API_KEY="secret_..."
export NOTION_PARENT_PAGE_ID="..."
./run.sh
```

Then configure the MeetingNotes app with:
- **Hub URL**: `https://mini.your-tailnet.ts.net:8000` (Tailscale MagicDNS)
- **API Key**: same as `HUB_API_KEY`

Without `HUB_API_KEY`, the API accepts any request (LAN-only use).
