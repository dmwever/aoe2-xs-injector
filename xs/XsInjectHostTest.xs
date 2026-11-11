// Test host for live smoke runs of the injector's host mode (ticket 10).
//
// A minimal host that rewrites the game's own .xsdat every game-second with its own packet, then
// lets the injector append its response section. Set up like XsInjectTest.xs (copy this file,
// xsinject.xs and xsinject_dispatch.xs into <profile>/resources/_common/xs/, make this the
// scenario's script, start editor test-play; the file is default1.xsdat).
//
// Host packet: [tick][string "xsinject test host"][tick * 2]. After a request, the file is this
// packet followed by the response section; both must decode.
include "./xsinject.xs";

int gHostTick = 0;

void main() {
    xsInjectUseHostWriter();
}

rule xsInjectTestHostWrite
    active
    minInterval 1
    maxInterval 1
{
    if (xsCreateFile(false) == false) {
        return;
    }
    gHostTick++;
    xsWriteInt(gHostTick);
    xsWriteString("xsinject test host");
    xsWriteInt(gHostTick * 2);
    xsInjectWriteSection();
    xsCloseFile();
}
