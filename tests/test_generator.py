"""Generator seam: catalog + renames + pinned table in; signatures, pinned table and dispatch out."""

import json
import re

import pytest

from xsinject.generate import GeneratorError, generate, main


def fn(name, params=(), returns="int", min_count=None):
    """An entry shaped like the repo's catalog/functions.json."""
    ps = [{"name": f"p{k}", "type": t} for k, t in enumerate(params)]
    return {
        "name": name,
        "return_type": returns,
        "param_count": len(ps),
        "min_param_count": len(ps) if min_count is None else min_count,
        "params": ps,
    }


def ids(result):
    return {s["name"]: s["id"] for s in result.signatures["functions"]}


def test_first_run_numbers_functions_in_catalog_order():
    result = generate([fn("a"), fn("b"), fn("c")], renames=[], pinned=None)
    assert ids(result) == {"a": 0, "b": 1, "c": 2}
    assert result.pinned["functions"] == {"a": 0, "b": 1, "c": 2}


def test_pinned_ids_survive_catalog_reordering():
    pinned = {"functions": {"a": 0, "b": 1}, "retired": {}}
    result = generate([fn("b"), fn("a")], renames=[], pinned=pinned)
    assert ids(result) == {"a": 0, "b": 1}


def test_new_function_takes_the_next_free_id_and_never_a_retired_one():
    pinned = {"functions": {"a": 0}, "retired": {"gone": 5}}
    result = generate([fn("new"), fn("a")], renames=[], pinned=pinned)
    assert ids(result) == {"a": 0, "new": 6}
    assert result.pinned == {"functions": {"a": 0, "new": 6}, "retired": {"gone": 5}}


def test_a_pinned_function_leaving_the_catalog_without_a_rename_fails_naming_it():
    pinned = {"functions": {"a": 0, "xsVanished": 1}, "retired": {}}
    with pytest.raises(GeneratorError, match="xsVanished"):
        generate([fn("a")], renames=[], pinned=pinned)


def test_a_renamed_function_keeps_its_id():
    pinned = {"functions": {"xsGetLocalPlayerId": 0, "b": 1}, "retired": {}}
    renames = [{"old_name": "xsGetLocalPlayerId", "new_name": "xsUnsyncGetLocalPlayerId"}]
    result = generate([fn("b"), fn("xsUnsyncGetLocalPlayerId")], renames=renames, pinned=pinned)
    assert ids(result) == {"xsUnsyncGetLocalPlayerId": 0, "b": 1}
    assert result.pinned["functions"] == {"xsUnsyncGetLocalPlayerId": 0, "b": 1}


def test_renames_chain_across_several_updates():
    pinned = {"functions": {"v1": 3}, "retired": {}}
    renames = [{"old_name": "v1", "new_name": "v2"}, {"old_name": "v2", "new_name": "v3"}]
    result = generate([fn("v3")], renames=renames, pinned=pinned)
    assert ids(result) == {"v3": 3}


def test_a_removal_named_for_retirement_retires_its_id_for_good():
    pinned = {"functions": {"a": 0, "gone": 1}, "retired": {}}
    result = generate([fn("a")], renames=[], pinned=pinned, retire=["gone"])
    assert result.pinned == {"functions": {"a": 0}, "retired": {"gone": 1}}
    assert ids(result) == {"a": 0}

    later = generate([fn("a"), fn("fresh")], renames=[], pinned=result.pinned)
    assert ids(later)["fresh"] == 2


def test_retiring_a_function_still_in_the_catalog_excludes_it_from_signatures_and_dispatch():
    pinned = {"functions": {"a": 0, "xsTask": 1}, "retired": {}}
    result = generate([fn("a"), fn("xsTask", returns="void")], renames=[], pinned=pinned, retire=["xsTask"])
    assert ids(result) == {"a": 0}
    assert result.pinned == {"functions": {"a": 0}, "retired": {"xsTask": 1}}
    assert "case 1:" not in result.dispatch
    assert "xsTask(" not in result.dispatch


def test_retiring_a_name_without_a_pinned_id_fails():
    with pytest.raises(GeneratorError, match="'nope'"):
        generate([fn("a")], renames=[], pinned={"functions": {"a": 0}, "retired": {}}, retire=["nope"])


def test_a_retired_function_still_in_the_catalog_stays_excluded_on_later_runs():
    pinned = {"functions": {"a": 0}, "retired": {"xsTask": 1}}
    result = generate([fn("a"), fn("xsTask"), fn("fresh")], renames=[], pinned=pinned)
    assert ids(result) == {"a": 0, "fresh": 2}
    assert result.pinned["retired"] == {"xsTask": 1}


