"""Every XS value type crossing the wire: literal validation and encoding, return decoding, void entries."""

import json
import math
import struct

import pytest

from conftest import FAST, FakeModule, i32, section

from xsinject import InvalidRequest, encode, run

# Ids pinned in xsinject/function_ids.json.
IS_RULE_ENABLED, VECTOR_GET_X, VECTOR_SET, ARRAY_CREATE_BOOL, CHAT_DATA, GET_STRING = 3, 13, 19, 24, 195, 197


def f32(*vals):
    return b"".join(struct.pack("<f", v) for v in vals)


def xs_string(text):
    raw = text.encode("utf-8")
    return struct.pack("<I", len(raw)) + raw


def sent(profile, calls, *entries):
    """The request bytes `run` wrote for `calls`, answered with OK entries made of `entries` bytes."""
    payload = b"".join(entries)
    answer = lambda rid: {"default1": section(rid, entries=payload, entry_count=len(entries))}
    with FakeModule(profile, answer) as module:
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK", result
    return module.requests[0]


# --- literals: encoded as the parameter's declared type ---------------------------------------


def test_float_literals_are_encoded_as_32_bit_floats_and_ints_are_accepted_for_floats(profile):
    data = sent(profile, [{"fn": "xsVectorSet", "args": [1.5, -2, 0.25]}], i32(0) + f32(1.5, -2, 0.25))
    assert data == i32(1, 1, VECTOR_SET, 3, 0) + f32(1.5) + i32(0) + f32(-2.0) + i32(0) + f32(0.25)


def test_string_literals_are_a_length_then_raw_utf8_bytes(profile):
    data = sent(profile, [{"fn": "xsIsRuleEnabled", "args": ["héllo ✓"]}], i32(0, 1))
    raw = "héllo ✓".encode("utf-8")
    assert data == i32(1, 1, IS_RULE_ENABLED, 1, 0, len(raw)) + raw


def test_vector_literals_are_three_floats(profile):
    data = sent(profile, [{"fn": "xsVectorGetX", "args": [[1, 2.5, -3]]}], i32(0) + f32(1))
    assert data == i32(1, 1, VECTOR_GET_X, 1, 0) + f32(1.0, 2.5, -3.0)


def test_bool_literals_are_sent_as_int(profile):
    calls = [{"fn": "xsArrayCreateBool", "args": [4, True, "a"]}, {"fn": "xsArrayCreateBool", "args": [4, False]}]
    data = sent(profile, calls, i32(0, 7), i32(0, 8))
    assert data == (
        i32(1, 2, ARRAY_CREATE_BOOL, 3, 0, 4, 0, 1, 0) + xs_string("a")
        + i32(ARRAY_CREATE_BOOL, 2, 0, 4, 0, 0)
    )


def invalid(profile, calls):
    result = run(calls, profile=profile, **FAST)
    assert result["status"] == "Invalid", result
    assert not (profile / "xsinject.xsdat").exists(), "nothing may be sent"
    return result


@pytest.mark.parametrize("bad", ["1.5", True, None, [1.5], {"x": 1}, 1e39, 10**400, math.inf, math.nan])
def test_a_literal_that_is_not_a_finite_32_bit_float_is_invalid_for_a_float_parameter(profile, bad):
    result = invalid(profile, [{"fn": "xsVectorSet", "args": [1.0, bad, 0.0]}])
    assert (result["failed_call"], result["failed_argument"]) == (0, 1)
    assert "float" in result["message"]


@pytest.mark.parametrize("bad", [1, 1.5, True, None, ["a"]])
def test_a_non_string_literal_is_invalid_for_a_string_parameter(profile, bad):
    result = invalid(profile, [{"fn": "xsIsRuleEnabled", "args": [bad]}])
    assert (result["failed_call"], result["failed_argument"]) == (0, 0)
    assert "string" in result["message"]


@pytest.mark.parametrize("bad", [[1, 2], [1, 2, 3, 4], [1, 2, "3"], [True, 1, 2], [1, 2, 1e39], [1, 2, 10**400], "v", 1, None])
def test_anything_but_three_finite_numbers_is_invalid_for_a_vector_parameter(profile, bad):
    result = invalid(profile, [{"fn": "xsVectorGetX", "args": [bad]}])
    assert (result["failed_call"], result["failed_argument"]) == (0, 0)
    assert "vector" in result["message"]


@pytest.mark.parametrize("bad", [1, 0, "true", None, 1.0])
def test_only_true_or_false_is_valid_for_a_bool_parameter(profile, bad):
    result = invalid(profile, [{"fn": "xsArrayCreateBool", "args": [4, bad]}])
    assert (result["failed_call"], result["failed_argument"]) == (0, 1)
    assert "bool" in result["message"]


