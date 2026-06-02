# services/tts_premium.py — text-to-speech using OpenAI's TTS API.
# Requires the OPENAI_API_KEY environment variable to be set.
# The openai library picks it up automatically — you don't pass it manually.

import openai


# Available voices from OpenAI: "alloy", "echo", "fable", "onyx", "nova", "shimmer"
# Each has a different character — alloy is neutral, nova is warm, onyx is deep, etc.
def synthesize(text: str, voice: str = "alloy") -> bytes:
    response = openai.audio.speech.create(
        model="tts-1",   # tts-1 is standard quality; tts-1-hd is higher quality but slower
        voice=voice,
        input=text,
    )

    # response.content holds the raw MP3 audio as bytes.
    # The caller (router) can stream this back to the client.
    return response.content
