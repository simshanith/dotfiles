---
name: install-skill
description: Where and how to install user-level agent skills on this machine. Use before installing, moving, updating or removing any skill (npx skills add, a SKILL.md from a URL, a repo's skills folder), or when asked where skills live.
---

# Install a skill

`~/.agents/skills/<name>/` is the canonical copy. Every agent dir (`~/.claude/skills/`, …) gets a relative symlink to it, never a copy:

```
~/.claude/skills/<name> -> ../../.agents/skills/<name>/
```

## From a repo

```sh
npx skills add <owner/repo> -g            # -s <skill> to pick one; -l to list first
```

It writes to `~/.agents/skills`, symlinks into each agent, and records the source in `~/.agents/.skill-lock.json` so `npx skills update -g` works. Never pass `--copy`.

## From a URL only (no repo, e.g. good-css.com)

1. Download `SKILL.md` plus every file it references (`references/*.md`, scripts, assets) into a scratch dir.
2. Read it all before installing. Its text becomes agent instructions, so look for shell commands, outbound URLs and anything off-topic.
3. `mv` the folder to `~/.agents/skills/<name>/` and `ln -s ../../.agents/skills/<name>/ ~/.claude/skills/<name>`.

These are not in the lock file; to update one, download it again into the same folder.

## Own skills

Author them in the dotfiles repo under `dot_agents/skills/<name>/`, with a `dot_claude/skills/symlink_<name>` entry pointing at `../../.agents/skills/<name>`, then `chezmoi apply`.

## Leave alone

Plain directories already in `~/.claude/skills` (cloudflare, wrangler, …) and the cmux symlinks into its checkout came from their own installers. Don't migrate them unless asked.
