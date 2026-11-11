"""The agent's side of a round trip: write a request, wait for the response section, decode it."""

import json
import os
import time
from pathlib import Path

from . import wire
from .profile import ProfileError, resolve_profile

REQUEST_NAME = wire.REQUEST_FILE + ".xsdat"
LAST_NAME = wire.REQUEST_FILE + ".last.json"

DEFAULT_TIMEOUT = 10.0
DEFAULT_POLL = 0.25
DEFAULT_LOCK_TIMEOUT = 5.0


def _result(request_id, status, message, failed_call=None, failed_argument=None, entries=None, **extra):
    return {
        "request_id": request_id,
        "status": status,
        "failed_call": failed_call,
        "failed_argument": failed_argument,
        "message": message,
        "entries": entries or [],
        **extra,
    }


def next_request_id(profile):
    try:
        data = (Path(profile) / REQUEST_NAME).read_bytes()
    except FileNotFoundError:
        return 1
    current = wire.read_request_id(data)
    return 1 if current is None else current + 1


def _replace_with_retry(target, data, lock_timeout, poll):
    """Write `data` to a temp file and os.replace it onto `target`, retrying while the game holds it.

    Returns True once replaced, False if still held after `lock_timeout` seconds.
    """
    tmp = target.with_name(target.name + ".tmp")
    tmp.write_bytes(data)
    deadline = time.monotonic() + lock_timeout
    while True:
        try:
            os.replace(tmp, target)
            return True
        except PermissionError:
            if time.monotonic() >= deadline:
                tmp.unlink(missing_ok=True)
                return False
            time.sleep(min(poll, 0.05))


def _candidate_files(profile, map_name):
    """The game .xsdat files that may hold the response: the --map file, or all but the request."""
    if map_name is not None:
        return [Path(profile) / f"{map_name}.xsdat"]
    return [p for p in Path(profile).glob("*.xsdat") if p.name.lower() != REQUEST_NAME]


def _mtimes(profile, map_name):
    mtimes = {}
    for path in _candidate_files(profile, map_name):
        try:
            mtimes[path] = path.stat().st_mtime_ns
        except OSError:
            pass
    return mtimes


def _sections(profile, map_name, before_send):
    """(path, fresh, section) for every candidate file carrying a response section.

    `fresh` means the file changed since the `before_send` mtime snapshot. Comparing against the
    file's own earlier mtime avoids mixing a precise clock with NTFS's coarser write times.
    """
    found = []
    for path in _candidate_files(profile, map_name):
        try:
            stat = path.stat()
            data = path.read_bytes()
        except OSError:  # missing, or held by an xsCreateFile handle mid-write
            continue
        sec = wire.find_section(data)
        if sec is not None:
            fresh = before_send.get(path) != stat.st_mtime_ns
            found.append((path, fresh, sec))
    return found


def _from_section(request_id, sec):
    status = wire.REQUEST_STATUS.get(sec["status"], f"Unknown({sec['status']})")
    failed_call = None if sec["failed_call"] == -1 else sec["failed_call"]
    failed_arg = None if sec["failed_argument"] == -1 else sec["failed_argument"]
    if status == "OK":
        message = "OK"
    else:
        message = status
        if failed_call is not None:
            message += f" at call #{failed_call}"
            if failed_arg is not None:
                message += f", argument #{failed_arg}"
    return _result(request_id, status, message, failed_call, failed_arg)


def _await_response(profile, request_id, before_send, map_name, timeout, poll):
    deadline = time.monotonic() + timeout
    while True:
        found = _sections(profile, map_name, before_send)
        ours = [(p, s) for p, fresh, s in found if fresh and s["request_id"] == request_id]
        final = [(p, s) for p, s in ours if s["status"] != wire.RUNNING]
        if len(final) > 1:
            names = ", ".join(sorted(p.stem for p, _ in final))
            return _result(
                request_id,
                "Ambiguous",
                f"several .xsdat files carry a response to request {request_id} ({names}); pass --map to pick one",
            )
        if final:
            return _from_section(request_id, final[0][1])
        if time.monotonic() >= deadline:
            return _timeout(request_id, found, timeout)
        time.sleep(poll)


def _timeout(request_id, found, timeout):
    if not found:
        diagnosis, why = "no-section", "no .xsdat in the profile folder carries a response section"
    elif any(fresh and s["request_id"] == request_id and s["status"] == wire.RUNNING for _, fresh, s in found):
        diagnosis, why = "stuck-running", f"request {request_id} is still Running; a call likely stopped the rule"
    else:
        diagnosis, why = "older-id", f"the response section has not caught up to request {request_id}"
    return _result(request_id, "Timeout", f"no response after {timeout:g} s: {why}", diagnosis=diagnosis)


def send(calls, *, profile=None, map=None, timeout=DEFAULT_TIMEOUT, poll=DEFAULT_POLL,
         lock_timeout=DEFAULT_LOCK_TIMEOUT):
    try:
        profile = resolve_profile(profile)
    except ProfileError as e:
        return _result(None, "Invalid", str(e))

    request_id = next_request_id(profile)
    last = json.dumps({"request_id": request_id, "calls": calls}, indent=2).encode("utf-8")
    if not _replace_with_retry(profile / LAST_NAME, last, lock_timeout, poll):
        return _result(request_id, "FileHeld", f"could not write {LAST_NAME} within {lock_timeout:g} s")

    before_send = _mtimes(profile, map)
    data = wire.encode_request(request_id, calls)
    if not _replace_with_retry(profile / REQUEST_NAME, data, lock_timeout, poll):
        return _result(
            request_id, "FileHeld",
            f"the game held {REQUEST_NAME} for {lock_timeout:g} s; nothing was sent",
        )
    return _await_response(profile, request_id, before_send, map, timeout, poll)


def ping(**options):
    """Send a zero-call request: OK means the module is live and answering."""
    return send([], **options)
