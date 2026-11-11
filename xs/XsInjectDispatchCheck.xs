// Compile gate for the generated dispatch (ticket 04, and after every catalog change).
//
// Copy this file and xsinject_dispatch.xs into <profile>/resources/_common/xs/, set this file as
// the scenario's script, and start editor test-play. A clean compile (no XS error dialog, and the
// chat line below) means every call site in the dispatch matches an engine signature. On an error,
// fix the named line's function in catalog/functions.json, regenerate, and relaunch.
include "./xsinject_dispatch.xs";

void main() {
    xsInjectSignaturesInit();
    xsChatData("xsinject dispatch compiled");
}
