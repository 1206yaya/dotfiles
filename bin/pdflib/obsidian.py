"""Obsidian note and .base file generation."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Optional

from .models import Book

OBSIDIAN_ROOT = Path.home() / "ghq/github.com/1206yaya/workspace"
NOTES_DIR = OBSIDIAN_ROOT / "30_resources" / "pdf"
TEMPLATE_DIR = OBSIDIAN_ROOT / "90_system" / "Templater"
BASE_FILE = NOTES_DIR / "books.base"


def _sanitize_filename(name: str) -> str:
    """Remove characters not allowed in filenames/Obsidian (: [] # ^ / \\ \")."""
    name = name.replace("/", "-").replace("\\", "-").replace(":", " -")
    name = name.replace("[", "(").replace("]", ")").replace("#", "").replace("^", "")
    return name.replace('"', "'")


def generate_note(book: Book, now: Optional[datetime] = None) -> tuple[str, str]:
    """Generate an Obsidian note for a book.

    Returns (filename, content).
    """
    now = now or datetime.now()
    created = now.strftime("%Y-%m-%d %H:%M")

    formats_list = sorted({f.format for f in book.formats})

    # Build frontmatter
    lines = [
        "---",
        f"created: {created}",
        f'title: "{book.title}"',
    ]
    if book.author:
        lines.append(f'author: "{book.author}"')
    if book.year:
        lines.append(f"year: {book.year}")
    if book.publisher:
        lines.append(f'publisher: "{book.publisher}"')
    lines.append(f"category: {book.category}")
    lines.append(f"language: {book.language}")
    lines.append(f"formats: [{', '.join(formats_list)}]")
    # PDF paths: Google Drive URL if available, else local path
    paths = []
    for f in book.formats:
        if f.gdrive_url:
            paths.append(f.gdrive_url)
        else:
            paths.append(f"~/Documents/PDF/{f.path}")
    if len(paths) == 1:
        lines.append(f'pdf_path: "{paths[0]}"')
    else:
        lines.append("pdf_path:")
        for p in paths:
            lines.append(f'  - "{p}"')
    lines.append(f"status: {book.status}")
    lines.append("rating: ")

    # Tags
    tags = ["book"]
    if book.category:
        tags.append(book.category.replace(" ", "-"))
    tags.extend(book.tags)
    # Deduplicate preserving order
    seen = set()
    unique_tags = []
    for t in tags:
        tl = t.lower()
        if tl not in seen:
            seen.add(tl)
            unique_tags.append(t)
    lines.append(f"tags: [{', '.join(unique_tags)}]")

    if book.is_translation and book.translation_of:
        lines.append(f'translation_of: "[[{book.translation_of}]]"')

    lines.append("---")
    lines.append("")
    lines.append(f"# {book.title}")
    lines.append("")

    if book.author:
        lines.append(f"**Author:** {book.author}")
    if book.publisher:
        lines.append(f"**Publisher:** {book.publisher}")
    if book.year:
        lines.append(f"**Year:** {book.year}")
    lines.append("")
    lines.append("## Notes")
    lines.append("")

    filename = "Book - " + _sanitize_filename(book.title)
    if book.language != "en":
        filename += f"_{book.language}"
    filename += ".md"

    return filename, "\n".join(lines)


def generate_base_file(books: list[Book]) -> str:
    """Generate books.base content following webclips.base pattern."""
    categories = sorted({b.category for b in books if b.category})

    lines = [
        "views:",
        "  - type: table",
        '    name: All',
        "    filters:",
        "      and:",
        '        - file.tags.contains("book")',
        "    order:",
        "      - file.name",
        "      - author",
        "      - year",
        "      - category",
        "      - language",
        "      - status",
        "      - rating",
        "      - file.tags",
        "    sort:",
        "      - property: category",
        "        direction: ASC",
        "    columnSize:",
        "      file.name: 400",
    ]

    # By Category views
    for cat in categories:
        lines.extend([
            "  - type: table",
            f'    name: "{cat}"',
            "    filters:",
            "      and:",
            '        - file.tags.contains("book")',
            f'        - category.contains("{cat}")',
            "    order:",
            "      - file.name",
            "      - author",
            "      - year",
            "      - language",
            "      - status",
            "      - rating",
            "      - file.tags",
            "    sort:",
            "      - property: year",
            "        direction: DESC",
            "    columnSize:",
            "      file.name: 400",
        ])

    # Unread view
    lines.extend([
        "  - type: table",
        '    name: Unread',
        "    filters:",
        "      and:",
        '        - file.tags.contains("book")',
        '        - status.contains("unread")',
        "    order:",
        "      - file.name",
        "      - author",
        "      - year",
        "      - category",
        "      - language",
        "      - file.tags",
        "    sort:",
        "      - property: category",
        "        direction: ASC",
        "    columnSize:",
        "      file.name: 400",
    ])

    # Reading view
    lines.extend([
        "  - type: table",
        '    name: Reading',
        "    filters:",
        "      and:",
        '        - file.tags.contains("book")',
        '        - status.contains("reading")',
        "    order:",
        "      - file.name",
        "      - author",
        "      - year",
        "      - category",
        "      - language",
        "      - rating",
        "      - file.tags",
        "    sort:",
        "      - property: file.name",
        "        direction: ASC",
        "    columnSize:",
        "      file.name: 400",
    ])

    # Japanese view
    lines.extend([
        "  - type: table",
        '    name: Japanese',
        "    filters:",
        "      and:",
        '        - file.tags.contains("book")',
        '        - language.contains("ja")',
        "    order:",
        "      - file.name",
        "      - author",
        "      - year",
        "      - category",
        "      - status",
        "      - rating",
        "      - file.tags",
        "    sort:",
        "      - property: category",
        "        direction: ASC",
        "    columnSize:",
        "      file.name: 400",
    ])

    return "\n".join(lines) + "\n"


def generate_template() -> str:
    """Generate Templater book template."""
    return """---
created: <% tp.date.now("YYYY-MM-DD HH:mm") %>
title: "<% tp.file.title %>"
author: ""
year:
publisher: ""
category:
language: en
formats: [pdf]
status: unread
rating:
tags: [book]
---

# <% tp.file.title %>

**Author:**
**Publisher:**
**Year:**

## Notes

"""


def plan_obsidian(books: list[Book]) -> list[tuple[str, str]]:
    """Plan Obsidian note generation.

    Returns list of (filepath, content) tuples.
    """
    now = datetime.now()
    results = []

    for book in books:
        filename, content = generate_note(book, now)
        filepath = str(NOTES_DIR / filename)
        results.append((filepath, content))

    # Base file
    base_content = generate_base_file(books)
    results.append((str(BASE_FILE), base_content))

    # Template
    tpl_content = generate_template()
    results.append((str(TEMPLATE_DIR / "book.tpl.md"), tpl_content))

    return results


def apply_obsidian(plans: list[tuple[str, str]]) -> list[str]:
    """Write Obsidian notes and files. Returns list of created paths."""
    created = []
    for filepath, content in plans:
        p = Path(filepath)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        created.append(filepath)
    return created
