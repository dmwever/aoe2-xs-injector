"""The agent docs keep up with the driver: every status it can print has a troubleshooting row,
every CLI command is documented, and the Ageipelago recipe sits where Ageipelago points."""

import re
from pathlib import Path

import pytest

from xsinject import cli, wire

DOCS = Path(__file__).resolve().parent.parent / "docs" / "agents"
TASK_DOCS = ["driving", "hosting", "troubleshooting", "maintaining"]
DRIVER_STATUSES = ["Timeout/no-section", "Timeout/older-id", "Timeout/stuck-running",
                   "FileHeld", "Invalid", "Ambiguous", "Undecodable"]
# Wire codes 2-9: the ones a request can fail with (0 is OK, 1 Running ends as Timeout/stuck-running).
WIRE_FAILURES = [name for code, name in wire.REQUEST_STATUS.items() if code >= 2]


def _doc(name):
    return (DOCS / f"{name}.md").read_text(encoding="utf-8")


def _troubleshooting_keys():
    """The first cell of every table row in troubleshooting.md, backticks stripped."""
    keys = []
    for line in _doc("troubleshooting").splitlines():
        m = re.match(r"\|\s*([^|]+?)\s*\|", line)
        if m:
            keys.append(m.group(1).replace("`", ""))
    return keys


@pytest.mark.parametrize("name", TASK_DOCS)
def test_each_task_doc_exists(name):
    assert (DOCS / f"{name}.md").is_file()


@pytest.mark.parametrize("status", DRIVER_STATUSES + WIRE_FAILURES)
def test_troubleshooting_has_a_row_for_every_status_the_driver_prints(status):
    assert any(key.startswith(status) for key in _troubleshooting_keys()), status


def test_troubleshooting_gives_a_paused_game_its_own_older_id_row():
    rows = [line for line in _doc("troubleshooting").splitlines() if line.startswith("| `Timeout/older-id`")]
    assert any("paused" in row.lower() for row in rows)
    assert len(rows) >= 2


@pytest.mark.parametrize("status", DRIVER_STATUSES + list(wire.REQUEST_STATUS.values()))
def test_driving_names_every_status(status):
    assert f"`{status.split('/')[-1]}`" in _doc("driving")


def test_driving_documents_every_cli_command():
    parser = cli._parser()
    commands = next(a for a in parser._actions if a.dest == "command").choices
    text = _doc("driving")
    for command in commands:
        assert f"xsinject {command}" in text, command


@pytest.mark.parametrize("line", ['include "./xsinject.xs";', "xsInjectUseHostWriter();", "xsInjectWriteSection();"])
def test_hosting_carries_the_ageipelago_recipe_lines(line):
    assert line in _doc("hosting")


def test_skill_routes_into_all_four_docs():
    skill = (DOCS / "skill" / "SKILL.md").read_text(encoding="utf-8")
    for name in TASK_DOCS:
        assert f"docs/agents/{name}.md" in skill, name
