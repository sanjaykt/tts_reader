# main.py — the entry point of the FastAPI application.
# When you run the server, Python starts here.

from fastapi import FastAPI
from .routers import tts

# Creates the FastAPI app instance. The title shows up in the auto-generated
# API docs at http://localhost:8000/docs
app = FastAPI(title="TTS Reader API")

# Registers all routes defined in routers/tts.py under the /tts prefix.
# So a route defined as /speak/free becomes /tts/speak/free.
# This keeps the router file focused on its own logic without hardcoding the prefix.
app.include_router(tts.router, prefix="/tts", tags=["tts"])


# A simple health check endpoint. Useful to confirm the server is running
# without triggering any real logic. Common in production deployments.
@app.get("/health")
def health():
    return {"status": "ok"}
