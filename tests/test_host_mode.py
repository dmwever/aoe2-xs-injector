"""Host mode at the driver seam: a host rewrites its own packet every tick and carries the section."""

import struct
import threading
import time

from conftest import FAST, MAGIC, i32, section, xs_string

from xsinject import run, wire

CALLS = [
    {"fn": "xsGetMapWidth", "args": []},
    {"fn": "strSubstring", "args": ["abcdef", 1, 4]},
]
ENTRIES = i32(0, 144) + i32(0) + xs_string("bcd")  # OK 144, OK "bcd"
SECTION_FIXED_BYTES = 32  # 6 header ints, then the body length and the magic (cXsInjectSectionFixedBytes)


def host_packet(tick):
    """An arbitrary host layout the driver knows nothing about; it changes every tick."""
    return i32(tick, -1, MAGIC) + xs_string("host packet") + i32(len("host packet"))


class HostModule:
    """A host that rewrites default1.xsdat every tick: its packet, then the module's kept section.

    `respond(request_id) -> [section bytes, ...]` are the responses the module stores in turn, one
    per tick (Running first, then the final one); the last one is kept and rewritten every tick.
    """

    def __init__(self, profile, respond):
        self.profile = profile
        self.respond = respond
        self.written = []
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True)

    def _loop(self):
        req = self.profile / "xsinject.xsdat"
        seen, kept, pending, tick = None, b"", [], 0
        while not self._stop.is_set():
            try:
                data = req.read_bytes()
            except OSError:
                data = b""
            if len(data) >= 4:
                rid = struct.unpack("<i", data[:4])[0]
                if rid != seen:
                    seen, pending = rid, list(self.respond(rid))
            if pending:
                kept = pending.pop(0)
            payload = host_packet(tick) + kept
            (self.profile / "default1.xsdat").write_bytes(payload)
            self.written.append(payload)
            tick += 1
            time.sleep(0.01)

    def __enter__(self):
        self._thread.start()
        return self

    def __exit__(self, *exc):
        self._stop.set()
        self._thread.join()


def test_a_response_carried_after_a_host_packet_decodes(profile):
    answer = lambda rid: [section(rid, wire.RUNNING), section(rid, entries=ENTRIES, entry_count=2)]
    with HostModule(profile, answer):
        result = run(CALLS, profile=profile, **FAST)
    assert result["status"] == "OK", result
    assert [e["value"] for e in result["entries"]] == [144, "bcd"]


def test_the_host_packet_still_decodes_in_front_of_the_section(profile):
    answer = lambda rid: [section(rid, entries=ENTRIES, entry_count=2)]
    with HostModule(profile, answer) as host:
        run(CALLS, profile=profile, **FAST)
    last = host.written[-1]
    sec = wire.find_section(last)
    host_bytes = last[: len(last) - SECTION_FIXED_BYTES - len(sec["entries_bytes"])]
    tick = struct.unpack_from("<i", host_bytes)[0]
    assert host_bytes == host_packet(tick)


def test_running_carried_by_the_host_is_waited_past(profile):
    answer = lambda rid: [section(rid, wire.RUNNING)] * 5 + [section(rid, entries=ENTRIES, entry_count=2)]
    with HostModule(profile, answer):
        result = run(CALLS, profile=profile, **FAST)
    assert result["status"] == "OK"


def test_running_kept_by_the_host_times_out_as_stuck_running(profile):
    answer = lambda rid: [section(rid, wire.RUNNING)]
    with HostModule(profile, answer):
        result = run(CALLS, profile=profile, **{**FAST, "timeout": 0.3})
    assert (result["status"], result["diagnosis"]) == ("Timeout", "stuck-running")


def test_too_large_after_a_host_packet_has_no_entries_and_says_to_split(profile):
    answer = lambda rid: [section(rid, wire.RUNNING), section(rid, status=wire.TOO_LARGE)]
    with HostModule(profile, answer):
        result = run(CALLS, profile=profile, **FAST)
    assert (result["status"], result["failed_call"], result["failed_argument"], result["entries"]) == (
        "TooLarge", None, None, [])
    assert "the calls ran" in result["message"]
    assert "split the request" in result["message"]
