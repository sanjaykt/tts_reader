# services/tts_free.py — offline text-to-speech using the pyttsx3 library.
# pyttsx3 talks directly to the operating system's built-in speech engine:
# macOS → "say", Windows → SAPI, Linux → espeak.
# No internet connection or API key required.

import pyttsx3


def synthesize(text: str) -> str:
    # init() starts the OS speech engine. This must be called before anything else.
    engine = pyttsx3.init()

    # Queues the text to be spoken. Nothing is spoken yet at this point.
    engine.say(text)

    # Actually speaks the queued text and blocks until it finishes.
    # NOTE: this plays audio on the server machine, not the client's device.
    # In a real app you would save the output to an audio file and return that instead.
    engine.runAndWait()

    return "ok"
