"""Data models for pdflib."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class FileFormat:
    format: str  # "pdf" or "epub"
    path: str  # relative path from PDF_ROOT
    original_filename: str
    normalized_filename: Optional[str] = None
    gdrive_url: Optional[str] = None


@dataclass
class Book:
    id: str
    title: str
    author: Optional[str] = None
    year: Optional[int] = None
    publisher: Optional[str] = None
    category: str = ""
    language: str = "en"
    formats: list[FileFormat] = field(default_factory=list)
    has_chapters: bool = False
    chapters_dir: Optional[str] = None
    is_translation: bool = False
    translation_of: Optional[str] = None
    tags: list[str] = field(default_factory=list)
    status: str = "unread"
    needs_review: bool = False

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "author": self.author,
            "year": self.year,
            "publisher": self.publisher,
            "category": self.category,
            "language": self.language,
            "formats": [
                {
                    "format": f.format,
                    "path": f.path,
                    "original_filename": f.original_filename,
                    "normalized_filename": f.normalized_filename,
                    "gdrive_url": f.gdrive_url,
                }
                for f in self.formats
            ],
            "has_chapters": self.has_chapters,
            "chapters_dir": self.chapters_dir,
            "is_translation": self.is_translation,
            "translation_of": self.translation_of,
            "tags": self.tags,
            "status": self.status,
            "needs_review": self.needs_review,
        }

    @classmethod
    def from_dict(cls, data: dict) -> Book:
        formats = [
            FileFormat(
                format=f["format"],
                path=f["path"],
                original_filename=f["original_filename"],
                normalized_filename=f.get("normalized_filename"),
                gdrive_url=f.get("gdrive_url"),
            )
            for f in data.get("formats", [])
        ]
        return cls(
            id=data["id"],
            title=data["title"],
            author=data.get("author"),
            year=data.get("year"),
            publisher=data.get("publisher"),
            category=data.get("category", ""),
            language=data.get("language", "en"),
            formats=formats,
            has_chapters=data.get("has_chapters", False),
            chapters_dir=data.get("chapters_dir"),
            is_translation=data.get("is_translation", False),
            translation_of=data.get("translation_of"),
            tags=data.get("tags", []),
            status=data.get("status", "unread"),
            needs_review=data.get("needs_review", False),
        )
