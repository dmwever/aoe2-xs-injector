"""Generator: catalog + renames + pinned id table -> signatures.json, pinned table, XS dispatch.

Standalone: every input lives in this repo. catalog/functions.json and catalog/renames.json were
seeded once (2026-11-11) from AoE2_AI_Modder's xs_functions_catalog.json and xs_renames.json; this
repo owns them now, and signature corrections are made here.
"""

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

VALUE_TYPES = ("int", "float", "bool", "string", "vector")


class GeneratorError(Exception):
    pass


@dataclass
class Result:
    signatures: dict
    pinned: dict
    dispatch: str


def generate(catalog, renames, pinned, retire=None):
    """Raises GeneratorError on anything that would let an id shift or a signature go unexpressed.

    `retire` maps each name to retire on this run to the reason it is retired.
    """
    for f in catalog:
        _check_signature(f)
    assigned, retired = _assign_ids([f["name"] for f in catalog], renames, pinned, retire or {})
    pinned_out = {
        "functions": _by_id(assigned),
        "retired": dict(sorted(retired.items(), key=lambda kv: kv[1]["id"])),
    }
    live = [f for f in catalog if f["name"] in assigned]
    sigs = sorted((_signature(f, assigned[f["name"]]) for f in live), key=lambda s: s["id"])
    return Result({"functions": sigs}, pinned_out, _dispatch(sigs))


def build_parser():
    p = argparse.ArgumentParser(
        prog="python -m xsinject.generate",
        description="Regenerate signatures.json, the pinned id table and the XS dispatch from catalog/.",
    )
    p.add_argument("--catalog", type=Path, default=REPO / "catalog" / "functions.json")
    p.add_argument("--renames", type=Path, default=REPO / "catalog" / "renames.json")
    p.add_argument("--pinned", type=Path, default=REPO / "xsinject" / "function_ids.json")
    p.add_argument("--signatures", type=Path, default=REPO / "xsinject" / "signatures.json")
    p.add_argument("--dispatch", type=Path, default=REPO / "xs" / "xsinject_dispatch.xs")
    p.add_argument("--retire", action="append", nargs=2, default=[], metavar=("NAME", "REASON"),
                   help="retire a pinned function, recording why: its id is never reused and it is left out of "
                        "the dispatch, whether it left the catalog or is still listed (e.g. deprecated). Repeatable")
    return p


def main(argv=None):
    a = build_parser().parse_args(argv)

    try:
        catalog = json.loads(a.catalog.read_text(encoding="utf-8"))
        renames = json.loads(a.renames.read_text(encoding="utf-8"))
        pinned = json.loads(a.pinned.read_text(encoding="utf-8")) if a.pinned.exists() else None
        result = generate(catalog, renames, pinned, retire=dict(a.retire))
    except (GeneratorError, OSError, ValueError, KeyError) as e:
        print(f"generate: {e}", file=sys.stderr)
        return 1

    _write(a.signatures, json.dumps(result.signatures, indent=2) + "\n")
    _write(a.pinned, json.dumps(result.pinned, indent=2) + "\n")
    _write(a.dispatch, result.dispatch)
    print(f"{len(result.signatures['functions'])} functions, "
          f"{len(result.pinned['retired'])} retired -> {a.signatures}, {a.pinned}, {a.dispatch}")
    return 0


def _write(path, text):
    path.write_text(text, encoding="ascii", newline="\n")



def _check_signature(f):
    name = f["name"]
    for p in f["params"]:
        if p["type"] not in VALUE_TYPES:
            raise GeneratorError(f"{name}: parameter {p['name']!r} has type {p['type']!r}, not one of {VALUE_TYPES}")
    if f["return_type"] not in VALUE_TYPES + ("void",):
        raise GeneratorError(f"{name}: return type {f['return_type']!r} is not one of {VALUE_TYPES + ('void',)}")
    if f["param_count"] != len(f["params"]):
        raise GeneratorError(f"{name}: param_count {f['param_count']} but {len(f['params'])} params listed")
    if not 0 <= f["min_param_count"] <= f["param_count"]:
        raise GeneratorError(f"{name}: min_param_count {f['min_param_count']} outside 0..{f['param_count']}")


