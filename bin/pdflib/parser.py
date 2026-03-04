"""Filename parser for PDF/epub files.

Priority-ordered regex matching:
1. Author - Title-Publisher (Year)  (Anna's Archive style included)
2. Title -- Author -- ... Year -- Publisher  (-- separated)
3. Title-Publisher (Year)  (no author)
4. Title (Year)  (no publisher)
5. Title only  (fallback)

Pre-processing removes: -ja, -ja_doclingo.ai, -ja_en.ai, .jp,
libgen.li, Anna's Archive, [Team-IRA]
Post-processing: _ → : in titles, _ → , in authors
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class ParseResult:
    title: str
    author: Optional[str] = None
    year: Optional[int] = None
    publisher: Optional[str] = None
    language: str = "en"
    is_translation: bool = False
    suffix_tag: Optional[str] = None  # e.g. "origin"


# Suffixes that indicate Japanese translation
_JA_SUFFIXES = [
    r"-ja_doclingo\.ai",
    r"-ja_en\.ai",
    r"-ja",
    r"\.jp",
]

# Noise to strip
_NOISE_PATTERNS = [
    r"\s*-\s*libgen\.li",
    r"\s*--\s*[0-9a-f]{32}\s*--\s*Anna's Archive",
    r"\s*--\s*Anna's Archive",
    r"\s*\[Team-IRA\]",
    r"\.origin$",
]


def _preprocess(stem: str) -> tuple[str, str, bool, Optional[str]]:
    """Clean filename stem. Returns (cleaned, language, is_translation, suffix_tag)."""
    language = "en"
    is_translation = False
    suffix_tag = None

    # Detect .origin suffix
    if stem.endswith(".origin"):
        suffix_tag = "origin"
        stem = stem[: -len(".origin")]

    # Detect Japanese translation suffixes
    for pat in _JA_SUFFIXES:
        m = re.search(pat + "$", stem)
        if m:
            language = "ja"
            is_translation = True
            stem = stem[: m.start()]
            break

    # Detect _lang, (lang), or [lang] suffix from normalized format
    m = re.search(r"(?:\s*[(\[]([a-z]{2})[)\]]|_([a-z]{2}))$", stem)
    if m:
        lang = m.group(1) or m.group(2)
        if lang != "en":
            language = lang
            is_translation = True
        stem = stem[: m.start()]

    # Remove noise
    for pat in _NOISE_PATTERNS:
        stem = re.sub(pat, "", stem)

    # Collapse multiple spaces (but don't replace _ yet — do it per-field after parsing)
    stem = re.sub(r"\s+", " ", stem).strip()

    return stem, language, is_translation, suffix_tag


def _clean_title(raw: str) -> str:
    """Post-process a parsed title: truncate at colon-encoded subtitle, remove unsafe chars.

    Only "_ " (original colon in filename) is treated as a subtitle separator.
    " - " is preserved as it may be part of the actual title.
    """
    t = raw
    # "Title_ Subtitle" → take "Title" only (underscore-space = original colon)
    if "_ " in t:
        t = t.split("_ ", 1)[0]
    t = t.replace(":", " -").replace("[", "(").replace("]", ")")
    t = t.replace("#", "").replace("^", "")
    return re.sub(r"\s+", " ", t).strip()


def _clean_author(raw: str) -> str:
    """Post-process a parsed author: _ → , (multiple authors)."""
    return re.sub(r"\s*_\s*", ", ", raw).strip()


# Pattern N: "Author - Title (Year)" (normalized format — no publisher)
# Must be tried BEFORE Pattern 1 to prevent hyphenated titles from being
# split into title + publisher (e.g. "Data-Intensive" → "Data" + "Intensive").
_PAT_NORMALIZED = re.compile(
    r"^(?P<author>.+?)\s+-\s+(?P<title>.+?)\s*\((?P<year>\d{4})\)$"
)

# Pattern 1: "Author - Title-Publisher (Year)"
# Title is GREEDY (.+) so it captures up to the LAST -Publisher before (Year)
_PAT1 = re.compile(
    r"^(?P<author>.+?)\s+-\s+(?P<title>.+)-(?P<publisher>[^(-]+?)\s*\((?P<year>\d{4})\)$"
)

# Pattern 2: "Title -- Author -- ... Year -- Publisher"
_PAT2 = re.compile(
    r"^(?P<title>.+?)\s+--\s+(?P<author>[^-]+?)\s+--\s+.*?(?P<year>\d{4})\s+--\s+(?P<publisher>.+?)(?:\s+--\s+.*)?$"
)

# Pattern 3: "Title-Publisher (Year)" (no author)
# Title is GREEDY to capture hyphens in titles like "Data-Intensive"
# (?<!\s)- ensures we don't match " - " (author separator) as publisher separator
_PAT3 = re.compile(
    r"^(?P<title>.+)(?<!\s)-(?P<publisher>[^(-]+?)\s*\((?P<year>\d{4}(?:[/_]\d{4})?)\)$"
)

# Pattern 4: "Title (Year)" (no publisher)
_PAT4 = re.compile(r"^(?P<title>.+?)\s*\((?P<year>\d{4})\)$")

# Japanese prefix pattern: "日本語タイトル - English Title-Publisher..."
_JA_PREFIX = re.compile(r"^[\u3000-\u9fff\uff00-\uffef]+\s+")


def parse_filename(filepath: str | Path) -> ParseResult:
    """Parse a PDF/epub filename into structured metadata."""
    path = Path(filepath)
    stem = path.stem
    cleaned, language, is_translation, suffix_tag = _preprocess(stem)

    # Check for Japanese title prefix (e.g. "プログラマが知るべき97のこと - 97 Things...")
    ja_match = _JA_PREFIX.match(cleaned)
    if ja_match:
        language = "ja"
        is_translation = True

    # Try patterns in order
    # Pattern N: Author - Title (Year) — normalized format, no publisher
    m = _PAT_NORMALIZED.match(cleaned)
    if m:
        return ParseResult(
            title=_clean_title(m.group("title")),
            author=_clean_author(m.group("author")),
            year=int(m.group("year")),
            language=language,
            is_translation=is_translation,
            suffix_tag=suffix_tag,
        )

    # Pattern 1: Author - Title-Publisher (Year)
    m = _PAT1.match(cleaned)
    if m:
        author = _clean_author(m.group("author"))
        title = _clean_title(m.group("title"))
        publisher = m.group("publisher").strip()
        year_str = m.group("year")
        return ParseResult(
            title=title,
            author=author if author else None,
            year=int(year_str),
            publisher=publisher,
            language=language,
            is_translation=is_translation,
            suffix_tag=suffix_tag,
        )

    # Pattern 2: Title -- Author -- ... Year -- Publisher
    m = _PAT2.match(cleaned)
    if m:
        return ParseResult(
            title=_clean_title(m.group("title")),
            author=_clean_author(m.group("author")),
            year=int(m.group("year")),
            publisher=m.group("publisher").strip(),
            language=language,
            is_translation=is_translation,
            suffix_tag=suffix_tag,
        )

    # Pattern 3: Title-Publisher (Year)
    m = _PAT3.match(cleaned)
    if m:
        year_str = m.group("year")
        # Handle "2006_2008" → take first year
        year = int(year_str.split("/")[0].split("_")[0])
        return ParseResult(
            title=_clean_title(m.group("title")),
            publisher=m.group("publisher").strip(),
            year=year,
            language=language,
            is_translation=is_translation,
            suffix_tag=suffix_tag,
        )

    # Pattern 4: Title (Year)
    m = _PAT4.match(cleaned)
    if m:
        return ParseResult(
            title=_clean_title(m.group("title")),
            year=int(m.group("year")),
            language=language,
            is_translation=is_translation,
            suffix_tag=suffix_tag,
        )

    # Fallback: title only
    return ParseResult(
        title=_clean_title(cleaned),
        language=language,
        is_translation=is_translation,
        suffix_tag=suffix_tag,
    )
