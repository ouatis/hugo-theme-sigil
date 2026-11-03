#!/usr/bin/env python3
"""Fail if a backtick identifier vanished from docs/api.md since the baseline.

docs/api.md is the frozen public contract. This guard answers one question:
does every inline-code identifier in the baseline still appear somewhere in
the current document? Renaming an identifier usually means editing it in
place; in a diff that looks harmless, and no build breaks. Here it is a CI
failure, with the old name printed so the reviewer can see the rename.

The document is prose, so this is deliberately an *identifier-presence*
check, not a contract-shape parser: an identifier may move between sections
and sentences may change freely. Only removal fails.

Set the baseline ref with --baseline (default: the API_BASELINE env var,
else v0.12.0). The default source is that git ref, read with ``git show
<ref>:<path>`` so a tag's content is authoritative rather than a checked-out
file that a PR could edit. Pass --source local when a filesystem baseline is
needed for a focused test.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

DEFAULT_BASELINE = "v0.12.0"
DEFAULT_DOC = "docs/api.md"

FENCE_RE = re.compile(r"^(```|~~~).*?^\1[^\n]*$", re.DOTALL | re.MULTILINE)
INLINE_CODE_RE = re.compile(r"(?<!`)(`+)(?P<code>[^`\n]+?)\1(?!`)")
# `...` is prose ellipsis, not a frozen identifier.
ELLIPSIS = {"...", "…"}


def read_baseline(ref: str, path: str, source: str) -> str:
    """Return the baseline document from a git ref or from the filesystem."""
    if source == "git":
        try:
            return subprocess.run(
                ["git", "show", f"{ref}:{path}"],
                check=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
            ).stdout
        except (OSError, subprocess.CalledProcessError) as exc:
            detail = getattr(exc, "stderr", "") or str(exc)
            raise SystemExit(f"api-guard: cannot read {path} from {ref}: {detail.strip()}")
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError as exc:
        raise SystemExit(f"api-guard: cannot read local baseline {path}: {exc}")


def identifiers(text: str) -> list[str]:
    """Inline-code spans outside fenced blocks, in stable document order."""
    spans = [m.group("code").strip() for m in INLINE_CODE_RE.finditer(FENCE_RE.sub("", text))]
    return [span for span in spans if span and span not in ELLIPSIS]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--baseline", default=os.environ.get("API_BASELINE", DEFAULT_BASELINE))
    parser.add_argument("--baseline-doc", default=DEFAULT_DOC, help="baseline document path")
    parser.add_argument("--current-doc", default=DEFAULT_DOC, help="current document path")
    parser.add_argument("--baseline-ref", help="read the baseline from `git show <ref>:<path>`")
    parser.add_argument(
        "--source",
        choices=("local", "git"),
        default="git",
        help="where the baseline comes from (default: git; use local for a file)",
    )
    args = parser.parse_args()
    baseline_ref = args.baseline_ref or args.baseline
    old_text = read_baseline(baseline_ref, args.baseline_doc, args.source)
    try:
        with open(args.current_doc, encoding="utf-8") as handle:
            new_text = handle.read()
    except OSError as exc:
        raise SystemExit(f"api-guard: cannot read current document {args.current_doc}: {exc}")

    new_ids = set(identifiers(new_text))
    old_ids = identifiers(old_text)
    removed = sorted({ident for ident in old_ids if ident not in new_ids})
    if removed:
        print(f"FAIL: {args.current_doc} dropped {len(removed)} identifier(s) from {args.baseline}:")
        for ident in removed:
            print(f"  - {ident}")
        print(
            "The API is frozen: renames need a deprecation window, removals a major "
            "release. Restore the old identifier or document the deprecation."
        )
        return 1

    print(
        f"OK: {len(set(old_ids))} baseline identifiers still present "
        f"({args.baseline}: {args.baseline_doc} -> {args.current_doc})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())