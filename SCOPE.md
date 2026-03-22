# Meeting Notes App — Scope Decision

## Decision: SwiftUI multiplatform + thin-client (hub) for iPhone

### Framework: SwiftUI

- **One codebase** for iPhone, iPad, and Mac
- Native feel and best integration with Apple ecosystem
- Shared UI and logic; platform-specific adaptations where needed
- Avoids Flutter overhead and separate build toolchains

### Architecture: Thin-client (hub) for iPhone

- **iPhone / iPad**: Record audio → auto-upload to Mac mini → show status; no large on-device models
- **Mac mini**: Runs Whisper-class ASR + local LLM (Ollama/MLX) + Notion API
- **Network**: Tailscale MagicDNS for stable hostname; LAN fallback when both on same Wi‑Fi
- **Offline**: Persistent queue on iOS with retry; upload when hub reachable

### Platform support

| Platform   | Role                                      |
|-----------|--------------------------------------------|
| iPhone    | Capture, upload, status; thin client       |
| iPad      | Same as iPhone; larger canvas              |
| Mac       | Full app + can run hub locally for dev     |

### Fallback (no hub)

- When hub unreachable: queue recordings; offer optional on-device path later (tiny Whisper) if we add it
- Primary path: always prefer hub for quality and battery
