# services/pdf_extractor.py — extracts plain text from an uploaded PDF file.
# Uses pdfplumber, which works well for PDFs with real text layers.
# Note: scanned PDFs (images of pages) won't return text — OCR would be needed for those.

from fastapi import UploadFile
import pdfplumber
import io
import re


async def extract(file: UploadFile) -> str:
    contents = await file.read()

    with pdfplumber.open(io.BytesIO(contents)) as pdf:
        # layout=True preserves spatial positioning so paragraphs stay intact.
        pages = [page.extract_text(layout=True) or "" for page in pdf.pages]

    text = "\n\n".join(pages)

    # Strip leading whitespace from each line (layout=True adds column padding).
    lines = [line.strip() for line in text.splitlines()]
    text = "\n".join(lines)

    # Collapse 3+ consecutive blank lines down to 2 (one paragraph break).
    text = re.sub(r'\n{3,}', '\n\n', text)

    return text.strip()
