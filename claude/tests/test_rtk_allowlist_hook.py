from __future__ import annotations

import io
import json
import os
import subprocess
import sys
from typing import TYPE_CHECKING, Any

import pytest

if sys.version_info < (3, 14):  # the gate runs via uv on 3.14; its syntax won't parse on 3.9
    pytest.skip("rtk-allowlist-hook needs Python 3.14", allow_module_level=True)

from script_loader import load

if TYPE_CHECKING:
    from pathlib import Path

os.environ["RTK_ALLOWLIST_CONFIG"] = "/nonexistent/rtk-allowlist.toml"  # built-in defaults
gate = load("rtk_allowlist_hook", "private_bin/executable_rtk-allowlist-hook")


@pytest.mark.parametrize(
    ("command", "allowed"),
    [
        ("ls -la", True),
        ("/bin/ls", True),
        ("FOO=1 BAR=2 cat x", True),
        ("git commit -m hi", True),
        ("git -C /tmp commit", True),  # value flag skipped
        ("git -c a=b fetch", True),
        ("git status", False),  # subcommand not allowlisted
        ("git", False),  # bare
        ("git -C", False),
        ("rm -rf /", False),
        ("ls && rm x", False),  # every metachar declines
        ("ls | wc", False),
        ("ls; ls", False),
        ("ls $(x)", False),
        ("ls > f", False),
        ("ls\nls", False),
        ("cat 'unbalanced", False),
        ("FOO-BAR=1 ls", False),  # not a VAR=value prefix
        ("", False),
        ("   ", False),
    ],
)
def test_is_allowed(command: str, *, allowed: bool) -> None:
    assert gate.is_allowed(command) is allowed


def test_config_overrides_and_defaults(tmp_path: Path) -> None:
    config = tmp_path / "allow.toml"
    config.write_text('commands = ["rg", ""]\n[subcommands]\njj = ["log"]\nbad = "x"\n')
    assert gate.load_config(config) == (frozenset({"rg"}), {"jj": frozenset({"log"})})
    config.write_text("not = [valid")
    assert gate.load_config(config) == (gate.DEFAULT_ALLOW, gate.DEFAULT_SUBCOMMANDS)
    assert gate.load_config(tmp_path / "missing.toml")[0] == gate.DEFAULT_ALLOW


@pytest.mark.parametrize(
    ("raw", "command"),
    [
        ('{"tool_name": "Bash", "tool_input": {"command": "ls"}}', "ls"),
        ('{"tool_name": "Edit", "tool_input": {"command": "ls"}}', None),
        ('{"tool_name": "Bash", "tool_input": "ls"}', None),
        ('{"tool_name": "Bash", "tool_input": {"command": 3}}', None),
        ("[1]", None),
        ("not json", None),
    ],
)
def test_bash_command(raw: str, command: str | None) -> None:
    assert gate.bash_command(raw) == command


def run_main(monkeypatch: pytest.MonkeyPatch, raw: str) -> str:
    out = io.StringIO()
    monkeypatch.setattr(sys, "stdin", io.StringIO(raw))
    monkeypatch.setattr(sys, "stdout", out)
    assert gate.main() == 0
    return out.getvalue()


def fake_rtk(stdout: str, returncode: int = 0) -> Any:
    def run(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess([], returncode, stdout=stdout)

    return run


def test_relays_rtk_for_allowed_commands(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(subprocess, "run", fake_rtk('{"rewrite": true}'))
    raw = json.dumps({"tool_name": "Bash", "tool_input": {"command": "ls"}})
    assert run_main(monkeypatch, raw) == '{"rewrite": true}'


def test_never_consults_rtk_for_other_commands(monkeypatch: pytest.MonkeyPatch) -> None:
    def explode(*_args: object, **_kwargs: object) -> None:
        msg = "rtk must not run"
        raise AssertionError(msg)

    monkeypatch.setattr(subprocess, "run", explode)
    raw = json.dumps({"tool_name": "Bash", "tool_input": {"command": "rm -rf /"}})
    assert run_main(monkeypatch, raw) == ""


@pytest.mark.parametrize(
    "rtk",
    [
        fake_rtk("", returncode=0),  # nothing to say
        fake_rtk('{"rewrite": true}', returncode=1),  # rtk failed
    ],
)
def test_fails_open_on_rtk_output(monkeypatch: pytest.MonkeyPatch, rtk: Any) -> None:
    monkeypatch.setattr(subprocess, "run", rtk)
    raw = json.dumps({"tool_name": "Bash", "tool_input": {"command": "ls"}})
    assert run_main(monkeypatch, raw) == ""


@pytest.mark.parametrize("error", [FileNotFoundError("rtk"), subprocess.TimeoutExpired("rtk", 10)])
def test_fails_open_when_rtk_is_missing_or_hangs(
    monkeypatch: pytest.MonkeyPatch, error: Exception
) -> None:
    def run(*_args: object, **_kwargs: object) -> None:
        raise error

    monkeypatch.setattr(subprocess, "run", run)
    raw = json.dumps({"tool_name": "Bash", "tool_input": {"command": "ls"}})
    assert run_main(monkeypatch, raw) == ""
