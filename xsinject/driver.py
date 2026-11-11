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


class InvalidRequest(Exception):
    """A request rejected before sending; `result` is its Invalid result."""

    def __init__(self, message, call=None, argument=None):
        super().__init__(message)
        self.call, self.argument = call, argument

    @property
    def result(self):
        return invalid(str(self), self.call, self.argument)


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _literal_problem(xs_type, value):
    """Why the JSON literal `value` can't be sent as `xs_type`, or None when it fits."""
    shown = json.dumps(value)
    if xs_type == "int":
        if isinstance(value, bool) or not isinstance(value, int):
            return f"expected an int literal, got {shown}"
        if value not in INT32:
            return f"{value} does not fit a 32-bit int"
    elif xs_type == "float":
        if not _is_number(value) or not wire.fits_float32(value):
            return f"expected a finite 32-bit float literal, got {shown}"
    elif xs_type == "bool":
        if not isinstance(value, bool):
            return f"expected a bool literal (true or false), got {shown}"
    elif xs_type == "string":
        if not isinstance(value, str):
            return f"expected a string literal, got {shown}"
    elif xs_type == "vector":
        if not (isinstance(value, list) and len(value) == 3
                and all(_is_number(v) and wire.fits_float32(v) for v in value)):
            return f"expected a vector literal [x, y, z] of finite 32-bit floats, got {shown}"
    else:
        return f"{xs_type} parameters can't take a literal"
    return None


def _reference_problem(n, arg, xs_type, checked, call_count):
    """(wire.Reference, None) for a valid reference `arg` in call #n, or (None, why it isn't)."""
    if set(arg) != {"ref"}:
        return None, f'a reference is {{"ref": <call #>}}, got {json.dumps(arg)}'
    target = arg["ref"]
    if isinstance(target, bool) or not isinstance(target, int):
        return None, f'the "ref" of a reference is a call number, got {json.dumps(target)}'
    if target == n:
        return None, "a reference can't point to its own call"
    if not 0 <= target < call_count:
        return None, f"a reference to no call #{target}; the request has calls #0..#{call_count - 1}"
    if target > n:
        return None, f"a reference to call #{target}, a later call; only earlier calls have results"
    sig = checked[target][0]
    if sig["returns"] == "void":
        return None, f"call #{target} ({sig['name']}) is void, so it has no result to reference"
    if sig["returns"] != xs_type:
        return None, f"call #{target} ({sig['name']}) returns {sig['returns']}, but the parameter is {xs_type}"
    return wire.Reference(target), None


def _validate(calls):
    """[(signature, [(param type, argument), ...])] for a JSON request, or raise InvalidRequest naming the mistake.

    An argument is the JSON literal, or a wire.Reference for {"ref": N}: N must be an earlier call whose
    return type is exactly the parameter's type.
    """
    if not isinstance(calls, list):
        raise InvalidRequest("a request is a JSON array of calls")
    sigs, checked = signatures(), []
    for n, call in enumerate(calls):
        if not isinstance(call, dict) or not isinstance(call.get("fn"), str) or not isinstance(call.get("args", []), list):
            raise InvalidRequest(f'call #{n} must be {{"fn": <name>, "args": [...]}}', n)
        name, args = call["fn"], call.get("args", [])
        sig = sigs.get(name)
        if sig is None:
            raise InvalidRequest(f"call #{n}: unknown function {name!r}", n)
        if not sig["min_args"] <= len(args) <= sig["max_args"]:
            want = str(sig["min_args"]) if sig["min_args"] == sig["max_args"] else f"{sig['min_args']}..{sig['max_args']}"
            raise InvalidRequest(f"call #{n} ({name}): takes {want} arguments, got {len(args)}", n)
        arguments = []
        for k, (arg, param) in enumerate(zip(args, sig["params"])):
            if isinstance(arg, dict) and "ref" in arg:
                arg, problem = _reference_problem(n, arg, param["type"], checked, len(calls))
            else:
                problem = _literal_problem(param["type"], arg)
            if problem is not None:
                raise InvalidRequest(f"call #{n} ({name}), argument #{k} ({param['name']}): {problem}", n, k)
            arguments.append((param["type"], arg))
        checked.append((sig, arguments))
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
    file's own earlier mtime avoids mixing a precise clock with NTFS's coarser write times. With no
    snapshot (fetch), every section counts as fresh.
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
            fresh = before_send is None or before_send.get(path) != stat.st_mtime_ns
            found.append((path, fresh, sec))
    return found


_STALE_CORE = "the module's core is likely stale: re-include xs/xsinject.xs in the host"
_DISAGREES = f"signatures.json says otherwise, so {_STALE_CORE}"
# A literal read as a type other than the one sent misaligns every read after it.
_MISREAD = f"a literal the module reads as another type does this too, so if the request looks right, {_STALE_CORE}"

