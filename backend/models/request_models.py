# models/request_models.py — defines the shape of data that the API expects to receive.
# Pydantic models serve as a contract: FastAPI uses them to automatically validate
# incoming JSON and return a clear error if required fields are missing or the wrong type.

from pydantic import BaseModel
from typing import Optional


# This model represents the JSON body for a TTS request.
# Example JSON: { "text": "Hello world", "voice": "nova", "speed": 1.5 }
class TTSRequest(BaseModel):
    text: str                        # required — the text to be spoken
    voice: Optional[str] = "alloy"   # optional — which voice to use (premium only)
    speed: Optional[float] = 1.0     # optional — playback speed multiplier
