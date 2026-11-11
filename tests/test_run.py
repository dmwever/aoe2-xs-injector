import json

from conftest import FAST, FakeModule, i32, section

from xsinject import run

BIT_AND, GET_UNIT_OWNER, GET_MAP_WIDTH = 67, 121, 175  # ids pinned in xsinject/function_ids.json


def answering(*values):
    """A module that answers every request with OK int entries holding `values`."""
    entries = b"".join(i32(0, v) for v in values)
    return lambda rid: {"default1": section(rid, entries=entries, entry_count=len(values))}


def test_one_int_call_returns_its_value(profile):
    with FakeModule(profile, answering(8)):
        result = run([{"fn": "bitAnd", "args": [12, 10]}], profile=profile, **FAST)
    assert result == {
        "request_id": 1,
        "status": "OK",
        "failed_call": None,
        "failed_argument": None,
        "message": "OK",
        "entries": [{"call": 0, "fn": "bitAnd", "status": "OK", "value": 8}],
    }


def test_calls_are_encoded_as_function_id_argument_count_then_tagged_int_literals(profile):
    calls = [{"fn": "bitAnd", "args": [12, -10]}, {"fn": "xsGetMapWidth", "args": []}]
    with FakeModule(profile, answering(4, 120)) as module:
        run(calls, profile=profile, **FAST)
    assert module.requests == [i32(1, 2, BIT_AND, 2, 0, 12, 0, -10, GET_MAP_WIDTH, 0)]
    assert json.loads((profile / "xsinject.last.json").read_text()) == {"request_id": 1, "calls": calls}


def test_every_call_gets_an_entry_in_call_order_and_minus_one_is_a_value(profile):
    calls = [
        {"fn": "bitAnd", "args": [12, 10]},
        {"fn": "xsGetUnitOwner", "args": [999999]},
        {"fn": "xsGetMapWidth", "args": []},
    ]
    with FakeModule(profile, answering(8, -1, 120)):
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "OK"
    assert result["entries"] == [
        {"call": 0, "fn": "bitAnd", "status": "OK", "value": 8},
        {"call": 1, "fn": "xsGetUnitOwner", "status": "OK", "value": -1},
        {"call": 2, "fn": "xsGetMapWidth", "status": "OK", "value": 120},
    ]


def test_args_may_be_omitted_for_a_zero_argument_function(profile):
    with FakeModule(profile, answering(120)) as module:
        result = run([{"fn": "xsGetMapWidth"}], profile=profile, **FAST)
    assert result["entries"][0]["value"] == 120
    assert module.requests == [i32(1, 1, GET_MAP_WIDTH, 0)]


def test_a_failure_message_names_the_function_at_the_failed_call(profile):
    failing = lambda rid: {"default1": section(rid, status=4, failed_call=1)}
    calls = [{"fn": "bitAnd", "args": [1, 2]}, {"fn": "bitOr", "args": [1, 2]}]
    with FakeModule(profile, failing):
        result = run(calls, profile=profile, **FAST)
    assert (result["status"], result["failed_call"], result["entries"]) == ("BadArgCount", 1, [])
    assert result["message"] == "BadArgCount at call #1 (bitOr)"


def test_a_response_that_does_not_fit_the_calls_sent_is_undecodable(profile):
    short = lambda rid: {"default1": section(rid, entries=i32(0, 8), entry_count=1)}
    calls = [{"fn": "bitAnd", "args": [12, 10]}, {"fn": "xsGetMapWidth", "args": []}]
    with FakeModule(profile, short):
        result = run(calls, profile=profile, **FAST)
    assert result["status"] == "Undecodable"
    assert "re-include" in result["message"]


def invalid(profile, calls):
    result = run(calls, profile=profile, **FAST)
    assert result["status"] == "Invalid"
    assert result["request_id"] is None
    assert not (profile / "xsinject.xsdat").exists(), "nothing may be sent"
    assert not (profile / "xsinject.last.json").exists()
    return result


def test_unknown_function_is_invalid(profile):
    result = invalid(profile, [{"fn": "bitAnd", "args": [1, 2]}, {"fn": "xsNoSuchThing", "args": []}])
    assert (result["failed_call"], result["failed_argument"]) == (1, None)
    assert "xsNoSuchThing" in result["message"]


def test_too_many_arguments_is_invalid(profile):
    result = invalid(profile, [{"fn": "bitAnd", "args": [1, 2, 3]}])
    assert result["failed_call"] == 0
    assert "takes 2 arguments, got 3" in result["message"]


def test_too_few_arguments_is_invalid(profile):
    result = invalid(profile, [{"fn": "xsGetPlayerUnitIds", "args": [1]}])
    assert "takes 2..3 arguments, got 1" in result["message"]


def test_a_non_int_literal_for_an_int_parameter_is_invalid(profile):
    for bad in (1.5, "1", True, None, [1, 2, 3]):
        result = invalid(profile, [{"fn": "bitAnd", "args": [1, bad]}])
        assert (result["failed_call"], result["failed_argument"]) == (0, 1)


def test_an_int_literal_outside_32_bits_is_invalid(profile):
    result = invalid(profile, [{"fn": "bitNot", "args": [2**31]}])
    assert "32-bit" in result["message"]


def test_a_request_that_is_not_a_list_of_calls_is_invalid(profile):
    invalid(profile, {"fn": "bitAnd", "args": [1, 2]})
    invalid(profile, ["bitAnd"])
    invalid(profile, [{"args": [1, 2]}])
