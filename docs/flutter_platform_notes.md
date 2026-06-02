# Flutter Platform Notes: Web vs Mobile

## Overview

Flutter lets you target iOS, Android, and Web from a single codebase. However, two areas
need platform-aware handling when building the TTS Reader app: **file handling** and **audio playback**.

---

## File Handling (PDF Upload)

| | Mobile | Web |
|---|---|---|
| **File picker** | Accesses device storage directly, returns a file path | Returns file bytes in memory (no real file path) |
| **Send to backend** | Multipart upload via file path | Multipart upload via bytes |

Both platforms use the `file_picker` package. The difference is only in how you read
the file before uploading:

- **Mobile:** read from file path
- **Web:** read from in-memory bytes

The multipart upload to the FastAPI backend works the same way on both — just a slightly
different source.

---

## Audio Playback

This is the more significant difference between platforms.

| | Mobile | Web |
|---|---|---|
| **How audio arrives** | Backend returns MP3 bytes → save to temp file → play from file | Backend returns MP3 bytes → play from in-memory blob URL |
| **Recommended package** | `just_audio` | `just_audio` (web support available, use carefully) or `audioplayers` |
| **Streaming support** | Easy — stream chunks and play progressively | Harder — browsers handle audio differently |

---

## Recommended Architecture: Streaming URL Approach

Instead of sending raw audio bytes to the Flutter client and handling them differently
per platform, the cleaner solution is:

**Have the FastAPI backend expose a streaming audio endpoint** that returns audio with
proper HTTP headers (`Content-Type: audio/mpeg`, `Transfer-Encoding: chunked`).

Flutter then simply passes the URL to `just_audio` on all platforms:

```dart
final player = AudioPlayer();
await player.setUrl('http://your-backend/tts/stream?text=...');
await player.play();
```

### Why this is better

- No platform-branching code in Flutter
- No bytes-in-memory juggling
- Works uniformly on iOS, Android, and Web
- Easier to maintain and extend (e.g. caching, CDN) in the future

---

## Backend Endpoint to Add

```python
@router.get("/tts/stream")
async def stream_tts(text: str):
    audio_bytes = generate_tts(text)  # existing TTS logic
    return StreamingResponse(
        iter([audio_bytes]),
        media_type="audio/mpeg"
    )
```

---

## Summary of Decisions

| Decision | Choice | Reason |
|---|---|---|
| Flutter targets | iOS + Android + Web | Single codebase, maximum reach |
| File picker | `file_picker` package | Handles both mobile and web |
| Audio playback | `just_audio` | Cross-platform, good community support |
| Audio delivery | Streaming URL from backend | Avoids platform-specific byte handling |
