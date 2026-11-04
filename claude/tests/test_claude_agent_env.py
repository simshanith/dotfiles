from __future__ import annotations

from typing import TYPE_CHECKING

from script_loader import load

if TYPE_CHECKING:
    from pathlib import Path

env = load("claude_agent_env", "claude/claude_agent_env.py")


def run(path: Path) -> int:
    return int(env.main(["claude-agent-env", str(path)]))


def test_creates_the_file(tmp_path: Path) -> None:
    path = tmp_path / "env"
    assert run(path) == 0
    assert path.read_text().splitlines() == env.WANT


def test_appends_after_other_hooks_lines(tmp_path: Path) -> None:
    path = tmp_path / "env"
    path.write_text("export OTHER=1")  # no trailing newline
    run(path)
    assert path.read_text().splitlines() == ["export OTHER=1", *env.WANT]


def test_idempotent(tmp_path: Path) -> None:
    path = tmp_path / "env"
    run(path)
    before = path.read_text()
    run(path)
    assert path.read_text() == before


def test_replaces_stale_and_duplicate_lines(tmp_path: Path) -> None:
    path = tmp_path / "env"
    stale = f"old line {env.MARKER}"
    path.write_text(f"export OTHER=1\n{stale}\n{stale}\n")
    run(path)
    assert path.read_text().splitlines() == ["export OTHER=1", *env.WANT]


def test_usage_error() -> None:
    assert env.main(["claude-agent-env"]) == 2
    assert env.main(["claude-agent-env", "a", "b"]) == 2
