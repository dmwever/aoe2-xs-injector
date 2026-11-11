"""Failure reporting: every request status rendered from the request sent, Running, NotRun, and fetch."""

import json
import os

import pytest

from conftest import FAST, QUICK, FakeModule, failing, i32, section

from xsinject import driver, fetch, run
from xsinject.cli import main

WAIT = {"timeout": QUICK["timeout"], "poll": QUICK["poll"]}  # fetch takes no lock_timeout

CALLS = [
    {"fn": "xsGetMapWidth", "args": []},
    {"fn": "bitAnd", "args": [{"ref": 0}, 10]},
]


def reported(profile, status, failed_call=-1, failed_arg=-1, calls=CALLS):
    with FakeModule(profile, failing(status, failed_call, failed_arg)):
        return run(calls, profile=profile, **FAST)


def test_truncated_names_the_call_and_argument_it_stopped_in(profile):
    result = reported(profile, 2, 1, 1)
    assert (result["status"], result["failed_call"], result["failed_argument"], result["entries"]) == (
        "Truncated", 1, 1, [])
    assert result["message"].startswith("Truncated at call #1 (bitAnd), argument #1 (y = 10): ")
    assert "ended before" in result["message"]


@pytest.mark.parametrize("code, failed_call, failed_arg, status, where, why", [
    (3, 1, -1, "UnknownFunction", " at call #1 (bitAnd): ", "re-include"),
    (4, 1, -1, "BadArgCount", " at call #1 (bitAnd): ", "re-include"),
    (5, 1, 0, "BadTag", ' at call #1 (bitAnd), argument #0 (x = {"ref": 0}): ', "neither 0 (literal) nor 1"),
    (6, 1, 0, "BadReference", ' at call #1 (bitAnd), argument #0 (x = {"ref": 0}): ', "earlier call"),
    (7, 1, 0, "ReferenceTypeMismatch", ' at call #1 (bitAnd), argument #0 (x = {"ref": 0}): ', "return type"),
    (8, -1, -1, "TooLarge", ": ", "split the request"),
    (9, -1, -1, "TrailingBytes", ": ", "after the last call"),
])
def test_every_failed_request_status_is_rendered_from_the_request_sent(profile, code, failed_call, failed_arg,
                                                                 status, where, why):
    result = reported(profile, code, failed_call, failed_arg)
    expect_call = None if failed_call == -1 else failed_call
    expect_arg = None if failed_arg == -1 else failed_arg
    assert (result["status"], result["failed_call"], result["failed_argument"], result["entries"]) == (
        status, expect_call, expect_arg, [])
    assert result["message"].startswith(status + where)
    assert why in result["message"]


def test_truncated_before_the_first_call_has_no_location(profile):
    result = reported(profile, 2)
    assert (result["failed_call"], result["failed_argument"]) == (None, None)
    assert result["message"].startswith("Truncated: ")


def test_a_failure_location_beyond_the_request_sent_is_still_reported(profile):
    result = reported(profile, 2, 5, 3)
    assert (result["failed_call"], result["failed_argument"]) == (5, 3)
    assert result["message"].startswith("Truncated at call #5, argument #3: ")


def test_an_unknown_wire_code_is_reported_by_number(profile):
    result = reported(profile, 42)
    assert result["status"] == "Unknown(42)"
    assert "does not know" in result["message"]


def test_a_not_run_entry_is_decoded_without_a_value(profile):
    entries = i32(1) + i32(0, 8)
    answer = lambda rid: {"default1": section(rid, entries=entries, entry_count=2)}
    with FakeModule(profile, answer):
        result = run(CALLS, profile=profile, **FAST)
    assert result["status"] == "OK"
    assert result["entries"] == [
        {"call": 0, "fn": "xsGetMapWidth", "status": "NotRun", "value": None},
        {"call": 1, "fn": "bitAnd", "status": "OK", "value": 8},
    ]


def test_a_response_stuck_at_running_times_out_as_stuck_running(profile):
    with FakeModule(profile, failing(1)):
        result = run(CALLS, profile=profile, **QUICK)
    assert (result["request_id"], result["status"], result["diagnosis"]) == (1, "Timeout", "stuck-running")
    assert "still Running" in result["message"]


