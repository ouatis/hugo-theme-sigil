#!/usr/bin/env bash
# Resolve a working Python 3 interpreter for the scripts in this directory.
#
# Sourced, not executed:
#     . "$SG_THEME_ROOT/scripts/lib-python.sh"
#     sg_resolve_python || fail "no working python3 (set SG_PYTHON)"
# Sets SG_PY in the caller's shell.
#
# Why this exists: on Windows, `python3` is usually the Microsoft Store
# app-execution stub. It sits on PATH — so `command -v python3` succeeds —
# but every invocation exits 49 with no output, which kills a script at its
# first Python heredoc with no error message at all. Probing PATH is
# therefore not enough; each candidate must actually run. SG_PYTHON wins
# over the search and must be a path Git Bash can see (POSIX form:
# /c/Users/.../python); a broken SG_PYTHON is an error, not a silent
# fallback, so a typo cannot quietly select a different interpreter.

sg_resolve_python() {
    local candidate
    if [ -n "${SG_PYTHON:-}" ]; then
        if ! command -v "$SG_PYTHON" >/dev/null 2>&1 \
           || ! "$SG_PYTHON" -c 'import sys' >/dev/null 2>&1; then
            echo "lib-python: SG_PYTHON=$SG_PYTHON is not a working python3" >&2
            return 1
        fi
        SG_PY="$SG_PYTHON"
        return 0
    fi
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1 \
           && "$candidate" -c 'import sys' >/dev/null 2>&1; then
            SG_PY="$candidate"
            return 0
        fi
    done
    echo "lib-python: no working python3 found (tried python3, python)" >&2
    return 1
}
