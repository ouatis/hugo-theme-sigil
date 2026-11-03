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

The baseline is a committed snapshot, ``scripts/ci/api-baseline.json``,
captured from the pre-rewrite ``v0.12.0`` tag (commit 45ef3cf). It is not a
git ref any more: the 2026-11-03 history rewrite moved every tag onto the new
root commit, so ``git show v0.12.0:docs/api.md`` would now return the current
file and the guard would compare the document with itself. A file cannot be
re-pointed by a force push.

Updating the snapshot is a deliberate act, not a way to make a red build
green: regenerate it only when the frozen surface is intentionally raised
(the snapshot grows), never to absorb an identifier that just disappeared.

``--source git`` remains for ad-hoc checks against another ref; the default
``--source snapshot`` is what CI runs.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys

DEFAULT_SNAPSHOT = "scripts/ci/api-baseline.json"
DEFAULT_REF = "v0.12.0"
DEFAULT_DOC = "docs/api.md"

FENCE_RE = re.compile(r"^(```|~~~).*?^\1[^\n]*$", re.DOTALL | re.MULTILINE)
INLINE_CODE_RE = re.compile(r"(?<!`)(`+)(?P<code>[^`\n]+?)\1(?!`)")
# `...` is prose ellipsis, not a frozen identifier.
ELLIPSIS = {"...", "…"}


def read_snapshot(path: str) -> list[str]:
    """Return the frozen identifier list from the committed snapshot."""
    try:
        with open(path, encoding="utf-8") as handle:
            payload = json.load(handle)
    except OSError as exc:
        raise SystemExit(f"api-guard: cannot read snapshot {path}: {exc}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"api-guard: {path} is not valid JSON: {exc}")
    identifiers = payload.get("identifiers")
    if not isinstance(identifiers, list) or not identifiers:
        raise SystemExit(
            f"api-guard: {path} has no non-empty 'identifiers' list — "
            "a missing baseline must fail loudly rather than compare against an empty set"
        )
    origin = payload.get("captured_from", "an unknown revision")
    commit = payload.get("captured_commit", "")
    if commit:
        # ASCII only: this also runs on Windows consoles with a legacy code page,
        # where an em dash prints as mojibake.
        print(f"api-guard: baseline snapshot from {origin} ({commit[:7]}) at {path}")
    return [str(item) for item in identifiers]


def read_document(ref: str, path: str, source: str) -> str:
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
    parser.add_argument(
        "--source",
        choices=("snapshot", "git", "local"),
        default="snapshot",
        help="where the baseline comes from (default: snapshot, the committed file)",
    )
    parser.add_argument("--snapshot", default=DEFAULT_SNAPSHOT, help="baseline snapshot path")
    parser.add_argument(
        "--ref",
        default=os.environ.get("API_BASELINE_REF", DEFAULT_REF),
        help="git ref for --source git (default: v0.12.0)",
    )
    parser.add_argument("--baseline-doc", default=DEFAULT_DOC, help="baseline document path")
    parser.add_argument("--current-doc", default=DEFAULT_DOC, help="current document path")
    args = parser.parse_args()

    if args.source == "snapshot":
        old_ids = read_snapshot(args.snapshot)
        origin = f"snapshot {args.snapshot}"
    else:
        old_ids = identifiers(read_document(args.ref, args.baseline_doc, args.source))
        origin = f"{args.source} {args.ref}:{args.baseline_doc}"

    try:
        with open(args.current_doc, encoding="utf-8") as handle:
            new_text = handle.read()
    except OSError as exc:
        raise SystemExit(f"api-guard: cannot read current document {args.current_doc}: {exc}")

    new_ids = set(identifiers(new_text))
    removed = sorted({ident for ident in old_ids if ident not in new_ids})
    if removed:
        print(f"FAIL: {args.current_doc} dropped {len(removed)} identifier(s) from {origin}:")
        for ident in removed:
            print(f"  - {ident}")
        print(
            "The API is frozen: renames need a deprecation window, removals a major "
            "release. Restore the old identifier or document the deprecation. Do not "
            f"regenerate {args.snapshot} to silence this."
        )
        return 1

    print(
        f"OK: {len(set(old_ids))} baseline identifiers still present "
        f"({origin} -> {args.current_doc})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
