// XS function injector: core module. Hosts include this file only.
//
// Once a game-second it reads xsinject.xsdat (written by the driver, xsinject/driver.py), runs a
// request whose id changed, and writes the response section at the end of the game's own .xsdat.
// Every layout here mirrors xsinject/wire.py; change both together.
//
// Request:          [request id][call count] ...calls (none are parsed yet: ping only)
// Response section: [body][body byte length][magic], body = [magic][request id][status]
//                   [failed call #][failed argument #][entry count] ...entries
// All values are int32. -1 is a legal read value, so every read is bounded by xsGetFileSize().

const int cXsInjectMagic = 441340760;       // 0x1A4E5358; a finder only, not a version (XS int literals max 9 digits)
const int cXsInjectHeaderBytes = 24;        // six ints

// Request status codes (wire).
const int cXsInjectOK = 0;
const int cXsInjectRunning = 1;
const int cXsInjectTruncated = 2;
const int cXsInjectUnknownFunction = 3;
const int cXsInjectTrailingBytes = 9;

bool gXsInjectStarted = false;
bool gXsInjectHaveSeenId = false;
int gXsInjectSeenId = -1;

// The last stored response; standalone writes it out, a host (later) carries it on its own writes.
int gXsInjectRespId = -1;
int gXsInjectRespStatus = -1;
int gXsInjectRespFailedCall = -1;
int gXsInjectRespFailedArg = -1;

void xsInjectStoreResponse(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1) {
    gXsInjectRespId = requestId;
    gXsInjectRespStatus = status;
    gXsInjectRespFailedCall = failedCall;
    gXsInjectRespFailedArg = failedArg;
}

void xsInjectWriteSectionBody() {
    xsWriteInt(cXsInjectMagic);
    xsWriteInt(gXsInjectRespId);
    xsWriteInt(gXsInjectRespStatus);
    xsWriteInt(gXsInjectRespFailedCall);
    xsWriteInt(gXsInjectRespFailedArg);
    xsWriteInt(0); // entry count
}

// Standalone: the module owns the game's .xsdat and writes the section alone.
void xsInjectWriteStandalone() {
    if (xsCreateFile(false) == false) {
        return;
    }
    xsInjectWriteSectionBody();
    xsWriteInt(cXsInjectHeaderBytes);
    xsWriteInt(cXsInjectMagic);
    xsCloseFile();
}

void xsInjectRespond(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1) {
    xsInjectStoreResponse(requestId, status, failedCall, failedArg);
    xsInjectWriteStandalone();
}

void xsInjectTick() {
    // A missing or empty request file means idle.
    if (xsOpenFile("xsinject") == false) {
        gXsInjectStarted = true;
        return;
    }
    int size = xsGetFileSize();
    if (size < 4) {
        xsCloseFile();
        gXsInjectStarted = true;
        return;
    }
    int requestId = xsReadInt();

    // The id found at startup is adopted without being run: it belongs to an earlier session.
    if (gXsInjectStarted == false) {
        gXsInjectStarted = true;
        gXsInjectHaveSeenId = true;
        gXsInjectSeenId = requestId;
        xsCloseFile();
        return;
    }
    if (gXsInjectHaveSeenId) {
        if (requestId == gXsInjectSeenId) {
            xsCloseFile();
            return;
        }
    }

    // Changed (not necessarily greater) id: mark it seen before parsing, so a bad request
    // is reported once, never retried.
    gXsInjectHaveSeenId = true;
    gXsInjectSeenId = requestId;

    // Parse the whole request, then close the file before anything runs.
    int status = cXsInjectOK;
    int failedCall = -1;
    if (size < 8) {
        status = cXsInjectTruncated;
    } else {
        int callCount = xsReadInt();
        if (callCount < 0) {
            status = cXsInjectTruncated;
        } else if (callCount > 0) {
            // No dispatch yet: every function id is unknown. The read of call #0's id is
            // still bounded by size.
            failedCall = 0;
            if (size < 12) {
                status = cXsInjectTruncated;
            } else {
                status = cXsInjectUnknownFunction;
            }
        } else if (size > 8) {
            status = cXsInjectTrailingBytes;
        }
    }
    xsCloseFile();

    if (status != cXsInjectOK) {
        xsInjectRespond(requestId, status, failedCall, -1);
        return;
    }

    // Running marks the request before call #0, so a call that kills the rule stays visible.
    xsInjectRespond(requestId, cXsInjectRunning, -1, -1);
    // (No calls yet.)
    xsInjectRespond(requestId, cXsInjectOK, -1, -1);
}

rule xsInjectRequestRule
    active
    minInterval 1
    maxInterval 1
{
    xsInjectTick();
}
