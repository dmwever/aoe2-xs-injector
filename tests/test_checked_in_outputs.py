"""The checked-in generator outputs: in sync with catalog/, and carrying the engine-true signatures."""

import json
from pathlib import Path

from xsinject.generate import generate

REPO = Path(__file__).resolve().parent.parent


def load(rel):
    return json.loads((REPO / rel).read_text(encoding="utf-8"))


def signatures():
    return {s["name"]: s for s in load("xsinject/signatures.json")["functions"]}


def test_checked_in_outputs_match_a_fresh_regeneration():
    pinned = load("xsinject/function_ids.json")
    result = generate(load("catalog/functions.json"), load("catalog/renames.json"), pinned)
    assert result.signatures == load("xsinject/signatures.json")
    assert result.pinned == pinned
    assert result.dispatch == (REPO / "xs" / "xsinject_dispatch.xs").read_text(encoding="ascii")


def test_known_engine_corrections_are_applied():
    sigs = signatures()
    assert sigs["xsIsRuleGroupEnabled"]["returns"] == "void"
    assert sigs["xsFlashUnit"]["params"][2] == {"name": "soundName", "type": "string"}
    assert sigs["xsBuildUnit"]["returns"] == "int"
    assert sigs["xsTaskUnits"]["returns"] == "void"
