import json
import sys
from pathlib import Path

CATALOG = Path(r"C:\Users\dmwev\Documents\GitHub\AoE2_AI_Modder\docs\agent_database\xs_functions_catalog.json")
OUT = Path(r"C:\Users\dmwev\Documents\GitHub\Ageipelago\age 2 files\resources\_common\xs\Test.xs")
TARGET_CASES = 289
VOID_IN_ENGINE = {"xsIsRuleGroupEnabled"}
PARAM_TYPE_IN_ENGINE = {("xsFlashUnit", 2): "string"}
ENGINE_VERIFIED_PREFIX = 170
RUNTIME_CALLED = {"xsGetGameTime", "strLen", "strSubstring", "xsVectorSet", "round", "xsGetMapName"}

ARG = {
    "int": "xsArrayGetInt(gAI, {k})",
    "float": "xsArrayGetFloat(gAF, {k})",
    "bool": "xsArrayGetBool(gAB, {k})",
    "string": "xsArrayGetString(gAS, {k})",
    "vector": "xsArrayGetVector(gAV, {k})",
}
RES = {
    "int": "xsArraySetInt(gRI, 0, {call});",
    "float": "xsArraySetFloat(gRF, 0, {call});",
    "bool": "xsArraySetBool(gRB, 0, {call});",
    "string": "xsArraySetString(gRS, 0, {call});",
    "vector": "xsArraySetVector(gRV, 0, {call});",
    "void": "{call};",
}

HEAD = """int gAI = -1;
int gAF = -1;
int gAB = -1;
int gAS = -1;
int gAV = -1;
int gRI = -1;
int gRF = -1;
int gRB = -1;
int gRS = -1;
int gRV = -1;
int gLab = -1;
int gVal = -1;
int gTxt = -1;
int gN = 0;

void R(string lab = "", int v = 0, string s = "") {
    xsArraySetString(gLab, gN, lab);
    xsArraySetInt(gVal, gN, v);
    xsArraySetString(gTxt, gN, s);
    gN++;
}

void FlushLog() {
    bool created = xsCreateFile(false);
    if (created == false) {
        return;
    }
    xsWriteInt(20261110);
    xsWriteInt(gN);
    for (i = 0; < gN) {
        xsWriteString(xsArrayGetString(gLab, i));
        xsWriteInt(xsArrayGetInt(gVal, i));
        xsWriteString(xsArrayGetString(gTxt, i));
    }
    xsWriteInt(424242);
    xsCloseFile();
}
"""

TAIL = """
void main() {
    gAI = xsArrayCreateInt(8, 0, "bAI");
    gAF = xsArrayCreateFloat(8, 0.0, "bAF");
    gAB = xsArrayCreateBool(8, false, "bAB");
    gAS = xsArrayCreateString(8, "", "bAS");
    gAV = xsArrayCreateVector(8, vector(0, 0, 0), "bAV");
    gRI = xsArrayCreateInt(1, 0, "bRI");
    gRF = xsArrayCreateFloat(1, 0.0, "bRF");
    gRB = xsArrayCreateBool(1, false, "bRB");
    gRS = xsArrayCreateString(1, "", "bRS");
    gRV = xsArrayCreateVector(1, vector(0, 0, 0), "bRV");
    gLab = xsArrayCreateString(64, "", "bLab");
    gVal = xsArrayCreateInt(64, 0, "bVal");
    gTxt = xsArrayCreateString(64, "", "bTxt");
    R("boot", xsGetWorldTime(), xsGetMapName(false));
    R("mapext", 0, xsGetMapName(true));
    R("cases", %(cases)d, "");
    R("callsites", %(sites)d, "");

    Dispatch(%(id_time)d, 0);
    R("xsGetGameTime", xsArrayGetInt(gRI, 0), "");

    xsArraySetString(gAS, 0, "abcd");
    Dispatch(%(id_strlen)d, 1);
    R("strLen", xsArrayGetInt(gRI, 0), "");

    xsArraySetString(gAS, 0, "abcdef");
    xsArraySetInt(gAI, 1, 1);
    xsArraySetInt(gAI, 2, 4);
    Dispatch(%(id_substr)d, 3);
    R("strSubstring", 0, xsArrayGetString(gRS, 0));

    xsArraySetFloat(gAF, 0, 2.5);
    xsArraySetFloat(gAF, 1, 1.25);
    xsArraySetFloat(gAF, 2, 3.0);
    Dispatch(%(id_vset)d, 3);
    R("xsVectorSet.y", bitCastToInt(xsVectorGetY(xsArrayGetVector(gRV, 0))), "");

    xsArraySetFloat(gAF, 0, 2.567);
    Dispatch(%(id_round)d, 1);
    R("round1", bitCastToInt(xsArrayGetFloat(gRF, 0)), "");
    xsArraySetInt(gAI, 1, 2);
    Dispatch(%(id_round)d, 2);
    R("round2", bitCastToInt(xsArrayGetFloat(gRF, 0)), "");

    xsArraySetBool(gAB, 0, false);
    Dispatch(%(id_mapname)d, 1);
    R("xsGetMapName", 0, xsArrayGetString(gRS, 0));

    R("done", gN, "");
    FlushLog();
    xsChatData("run B done: " + xsGetMapName(false));
}
"""


def main():
    fs = json.loads(CATALOG.read_text(encoding="utf-8"))
    ids = {f["name"]: fid for fid, f in enumerate(fs)}
    bodies = []
    for f in fs:
        body = []
        for argc in range(f["min_param_count"], f["param_count"] + 1):
            args = ", ".join(ARG[PARAM_TYPE_IN_ENGINE.get((f["name"], k), p["type"])].format(k=k) for k, p in enumerate(f["params"][:argc]))
            call = f"{f['name']}({args})"
            body.append(f"            if (argc == {argc}) {{\n                {RES['void' if f['name'] in VOID_IN_ENGINE else f['return_type']].format(call=call)}\n            }}")
        bodies.append(body)
    filler = sorted(bodies[:ENGINE_VERIFIED_PREFIX], key=len, reverse=True)
    cases = []
    sites = 0
    k = 0
    for fid in range(TARGET_CASES):
        if fid < ENGINE_VERIFIED_PREFIX or (fid < len(fs) and fs[fid]["name"] in RUNTIME_CALLED):
            body = bodies[fid]
        else:
            body = filler[k % len(filler)]
            k += 1
        sites += len(body)
        cases.append(f"        case {fid}: {{\n" + "\n".join(body) + "\n        }")
    dispatch = "\nvoid Dispatch(int fid = -1, int argc = 0) {\n    switch (fid) {\n" + "\n".join(cases) + "\n    }\n}\n"
    tail = TAIL % {
        "cases": TARGET_CASES, "sites": sites,
        "id_time": ids["xsGetGameTime"], "id_strlen": ids["strLen"], "id_substr": ids["strSubstring"],
        "id_vset": ids["xsVectorSet"], "id_round": ids["round"], "id_mapname": ids["xsGetMapName"],
    }
    OUT.write_text(HEAD + dispatch + tail, encoding="ascii", newline="\n")
    print(TARGET_CASES, sites, OUT.stat().st_size)


if __name__ == "__main__":
    main()
