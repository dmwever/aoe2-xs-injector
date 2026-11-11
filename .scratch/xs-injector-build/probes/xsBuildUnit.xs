// Probe (ticket 04): xsBuildUnit(int, int, vector) failed in the dispatch with
// "expression type does not match expected type" while its result was stored as bool.
// The engine stops at the first error, so the line it names answers the question:
//   line A fails -> a parameter type is wrong (arguments alone, result discarded)
//   line B fails -> a parameter in the optional tail (vector, bool, bool) is wrong
//   line C fails -> the result is not int
//   line D fails -> the result is not bool (and C passing means it is int)
//   all pass     -> chat shows "xsBuildUnit probe: all lines compiled"
void main() {
    int unitIds = -1;
    int objectId = -1;
    vector loc = cInvalidVector;
    bool flag = false;
    xsBuildUnit(unitIds, objectId, loc);                          // A
    xsBuildUnit(unitIds, objectId, loc, loc, flag, flag);         // B
    int asInt = xsBuildUnit(unitIds, objectId, loc);              // C
    bool asBool = xsBuildUnit(unitIds, objectId, loc);            // D
    xsChatData("xsBuildUnit probe: all lines compiled");
}
