#!/usr/bin/env python3
"""pdflib — PDF library management CLI.

Commands:
  scan      Scan ~/Documents/PDF/ and build catalog.json
  rename    Normalize filenames (--dry-run / --apply)
  chapters  Organize chapter PDFs into _chapters/ (--dry-run / --apply)
  obsidian  Generate Obsidian notes and .base file (--dry-run / --apply)
  upload    Upload PDFs to Google Drive via rclone (--dry-run / --apply)
  search    Search catalog by title/author/tag
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def cmd_scan(args: argparse.Namespace) -> None:
    from .catalog import save_catalog, scan

    print("Scanning ~/Documents/PDF/ ...")
    books = scan()
    out = save_catalog(books)
    print(f"Catalog saved: {out}")
    print(f"Total books: {len(books)}")

    needs_review = [b for b in books if b.needs_review]
    if needs_review:
        print(f"\nNeeds review ({len(needs_review)}):")
        for b in needs_review:
            missing = []
            if not b.author:
                missing.append("author")
            if not b.year:
                missing.append("year")
            print(f"  - {b.title} (missing: {', '.join(missing)})")


def cmd_rename(args: argparse.Namespace) -> None:
    from .catalog import scan, plan_renames, apply_renames, save_catalog

    # Always scan fresh to detect files needing renames
    print("Scanning files...")
    books = scan()
    if not books:
        print("No PDF files found.")
        return

    renames = plan_renames(books)
    if not renames:
        print("No renames needed.")
        save_catalog(books)
        return

    print(f"Planned renames ({len(renames)}):")
    for old, new in renames:
        print(f"  {old.name}")
        print(f"  → {new.name}")
        print()

    if args.apply:
        done = apply_renames(renames)
        # Only update catalog for successfully renamed files
        done_set = {str(old) for old, _ in done}
        for book in books:
            for fmt in book.formats:
                if fmt.normalized_filename:
                    old_path = Path(fmt.path)
                    full_old = str(Path.home() / "Documents" / "PDF" / fmt.path)
                    if full_old in done_set:
                        fmt.path = str(old_path.parent / fmt.normalized_filename)
                        fmt.original_filename = fmt.normalized_filename
                    fmt.normalized_filename = None
        save_catalog(books)
        print(f"Applied {len(done)} renames. Catalog updated.")
    else:
        # Clear normalized_filename flags (dry-run, no rename applied)
        for book in books:
            for fmt in book.formats:
                fmt.normalized_filename = None
        save_catalog(books)
        print("(dry-run — use --apply to execute)")


def cmd_chapters(args: argparse.Namespace) -> None:
    from .catalog import plan_chapters, apply_chapter_moves

    moves = plan_chapters()
    if not moves:
        print("No chapter directories to move.")
        return

    print(f"Planned chapter moves ({len(moves)}):")
    for old, new in moves:
        print(f"  {old.relative_to(Path.home() / 'Documents/PDF')}")
        print(f"  → {new.relative_to(Path.home() / 'Documents/PDF')}")
        print()

    if args.apply:
        done = apply_chapter_moves(moves)
        print(f"Applied {len(done)} moves.")
    else:
        print("(dry-run — use --apply to execute)")


def cmd_obsidian(args: argparse.Namespace) -> None:
    from .catalog import load_catalog
    from .obsidian import plan_obsidian, apply_obsidian

    books = load_catalog()
    if not books:
        print("No catalog found. Run 'pdflib scan' first.")
        return

    plans = plan_obsidian(books)
    notes = [p for p in plans if p[0].endswith(".md") and "book.tpl.md" not in p[0] and "books.base" not in p[0]]
    base = [p for p in plans if p[0].endswith(".base")]
    tpl = [p for p in plans if "book.tpl.md" in p[0]]

    print(f"Planned Obsidian output:")
    print(f"  Notes: {len(notes)}")
    if base:
        print(f"  Base file: {base[0][0]}")
    if tpl:
        print(f"  Template: {tpl[0][0]}")

    if args.verbose:
        print("\nNotes to create:")
        for filepath, _ in notes:
            print(f"  {Path(filepath).name}")

    if args.apply:
        created = apply_obsidian(plans)
        print(f"\nCreated {len(created)} files.")
    else:
        print("\n(dry-run — use --apply to execute)")


def cmd_upload(args: argparse.Namespace) -> None:
    from .catalog import load_catalog, save_catalog
    from .gdrive import collect_targets, upload_all

    books = load_catalog()
    if not books:
        print("No catalog found. Run 'pdflib scan' first.")
        return

    category = getattr(args, "category", None)

    if args.apply:
        uploaded = upload_all(books, category=category, force=args.force)
        save_catalog(books)
        print(f"\nUploaded {len(uploaded)} files. Catalog updated.")
    else:
        targets = collect_targets(books, category=category, force=args.force)
        if not targets:
            print("No files to upload (all already have gdrive_url).")
            return
        print(f"Files to upload ({len(targets)}):")
        for book, fmt in targets:
            print(f"  [{book.category}] {fmt.original_filename}")
        print("\n(dry-run — use --apply to execute)")


def cmd_search(args: argparse.Namespace) -> None:
    from .catalog import load_catalog

    books = load_catalog()
    if not books:
        print("No catalog found. Run 'pdflib scan' first.")
        return

    query = args.query.lower()
    results = []
    for b in books:
        searchable = f"{b.title} {b.author or ''} {' '.join(b.tags)} {b.category}".lower()
        if query in searchable:
            results.append(b)

    if not results:
        print(f"No results for '{args.query}'")
        return

    print(f"Results ({len(results)}):")
    for b in results:
        author_str = f" by {b.author}" if b.author else ""
        year_str = f" ({b.year})" if b.year else ""
        formats = ", ".join(f.format for f in b.formats)
        print(f"  [{b.category}] {b.title}{author_str}{year_str} [{formats}]")


def main() -> None:
    parser = argparse.ArgumentParser(prog="pdflib", description="PDF library manager")
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("scan", help="Scan and build catalog")

    p_rename = sub.add_parser("rename", help="Normalize filenames")
    p_rename.add_argument("--apply", action="store_true", help="Apply renames (default: dry-run)")

    p_chapters = sub.add_parser("chapters", help="Organize chapter PDFs")
    p_chapters.add_argument("--apply", action="store_true", help="Apply moves (default: dry-run)")

    p_obsidian = sub.add_parser("obsidian", help="Generate Obsidian notes")
    p_obsidian.add_argument("--apply", action="store_true", help="Apply generation (default: dry-run)")
    p_obsidian.add_argument("-v", "--verbose", action="store_true", help="Show all planned notes")

    p_upload = sub.add_parser("upload", help="Upload PDFs to Google Drive")
    p_upload.add_argument("--apply", action="store_true", help="Execute upload (default: dry-run)")
    p_upload.add_argument("--category", help="Filter by category (e.g. Go)")
    p_upload.add_argument("--force", action="store_true", help="Re-upload even if gdrive_url exists")

    p_search = sub.add_parser("search", help="Search catalog")
    p_search.add_argument("query", help="Search query")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    commands = {
        "scan": cmd_scan,
        "rename": cmd_rename,
        "chapters": cmd_chapters,
        "obsidian": cmd_obsidian,
        "upload": cmd_upload,
        "search": cmd_search,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