def _signature(f, fid):
    return {
        "name": f["name"],
        "id": fid,
        "params": [{"name": p["name"], "type": p["type"]} for p in f["params"]],
        "min_args": f["min_param_count"],
        "max_args": f["param_count"],
        "returns": f["return_type"],
    }


_XS_NAME = {"int": "Int", "float": "Float", "bool": "Bool", "string": "String", "vector": "Vector"}


def _call_site(sig, argc):
    args = ", ".join(
        f"xsArrayGet{_XS_NAME[p['type']]}(gXsInjectArg{_XS_NAME[p['type']]}, argBase + {k})"
        for k, p in enumerate(sig["params"][:argc])
    )
    call = f"{sig['name']}({args})"
    if sig["returns"] == "void":
        return f"{call};"
    t = _XS_NAME[sig["returns"]]
    return f"xsArraySet{t}(gXsInjectRes{t}, slot, {call});"


def _case(sig):
    lines = [f"        case {sig['id']}: {{  // {sig['name']}"]
    for argc in range(sig["min_args"], sig["max_args"] + 1):
        lines += [
            f"            if (argc == {argc}) {{",
            f"                {_call_site(sig, argc)}",
            "            }",
        ]
    lines.append("        }")
    return "\n".join(lines)


_HEADER = """\
// GENERATED by xsinject/generate.py from catalog/ and xsinject/function_ids.json.
// Do not edit by hand: regenerate, then re-include the core (xs/xsinject.xs) in every host.
//
// The core includes this file. XS keeps constants and globals private to their file, so every
// one here is extern for the core to see. The core owns the arrays behind the handles below: it
// creates them, stages each call's arguments into the gXsInjectArg* arrays (one shared index),
// and reads results from the gXsInjectRes* arrays at the call's index. Bools are native bool arrays.

extern int gXsInjectArgInt = -1;
extern int gXsInjectArgFloat = -1;
extern int gXsInjectArgBool = -1;
extern int gXsInjectArgString = -1;
extern int gXsInjectArgVector = -1;
extern int gXsInjectResInt = -1;
extern int gXsInjectResFloat = -1;
extern int gXsInjectResBool = -1;
extern int gXsInjectResString = -1;
extern int gXsInjectResVector = -1;

// Value types in the parameter-type table.
extern const int cXsInjectTypeInt = 0;
extern const int cXsInjectTypeFloat = 1;
extern const int cXsInjectTypeBool = 2;
extern const int cXsInjectTypeString = 3;
extern const int cXsInjectTypeVector = 4;
extern const int cXsInjectTypeVoid = 5;

// Function ids run 0..cXsInjectFunctionIdLimit-1; a retired or unused id is unknown (max args -1).
extern const int cXsInjectFunctionIdLimit = {function_slots};
extern const int cXsInjectParamTotal = {param_slots};

extern int gXsInjectFnMinArgs = -1;
extern int gXsInjectFnMaxArgs = -1;
extern int gXsInjectFnReturn = -1;
extern int gXsInjectFnParamStart = -1;
extern int gXsInjectParamTypes = -1;
extern int gXsInjectParamCount = 0;

void xsInjectDefine(int fid = -1, int minArgs = 0, int maxArgs = 0, int returnType = 0) {{
    xsArraySetInt(gXsInjectFnMinArgs, fid, minArgs);
    xsArraySetInt(gXsInjectFnMaxArgs, fid, maxArgs);
    xsArraySetInt(gXsInjectFnReturn, fid, returnType);
    xsArraySetInt(gXsInjectFnParamStart, fid, gXsInjectParamCount);
}}

void xsInjectParam(int paramType = 0) {{
    xsArraySetInt(gXsInjectParamTypes, gXsInjectParamCount, paramType);
    gXsInjectParamCount++;
}}

bool xsInjectKnownFunction(int fid = -1) {{
    if ((fid < 0) || (fid >= cXsInjectFunctionIdLimit)) {{
        return (false);
    }}
    return (xsArrayGetInt(gXsInjectFnMaxArgs, fid) >= 0);
}}

// The accessors below expect a known function id.
int xsInjectMinArgs(int fid = -1) {{
    return (xsArrayGetInt(gXsInjectFnMinArgs, fid));
}}

int xsInjectMaxArgs(int fid = -1) {{
    return (xsArrayGetInt(gXsInjectFnMaxArgs, fid));
}}

int xsInjectReturnType(int fid = -1) {{
    return (xsArrayGetInt(gXsInjectFnReturn, fid));
}}

int xsInjectParamType(int fid = -1, int argIndex = 0) {{
    return (xsArrayGetInt(gXsInjectParamTypes, xsArrayGetInt(gXsInjectFnParamStart, fid) + argIndex));
}}

// Builds the parameter-type table; the core calls this once before parsing any request.
void xsInjectSignaturesInit() {{
    gXsInjectFnMinArgs = xsArrayCreateInt({function_array}, -1, "xsInjectFnMinArgs");
    gXsInjectFnMaxArgs = xsArrayCreateInt({function_array}, -1, "xsInjectFnMaxArgs");
    gXsInjectFnReturn = xsArrayCreateInt({function_array}, -1, "xsInjectFnReturn");
    gXsInjectFnParamStart = xsArrayCreateInt({function_array}, -1, "xsInjectFnParamStart");
    gXsInjectParamTypes = xsArrayCreateInt({param_array}, -1, "xsInjectParamTypes");
    gXsInjectParamCount = 0;
{defines}
}}

"""


