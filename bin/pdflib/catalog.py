"""Catalog management: scan, load, save, merge."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Optional

from .metadata import extract_metadata
from .models import Book, FileFormat
from .parser import parse_filename

PDF_ROOT = Path.home() / "Documents" / "PDF"
CATALOG_PATH = PDF_ROOT / "catalog.json"

EXCLUDE_DIRS = {"_Novel", "unuseful", ".DS_Store", ".history", "_chapters"}
CHAPTER_DIR_PATTERNS = [
    re.compile(r"\bpdfs?\b", re.IGNORECASE),
]


def _is_chapter_dir(dirpath: Path) -> bool:
    """Check if a directory contains chapter PDFs (not the main book file)."""
    name = dirpath.name
    # Explicit pattern match: dirs ending with "pdfs" or "pdf"
    if any(p.search(name) for p in CHAPTER_DIR_PATTERNS):
        return True
    # Also detect dirs that contain only chapter-like PDFs (numbered files, no full book)
    # e.g. "Pro Git-Apress (2014)/" with files like "al-1Contents.pdf"
    pdfs = list(dirpath.glob("*.pdf"))
    if pdfs and all(_looks_like_chapter(f.stem) for f in pdfs):
        return True
    return False


def _looks_like_chapter(stem: str) -> bool:
    """Check if a filename looks like a chapter file."""
    # Starts with number or "al-" prefix, or contains "Chapter"
    if re.match(r"^(\d+|al-\d+)", stem):
        return True
    if "chapter" in stem.lower() or "contents" in stem.lower():
        return True
    return False


def _should_skip(path: Path) -> bool:
    """Check if path should be excluded from scanning."""
    parts = path.relative_to(PDF_ROOT).parts
    return any(p in EXCLUDE_DIRS for p in parts)


def _make_id(title: str, language: str) -> str:
    """Generate a slug ID from title and language."""
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", title.lower()).strip("-")
    # Truncate overly long slugs
    if len(slug) > 60:
        slug = slug[:60].rsplit("-", 1)[0]
    return f"{slug}-{language}"


def _find_chapter_dirs() -> dict[str, Path]:
    """Find directories that contain chapter PDFs.

    Returns mapping of parent book identifier → chapter dir path.
    """
    chapters = {}
    for dirpath in PDF_ROOT.rglob("*"):
        if not dirpath.is_dir():
            continue
        if _should_skip(dirpath):
            continue
        if _is_chapter_dir(dirpath):
            rel = dirpath.relative_to(PDF_ROOT)
            chapters[str(rel)] = dirpath
    return chapters


def scan(pdf_root: Optional[Path] = None) -> list[Book]:
    """Scan PDF_ROOT and build a book catalog.

    Groups files by title+language to merge multiple formats.
    """
    root = pdf_root or PDF_ROOT
    chapter_dirs = _find_chapter_dirs()
    chapter_paths = set()
    for d in chapter_dirs.values():
        for f in d.rglob("*"):
            chapter_paths.add(f)

    # Collect all book files
    files: list[Path] = []
    for ext in ("*.pdf", "*.epub"):
        for f in root.rglob(ext):
            if _should_skip(f):
                continue
            if f in chapter_paths:
                continue
            files.append(f)

    # Group by (title, language) to merge formats
    books_map: dict[str, Book] = {}

    for filepath in sorted(files):
        parsed = parse_filename(filepath)
        meta = extract_metadata(filepath)

        # Merge: parsed takes priority for structure, meta fills gaps
        title = parsed.title
        author = parsed.author or meta.author
        year = parsed.year or meta.year
        # Validate year is plausible (1950-2030)
        if year and not (1950 <= year <= 2030):
            year = None
        publisher = parsed.publisher or meta.publisher
        language = parsed.language

        # Determine category from directory structure
        rel = filepath.relative_to(root)
        category = rel.parts[0] if len(rel.parts) > 1 else ""

        book_id = _make_id(title, language)

        # Build FileFormat entry
        fmt = FileFormat(
            format=filepath.suffix.lstrip(".").lower(),
            path=str(rel),
            original_filename=filepath.name,
        )

        if book_id in books_map:
            existing = books_map[book_id]
            # Merge format if not already present
            existing_formats = {f.format for f in existing.formats}
            if fmt.format not in existing_formats:
                existing.formats.append(fmt)
            # Fill missing metadata
            if not existing.author and author:
                existing.author = author
            if not existing.year and year:
                existing.year = year
            if not existing.publisher and publisher:
                existing.publisher = publisher
        else:
            # Check for chapter dirs
            has_chapters = False
            chapters_dir_str = None
            for cdir_rel, cdir_path in chapter_dirs.items():
                # Match by title similarity in the chapter dir name
                cdir_name = cdir_path.name.lower()
                title_words = title.lower().split()[:3]
                if any(w in cdir_name for w in title_words if len(w) > 3):
                    has_chapters = True
                    chapters_dir_str = cdir_rel
                    break

            # Determine tags from category
            tag_map = {
                "Go": ["golang"],
                "Database": ["database"],
                "Infrastructure": ["infrastructure"],
                "React": ["react", "frontend"],
                "Javascript": ["javascript", "frontend"],
                "API": ["api"],
                "AI": ["ai"],
                "Git": ["git"],
                "Software Engineering": ["software-engineering"],
            }
            tags = tag_map.get(category, [category.lower()] if category else [])

            # Translation linking
            is_translation = parsed.is_translation
            translation_of = None
            if is_translation:
                en_id = _make_id(title, "en")
                if en_id in books_map:
                    translation_of = en_id

            needs_review = not author or not year

            book = Book(
                id=book_id,
                title=title,
                author=author,
                year=year,
                publisher=publisher,
                category=category,
                language=language,
                formats=[fmt],
                has_chapters=has_chapters,
                chapters_dir=chapters_dir_str,
                is_translation=is_translation,
                translation_of=translation_of,
                tags=tags,
                status="unread",
                needs_review=needs_review,
            )
            books_map[book_id] = book

    # Recalculate needs_review after all merging is done
    for book in books_map.values():
        book.needs_review = not book.author or not book.year

    return list(books_map.values())


def save_catalog(books: list[Book], path: Optional[Path] = None) -> Path:
    """Save catalog to JSON."""
    out = path or CATALOG_PATH
    data = {
        "version": 1,
        "books": [b.to_dict() for b in books],
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return out


def load_catalog(path: Optional[Path] = None) -> list[Book]:
    """Load catalog from JSON."""
    src = path or CATALOG_PATH
    if not src.exists():
        return []
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
    return [Book.from_dict(b) for b in data.get("books", [])]


def build_normalized_filename(book: Book, fmt: str) -> str:
    """Build normalized filename: Author - Title (Year).ext"""
    parts = []
    if book.author:
        parts.append(book.author)
        parts.append(" - ")
    parts.append(book.title)
    if book.year:
        parts.append(f" ({book.year})")
    if book.language != "en":
        parts.append(f"_{book.language}")
    return "".join(parts) + f".{fmt}"


def plan_renames(books: list[Book]) -> list[tuple[Path, Path]]:
    """Plan file renames. Returns list of (old_path, new_path) tuples."""
    renames = []
    for book in books:
        for fmt in book.formats:
            normalized = build_normalized_filename(book, fmt.format)
            if fmt.original_filename == normalized:
                continue
            old = PDF_ROOT / fmt.path
            new = old.parent / normalized
            if old != new:
                renames.append((old, new))
                fmt.normalized_filename = normalized
    return renames


def apply_renames(renames: list[tuple[Path, Path]]) -> list[tuple[Path, Path]]:
    """Apply file renames. Returns list of successful renames."""
    done = []
    for old, new in renames:
        if old.exists() and not new.exists():
            old.rename(new)
            done.append((old, new))
    return done


def plan_chapters() -> list[tuple[Path, Path]]:
    """Plan chapter directory moves to _chapters/.

    Returns list of (old_dir, new_dir) tuples.
    """
    moves = []
    chapter_dirs = _find_chapter_dirs()

    for cdir_rel, cdir_path in chapter_dirs.items():
        # Determine the target _chapters/ location
        rel = cdir_path.relative_to(PDF_ROOT)
        parent = cdir_path.parent

        # Extract book name from the chapter dir name
        # e.g. "100 Go Mistakes pdfs" → "100 Go Mistakes"
        book_name = re.sub(r"\s*pdfs?\s*$", "", cdir_path.name, flags=re.IGNORECASE).strip()
        if not book_name:
            book_name = cdir_path.name

        new_dir = parent / "_chapters" / book_name
        if cdir_path != new_dir:
            moves.append((cdir_path, new_dir))

    return moves


def apply_chapter_moves(moves: list[tuple[Path, Path]]) -> list[tuple[Path, Path]]:
    """Apply chapter directory moves."""
    import shutil

    done = []
    for old, new in moves:
        if old.exists():
            new.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old), str(new))
            done.append((old, new))
    return done