# --- returns: decoded by the return types of the calls sent -----------------------------------


def entries(profile, calls, payload):
    answer = lambda rid: {"default1": section(rid, entries=payload, entry_count=len(calls))}
    with FakeModule(profile, answer):
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK", result
    return [(e["fn"], e["status"], e["value"]) for e in result["entries"]]


def test_float_returns_decode_to_their_shortest_float32_spelling(profile):
    calls = [{"fn": "xsVectorGetX", "args": [[0.1, 0, 0]]}, {"fn": "xsVectorGetX", "args": [[-2.5, 0, 0]]}]
    assert entries(profile, calls, i32(0) + f32(0.1) + i32(0) + f32(-2.5)) == [
        ("xsVectorGetX", "OK", 0.1),
        ("xsVectorGetX", "OK", -2.5),
    ]


def test_vector_returns_decode_to_a_list_of_three(profile):
    calls = [{"fn": "xsVectorSet", "args": [1, 2.5, 0.1]}]
    assert entries(profile, calls, i32(0) + f32(1, 2.5, 0.1)) == [("xsVectorSet", "OK", [1.0, 2.5, 0.1])]


def test_bool_returns_cross_as_int_and_decode_to_true_or_false(profile):
    calls = [{"fn": "xsIsRuleEnabled", "args": ["a"]}, {"fn": "xsIsRuleEnabled", "args": ["b"]}]
    assert entries(profile, calls, i32(0, 1, 0, 0)) == [
        ("xsIsRuleEnabled", "OK", True),
        ("xsIsRuleEnabled", "OK", False),
    ]


def test_string_returns_decode_utf8_byte_exact(profile):
    calls = [{"fn": "xsGetString", "args": [1]}, {"fn": "xsGetString", "args": [2]}]
    assert entries(profile, calls, i32(0) + xs_string("Ça ✓ 日本") + i32(0) + xs_string("")) == [
        ("xsGetString", "OK", "Ça ✓ 日本"),
        ("xsGetString", "OK", ""),
    ]


def test_a_void_entry_is_the_status_alone_and_keeps_call_numbers_aligned(profile):
    calls = [
        {"fn": "xsGetString", "args": [1]},
        {"fn": "xsChatData", "args": ["hi"]},
        {"fn": "xsVectorGetX", "args": [[3, 0, 0]]},
    ]
    answer = lambda rid: {
        "default1": section(rid, entries=i32(0) + xs_string("x") + i32(0) + i32(0) + f32(3), entry_count=3)
    }
    with FakeModule(profile, answer):
        result = run(calls, profile=profile, **FAST)
    assert result["entries"] == [
        {"call": 0, "fn": "xsGetString", "status": "OK", "value": "x"},
        {"call": 1, "fn": "xsChatData", "status": "OK", "value": None},
        {"call": 2, "fn": "xsVectorGetX", "status": "OK", "value": 3.0},
    ]


def test_a_string_running_past_the_section_is_undecodable(profile):
    calls = [{"fn": "xsGetString", "args": [1]}]
    answer = lambda rid: {"default1": section(rid, entries=i32(0, 50) + b"short", entry_count=1)}
    with FakeModule(profile, answer):
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "Undecodable"


def test_a_string_that_is_not_utf8_still_decodes(profile):
    calls = [{"fn": "xsGetString", "args": [1]}]
    answer = lambda rid: {"default1": section(rid, entries=i32(0, 2) + b"\xe9a", entry_count=1)}
    with FakeModule(profile, answer):
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK"
    assert result["entries"][0]["value"].endswith("a")
    json.dumps(result)  # the result stays printable


# --- encode: the request bytes, unsent ---------------------------------------------------------


def test_encode_returns_the_bytes_run_would_send_without_sending(profile):
    (profile / "xsinject.xsdat").write_bytes(i32(6, 0))
    calls = [{"fn": "xsIsRuleEnabled", "args": ["r"]}, {"fn": "xsVectorGetX", "args": [[1, 2, 3]]}]
    assert encode(calls, profile=profile) == (
        i32(7, 2, IS_RULE_ENABLED, 1, 0) + xs_string("r") + i32(VECTOR_GET_X, 1, 0) + f32(1, 2, 3)
    )
    assert (profile / "xsinject.xsdat").read_bytes() == i32(6, 0), "nothing may be sent"


def test_encode_rejects_an_invalid_request_with_the_invalid_result():
    with pytest.raises(InvalidRequest) as caught:
        encode([{"fn": "xsVectorGetX", "args": ["v"]}])
    assert caught.value.result["status"] == "Invalid"
    assert (caught.value.result["failed_call"], caught.value.result["failed_argument"]) == (0, 0)