def test_signatures_carry_types_argument_range_and_return_type_in_id_order():
    catalog = [
        fn("round", ["float", "int"], returns="float", min_count=1),
        fn("xsChatData", ["string", "int"], returns="void", min_count=1),
    ]
    pinned = {"functions": {"xsChatData": 0, "round": 1}, "retired": {}}
    result = generate(catalog, renames=[], pinned=pinned)
    assert result.signatures["functions"] == [
        {
            "name": "xsChatData",
            "id": 0,
            "params": [{"name": "p0", "type": "string"}, {"name": "p1", "type": "int"}],
            "min_args": 1,
            "max_args": 2,
            "returns": "void",
        },
        {
            "name": "round",
            "id": 1,
            "params": [{"name": "p0", "type": "float"}, {"name": "p1", "type": "int"}],
            "min_args": 1,
            "max_args": 2,
            "returns": "float",
        },
    ]


@pytest.mark.parametrize(
    "entry",
    [
        fn("xsOdd", ["int[]"]),
        fn("xsOdd", returns="char"),
        {**fn("xsOdd", ["int"]), "param_count": 2},
        fn("xsOdd", ["int"], min_count=2),
    ],
)
def test_an_inexpressible_or_inconsistent_signature_fails_naming_the_function(entry):
    with pytest.raises(GeneratorError, match="xsOdd"):
        generate([entry], renames=[], pinned=None)


def case_block(dispatch, fid):
    """The XS text of `case <fid>:` up to the next case (or the end of the switch)."""
    found = re.search(rf"case {fid}: \{{(.*?)(?=\n\s*case \d+:|\n\s*\}}\n\}})", dispatch, re.S)
    assert found, f"no case {fid}"
    return found.group(1)


def call_sites(block, name):
    """Each `name(...)` call in `block`, as its list of top-level argument texts."""
    sites = []
    for m in re.finditer(rf"\b{name}\(", block):
        depth, start, args, i = 1, m.end(), [], m.end()
        while depth:
            c = block[i]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif c == "," and depth == 1:
                args.append(block[start:i].strip())
                start = i + 1
            i += 1
        last = block[start : i - 1].strip()
        sites.append(args + [last] if last or args else [])
    return sites


def test_dispatch_has_one_case_per_function_and_one_call_site_per_allowed_argument_count():
    catalog = [
        fn("xsGetGameTime"),
        fn("round", ["float", "int"], returns="float", min_count=1),
        fn("xsOptional", ["int", "string", "vector"], returns="void", min_count=0),
    ]
    dispatch = generate(catalog, renames=[], pinned=None).dispatch
    assert sorted(int(n) for n in re.findall(r"case (\d+):", dispatch)) == [0, 1, 2]
    assert [len(s) for s in call_sites(case_block(dispatch, 0), "xsGetGameTime")] == [0]
    assert sorted(len(s) for s in call_sites(case_block(dispatch, 1), "round")) == [1, 2]
    assert sorted(len(s) for s in call_sites(case_block(dispatch, 2), "xsOptional")) == [0, 1, 2, 3]


def test_dispatch_reads_each_argument_from_the_staged_array_of_its_type():
    catalog = [fn("xsMixed", ["int", "float", "bool", "string", "vector"], returns="void")]
    dispatch = generate(catalog, renames=[], pinned=None).dispatch
    [site] = call_sites(case_block(dispatch, 0), "xsMixed")
    getters = [re.match(r"xsArrayGet(\w+)\(", a).group(1) for a in site]
    assert getters == ["Int", "Float", "Bool", "String", "Vector"]
    # Argument k of the call is the k-th staged value after the call's base.
    assert [re.search(r"\+ (\d+)\)$", a).group(1) for a in site] == ["0", "1", "2", "3", "4"]


@pytest.mark.parametrize("returns, setter", [
    ("int", "Int"), ("float", "Float"), ("bool", "Bool"), ("string", "String"), ("vector", "Vector"),
])
def test_a_non_void_result_goes_to_the_result_array_of_its_return_type(returns, setter):
    dispatch = generate([fn("xsThing", returns=returns)], renames=[], pinned=None).dispatch
    block = case_block(dispatch, 0)
    [store] = call_sites(block, f"xsArraySet{setter}")
    assert store[2] == "xsThing()"
    assert len(call_sites(block, r"xsArraySet\w+")) == 1


def test_a_void_call_is_a_bare_statement():
    dispatch = generate([fn("xsChatData", ["string"], returns="void")], renames=[], pinned=None).dispatch
    block = case_block(dispatch, 0)
    assert call_sites(block, r"xsArraySet\w+") == []
    assert re.search(r"^\s*xsChatData\(.*\);$", block, re.M)


