"""PDF/epub metadata extraction using pypdf and ebooklib."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class FileMetadata:
    title: Optional[str] = None
    author: Optional[str] = None
    year: Optional[int] = None
    publisher: Optional[str] = None


def extract_pdf_metadata(filepath: Path) -> FileMetadata:
    """Extract metadata from a PDF file."""
    try:
        import logging

        logging.getLogger("pypdf").setLevel(logging.ERROR)
        from pypdf import PdfReader

        reader = PdfReader(str(filepath))
        info = reader.metadata
        if not info:
            return FileMetadata()

        title = info.get("/Title")
        author = info.get("/Author")
        # Try to extract year from CreationDate or ModDate
        year = None
        for key in ("/CreationDate", "/ModDate"):
            date_str = info.get(key)
            if date_str and len(date_str) >= 6:
                # Format: D:YYYYMMDDHHmmSS or YYYY...
                cleaned = str(date_str).replace("D:", "")
                try:
                    y = int(cleaned[:4])
                    if 1900 <= y <= 2030:
                        year = y
                        break
                except (ValueError, IndexError):
                    pass
        publisher = info.get("/Publisher")

        return FileMetadata(
            title=str(title) if title else None,
            author=str(author) if author else None,
            year=year,
            publisher=str(publisher) if publisher else None,
        )
    except Exception:
        return FileMetadata()


def extract_epub_metadata(filepath: Path) -> FileMetadata:
    """Extract metadata from an epub file."""
    try:
        import ebooklib
        from ebooklib import epub

        book = epub.read_epub(str(filepath), options={"ignore_ncx": True})

        title = book.get_metadata("DC", "title")
        title = title[0][0] if title else None

        creator = book.get_metadata("DC", "creator")
        author = creator[0][0] if creator else None

        date = book.get_metadata("DC", "date")
        year = None
        if date:
            try:
                year = int(str(date[0][0])[:4])
            except (ValueError, IndexError):
                pass

        pub = book.get_metadata("DC", "publisher")
        publisher = pub[0][0] if pub else None

        return FileMetadata(
            title=str(title) if title else None,
            author=str(author) if author else None,
            year=year,
            publisher=str(publisher) if publisher else None,
        )
    except Exception:
        return FileMetadata()


def extract_metadata(filepath: Path) -> FileMetadata:
    """Extract metadata from a PDF or epub file."""
    suffix = filepath.suffix.lower()
    if suffix == ".pdf":
        return extract_pdf_metadata(filepath)
    elif suffix == ".epub":
        return extract_epub_metadata(filepath)
    return FileMetadata()
