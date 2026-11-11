"""References: {"ref": N} passes call N's result into a later call of the same request."""

import struct

import pytest

from conftest import FAST, FakeModule, i32, section

from xsinject import encode, run

# Ids pinned in xsinject/function_ids.json.
IS_RULE_ENABLED, VECTOR_GET_X, VECTOR_SET = 3, 13, 19

REF = 1  # argument tag


def test_a_reference_is_tag_1_then_the_call_number(profile):
    calls = [
        {"fn": "xsVectorSet", "args": [1, 2, 3]},
        {"fn": "xsVectorGetX", "args": [{"ref": 0}]},
    ]
    assert encode(calls, profile=profile) == (
        i32(1, 2, VECTOR_SET, 3, 0) + struct.pack("<f", 1) + i32(0) + struct.pack("<f", 2) + i32(0)
        + struct.pack("<f", 3) + i32(VECTOR_GET_X, 1, REF, 0)
    )


def test_a_chained_request_decodes_each_entry_by_its_own_return_type(profile):
    calls = [
        {"fn": "xsVectorSet", "args": [1.5, 2, 3]},
        {"fn": "xsVectorGetX", "args": [{"ref": 0}]},
    ]
    payload = i32(0) + struct.pack("<3f", 1.5, 2, 3) + i32(0) + struct.pack("<f", 1.5)
    answer = lambda rid: {"default1": section(rid, entries=payload, entry_count=2)}
    with FakeModule(profile, answer) as module:
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK", result
    assert [e["value"] for e in result["entries"]] == [[1.5, 2.0, 3.0], 1.5]
    assert module.requests[0].endswith(i32(VECTOR_GET_X, 1, REF, 0))


def invalid(profile, calls):
    result = run(calls, profile=profile, **FAST)
    assert result["status"] == "Invalid", result
    assert not (profile / "xsinject.xsdat").exists(), "nothing may be sent"
    return result


VEC = {"fn": "xsVectorSet", "args": [1, 2, 3]}


@pytest.mark.parametrize(
    "calls, at, words",
    [
        ([{"fn": "xsVectorGetX", "args": [{"ref": 0}]}], (0, 0), "itself"),
        ([VEC, {"fn": "xsVectorGetX", "args": [{"ref": 1}]}], (1, 0), "itself"),
        ([VEC, {"fn": "xsVectorGetX", "args": [{"ref": 2}]}, VEC], (1, 0), "later call"),
        ([VEC, {"fn": "xsVectorGetX", "args": [{"ref": 5}]}], (1, 0), "no call #5"),
        ([VEC, {"fn": "xsVectorGetX", "args": [{"ref": -1}]}], (1, 0), "no call #-1"),
    ],
    ids=["self-first", "self", "forward", "out-of-range", "negative"],
)
def test_a_reference_must_point_to_an_earlier_call(profile, calls, at, words):
    result = invalid(profile, calls)
    assert (result["failed_call"], result["failed_argument"]) == at
    assert words in result["message"]


def test_a_reference_to_a_void_call_is_invalid(profile):
    calls = [{"fn": "xsChatData", "args": ["hi"]}, {"fn": "xsIsRuleEnabled", "args": [{"ref": 0}]}]
    result = invalid(profile, calls)
    assert (result["failed_call"], result["failed_argument"]) == (1, 0)
    assert "void" in result["message"]


@pytest.mark.parametrize(
    "first, second",
    [
        ({"fn": "xsGetString", "args": [1]}, {"fn": "xsVectorGetX", "args": [{"ref": 0}]}),  # string -> vector
        ({"fn": "xsVectorGetX", "args": [[1, 2, 3]]}, {"fn": "xsGetString", "args": [{"ref": 0}]}),  # float -> int
        ({"fn": "xsIsRuleEnabled", "args": ["r"]}, {"fn": "xsGetString", "args": [{"ref": 0}]}),  # bool -> int
    ],
    ids=["string-to-vector", "float-to-int", "bool-to-int"],
)
def test_a_reference_whose_return_type_does_not_match_the_parameter_is_invalid(profile, first, second):
    result = invalid(profile, [first, second])
    assert (result["failed_call"], result["failed_argument"]) == (1, 0)
    assert "returns" in result["message"]


@pytest.mark.parametrize("bad", [{"ref": "0"}, {"ref": True}, {"ref": 0.0}, {"ref": 0, "x": 1}, {"ref": None}])
def test_a_malformed_reference_is_invalid(profile, bad):
    result = invalid(profile, [VEC, {"fn": "xsVectorGetX", "args": [bad]}])
    assert (result["failed_call"], result["failed_argument"]) == (1, 0)
    assert "ref" in result["message"]


def test_a_string_result_can_feed_a_string_parameter(profile):
    calls = [
        {"fn": "xsGetString", "args": [1]},
        {"fn": "xsIsRuleEnabled", "args": [{"ref": 0}]},
    ]
    assert encode(calls, profile=profile).endswith(i32(IS_RULE_ENABLED, 1, REF, 0))
