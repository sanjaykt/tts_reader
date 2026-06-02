# services/tts_free.py — offline-friendly text-to-speech using gTTS (Google TTS).
# gTTS sends the text to Google's TTS API and returns MP3 audio as bytes.
# No API key required. Requires an internet connection.

from gtts import gTTS
from io import BytesIO


def synthesize(text: str) -> bytes:
    tts = gTTS(text=text, lang="en")

    # Write the MP3 output into an in-memory buffer instead of a file on disk.
    # This keeps the service stateless — no temp files to manage or clean up.
    buffer = BytesIO()
    tts.write_to_fp(buffer)
    buffer.seek(0)

    return buffer.read()
