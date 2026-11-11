"""Test doubles that stand in for the XS module inside a temp profile folder."""

import struct
import threading
import time

import pytest

MAGIC = 441340760  # must match cXsInjectMagic in xs/xsinject.xs


def i32(*vals):
    return b"".join(struct.pack("<i", v) for v in vals)


def section(request_id, status=0, failed_call=-1, failed_arg=-1, entries=b"", entry_count=0):
    """A response section exactly as the spec lays it out: [body][body length][magic]."""
    body = i32(MAGIC, request_id, status, failed_call, failed_arg, entry_count) + entries
    return body + i32(len(body), MAGIC)


def request_id_in(profile):
    data = (profile / "xsinject.xsdat").read_bytes()
    return struct.unpack("<i", data[:4])[0]


class FakeModule:
    """Waits for a request with a new id, then writes responses into game .xsdat files.

    `respond(request_id) -> {stem: bytes}` decides what gets written.
    """

    def __init__(self, profile, respond, seen_id=None):
        self.profile = profile
        self.respond = respond
        self.seen_id = seen_id
        self.requests = []
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True)

    def _loop(self):
        req = self.profile / "xsinject.xsdat"
        while not self._stop.is_set():
            try:
                data = req.read_bytes()
            except OSError:
                data = b""
            if len(data) >= 4:
                rid = struct.unpack("<i", data[:4])[0]
                if rid != self.seen_id:
                    self.seen_id = rid
                    self.requests.append(data)
                    for stem, payload in self.respond(rid).items():
                        (self.profile / f"{stem}.xsdat").write_bytes(payload)
            time.sleep(0.01)

    def __enter__(self):
        self._thread.start()
        return self

    def __exit__(self, *exc):
        self._stop.set()
        self._thread.join()


@pytest.fixture
def profile(tmp_path):
    p = tmp_path / "profile"
    p.mkdir()
    return p


FAST = {"timeout": 2.0, "poll": 0.02, "lock_timeout": 0.3}
QUICK = {**FAST, "timeout": 0.3}  # for waits that are meant to time out
