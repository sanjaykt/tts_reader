# main.py — the entry point of the FastAPI application.
# When you run the server, Python starts here.

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import tts

app = FastAPI(title="TTS Reader API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "http://127.0.0.1:8080"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registers all routes defined in routers/tts.py under the /tts prefix.
# So a route defined as /speak/free becomes /tts/speak/free.
# This keeps the router file focused on its own logic without hardcoding the prefix.
app.include_router(tts.router, prefix="/tts", tags=["tts"])


# A simple health check endpoint. Useful to confirm the server is running
# without triggering any real logic. Common in production deployments.
@app.get("/health")
def health():
    return {"status": "ok"}
