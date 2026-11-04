from __future__ import annotations

import json
from typing import TYPE_CHECKING

from script_loader import load

if TYPE_CHECKING:
    from pathlib import Path

    import pytest

hook = load("merge_agent_env_hook", "claude/merge_agent_env_hook.py")


def ours(settings: dict[str, object]) -> list[str]:
    groups = settings["hooks"]["SessionStart"]  # type: ignore[index]
    return [h["command"] for g in groups for h in g["hooks"] if hook.MARKER in h["command"]]


def test_adds_hook_to_empty_settings() -> None:
    settings: dict[str, object] = {}
    assert hook.merge(settings) == ["added SessionStart hook"]
    assert ours(settings) == [hook.HOOK]


def test_second_merge_is_a_no_op() -> None:
    settings: dict[str, object] = {}
    hook.merge(settings)
    assert hook.merge(settings) == []


def test_repoints_a_drifted_entry_and_keeps_others() -> None:
    other = {"type": "command", "command": "other-tool"}
    settings: dict[str, object] = {
        "model": "x",
        "hooks": {
            "SessionStart": [
                {"hooks": [other, {"type": "command", "command": "old claude-agent-env"}]}
            ]
        },
    }
    assert hook.merge(settings) == ["repointed SessionStart hook at the current command"]
    assert ours(settings) == [hook.HOOK]
    assert other in settings["hooks"]["SessionStart"][0]["hooks"]  # type: ignore[index]
    assert settings["model"] == "x"


def test_main_writes_backup_and_reports(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    path = tmp_path / "settings.json"
    path.write_text('{"model": "x"}')
    assert hook.main(["merge", str(path)]) == 0
    assert ours(json.loads(path.read_text())) == [hook.HOOK]
    assert (tmp_path / "settings.json.claude-agent-env.bak").read_text() == '{"model": "x"}'
    assert "added SessionStart hook" in capsys.readouterr().out


def test_main_is_silent_when_nothing_changes(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    path = tmp_path / "settings.json"
    hook.main(["merge", str(path)])
    capsys.readouterr()
    before = path.read_text()
    assert hook.main(["merge", str(path)]) == 0
    assert path.read_text() == before
    assert capsys.readouterr().out == ""


def test_main_never_rewrites_unparseable_settings(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    path = tmp_path / "settings.json"
    for content in ("{not json", "[1, 2]"):
        path.write_text(content)
        assert hook.main(["merge", str(path)]) == 0
        assert path.read_text() == content
        assert "leaving it alone" in capsys.readouterr().err
