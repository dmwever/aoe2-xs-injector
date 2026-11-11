// XS function injector: core module. Hosts include this file only.
//
// Once a game-second it reads xsinject.xsdat (written by the driver, xsinject/driver.py), runs a
// request whose id changed, and writes the response section at the end of the game's own .xsdat.
// Every layout here mirrors xsinject/wire.py; change both together.
//
// Request:          [request id][call count], then per call [function id][argument count],
//                   then per argument [tag][payload]. Tag 0 = literal (int only so far).
// Response section: [body][body byte length][magic], body = [magic][request id][status]
//                   [failed call #][failed argument #][entry count] ...entries
// Entry:            [entry status], then the value when OK and the function is non-void.
// All values are int32. -1 is a legal read value, so every read is bounded by xsGetFileSize().
//
// The generated dispatch (xsinject_dispatch.xs) must sit next to this file; this file includes it.
include "./xsinject_dispatch.xs";

const int cXsInjectMagic = 441340760;       // 0x1A4E5358; a finder only, not a version (XS int literals max 9 digits)
const int cXsInjectHeaderBytes = 24;        // six ints

// Request status codes (wire).
const int cXsInjectOK = 0;
const int cXsInjectRunning = 1;
const int cXsInjectTruncated = 2;
const int cXsInjectUnknownFunction = 3;
const int cXsInjectBadArgCount = 4;
const int cXsInjectBadTag = 5;
const int cXsInjectTrailingBytes = 9;

const int cXsInjectEntryOK = 0;
const int cXsInjectTagLiteral = 0;

bool gXsInjectInitDone = false;
bool gXsInjectStarted = false;
bool gXsInjectHaveSeenId = false;
int gXsInjectSeenId = -1;

// The last stored response; standalone writes it out, a host (later) carries it on its own writes.
int gXsInjectRespId = -1;
int gXsInjectRespStatus = -1;
int gXsInjectRespFailedCall = -1;
int gXsInjectRespFailedArg = -1;
int gXsInjectRespEntryCount = 0;  // entries come from the staged calls and their result slots

// The staged request: per call its function id, argument count and the index of its first
// argument in the gXsInjectArg* arrays (one shared index across types).
int gXsInjectCallCount = 0;
int gXsInjectCallFn = -1;
int gXsInjectCallArgc = -1;
int gXsInjectCallArgBase = -1;

// Where the last parse failed (-1 when n/a).
int gXsInjectParseCall = -1;
int gXsInjectParseArg = -1;

void xsInjectInit() {
    xsInjectSignaturesInit();
    gXsInjectArgInt = xsArrayCreateInt(1, 0, "xsInjectArgInt");
    gXsInjectArgFloat = xsArrayCreateFloat(1, 0.0, "xsInjectArgFloat");
    gXsInjectArgBool = xsArrayCreateBool(1, false, "xsInjectArgBool");
    gXsInjectArgString = xsArrayCreateString(1, "", "xsInjectArgString");
    gXsInjectArgVector = xsArrayCreateVector(1, vector(0.0, 0.0, 0.0), "xsInjectArgVector");
    gXsInjectResInt = xsArrayCreateInt(1, 0, "xsInjectResInt");
    gXsInjectResFloat = xsArrayCreateFloat(1, 0.0, "xsInjectResFloat");
    gXsInjectResBool = xsArrayCreateBool(1, false, "xsInjectResBool");
    gXsInjectResString = xsArrayCreateString(1, "", "xsInjectResString");
    gXsInjectResVector = xsArrayCreateVector(1, vector(0.0, 0.0, 0.0), "xsInjectResVector");
    gXsInjectCallFn = xsArrayCreateInt(1, -1, "xsInjectCallFn");
    gXsInjectCallArgc = xsArrayCreateInt(1, 0, "xsInjectCallArgc");
    gXsInjectCallArgBase = xsArrayCreateInt(1, 0, "xsInjectCallArgBase");
    gXsInjectInitDone = true;
}

// Sizes the staging arrays for up to `calls` calls and `args` arguments in all.
void xsInjectResizeStaging(int calls = 0, int args = 0) {
    if (calls < 1) {
        calls = 1;
    }
    if (args < 1) {
        args = 1;
    }
    xsArrayResizeInt(gXsInjectCallFn, calls);
    xsArrayResizeInt(gXsInjectCallArgc, calls);
    xsArrayResizeInt(gXsInjectCallArgBase, calls);
    xsArrayResizeInt(gXsInjectResInt, calls);
    xsArrayResizeFloat(gXsInjectResFloat, calls);
    xsArrayResizeBool(gXsInjectResBool, calls);
    xsArrayResizeString(gXsInjectResString, calls);
    xsArrayResizeVector(gXsInjectResVector, calls);
    xsArrayResizeInt(gXsInjectArgInt, args);
    xsArrayResizeFloat(gXsInjectArgFloat, args);
    xsArrayResizeBool(gXsInjectArgBool, args);
    xsArrayResizeString(gXsInjectArgString, args);
    xsArrayResizeVector(gXsInjectArgVector, args);
}

