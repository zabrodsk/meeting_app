"""
Meeting Hub API — Mac mini inference service.

POST /jobs — upload audio, returns job_id
GET /jobs/{job_id} — job status and result
GET /health — liveness
"""
import os
import uuid
import asyncio
from pathlib import Path
from datetime import datetime
from contextlib import asynccontextmanager

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends, Header
from fastapi.security import APIKeyHeader
from pydantic import BaseModel

# Optional API key for auth (set HUB_API_KEY env)
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

JOBS_DIR = Path(os.environ.get("HUB_JOBS_DIR", "/tmp/meeting-hub-jobs"))
JOBS_DIR.mkdir(parents=True, exist_ok=True)


async def verify_api_key(x_api_key: str | None = Header(default=None)):
    expected = os.environ.get("HUB_API_KEY")
    if expected and x_api_key != expected:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    return x_api_key


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    # Cleanup if needed


app = FastAPI(title="Meeting Hub", lifespan=lifespan)


class JobStatus(BaseModel):
    job_id: str
    status: str  # pending, transcribing, formatting, saving, done, failed
    created_at: str
    error: str | None = None
    notion_url: str | None = None


class JobCreate(BaseModel):
    job_id: str


def get_job_path(job_id: str) -> Path:
    return JOBS_DIR / job_id


def get_meta_path(job_id: str) -> Path:
    return get_job_path(job_id) / "meta.txt"


def get_audio_path(job_id: str) -> Path:
    return get_job_path(job_id) / "audio.upload"


def read_job_status(job_id: str) -> JobStatus | None:
    meta_path = get_meta_path(job_id)
    if not meta_path.exists():
        return None
    lines = meta_path.read_text().strip().split("\n")
    data = dict(line.split(":", 1) for line in lines if ":" in line)
    return JobStatus(
        job_id=job_id,
        status=data.get("status", "pending"),
        created_at=data.get("created_at", ""),
        error=data.get("error"),
        notion_url=data.get("notion_url"),
    )


def write_job_status(job_id: str, status: str, error: str | None = None, notion_url: str | None = None):
    path = get_job_path(job_id)
    path.mkdir(parents=True, exist_ok=True)
    meta = get_meta_path(job_id)
    existing = read_job_status(job_id)
    created = existing.created_at if existing else datetime.utcnow().isoformat() + "Z"
    lines = [
        f"status:{status}",
        f"created_at:{created}",
    ]
    if error:
        lines.append(f"error:{error}")
    if notion_url:
        lines.append(f"notion_url:{notion_url}")
    meta.write_text("\n".join(lines))


async def process_job(job_id: str):
    """Background pipeline: transcribe → format → Notion."""
    try:
        write_job_status(job_id, "transcribing")
        audio_path = get_audio_path(job_id)
        if not audio_path.exists():
            write_job_status(job_id, "failed", error="Audio file missing")
            return

        # Transcribe (CPU-bound, run in thread)
        from transcribe import transcribe
        model_size = os.environ.get("WHISPER_MODEL", "base")
        transcript = await asyncio.to_thread(
            transcribe, str(audio_path), model_size
        )

        write_job_status(job_id, "formatting")

        # Format with local LLM (Ollama)
        formatted = await format_transcript(transcript)

        write_job_status(job_id, "saving")

        # Save to Notion
        notion_url = await save_to_notion(formatted, job_id)
        write_job_status(job_id, "done", notion_url=notion_url)

    except Exception as e:
        write_job_status(job_id, "failed", error=str(e))


async def format_transcript(transcript: str) -> str:
    """Use Ollama to structure the transcript into markdown."""
    ollama_url = os.environ.get("OLLAMA_URL", "http://localhost:11434")
    import httpx

    prompt = f"""Convert this meeting transcript into structured markdown:

Format:
# Meeting Notes

## Summary
(2-3 sentence summary)

## Key Points
- Bullet points of main topics

## Action Items
- [ ] Action 1
- [ ] Action 2

Transcript:
{transcript}
"""

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"{ollama_url}/api/generate",
                json={
                    "model": os.environ.get("OLLAMA_MODEL", "llama3.2"),
                    "prompt": prompt,
                    "stream": False,
                },
            )
            resp.raise_for_status()
            result = resp.json()
            return result.get("response", transcript)
    except Exception:
        # Fallback: minimal structure
        return f"# Meeting Notes\n\n## Transcript\n\n{transcript}"


async def save_to_notion(markdown: str, job_id: str) -> str | None:
    """Save formatted markdown to Notion; return page URL."""
    api_key = os.environ.get("NOTION_API_KEY")
    parent_id = os.environ.get("NOTION_PARENT_PAGE_ID")
    if not api_key or not parent_id:
        return None

    from notion_client import create_page_from_markdown
    page = await asyncio.to_thread(create_page_from_markdown, parent_id, markdown, api_key=api_key)
    return page.get("url")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/jobs", response_model=JobCreate)
async def create_job(
    file: UploadFile = File(...),
    _: str | None = Depends(verify_api_key),
):
    job_id = str(uuid.uuid4())
    path = get_job_path(job_id)
    path.mkdir(parents=True, exist_ok=True)
    audio_path = get_audio_path(job_id)

    content = await file.read()
    audio_path.write_bytes(content)

    write_job_status(job_id, "pending")
    asyncio.create_task(process_job(job_id))

    return JobCreate(job_id=job_id)


@app.get("/jobs/{job_id}", response_model=JobStatus)
async def get_job(
    job_id: str,
    _: str | None = Depends(verify_api_key),
):
    status = read_job_status(job_id)
    if not status:
        raise HTTPException(status_code=404, detail="Job not found")
    return status
