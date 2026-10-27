#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Write the lines Claude Code's agent shell needs into $CLAUDE_ENV_FILE.

    claude-agent-env <file>

Installed as ~/bin/claude-agent-env (a chezmoi symlink to this file) and called
by the user-level SessionStart hook that merge_agent_env_hook.py wires. Claude
Code sources that file before every Bash command, after its shell snapshot --
the only point where PATH edits survive. ~/.zshenv runs too early: the snapshot
overwrites PATH after it.

    mise hook-env   The snapshot freezes PATH at session start and mise's prompt
                    hook never fires, so project _.path and [env] never apply.
                    Re-deriving per command costs ~30ms and follows each
                    command's starting cwd (a `cd` inside one command doesn't).
    not-found       The snapshot also captures pay-respects'
                    command_not_found_handler, so a missing command exits 0 and
                    fakes a green run. Unsetting it restores exit 127. Both
                    names: zsh's handler and bash's handle.

Idempotent. Other hooks' lines stay; stale or duplicate marked lines collapse to
the current set. Stdlib only, 3.9-compatible (macOS system python3).
"""

from __future__ import annotations

import sys
from pathlib import Path

# Distinct from lit-ui-router's '# mise agent_env' so the two never strip each
# other's lines while both are wired.
MARKER = "# claude-agent-env"

# The shell that sources the lines picks its own -s flag.
WANT = [
    f'eval "$(mise hook-env -s ${{ZSH_VERSION:+zsh}}${{BASH_VERSION:+bash}})" {MARKER}',
    # zsh's unset -f returns 1 when either name is missing.
    f"unset -f command_not_found_handler command_not_found_handle 2>/dev/null || : {MARKER}",
]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: claude-agent-env <file>", file=sys.stderr)
        return 2
    path = Path(argv[1])

    try:
        text = path.read_text()
    except FileNotFoundError:
        text = ""
    lines = text.splitlines()
    seen = [ln for ln in lines if ln.endswith(MARKER)]

    if seen == WANT:
        return 0

    if not seen:
        # Claude Code runs SessionStart hooks in parallel, and others may write
        # this file too. Append when there's nothing to replace: concurrent
        # small appends don't clobber each other, while read-then-rewrite would
        # drop a sibling's lines.
        with path.open("a") as fh:
            fh.write(
                ("\n" if text and not text.endswith("\n") else "")
                + "\n".join(WANT)
                + "\n"
            )
        return 0

    # Rewrite only to clear stale or duplicate marked lines.
    kept = [ln for ln in lines if not ln.endswith(MARKER)]
    path.write_text("\n".join(kept + WANT) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