def type_table(dispatch):
    """{fid: (min, max, return type, [param types])} as the generated XS table defines it."""
    table, current = {}, None
    for line in dispatch.splitlines():
        if m := re.match(r"\s*xsInjectDefine\((\d+), (\d+), (\d+), cXsInjectType(\w+)\);", line):
            current = int(m.group(1))
            table[current] = (int(m.group(2)), int(m.group(3)), m.group(4), [])
        elif m := re.match(r"\s*xsInjectParam\(cXsInjectType(\w+)\);", line):
            table[current][3].append(m.group(1))
    return table


def test_the_parameter_type_table_defines_every_function_and_leaves_retired_ids_unknown():
    catalog = [
        fn("round", ["float", "int"], returns="float", min_count=1),
        fn("xsChatData", ["string", "bool", "vector"], returns="void"),
    ]
    pinned = {"functions": {"round": 0}, "retired": {"gone": 1}}
    dispatch = generate(catalog, renames=[], pinned=pinned).dispatch
    assert type_table(dispatch) == {
        0: (1, 2, "Float", ["Float", "Int"]),
        2: (3, 3, "Void", ["String", "Bool", "Vector"]),
    }
    assert re.search(r"const int cXsInjectFunctionIdLimit = 3;", dispatch)
    assert re.search(r"const int cXsInjectParamTotal = 5;", dispatch)


@pytest.fixture
def files(tmp_path):
    kb = tmp_path / "kb"
    kb.mkdir()
    out = tmp_path / "out"
    out.mkdir()
    paths = {
        "kb": kb,
        "pinned": out / "function_ids.json",
        "signatures": out / "signatures.json",
        "dispatch": out / "dispatch.xs",
    }
    args = ["--catalog", str(kb / "functions.json"), "--renames", str(kb / "renames.json"),
            "--pinned", str(paths["pinned"]),
            "--signatures", str(paths["signatures"]), "--dispatch", str(paths["dispatch"])]
    return paths, args


def write_kb(kb, catalog, renames=()):
    (kb / "functions.json").write_text(json.dumps(catalog))
    (kb / "renames.json").write_text(json.dumps(list(renames)))


def test_cli_writes_signatures_pinned_table_and_dispatch_and_rereads_the_table(files):
    paths, args = files
    write_kb(paths["kb"], [fn("a"), fn("b", ["float"], returns="void")])
    assert main(args) == 0
    sigs = json.loads(paths["signatures"].read_text())
    assert [(s["name"], s["id"]) for s in sigs["functions"]] == [("a", 0), ("b", 1)]
    assert json.loads(paths["pinned"].read_text()) == {"functions": {"a": 0, "b": 1}, "retired": {}}
    assert "case 1: {" in paths["dispatch"].read_text()

    write_kb(paths["kb"], [fn("c"), fn("b", ["float"], returns="void")])
    assert main(args + ["--retire", "a"]) == 0
    assert json.loads(paths["pinned"].read_text()) == {"functions": {"b": 1, "c": 2}, "retired": {"a": 0}}


def test_cli_failure_names_the_function_and_writes_nothing(files, capsys):
    paths, args = files
    write_kb(paths["kb"], [fn("a"), fn("b")])
    assert main(args) == 0
    before = {k: paths[k].read_bytes() for k in ("pinned", "signatures", "dispatch")}

    write_kb(paths["kb"], [fn("a")])
    assert main(args) == 1
    assert re.search(r"without a rename entry: b\b", capsys.readouterr().err)
    assert {k: paths[k].read_bytes() for k in before} == before


def test_the_handles_the_core_assigns_are_extern():
    """XS globals are private to their file; the core sets these handles, so they must be extern."""
    dispatch = generate([fn("a")], renames=[], pinned=None).dispatch
    declared = re.findall(r"^(extern )?int (gXsInject(?:Arg|Res)\w+) = -1;$", dispatch, re.M)
    assert len(declared) == 10
    assert all(ext for ext, _ in declared)


def test_a_rename_onto_a_retired_name_fails_rather_than_giving_one_name_two_ids():
    pinned = {"functions": {"old": 0}, "retired": {"new": 1}}
    with pytest.raises(GeneratorError, match="'new'"):
        generate([fn("new")], renames=[{"old_name": "old", "new_name": "new"}], pinned=pinned)


def test_every_default_input_and_output_lives_inside_this_repo():
    """The toolkit is standalone: regenerating never reaches outside the repo."""
    from pathlib import Path
    import xsinject.generate as g

    repo = Path(g.__file__).resolve().parent.parent
    for action in g.build_parser()._actions:
        if isinstance(action.default, Path):
            assert action.default.resolve().is_relative_to(repo), action.dest
            assert action.dest == "pinned" or action.default.exists(), action.dest