# Why the module gave each non-OK request status. The driver's validation blocks 3-7 and 9 before
# sending, so reaching one means the module and driver disagree (or the bytes were crafted). Running
# never gets here: a request stuck at Running ends as Timeout/stuck-running.
_WHY = {
    "Truncated": f"the request file ended before everything its counts promised was read; {_MISREAD}",
    "UnknownFunction": f"the module has no function with this id; {_DISAGREES}",
    "BadArgCount": f"the module does not accept this many arguments for this function; {_DISAGREES}",
    "BadTag": f"the argument's tag is neither 0 (literal) nor 1 (reference); {_MISREAD}",
    "BadReference": "the reference does not point to an earlier call in the request",
    "ReferenceTypeMismatch": f"the referenced call's return type is not the parameter's type; {_DISAGREES}",
    "TooLarge": "the calls ran, but the response would push the .xsdat past the game's 1,048,575-byte "
                "write limit; split the request into smaller reads",
    "TrailingBytes": f"bytes were left in the request file after the last call; {_MISREAD}",
}


def _argument_as_json(arg):
    """An argument as the agent wrote it: the JSON literal, or {"ref": N}."""
    return json.dumps({"ref": int(arg)} if isinstance(arg, wire.Reference) else arg)


def _where(checked, failed_call, failed_arg):
    """' at call #N (fn), argument #K (param = value)' as far as the request sent can name it."""
    if failed_call is None:
        return ""
    where = f" at call #{failed_call}"
    if not 0 <= failed_call < len(checked):
        return where + (f", argument #{failed_arg}" if failed_arg is not None else "")
    sig, args = checked[failed_call]
    where += f" ({sig['name']})"
    if failed_arg is not None:
        where += f", argument #{failed_arg}"
        if 0 <= failed_arg < len(args):
            where += f" ({sig['params'][failed_arg]['name']} = {_argument_as_json(args[failed_arg][1])})"
    return where


def _failure_message(status, checked, failed_call, failed_arg):
    why = _WHY.get(status, "the module returned a status this driver does not know")
    return f"{status}{_where(checked, failed_call, failed_arg)}: {why}"


def _from_section(request_id, sec, checked):
    status = wire.REQUEST_STATUS.get(sec["status"], f"Unknown({sec['status']})")
    failed_call = None if sec["failed_call"] == -1 else sec["failed_call"]
    failed_arg = None if sec["failed_argument"] == -1 else sec["failed_argument"]
    if status != "OK":
        message = _failure_message(status, checked, failed_call, failed_arg)
        return _result(request_id, status, message, failed_call, failed_arg)

    decoded = None
    if sec["entry_count"] == len(checked):
        decoded = wire.decode_entries(sec["entries_bytes"], [sig["returns"] for sig, _ in checked])
    if decoded is None:
        return _result(
            request_id, "Undecodable",
            f"the response to request {request_id} does not fit the {len(checked)} calls sent; {_STALE_CORE}",
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
    except InvalidRequest as e:
        return e.result
    try:
        profile = resolve_profile(profile)
    except ProfileError as e:
        return invalid(str(e))

    request_id = next_request_id(profile)
    last = json.dumps({"request_id": request_id, "calls": calls}, indent=2).encode("utf-8")
    if not _replace_with_retry(profile / LAST_NAME, last, lock_timeout, poll):
        return _result(request_id, "FileHeld", f"could not write {LAST_NAME} within {lock_timeout:g} s")

    before_send = _mtimes(profile, map)
    data = _encode_checked(request_id, checked)
    if not _replace_with_retry(profile / REQUEST_NAME, data, lock_timeout, poll):
        return _result(
            request_id, "FileHeld",
            f"the game held {REQUEST_NAME} for {lock_timeout:g} s; nothing was sent",
        )
    return _await_response(profile, request_id, checked, before_send, map, timeout, poll)


def fetch(*, profile=None, map=None, timeout=DEFAULT_TIMEOUT, poll=DEFAULT_POLL):
    """Decode the current response against the last request sent (xsinject.last.json); nothing is sent.

    Recovers a response that arrived after `run` timed out. Waits up to `timeout` like `run`, but any
    section echoing the last request id counts, however old.
    """
    try:
        profile = resolve_profile(profile)
    except ProfileError as e:
        return invalid(str(e))
    try:
        last = json.loads((profile / LAST_NAME).read_text(encoding="utf-8"))
        request_id, calls = last["request_id"], last["calls"]
    except FileNotFoundError:
        return invalid(f"no {LAST_NAME} in {profile}: nothing has been sent from this profile folder")
    except (OSError, ValueError, KeyError, TypeError) as e:
        return invalid(f"could not read the last request from {LAST_NAME}: {e}")
    try:
        checked = _validate(calls)
    except InvalidRequest as e:
        return invalid(f"the last request in {LAST_NAME} no longer validates: {e}", e.call, e.argument)
    return _await_response(profile, request_id, checked, None, map, timeout, poll)


def _encode_checked(request_id, checked):
    return wire.encode_request(request_id, [(sig["id"], args) for sig, args in checked])


def encode(calls, *, profile=None):
    """The request bytes `run` would send for `calls` now; nothing is sent.

    The request id is the next one for the profile folder, or 1 when no profile resolves.
    Raises InvalidRequest (whose `result` is the Invalid result) when validation fails.
    """
    checked = _validate(calls)
    try:
        request_id = next_request_id(resolve_profile(profile))
    except ProfileError:
        request_id = 1
    return _encode_checked(request_id, checked)


def ping(**options):
    """Send a zero-call request: OK means the module is live and answering."""
    return run([], **options)
