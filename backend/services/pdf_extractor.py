# services/pdf_extractor.py — extracts plain text from an uploaded PDF file.
# Uses pdfplumber, which works well for PDFs with real text layers.
# Note: scanned PDFs (images of pages) won't return text — OCR would be needed for those.

from fastapi import UploadFile
import pdfplumber
import io


async def extract(file: UploadFile) -> str:
    # Read all bytes from the uploaded file asynchronously.
    # `await` pauses this function until the data is ready, freeing the server
    # to handle other requests in the meantime.
    contents = await file.read()

    # io.BytesIO wraps raw bytes in a file-like object so pdfplumber can read it
    # as if it were a file on disk — no need to save it to disk first.
    with pdfplumber.open(io.BytesIO(contents)) as pdf:
        # Loop through every page and extract its text.
        # `or ""` handles pages with no extractable text (e.g. image-only pages)
        # so we get an empty string instead of None, which would break the join below.
        pages = [page.extract_text() or "" for page in pdf.pages]

    # Join all pages into one string separated by newlines.
    return "\n".join(pages)
