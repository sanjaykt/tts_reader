# routers/tts.py — defines the HTTP endpoints for all TTS-related features.
# A router is like a mini-app: it groups related routes and gets mounted in main.py.

import asyncio
from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from ..models.request_models import TTSRequest
from ..services import tts_free, tts_premium, pdf_extractor

MAX_TTS_CHARS = 5000

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
# gTTS is a blocking network call so we run it in a thread to avoid blocking the event loop.
@router.post("/stream/free")
async def stream_free(request: TTSRequest):
    if len(request.text) > MAX_TTS_CHARS:
        raise HTTPException(status_code=400, detail=f"Text too long. Maximum {MAX_TTS_CHARS} characters.")
    loop = asyncio.get_event_loop()
    audio = await loop.run_in_executor(None, tts_free.synthesize, request.text)
    return StreamingResponse(iter([audio]), media_type="audio/mpeg")


# Streams premium TTS audio directly to the client as MP3.
@router.post("/stream/premium")
async def stream_premium(request: TTSRequest):
    if len(request.text) > MAX_TTS_CHARS:
        raise HTTPException(status_code=400, detail=f"Text too long. Maximum {MAX_TTS_CHARS} characters.")
    loop = asyncio.get_event_loop()
    audio = await loop.run_in_executor(None, tts_premium.synthesize, request.text, request.voice)
    return StreamingResponse(iter([audio]), media_type="audio/mpeg")


# Handles PDF file uploads and returns the extracted text.
# `async def` is used here because reading an uploaded file is an I/O operation —
# using async lets the server handle other requests while waiting for the file read.
# `File(...)` means the field is required (the ... is Python's way of saying "no default").
@router.post("/pdf")
async def extract_pdf(file: UploadFile = File(...)):
    text = await pdf_extractor.extract(file)
    return {"text": text}
