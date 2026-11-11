"""Byte layouts shared with the XS module (xs/xsinject.xs).

Little-endian: ints int32, floats IEEE 32-bit, a vector three floats, bool an int, a string a
uint32 byte length then raw bytes.
"""

import math
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

LITERAL = 0  # argument tags
REFERENCE = 1


class Ref(int):
    """A reference argument: the number of an earlier call in the same request."""

_INT = struct.Struct("<i")
_UINT = struct.Struct("<I")
_FLOAT = struct.Struct("<f")
_VECTOR = struct.Struct("<3f")
_HEADER = struct.Struct("<6i")  # magic, request id, status, failed call, failed arg, entry count


def encode_value(xs_type, value):
    """`value` in the wire layout of `xs_type`; the driver has already checked that it fits.

    Bool crosses as int; a string is a uint32 byte length then its raw UTF-8 bytes.
    """
    if xs_type == "int":
        return _INT.pack(value)
    if xs_type == "bool":
        return _INT.pack(1 if value else 0)
    if xs_type == "float":
        return _FLOAT.pack(value)
    if xs_type == "vector":
        return _VECTOR.pack(*value)
    if xs_type == "string":
        raw = value.encode("utf-8")
        return _UINT.pack(len(raw)) + raw
    raise ValueError(f"no wire layout for {xs_type!r}")


def encode_request(request_id, calls):
    """Request bytes for `calls`, a list of (function id, [(param type, argument), ...]).

    An argument is a literal, or a Ref sent as tag 1 plus the call number.
    """
    out = [_INT.pack(request_id), _INT.pack(len(calls))]
    for fid, args in calls:
        out.append(_INT.pack(fid) + _INT.pack(len(args)))
        for xs_type, value in args:
            if isinstance(value, Ref):
                out.append(_INT.pack(REFERENCE) + _INT.pack(value))
            else:
                out.append(_INT.pack(LITERAL) + encode_value(xs_type, value))
    return b"".join(out)


def fits_float32(value):
    """Whether the number `value` is finite and within 32-bit float range."""
    try:
        if not math.isfinite(value):
            return False
        _FLOAT.pack(value)
    except OverflowError:  # out of float32 range, or an int too big for a double
        return False
    return True


def float32(value):
    """The shortest decimal that is the same 32-bit float as `value` (0.1, not 0.10000000149)."""
    if not math.isfinite(value):
        return value
    packed = _FLOAT.pack(value)
    for digits in range(1, 10):
        short = float(f"{value:.{digits}g}")
        if _FLOAT.pack(short) == packed:
            return short
    return value


def _decode_value(xs_type, data, pos):
    """(value, next position) for one value of `xs_type` at `pos`, or None if it runs past `data`."""
    if xs_type in ("int", "bool"):
        if pos + 4 > len(data):
            return None
        value = _INT.unpack_from(data, pos)[0]
        return (value != 0 if xs_type == "bool" else value), pos + 4
    if xs_type == "float":
        if pos + 4 > len(data):
            return None
        return float32(_FLOAT.unpack_from(data, pos)[0]), pos + 4
    if xs_type == "vector":
        if pos + 12 > len(data):
            return None
        return [float32(v) for v in _VECTOR.unpack_from(data, pos)], pos + 12
    if xs_type == "string":
        if pos + 4 > len(data):
            return None
        length = _UINT.unpack_from(data, pos)[0]
        pos += 4
        if pos + length > len(data):
            return None
        return data[pos : pos + length].decode("utf-8", errors="replace"), pos + length
    return None


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
            decoded = _decode_value(rtype, data, pos)
            if decoded is None:
                return None
            value, pos = decoded
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
