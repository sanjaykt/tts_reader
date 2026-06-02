# routers/tts.py — defines the HTTP endpoints for all TTS-related features.
# A router is like a mini-app: it groups related routes and gets mounted in main.py.

from fastapi import APIRouter, UploadFile, File
from fastapi.responses import StreamingResponse
from ..models.request_models import TTSRequest
from ..services import tts_free, tts_premium, pdf_extractor

# APIRouter groups these routes together. main.py mounts this with prefix="/tts".
router = APIRouter()


# Handles free (offline) text-to-speech.
# FastAPI automatically reads the JSON body and validates it against TTSRequest.
@router.post("/speak/free")
def speak_free(request: TTSRequest):
    audio = tts_free.synthesize(request.text)
    return {"audio": audio}


# Handles premium (OpenAI) text-to-speech.
# Passes the voice field so the caller can choose from OpenAI's voice options.
@router.post("/speak/premium")
def speak_premium(request: TTSRequest):
    audio = tts_premium.synthesize(request.text, voice=request.voice)
    return {"audio": audio}


# Streams free TTS audio directly to the client as MP3.
# Flutter (and browsers) can play this by pointing an audio player at this URL.
@router.post("/stream/free")
def stream_free(request: TTSRequest):
    audio = tts_free.synthesize(request.text)
    return StreamingResponse(iter([audio]), media_type="audio/mpeg")


# Streams premium TTS audio directly to the client as MP3.
@router.post("/stream/premium")
def stream_premium(request: TTSRequest):
    audio = tts_premium.synthesize(request.text, voice=request.voice)
    return StreamingResponse(iter([audio]), media_type="audio/mpeg")


# Handles PDF file uploads and returns the extracted text.
# `async def` is used here because reading an uploaded file is an I/O operation —
# using async lets the server handle other requests while waiting for the file read.
# `File(...)` means the field is required (the ... is Python's way of saying "no default").
@router.post("/pdf")
async def extract_pdf(file: UploadFile = File(...)):
    text = await pdf_extractor.extract(file)
    return {"text": text}
