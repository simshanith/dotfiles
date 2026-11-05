"""Load the script as a module and serve recorded API responses."""

import importlib.util
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Any

import pytest

if TYPE_CHECKING:
    from collections.abc import Callable
    from types import ModuleType

SKILL = Path(__file__).resolve().parents[1]
FIXTURES = Path(__file__).parent / "fixtures"


sys.dont_write_bytecode = True  # no __pycache__ next to the deployed script


def _load() -> ModuleType:
    path = SKILL / "scripts" / "executable_read_tweet.py"
    spec = importlib.util.spec_from_file_location("read_tweet", path)
    assert spec
    assert spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules["read_tweet"] = module  # dataclasses resolve their module by name
    spec.loader.exec_module(module)
    return module


rt = _load()


def fixture_for(url: str) -> str:
    """Map an endpoint URL to its recorded fixture name."""
    path, _, _ = url.partition("?")
    tail = path.rstrip("/").rsplit("/", 2)
    if "oembed" in path:
        return "oembed-" + url.rsplit("status%2F", 1)[1].split("&", 1)[0]
    kind = {"thread": "thread", "conversation": "conversation"}.get(tail[-2])
    if kind:
        return f"{kind}-{tail[-1]}"
    return ("status2-" if "/2/status/" in path else "status1-") + tail[-1]


class Recorded:
    """A fetcher that serves fixtures, can fail or rewrite chosen URLs, and logs calls."""

    def __init__(
        self,
        fail: Callable[[str], bool] = lambda _url: False,
        rewrite: Callable[[str, bytes], bytes] = lambda _url, body: body,
    ) -> None:
        self.fail = fail
        self.rewrite = rewrite
        self.calls: list[str] = []

    def __call__(self, url: str) -> bytes:
        self.calls.append(url)
        if self.fail(url):
            msg = f"simulated outage: {url}"
            raise rt.SourceError(msg)
        path = FIXTURES / f"{fixture_for(url)}.json"
        if not path.exists():
            msg = f"no fixture for {url}"
            raise rt.SourceError(msg)
        return self.rewrite(url, path.read_bytes())


@pytest.fixture
def recorded() -> Recorded:
    return Recorded()


def make_api(get_json: Recorded) -> Any:
    return rt.Api(fetch=get_json)
