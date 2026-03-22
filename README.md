# Meeting Notes

Lightweight local-first meeting recording app: record on iPhone/iPad/Mac → upload to Mac mini → transcribe (Whisper) → format (Ollama) → save to Notion.

## Architecture

```
iPhone/iPad     ──upload──►  Mac mini (hub)  ──►  Notion
     │                            │
     │                     Whisper ASR
     │                     Ollama LLM
```

- **Tailscale** recommended for stable hostname and access from anywhere.
- **Notion API** (not MCP) for creating pages from formatted markdown.

## Components

| Component | Path | Description |
|-----------|------|-------------|
| **MeetingNotes app** | `MeetingNotes/` | SwiftUI app (iOS, iPad, Mac). Record → auto-upload → queue with retry. |
| **Meeting Hub** | `meeting-hub/` | Python service on Mac mini. HTTP API, Whisper, Ollama, Notion. |
| **SCOPE** | `SCOPE.md` | Scope decision: SwiftUI multiplatform, thin-client. |
| **DEFINE_OFFLINE** | `DEFINE_OFFLINE.md` | Recording limits and model sizes per device. |

## Clone on your Mac mini

```bash
git clone https://github.com/zabrodsk/meeting_app.git
cd meeting_app/meeting-hub
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your secrets, then:
./run.sh
```

(Replace `zabrodsk/meeting_app` with your fork or org if different.)

## Quick start

### 1. Mac mini (hub)

```bash
cd meeting-hub
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export HUB_API_KEY=your-secret
export NOTION_API_KEY=secret_...
export NOTION_PARENT_PAGE_ID=...
./run.sh
```

Share a Notion page with your integration; use its ID as `NOTION_PARENT_PAGE_ID`.

### 2. Install Ollama and pull a model

```bash
ollama run llama3.2
```

### 3. MeetingNotes app

Open `MeetingNotes/MeetingNotes.xcodeproj` in Xcode. Build and run on iOS Simulator or device.

In Settings, enter:
- **Hub URL**: `https://mini.your-tailnet.ts.net:8000` (Tailscale MagicDNS)
- **API Key**: same as `HUB_API_KEY`

### 4. Record

Tap Record, speak, tap Stop. The app uploads automatically and shows status (Queued → Uploading → Processing → Saved to Notion).
