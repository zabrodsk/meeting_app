#!/usr/bin/env python3
"""
ASR spike: local Whisper-class transcription on Mac.
Supports multi-language via auto-detect or explicit language hint.
"""
from pathlib import Path
import argparse


def transcribe(audio_path: str, model_size: str = "base", language: str | None = None) -> str:
    """Transcribe audio file to text using faster-whisper."""
    from faster_whisper import WhisperModel

    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, info = model.transcribe(audio_path, language=language, beam_size=5)
    full_text = " ".join(s.text.strip() for s in segments).strip()
    return full_text


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio (ASR spike)")
    parser.add_argument("audio", type=str, help="Path to audio file (wav, mp3, m4a)")
    parser.add_argument("--model", "-m", default="base", choices=["tiny", "base", "small", "medium", "large-v2", "large-v3"],
                        help="Model size (default: base)")
    parser.add_argument("--language", "-l", default=None,
                        help="Language code (e.g. en, es, de) or auto-detect if omitted")
    args = parser.parse_args()

    if not Path(args.audio).exists():
        raise SystemExit(f"File not found: {args.audio}")

    text = transcribe(args.audio, model_size=args.model, language=args.language)
    print(text)


if __name__ == "__main__":
    main()
