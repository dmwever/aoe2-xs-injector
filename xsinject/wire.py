"""Byte layouts shared with the XS module (xs/xsinject.xs). All values are little-endian int32."""

import struct

MAGIC = 0x1A4E5358  # 441340760; a finder only, not a version. XS int literals max out at 9 digits.
REQUEST_FILE = "xsinject"  # stem; the module opens it with xsOpenFile("xsinject")

REQUEST_STATUS = {
    0: "OK",
    1: "Running",
    2: "Truncated",
    3: "UnknownFunction",
    4: "BadArgCount",
    5: "BadTag",
    6: "BadReference",
    7: "ReferenceTypeMismatch",
    8: "TooLarge",
    9: "TrailingBytes",
}
RUNNING = 1  # stored before call #0; a section stuck here means a call stopped the rule

ENTRY_STATUS = {0: "OK", 1: "NotRun"}  # NotRun is reserved; no module path produces it yet
ENTRY_OK = 0

LITERAL = 0  # argument tag; tag 1 (reference) arrives with references

_INT = struct.Struct("<i")
_HEADER = struct.Struct("<6i")  # magic, request id, status, failed call, failed arg, entry count


def encode_request(request_id, calls):
    """Request bytes for `calls`, a list of (function id, [int literal, ...])."""
    out = [_INT.pack(request_id), _INT.pack(len(calls))]
    for fid, args in calls:
        out.append(_INT.pack(fid) + _INT.pack(len(args)))
        for value in args:
            out.append(_INT.pack(LITERAL) + _INT.pack(value))
    return b"".join(out)


def decode_entries(data, return_types):
    """[(entry status, value)] for one entry per return type, or None if `data` doesn't fit them.

    A value follows the status only when the entry is OK and the function is non-void.
    """
    entries, pos = [], 0
    for rtype in return_types:
        if pos + 4 > len(data):
            return None
        status = _INT.unpack_from(data, pos)[0]
        pos += 4
        value = None
        if status == ENTRY_OK and rtype != "void":
            if rtype != "int" or pos + 4 > len(data):
                return None
            value = _INT.unpack_from(data, pos)[0]
            pos += 4
        entries.append((status, value))
    return entries if pos == len(data) else None


def read_request_id(data):
    """The id at the front of a request file's bytes, or None when there isn't one."""
    if len(data) < 4:
        return None
    return _INT.unpack_from(data)[0]


def find_section(data):
    """Decode the response section trailing `data`, or None when there is none.

    Framing: [body][body byte length][magic], where the body opens with the magic too.
    """
    if len(data) < 8 or _INT.unpack_from(data, len(data) - 4)[0] != MAGIC:
        return None
    length = _INT.unpack_from(data, len(data) - 8)[0]
    if length < _HEADER.size or length > len(data) - 8:
        return None
    body = data[len(data) - 8 - length : len(data) - 8]
    magic, request_id, status, failed_call, failed_arg, entry_count = _HEADER.unpack_from(body)
    if magic != MAGIC:
        return None
    return {
        "request_id": request_id,
        "status": status,
        "failed_call": failed_call,
        "failed_argument": failed_arg,
        "entry_count": entry_count,
        "entries_bytes": body[_HEADER.size :],
    }
