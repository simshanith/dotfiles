#!/bin/sh
# Wire rtk into Claude Code, selectively -- the parts of `rtk init -g` we want.
#
# `rtk init -g` is not used: it repoints the Bash PreToolUse hook straight at
# `rtk hook claude`, which re-arms every handler rtk ships (33 of them, 21 never
# invoked in 90 days), and it overwrites ~/.claude/RTK.md with guidance claiming
# everything is rewritten. This asserts only the two bits we actually want, and
# re-asserts them on every `chezmoi apply`, so a stray `rtk init -g` self-heals.
#
#   1. PreToolUse[Bash] -> ~/bin/rtk-allowlist-hook   (the allowlist gate)
#   2. ~/.claude/CLAUDE.md includes @RTK.md           (chezmoi owns RTK.md)
#
# Touches only those two things. Other hooks, matchers, and CLAUDE.md content are
# left exactly as found. No-ops silently when Claude Code or python3 is absent.

set -eu

CLAUDE_DIR="$HOME/.claude"
[ -d "$CLAUDE_DIR" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$CLAUDE_DIR" <<'PY'
import json
import os
import sys

claude_dir = sys.argv[1]
settings_path = os.path.join(claude_dir, "settings.json")
memory_path = os.path.join(claude_dir, "CLAUDE.md")

WRAPPER = 'if [ -x "$HOME/bin/rtk-allowlist-hook" ]; then "$HOME/bin/rtk-allowlist-hook"; fi'
changes = []

# --- 1. Bash PreToolUse hook -------------------------------------------------
# Only rewrite an entry that is already rtk's (or already ours). A Bash hook
# pointing at something else belongs to another tool and is left alone.
RTK_COMMANDS = ("rtk hook claude", WRAPPER)

try:
    with open(settings_path) as handle:
        settings = json.load(handle)
except FileNotFoundError:
    settings = {}
except Exception:
    settings = None  # unparseable: do not risk truncating the user's settings

if isinstance(settings, dict):
    hooks = settings.setdefault("hooks", {})
    pre = hooks.setdefault("PreToolUse", [])

    bash_entry = next(
        (e for e in pre if isinstance(e, dict) and e.get("matcher") == "Bash"), None
    )
    if bash_entry is None:
        pre.append({"matcher": "Bash", "hooks": [{"type": "command", "command": WRAPPER}]})
        changes.append("added Bash PreToolUse hook")
    else:
        inner = bash_entry.setdefault("hooks", [])
        existing = [h for h in inner if h.get("command") in RTK_COMMANDS]
        if not existing:
            inner.append({"type": "command", "command": WRAPPER})
            changes.append("added allowlist hook alongside existing Bash hooks")
        else:
            for hook in existing:
                if hook.get("command") != WRAPPER:
                    hook["command"] = WRAPPER
                    changes.append("repointed Bash hook from `rtk hook claude`")

    if changes:
        tmp = settings_path + ".tmp"
        with open(tmp, "w") as handle:
            json.dump(settings, handle, indent=2)
            handle.write("\n")
        os.replace(tmp, settings_path)  # atomic; never leaves a half-written file

# --- 2. @RTK.md include ------------------------------------------------------
# Append-only. CLAUDE.md is the user's own global instruction file, so it is not
# chezmoi-managed -- we only ensure the include line is present.
try:
    with open(memory_path) as handle:
        memory = handle.read()
except FileNotFoundError:
    memory = ""
except Exception:
    memory = None

if memory is not None and "@RTK.md" not in memory:
    with open(memory_path, "a") as handle:
        if memory:
            handle.write("\n" if memory.endswith("\n") else "\n\n")
        handle.write("@RTK.md\n")
    changes.append("added @RTK.md include to CLAUDE.md")

for change in changes:
    print(f"rtk: {change}")
PY
