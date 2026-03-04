"""Google Drive upload via rclone."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Optional

from .catalog import PDF_ROOT
from .models import Book, FileFormat

RCLONE_REMOTE = "gdrive"
DRIVE_ROOT = "PDF"


def check_rclone() -> None:
    """Verify rclone is installed and the remote is configured."""
    if not shutil.which("rclone"):
        raise RuntimeError(
            "rclone not found. Install with: brew install rclone"
        )
    result = subprocess.run(
        ["rclone", "listremotes"],
        capture_output=True,
        text=True,
    )
    remotes = result.stdout.strip().splitlines()
    if f"{RCLONE_REMOTE}:" not in remotes:
        raise RuntimeError(
            f"rclone remote '{RCLONE_REMOTE}' not configured. "
            f"Run: rclone config"
        )


def upload_file(local_path: Path, drive_folder: str) -> Optional[str]:
    """Upload a file to Google Drive and return its share link.

    Args:
        local_path: Full local path to the file.
        drive_folder: Target folder on Google Drive (e.g. "PDF/Go").

    Returns:
        Google Drive share URL, or None on failure.
    """
    dest = f"{RCLONE_REMOTE}:{drive_folder}/"
    result = subprocess.run(
        ["rclone", "copy", str(local_path), dest, "--quiet"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  ERROR upload: {result.stderr.strip()}")
        return None

    remote_path = f"{RCLONE_REMOTE}:{drive_folder}/{local_path.name}"
    result = subprocess.run(
        ["rclone", "link", remote_path],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()

    # Fallback: try to get file ID
    result = subprocess.run(
        ["rclone", "lsf", remote_path, "--format", "i"],
        capture_output=True,
        text=True,
    )
    file_id = result.stdout.strip()
    if file_id:
        return f"https://drive.google.com/file/d/{file_id}/view?usp=sharing"

    print(f"  WARNING: could not get link for {local_path.name}")
    return None


def collect_targets(
    books: list[Book],
    category: Optional[str] = None,
    force: bool = False,
) -> list[tuple[Book, FileFormat]]:
    """Collect (book, format) pairs that need uploading.

    Skips formats that already have gdrive_url unless force=True.
    """
    targets = []
    for book in books:
        if category and book.category.lower() != category.lower():
            continue
        for fmt in book.formats:
            if not force and fmt.gdrive_url:
                continue
            local = PDF_ROOT / fmt.path
            if not local.exists():
                continue
            targets.append((book, fmt))
    return targets


def upload_all(
    books: list[Book],
    category: Optional[str] = None,
    force: bool = False,
) -> list[tuple[Book, FileFormat]]:
    """Upload all pending files to Google Drive.

    Sets gdrive_url on each FileFormat. Returns list of successfully uploaded
    (book, format) pairs.
    """
    check_rclone()
    targets = collect_targets(books, category=category, force=force)
    uploaded = []

    for i, (book, fmt) in enumerate(targets, 1):
        local = PDF_ROOT / fmt.path
        # Mirror local folder structure: Go/book.pdf → PDF/Go/book.pdf
        drive_folder = f"{DRIVE_ROOT}/{Path(fmt.path).parent}"
        # Normalize: "PDF/." → "PDF"
        drive_folder = drive_folder.rstrip("/.")

        print(f"  [{i}/{len(targets)}] {fmt.original_filename} -> {drive_folder}/")
        url = upload_file(local, drive_folder)
        if url:
            fmt.gdrive_url = url
            uploaded.append((book, fmt))
            print(f"    OK: {url}")

    return uploaded
