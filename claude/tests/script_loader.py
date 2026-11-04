"""Load the helper scripts as modules (they aren't a package, one has no .py)."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import sys
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from types import ModuleType

REPO = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True  # keep __pycache__ out of the source tree


def load(name: str, relative: str) -> ModuleType:
    """Import the script at REPO/relative as module `name`."""
    path = REPO / relative
    loader = importlib.machinery.SourceFileLoader(name, str(path))  # no .py suffix needed
    spec = importlib.util.spec_from_loader(name, loader)
    assert spec
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    loader.exec_module(module)
    return module