// Parses the open request file (positioned just after the request id) into staging. Returns a
// request status; on failure gXsInjectParseCall/Arg say where. Every read is bounded by `size`.
int xsInjectParse(int size = 0) {
    int pos = 4;
    int callCount = 0;
    int maxCalls = 0;
    int call = 0;
    int fid = -1;
    int argc = 0;
    int arg = 0;
    int argBase = 0;
    int tag = 0;
    gXsInjectParseCall = -1;
    gXsInjectParseArg = -1;
    gXsInjectCallCount = 0;

    if (pos + 4 > size) {
        return (cXsInjectTruncated);
    }
    callCount = xsReadInt();
    pos = pos + 4;
    if (callCount < 0) {
        return (cXsInjectTruncated);
    }
    // Every call and every argument takes at least 8 bytes, which bounds the staging sizes.
    maxCalls = (size - pos) / 8;
    if (callCount < maxCalls) {
        xsInjectResizeStaging(callCount, maxCalls);
    } else {
        xsInjectResizeStaging(maxCalls, maxCalls);
    }

    while (call < callCount) {
        gXsInjectParseCall = call;
        if (pos + 8 > size) {
            return (cXsInjectTruncated);
        }
        fid = xsReadInt();
        argc = xsReadInt();
        pos = pos + 8;
        if (xsInjectKnownFunction(fid) == false) {
            return (cXsInjectUnknownFunction);
        }
        if ((argc < xsInjectMinArgs(fid)) || (argc > xsInjectMaxArgs(fid))) {
            return (cXsInjectBadArgCount);
        }
        // Only int and void results can be reported so far; refuse the rest before anything runs.
        if ((xsInjectReturnType(fid) != cXsInjectTypeInt) && (xsInjectReturnType(fid) != cXsInjectTypeVoid)) {
            return (cXsInjectUnknownFunction);
        }
        xsArraySetInt(gXsInjectCallFn, call, fid);
        xsArraySetInt(gXsInjectCallArgc, call, argc);
        xsArraySetInt(gXsInjectCallArgBase, call, argBase);

        arg = 0;
        while (arg < argc) {
            gXsInjectParseArg = arg;
            if (pos + 4 > size) {
                return (cXsInjectTruncated);
            }
            tag = xsReadInt();
            pos = pos + 4;
            if (tag != cXsInjectTagLiteral) {
                return (cXsInjectBadTag);
            }
            // Only int literals are parsed so far; the driver sends no other kind.
            if (xsInjectParamType(fid, arg) != cXsInjectTypeInt) {
                return (cXsInjectBadTag);
            }
            if (pos + 4 > size) {
                return (cXsInjectTruncated);
            }
            xsArraySetInt(gXsInjectArgInt, argBase, xsReadInt());
            pos = pos + 4;
            argBase++;
            arg++;
        }
        gXsInjectParseArg = -1;
        call++;
    }
    gXsInjectParseCall = -1;
    if (pos < size) {
        return (cXsInjectTrailingBytes);
    }
    gXsInjectCallCount = callCount;
    return (cXsInjectOK);
}

// Runs every staged call in order; call #n's result lands at index n of its return type's array.
// A return of -1 or false is a value: the module never judges one, and every call runs.
void xsInjectRunCalls() {
    int call = 0;
    while (call < gXsInjectCallCount) {
        xsInjectDispatch(xsArrayGetInt(gXsInjectCallFn, call), xsArrayGetInt(gXsInjectCallArgc, call),
            xsArrayGetInt(gXsInjectCallArgBase, call), call);
        call++;
    }
}

void xsInjectStoreResponse(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1,
    int entryCount = 0) {
    gXsInjectRespId = requestId;
    gXsInjectRespStatus = status;
    gXsInjectRespFailedCall = failedCall;
    gXsInjectRespFailedArg = failedArg;
    gXsInjectRespEntryCount = entryCount;
}

// Byte length of the stored response's body.
int xsInjectBodyBytes() {
    int bytes = cXsInjectHeaderBytes;
    int call = 0;
    while (call < gXsInjectRespEntryCount) {
        bytes = bytes + 4;
        if (xsInjectReturnType(xsArrayGetInt(gXsInjectCallFn, call)) == cXsInjectTypeInt) {
            bytes = bytes + 4;
        }
        call++;
    }
    return (bytes);
}

void xsInjectWriteSectionBody() {
    int call = 0;
    xsWriteInt(cXsInjectMagic);
    xsWriteInt(gXsInjectRespId);
    xsWriteInt(gXsInjectRespStatus);
    xsWriteInt(gXsInjectRespFailedCall);
    xsWriteInt(gXsInjectRespFailedArg);
    xsWriteInt(gXsInjectRespEntryCount);
    // One entry per call, in call order; only int values are written so far.
    while (call < gXsInjectRespEntryCount) {
        xsWriteInt(cXsInjectEntryOK);
        if (xsInjectReturnType(xsArrayGetInt(gXsInjectCallFn, call)) == cXsInjectTypeInt) {
            xsWriteInt(xsArrayGetInt(gXsInjectResInt, call));
        }
        call++;
    }
}

// Standalone: the module owns the game's .xsdat and writes the section alone.
void xsInjectWriteStandalone() {
    if (xsCreateFile(false) == false) {
        return;
    }
    xsInjectWriteSectionBody();
    xsWriteInt(xsInjectBodyBytes());
    xsWriteInt(cXsInjectMagic);
    xsCloseFile();
}

void xsInjectRespond(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1,
    int entryCount = 0) {
    xsInjectStoreResponse(requestId, status, failedCall, failedArg, entryCount);
    xsInjectWriteStandalone();
}

void xsInjectTick() {
    if (gXsInjectInitDone == false) {
        xsInjectInit();
    }
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

    // Parse the whole request into staging, then close the file before any call runs.
    int status = xsInjectParse(size);
    xsCloseFile();

    if (status != cXsInjectOK) {
        xsInjectRespond(requestId, status, gXsInjectParseCall, gXsInjectParseArg, 0);
        return;
    }

    // Running marks the request before call #0, so a call that kills the rule stays visible.
    xsInjectRespond(requestId, cXsInjectRunning, -1, -1, 0);
    xsInjectRunCalls();
    xsInjectRespond(requestId, cXsInjectOK, -1, -1, gXsInjectCallCount);
}

rule xsInjectRequestRule
    active
    minInterval 1
    maxInterval 1
{
    xsInjectTick();
}
