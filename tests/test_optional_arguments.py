"""Optional arguments: any count in a function's min..max range is sent as that count, so XS applies its defaults.

Counts outside the range are Invalid; tests/test_run.py covers that.
"""

import struct

import pytest

from conftest import FAST, FakeModule, i32, section

from xsinject import run

# Ids pinned in xsinject/function_ids.json.
ROUND, CLEAR_INSTRUCTIONS = 63, 203  # round(x, places = ...) takes 1..2; xsClearInstructions takes 0..2


def f32(*vals):
    return b"".join(struct.pack("<f", v) for v in vals)


def sent(profile, calls, *entries):
    """The request bytes `run` wrote for `calls`, answered with OK entries made of `entries` bytes."""
    payload = b"".join(entries)
    answer = lambda rid: {"default1": section(rid, entries=payload, entry_count=len(entries))}
    with FakeModule(profile, answer) as module:
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK", result
    return module.requests[0]


@pytest.mark.parametrize("args, sent_args", [
    ([], b""),
    ([3], i32(0, 3)),
    ([3, 1], i32(0, 3, 0, 1)),
], ids=["no-args", "first-only", "all"])
def test_every_count_from_min_to_max_arguments_is_sent_as_that_count(profile, args, sent_args):
    data = sent(profile, [{"fn": "xsClearInstructions", "args": args}], i32(0, 1))
    assert data == i32(1, 1, CLEAR_INSTRUCTIONS, len(args)) + sent_args


def test_omitting_an_optional_argument_sends_only_the_given_ones(profile):
    calls = [{"fn": "round", "args": [2.5]}, {"fn": "round", "args": [2.5, 0]}]
    data = sent(profile, calls, i32(0) + f32(3), i32(0) + f32(3))
    assert data == (
        i32(1, 2, ROUND, 1, 0) + f32(2.5)
        + i32(ROUND, 2, 0) + f32(2.5) + i32(0, 0)
    )