def _xs_type(t):
    return "cXsInjectType" + ("Void" if t == "void" else _XS_NAME[t])


def _defines(sigs):
    lines = []
    for s in sigs:
        lines.append(f"    xsInjectDefine({s['id']}, {s['min_args']}, {s['max_args']}, {_xs_type(s['returns'])});  // {s['name']}")
        lines += [f"    xsInjectParam({_xs_type(p['type'])});" for p in s["params"]]
    return "\n".join(lines)


def _dispatch(sigs):
    function_slots = max((s["id"] for s in sigs), default=-1) + 1
    param_slots = sum(len(s["params"]) for s in sigs)
    header = _HEADER.format(
        function_slots=function_slots,
        param_slots=param_slots,
        function_array=max(function_slots, 1),
        param_array=max(param_slots, 1),
        defines=_defines(sigs),
    )
    return header + (
        "// Runs call `fid` with `argc` arguments staged at argBase.. in the typed argument arrays;\n"
        "// a non-void result goes to index `slot` of the result array of its return type.\n"
        "void xsInjectDispatch(int fid = -1, int argc = 0, int argBase = 0, int slot = 0) {\n"
        "    switch (fid) {\n"
        + "\n".join(_case(s) for s in sigs)
        + "\n    }\n}\n"
    )


def _assign_ids(names, renames, pinned, retire):
    """Pinned ids stay put, renames carry their id, retired names are excluded, new names append.

    A retired function gets no id even while the catalog still lists it (e.g. a deprecated one).
    Ids are never reused: the next id is one past every id ever handed out, retired ones included.
    """
    pinned = pinned or {"functions": {}, "retired": {}}
    assigned = dict(pinned["functions"])
    retired = dict(pinned["retired"])  # name -> {"id", "reason"}
    in_catalog = set(names)

    # Renames apply in file order, so a chain old -> mid -> new carries the id all the way.
    for r in renames:
        old, new = r["old_name"], r["new_name"]
        if old in assigned and old not in in_catalog:
            if new in assigned or new in retired:
                raise GeneratorError(f"rename {old!r} -> {new!r}: {new!r} already has an id (pinned or retired)")
            assigned[new] = assigned.pop(old)

    for name, reason in retire.items():
        if name not in assigned:
            raise GeneratorError(f"cannot retire {name!r}: it has no pinned id")
        if not reason.strip():
            raise GeneratorError(f"cannot retire {name!r}: give a reason")
        retired[name] = {"id": assigned.pop(name), "reason": reason.strip()}

    missing = [n for n in assigned if n not in in_catalog]
    if missing:
        raise GeneratorError(
            "pinned functions left the catalog without a rename entry: "
            + ", ".join(missing)
            + ". Add a rename to catalog/renames.json, or retire them with --retire NAME REASON."
        )

    next_id = max([*assigned.values(), *(r["id"] for r in retired.values())], default=-1) + 1
    for name in names:
        if name in assigned:
            continue
        if name in retired:
            continue
        assigned[name] = next_id
        next_id += 1
    return assigned, retired


def _by_id(table):
    return dict(sorted(table.items(), key=lambda kv: kv[1]))


if __name__ == "__main__":
    sys.exit(main())
