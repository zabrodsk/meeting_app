# Offline and Device Tier Specs

## Max recording length

| Context | Max duration | Rationale |
|---------|--------------|-----------|
| **iPhone (hub path)** | 4 hours | iOS background limits; large files; upload over cellular capped by data |
| **iPad (hub path)** | 4 hours | Same as iPhone |
| **Mac (hub or local)** | 8 hours | No battery constraint; local storage; longer meetings common |
| **On-device only (fallback)** | 30 min | Tiny/base model memory; battery; thermal throttling |

Recommendation: cap at 4h for mobile, 8h for Mac in the app. Hub accepts up to configured limit (e.g. 4h audio ≈ ~500 MB at 256 kbps).

## Model sizes by device tier

### Mac mini (hub)

| Model | Size | RAM | Use case |
|-------|------|-----|----------|
| `base` | ~150 MB | ~1 GB | Default; good quality, multi-language |
| `small` | ~500 MB | ~2 GB | Better accuracy for noisy meetings |
| `medium` | ~1.5 GB | ~5 GB | High quality; longer processing |
| `large-v3` | ~3 GB | ~10 GB | Best quality; only if mini has 16+ GB RAM |

Default: `base`. Configurable via hub env (e.g. `WHISPER_MODEL=small`).

### iPhone / iPad (thin client)

No on-device Whisper in primary path. If we add a fallback when hub unreachable:

| Model | Size | Use case |
|-------|------|----------|
| `tiny` | ~75 MB | Quick fallback; short clips (<10 min) |
| `base` | ~150 MB | Optional; only on newer iPads with enough memory |

### Local LLM (formatting) — Mac mini

| Model | Notes |
|-------|-------|
| Ollama `llama3.2` or `phi3` | ~2–4 GB; good for summarization and structure |
| Ollama `gemma2:2b` | Smaller; faster |
| MLX `mlx-community/Llama-3.2-1B-Instruct` | Apple Silicon optimized |

Default: small instruct model via Ollama (`ollama run llama3.2:latest` or similar).

## Offline queue behavior

- **Persistent**: Store queued recordings in app sandbox; survive app kill
- **Retry**: Exponential backoff (e.g. 30s, 1m, 5m) when hub unreachable
- **Status**: Queued → Uploading → Processing → Done (or Failed)
- **Max queue size**: 50 recordings; warn user if exceeded
