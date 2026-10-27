#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Merge the claude-agent-env SessionStart hook into Claude Code's settings.json.

Run by run_onchange_after_21-claude-agent-env-hook.sh on `chezmoi apply`; see
claude_agent_env.py for what the hook does and why.

settings.json is not chezmoi-managed, so this asserts one hook entry and leaves
everything else alone, the way rtk-hook does: our entry is found by the
"claude-agent-env" substring and repointed if it drifted. Other hooks, other
SessionStart groups, and every other setting survive untouched. An unparseable
settings.json is never rewritten.

Stdlib only, and 3.9-compatible: this runs at bootstrap under macOS's system
python3, before mise has installed anything.

Prints only when it changes something, so a clean apply stays silent.
"""

from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path

MARKER = "claude-agent-env"

# `[ -z ] ||` exits 0 when unset; `[ -n ] &&` would exit 1, which Claude Code
# reports as a hook error.
HOOK = '[ -z "$CLAUDE_ENV_FILE" ] || "$HOME/bin/claude-agent-env" "$CLAUDE_ENV_FILE"'


def merge(settings: dict) -> list[str]:
    """Assert our hook in place; return what changed (empty if nothing)."""
    hooks = settings.setdefault("hooks", {})
    start = hooks.setdefault("SessionStart", [])
    ours = [
        h
        for group in start
        if isinstance(group, dict)
        for h in group.get("hooks") or []
        if isinstance(h, dict) and MARKER in str(h.get("command", ""))
    ]
    if not ours:
        start.append({"hooks": [{"type": "command", "command": HOOK}]})
        return ["added SessionStart hook"]
    changes = []
    for h in ours:
        if h.get("command") != HOOK:
            h["command"] = HOOK
            changes.append("repointed SessionStart hook at the current command")
    return changes


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else Path.home() / ".claude" / "settings.json"

    try:
        settings = json.loads(path.read_text())
    except FileNotFoundError:
        settings = {}
    except (OSError, ValueError) as exc:  # unreadable, bad UTF-8, or bad JSON
        print(
            f"claude-agent-env: could not parse {path} ({exc}); leaving it alone",
            file=sys.stderr,
        )
        return 0
    if not isinstance(settings, dict):
        print(
            f"claude-agent-env: {path} is not a JSON object; leaving it alone",
            file=sys.stderr,
        )
        return 0

    changes = merge(settings)
    if not changes:
        return 0

    if path.exists():
        shutil.copyfile(path, f"{path}.claude-agent-env.bak")
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(settings, indent=2) + "\n")
    os.replace(tmp, path)  # atomic; never a half-written settings.json
    for c in changes:
        print(
            f"claude-agent-env: {c}. Restart Claude Code so it reloads settings.json."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
