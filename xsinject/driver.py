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

SIGNATURES_PATH = Path(__file__).resolve().parent / "signatures.json"
INT32 = range(-(2**31), 2**31)
SUPPORTED_TYPES = {"int"}  # literal and return types the driver encodes and decodes so far


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


_signatures = None


def signatures():
    """name -> signature, from the generated signatures.json the module's dispatch was built from."""
    global _signatures
    if _signatures is None:
        data = json.loads(SIGNATURES_PATH.read_text(encoding="utf-8"))
        _signatures = {s["name"]: s for s in data["functions"]}
    return _signatures


class _Invalid(Exception):
    def __init__(self, message, call=None, argument=None):
        super().__init__(message)
        self.call, self.argument = call, argument


def _validate(calls):
    """[(signature, [int literal, ...])] for a JSON request, or raise _Invalid naming the mistake."""
    if not isinstance(calls, list):
        raise _Invalid("a request is a JSON array of calls")
    sigs, checked = signatures(), []
    for n, call in enumerate(calls):
        if not isinstance(call, dict) or not isinstance(call.get("fn"), str) or not isinstance(call.get("args", []), list):
            raise _Invalid(f'call #{n} must be {{"fn": <name>, "args": [...]}}', n)
        name, args = call["fn"], call.get("args", [])
        sig = sigs.get(name)
        if sig is None:
            raise _Invalid(f"call #{n}: unknown function {name!r}", n)
        if not sig["min_args"] <= len(args) <= sig["max_args"]:
            want = str(sig["min_args"]) if sig["min_args"] == sig["max_args"] else f"{sig['min_args']}..{sig['max_args']}"
            raise _Invalid(f"call #{n} ({name}): takes {want} arguments, got {len(args)}", n)
        if sig["returns"] not in SUPPORTED_TYPES:
            raise _Invalid(f"call #{n} ({name}): {sig['returns']} returns are not supported yet", n)
        for k, (arg, param) in enumerate(zip(args, sig["params"])):
            where = f"call #{n} ({name}), argument #{k} ({param['name']})"
            if param["type"] not in SUPPORTED_TYPES:
                raise _Invalid(f"{where}: {param['type']} parameters are not supported yet", n, k)
            if isinstance(arg, bool) or not isinstance(arg, int):
                raise _Invalid(f"{where}: expected an int literal, got {json.dumps(arg)}", n, k)
            if arg not in INT32:
                raise _Invalid(f"{where}: {arg} does not fit a 32-bit int", n, k)
        checked.append((sig, list(args)))
    return checked


def invalid(message, call=None, argument=None):
    """The Invalid result: the request was rejected before anything was sent."""
    return _result(None, "Invalid", message, call, argument)


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


def _from_section(request_id, sec, checked):
    status = wire.REQUEST_STATUS.get(sec["status"], f"Unknown({sec['status']})")
    failed_call = None if sec["failed_call"] == -1 else sec["failed_call"]
    failed_arg = None if sec["failed_argument"] == -1 else sec["failed_argument"]
    if status != "OK":
        message = status
        if failed_call is not None:
            message += f" at call #{failed_call}"
            if 0 <= failed_call < len(checked):
                message += f" ({checked[failed_call][0]['name']})"
            if failed_arg is not None:
                message += f", argument #{failed_arg}"
        return _result(request_id, status, message, failed_call, failed_arg)

    decoded = None
    if sec["entry_count"] == len(checked):
        decoded = wire.decode_entries(sec["entries_bytes"], [sig["returns"] for sig, _ in checked])
    if decoded is None:
        return _result(
            request_id, "Undecodable",
            f"the response to request {request_id} does not fit the {len(checked)} calls sent; "
            "the module's core is likely stale: re-include xs/xsinject.xs in the host",
        )
    entries = [
        {"call": n, "fn": sig["name"], "status": wire.ENTRY_STATUS.get(st, f"Unknown({st})"), "value": value}
        for n, ((sig, _), (st, value)) in enumerate(zip(checked, decoded))
    ]
    return _result(request_id, "OK", "OK", entries=entries)


def _await_response(profile, request_id, checked, before_send, map_name, timeout, poll):
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
            return _from_section(request_id, final[0][1], checked)
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


def run(calls, *, profile=None, map=None, timeout=DEFAULT_TIMEOUT, poll=DEFAULT_POLL,
        lock_timeout=DEFAULT_LOCK_TIMEOUT):
    """Send a request (a JSON list of {"fn", "args"} calls) and wait for its response.

    The request is validated against signatures.json first; a mistake returns Invalid and
    nothing is sent.
    """
    try:
        checked = _validate(calls)
    except _Invalid as e:
        return invalid(str(e), e.call, e.argument)
    try:
        profile = resolve_profile(profile)
    except ProfileError as e:
        return invalid(str(e))

    request_id = next_request_id(profile)
    last = json.dumps({"request_id": request_id, "calls": calls}, indent=2).encode("utf-8")
    if not _replace_with_retry(profile / LAST_NAME, last, lock_timeout, poll):
        return _result(request_id, "FileHeld", f"could not write {LAST_NAME} within {lock_timeout:g} s")

    before_send = _mtimes(profile, map)
    data = wire.encode_request(request_id, [(sig["id"], args) for sig, args in checked])
    if not _replace_with_retry(profile / REQUEST_NAME, data, lock_timeout, poll):
        return _result(
            request_id, "FileHeld",
            f"the game held {REQUEST_NAME} for {lock_timeout:g} s; nothing was sent",
        )
    return _await_response(profile, request_id, checked, before_send, map, timeout, poll)


def ping(**options):
    """Send a zero-call request: OK means the module is live and answering."""
    return run([], **options)