def test_fetch_recovers_a_response_that_arrived_after_the_timeout(profile):
    late = run(CALLS, profile=profile, **QUICK)
    assert late["status"] == "Timeout"
    (profile / "default1.xsdat").write_bytes(section(1, entries=i32(0, 120, 0, 8), entry_count=2))
    sent = (profile / "xsinject.xsdat").read_bytes()
    result = fetch(profile=profile, **WAIT)
    assert result == {
        "request_id": 1,
        "status": "OK",
        "failed_call": None,
        "failed_argument": None,
        "message": "OK",
        "entries": [
            {"call": 0, "fn": "xsGetMapWidth", "status": "OK", "value": 120},
            {"call": 1, "fn": "bitAnd", "status": "OK", "value": 8},
        ],
    }
    assert (profile / "xsinject.xsdat").read_bytes() == sent, "fetch sends nothing"


def saved_last_request(profile, request_id=1, calls=CALLS):
    """Send `calls` as request `request_id` with no module answering, so only fetch can pick it up."""
    if request_id > 1:
        (profile / "xsinject.xsdat").write_bytes(i32(request_id - 1, 0))
    assert run(calls, profile=profile, **{**QUICK, "timeout": 0})["status"] == "Timeout"


def test_fetch_with_nothing_sent_is_invalid(profile):
    result = fetch(profile=profile, **WAIT)
    assert result["status"] == "Invalid"
    assert "xsinject.last.json" in result["message"]


def test_fetch_of_a_request_still_running_is_stuck_running(profile):
    saved_last_request(profile)
    (profile / "default1.xsdat").write_bytes(section(1, status=1))
    result = fetch(profile=profile, **WAIT)
    assert (result["status"], result["diagnosis"]) == ("Timeout", "stuck-running")


def test_fetch_ignores_a_response_to_another_request(profile):
    saved_last_request(profile, request_id=2)
    (profile / "default1.xsdat").write_bytes(section(1))
    result = fetch(profile=profile, **WAIT)
    assert (result["request_id"], result["status"], result["diagnosis"]) == (2, "Timeout", "older-id")


def test_fetch_renders_a_failure_from_the_saved_request(profile):
    saved_last_request(profile)
    (profile / "default1.xsdat").write_bytes(section(1, status=6, failed_call=1, failed_arg=0))
    result = fetch(profile=profile, **WAIT)
    assert result["message"].startswith('BadReference at call #1 (bitAnd), argument #0 (x = {"ref": 0}): ')


def test_cli_fetch_prints_the_result_and_exits_0_on_ok(profile, capsys):
    saved_last_request(profile)
    (profile / "default1.xsdat").write_bytes(section(1, entries=i32(0, 120, 0, 8), entry_count=2))
    code = main(["fetch", "--profile", str(profile), "--timeout", "0.3", "--poll", "0.02"])
    out = json.loads(capsys.readouterr().out)
    assert (code, out["status"], [e["value"] for e in out["entries"]]) == (0, "OK", [120, 8])


def test_cli_fetch_exits_nonzero_when_the_response_has_not_arrived(profile, capsys):
    saved_last_request(profile)
    code = main(["fetch", "--profile", str(profile), "--timeout", "0.2", "--poll", "0.02"])
    assert (code, json.loads(capsys.readouterr().out)["diagnosis"]) == (1, "no-section")


def test_fetch_decodes_with_the_signatures_saved_at_send_time(profile, monkeypatch):
    saved_last_request(profile)
    monkeypatch.setattr(driver, "_signatures", {})  # signatures.json regenerated since the send
    (profile / "default1.xsdat").write_bytes(section(1, entries=i32(0, 120, 0, 8), entry_count=2))
    result = fetch(profile=profile, **WAIT)
    assert (result["status"], [e["fn"] for e in result["entries"]]) == ("OK", ["xsGetMapWidth", "bitAnd"])


def test_fetch_ignores_responses_written_before_the_send(profile):
    for stem in ("default1", "XsTesting"):
        stale = profile / f"{stem}.xsdat"
        stale.write_bytes(section(1))
        os.utime(stale, (1_000_000_000, 1_000_000_000))
    saved_last_request(profile)
    result = fetch(profile=profile, **WAIT)
    assert (result["status"], result["diagnosis"]) == ("Timeout", "older-id")


def test_a_timeout_names_the_request_the_response_section_answers(profile):
    saved_last_request(profile, request_id=2)
    (profile / "default1.xsdat").write_bytes(section(7))
    result = fetch(profile=profile, **WAIT)
    assert "request 7" in result["message"]
