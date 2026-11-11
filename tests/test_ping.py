import json
import os
import struct

from conftest import FAST, QUICK, FakeModule, i32, section

from xsinject import ping


def standalone(rid):
    return {"default1": section(rid)}


def test_ping_returns_ok_echoing_request_id(profile):
    with FakeModule(profile, standalone):
        result = ping(profile=profile, **FAST)
    assert result == {
        "request_id": 1,
        "status": "OK",
        "failed_call": None,
        "failed_argument": None,
        "message": "OK",
        "entries": [],
    }


def test_ping_writes_a_zero_call_request_and_saves_it_as_last_json(profile):
    with FakeModule(profile, standalone) as module:
        ping(profile=profile, **FAST)
    assert module.requests == [i32(1, 0)]
    last = json.loads((profile / "xsinject.last.json").read_text())
    assert (last["request_id"], last["calls"]) == (1, [])


def test_next_ping_takes_the_next_id(profile):
    with FakeModule(profile, standalone):
        first = ping(profile=profile, **FAST)
        second = ping(profile=profile, **FAST)
    assert (first["request_id"], second["request_id"]) == (1, 2)
    assert second["status"] == "OK"


def test_next_id_follows_the_id_already_in_the_request_file(profile):
    (profile / "xsinject.xsdat").write_bytes(i32(41, 0))
    with FakeModule(profile, standalone, seen_id=41) as module:
        result = ping(profile=profile, **FAST)
    assert result["request_id"] == 42
    assert module.requests == [i32(42, 0)]


def test_finds_a_section_trailing_a_host_packet(profile):
    host_packet = i32(7, 8, 9) + struct.pack("<I", 3) + b"abc"
    with FakeModule(profile, lambda rid: {"XsTesting": host_packet + section(rid)}):
        result = ping(profile=profile, **FAST)
    assert result["status"] == "OK"


def test_ignores_files_without_the_trailing_magic(profile):
    (profile / "other.xsdat").write_bytes(i32(1, 2, 3, 4, 5, 6, 7, 8))
    with FakeModule(profile, standalone):
        result = ping(profile=profile, **FAST)
    assert result["status"] == "OK"


def test_waits_past_a_section_echoing_another_id(profile):
    (profile / "default1.xsdat").write_bytes(section(0))
    with FakeModule(profile, standalone):
        result = ping(profile=profile, **FAST)
    assert (result["request_id"], result["status"]) == (1, "OK")


def test_two_files_answering_the_request_is_ambiguous(profile):
    both = lambda rid: {"default1": section(rid), "XsTesting": section(rid)}
    with FakeModule(profile, both):
        result = ping(profile=profile, **FAST)
    assert result["status"] == "Ambiguous"
    assert "--map" in result["message"]


def test_map_pins_the_response_file(profile):
    both = lambda rid: {"default1": section(rid, status=2), "XsTesting": section(rid)}
    with FakeModule(profile, both):
        result = ping(profile=profile, map="XsTesting", **FAST)
    assert result["status"] == "OK"


def test_decodes_a_failure_header(profile):
    with FakeModule(profile, lambda rid: {"default1": section(rid, status=2, failed_call=0, failed_arg=-1)}):
        result = ping(profile=profile, **FAST)
    assert result["status"] == "Truncated"
    assert (result["failed_call"], result["failed_argument"]) == (0, None)
    assert "call #0" in result["message"]



def test_timeout_with_no_section_anywhere(profile):
    (profile / "default1.xsdat").write_bytes(i32(1, 2, 3))
    result = ping(profile=profile, **QUICK)
    assert (result["status"], result["diagnosis"]) == ("Timeout", "no-section")


def test_timeout_with_only_an_older_section(profile):
    (profile / "default1.xsdat").write_bytes(section(0))
    result = ping(profile=profile, **QUICK)
    assert (result["status"], result["diagnosis"]) == ("Timeout", "older-id")


def test_a_section_written_before_the_send_is_not_the_answer(profile):
    stale = profile / "default1.xsdat"
    stale.write_bytes(section(1))
    os.utime(stale, (1_000_000_000, 1_000_000_000))
    result = ping(profile=profile, **QUICK)
    assert result["status"] == "Timeout"


def test_timeout_reports_older_id_for_a_pinned_map(profile):
    (profile / "XsTesting.xsdat").write_bytes(section(0))
    with FakeModule(profile, lambda rid: {"default1": section(rid)}):
        result = ping(profile=profile, map="XsTesting", **QUICK)
    assert (result["status"], result["diagnosis"]) == ("Timeout", "older-id")


def test_file_held_when_the_game_will_not_release_the_request_file(profile):
    req = profile / "xsinject.xsdat"
    req.write_bytes(i32(5, 0))
    with open(req, "rb"):  # on Windows an open handle blocks os.replace, as XS's does
        result = ping(profile=profile, **QUICK)
    assert result["status"] == "FileHeld"
    assert req.read_bytes() == i32(5, 0)
    assert not list(profile.glob("*.tmp"))


def test_invalid_when_no_profile_can_be_found(tmp_path):
    result = ping(profile=tmp_path / "missing", **QUICK)
    assert result["status"] == "Invalid"
    assert "does not exist" in result["message"]
