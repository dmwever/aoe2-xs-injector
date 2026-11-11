import io
import json
import subprocess
import sys

from conftest import FakeModule, i32, section

from xsinject.cli import main

FAST_ARGS = ["--timeout", "2", "--poll", "0.02", "--lock-timeout", "0.3"]


def test_ping_prints_the_result_and_exits_0_on_ok(profile, capsys):
    with FakeModule(profile, lambda rid: {"default1": section(rid)}):
        code = main(["ping", "--profile", str(profile), *FAST_ARGS])
    out = json.loads(capsys.readouterr().out)
    assert code == 0
    assert (out["request_id"], out["status"], out["entries"]) == (1, "OK", [])


def test_ping_exits_nonzero_on_timeout(profile, capsys):
    (profile / "default1.xsdat").write_bytes(i32(1))
    code = main(["ping", "--profile", str(profile), "--timeout", "0.2", "--poll", "0.02"])
    out = json.loads(capsys.readouterr().out)
    assert code == 1
    assert (out["status"], out["diagnosis"]) == ("Timeout", "no-section")


def test_ping_exits_nonzero_on_a_wire_failure(profile, capsys):
    with FakeModule(profile, lambda rid: {"default1": section(rid, status=9)}):
        code = main(["ping", "--profile", str(profile), *FAST_ARGS])
    assert code == 1
    assert json.loads(capsys.readouterr().out)["status"] == "TrailingBytes"


def test_map_option_pins_the_response_file(profile, capsys):
    both = lambda rid: {"default1": section(rid), "XsTesting": section(rid)}
    with FakeModule(profile, both):
        code = main(["ping", "--profile", str(profile), "--map", "default1", *FAST_ARGS])
    assert code == 0


def test_profile_from_environment(profile, capsys, monkeypatch):
    monkeypatch.setenv("XSINJECT_PROFILE", str(profile))
    with FakeModule(profile, lambda rid: {"default1": section(rid)}):
        code = main(["ping", *FAST_ARGS])
    assert code == 0


def test_runs_as_a_module(profile):
    proc = subprocess.run(
        [sys.executable, "-m", "xsinject", "ping", "--profile", str(profile), "--timeout", "0.2"],
        capture_output=True, text=True,
    )
    assert proc.returncode == 1
    assert json.loads(proc.stdout)["diagnosis"] == "no-section"


def int_entries(rid):
    return {"default1": section(rid, entries=i32(0, 8), entry_count=1)}


def test_run_reads_the_request_from_a_file(profile, tmp_path, capsys):
    req = tmp_path / "req.json"
    req.write_text(json.dumps([{"fn": "bitAnd", "args": [12, 10]}]))
    with FakeModule(profile, int_entries):
        code = main(["run", str(req), "--profile", str(profile), *FAST_ARGS])
    out = json.loads(capsys.readouterr().out)
    assert code == 0
    assert out["entries"] == [{"call": 0, "fn": "bitAnd", "status": "OK", "value": 8}]


def test_run_reads_the_request_from_stdin(profile, capsys, monkeypatch):
    monkeypatch.setattr(sys, "stdin", io.StringIO('[{"fn": "bitAnd", "args": [12, 10]}]'))
    with FakeModule(profile, int_entries):
        code = main(["run", "-", "--profile", str(profile), *FAST_ARGS])
    assert code == 0
    assert json.loads(capsys.readouterr().out)["entries"][0]["value"] == 8


def test_run_exits_nonzero_on_an_invalid_request(profile, capsys):
    proc = subprocess.run(
        [sys.executable, "-m", "xsinject", "run", "-", "--profile", str(profile)],
        input='[{"fn": "xsNoSuchThing"}]', capture_output=True, text=True,
    )
    assert proc.returncode == 1
    assert json.loads(proc.stdout)["status"] == "Invalid"


def test_run_reports_malformed_json_as_invalid(profile, capsys, monkeypatch):
    monkeypatch.setattr(sys, "stdin", io.StringIO("[{"))
    code = main(["run", "-", "--profile", str(profile), *FAST_ARGS])
    out = json.loads(capsys.readouterr().out)
    assert (code, out["status"]) == (1, "Invalid")
    assert not (profile / "xsinject.xsdat").exists()


def test_encode_prints_the_request_bytes_without_sending(profile):
    (profile / "xsinject.xsdat").write_bytes(i32(41, 0))
    proc = subprocess.run(
        [sys.executable, "-m", "xsinject", "encode", "-", "--profile", str(profile)],
        input=b'[{"fn": "bitAnd", "args": [12, 10]}]', capture_output=True,
    )
    assert proc.returncode == 0
    assert proc.stdout == i32(42, 1, 67, 2, 0, 12, 0, 10)  # the next id after the one in the request file
    assert (profile / "xsinject.xsdat").read_bytes() == i32(41, 0), "nothing may be sent"
    assert not (profile / "xsinject.last.json").exists()


def test_encode_without_a_profile_uses_request_id_1(tmp_path):
    proc = subprocess.run(
        [sys.executable, "-m", "xsinject", "encode", "-", "--profile", str(tmp_path / "missing")],
        input=b'[{"fn": "xsGetMapWidth"}]', capture_output=True,
    )
    assert proc.returncode == 0
    assert proc.stdout == i32(1, 1, 175, 0)


def test_encode_exits_nonzero_with_the_invalid_result(profile):
    proc = subprocess.run(
        [sys.executable, "-m", "xsinject", "encode", "-", "--profile", str(profile)],
        input=b'[{"fn": "bitAnd", "args": [1, "2"]}]', capture_output=True,
    )
    assert proc.returncode == 1
    assert json.loads(proc.stdout)["status"] == "Invalid"
