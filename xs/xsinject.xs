// XS function injector: core module. Hosts include this file only.
//
// Once a game-second it reads xsinject.xsdat (written by the driver, xsinject/driver.py), runs a
// request whose id changed, and writes the response section at the end of the game's own .xsdat.
// Every layout here mirrors xsinject/wire.py; change both together.
//
// Request:          [request id][call count], then per call [function id][argument count],
//                   then per argument [tag][payload]. Tag 0 = literal, encoded as the parameter's
//                   declared type: int, float, bool as int, vector as 3 floats, string as a uint32
//                   byte length then raw bytes. Tag 1 = reference, an int call number of an
//                   earlier call in the same request whose return type is the parameter's type.
// Response section: [body][body byte length][magic], body = [magic][request id][status]
//                   [failed call #][failed argument #][entry count] ...entries
// Entry:            [entry status], then the value when OK and the function is non-void, written
//                   by return type (bool as int).
// Ints are int32 and floats IEEE 32-bit, little-endian. -1 is a legal read value, so every read
// is bounded by xsGetFileSize(), and a string's length is checked before the string is read.
//
// Standalone (the default): the module writes the section alone into the game's own .xsdat,
// once per stored response. Host mode: a scenario or mod that rewrites the game's .xsdat itself
// calls xsInjectUseHostWriter() from main(), and xsInjectWriteSection() just before each of its own
// xsCloseFile() calls; the module keeps its last response and appends it on every host write.
// Writing that file without opting in wipes the response.
//
// The generated dispatch (xsinject_dispatch.xs) must sit next to this file; this file includes it.
include "./xsinject_dispatch.xs";

const int cXsInjectMagic = 441340760;       // 0x1A4E5358; a finder only, not a version (XS int literals max 9 digits)

// Request status codes (wire).
const int cXsInjectOK = 0;
const int cXsInjectRunning = 1;
const int cXsInjectTruncated = 2;
const int cXsInjectUnknownFunction = 3;
const int cXsInjectBadArgCount = 4;
const int cXsInjectBadTag = 5;
const int cXsInjectBadReference = 6;
const int cXsInjectReferenceTypeMismatch = 7;
const int cXsInjectTooLarge = 8;
const int cXsInjectTrailingBytes = 9;

// The game's .xsdat write cap in bytes; a host's own bytes count against it.
const int cXsInjectWriteLimit = 1048575;
const int cXsInjectSectionFixedBytes = 32;  // 6 header ints, then the body length and the magic

const int cXsInjectEntryOK = 0;
const int cXsInjectTagLiteral = 0;
const int cXsInjectTagReference = 1;

bool gXsInjectInitDone = false;
bool gXsInjectStarted = false;
bool gXsInjectHaveSeenId = false;
int gXsInjectSeenId = -1;
bool gXsInjectHosted = false;  // set by xsInjectUseHostWriter(); otherwise standalone

// The last stored response; standalone writes it out once, a host carries it on every write.
bool gXsInjectHaveResp = false;
int gXsInjectRespId = -1;
int gXsInjectRespStatus = -1;
int gXsInjectRespFailedCall = -1;
int gXsInjectRespFailedArg = -1;
int gXsInjectRespEntryCount = 0;  // entries come from the staged calls and their result slots
int gXsInjectRespSize = 0;  // the whole section's byte size, trailer included

// The staged request: per call its function id, argument count and the index of its first
// argument in the gXsInjectArg* arrays (one shared index across types).
int gXsInjectCallCount = 0;
int gXsInjectCallFn = -1;
int gXsInjectCallArgc = -1;
int gXsInjectCallArgBase = -1;
int gXsInjectArgRef = -1;  // per argument: the referenced call #, or -1 for a literal

int gXsInjectVectorArrays = 0;  // replacement vector arrays made so far; names each one uniquely

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
    gXsInjectArgRef = xsArrayCreateInt(1, -1, "xsInjectArgRef");
    gXsInjectInitDone = true;
}

// xsArrayResizeVector returns false and leaves the array as it is in this build (observed live
// 2026-11-11; the other resizes work). A vector array grows by being replaced with a bigger one,
// at least doubling so few arrays are abandoned. Returns the array to use from now on.
int xsInjectVectorArrayAtLeast(int arrayId = -1, int size = 1) {
    int current = xsArrayGetSize(arrayId);
    if (current >= size) {
        return (arrayId);
    }
    if (size < current * 2) {
        size = current * 2;
    }
    gXsInjectVectorArrays++;
    return (xsArrayCreateVector(size, vector(0.0, 0.0, 0.0), "xsInjectVector" + gXsInjectVectorArrays));
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
    gXsInjectResVector = xsInjectVectorArrayAtLeast(gXsInjectResVector, calls);
    xsArrayResizeInt(gXsInjectArgInt, args);
    xsArrayResizeInt(gXsInjectArgRef, args);
    xsArrayResizeFloat(gXsInjectArgFloat, args);
    xsArrayResizeBool(gXsInjectArgBool, args);
    xsArrayResizeString(gXsInjectArgString, args);
    gXsInjectArgVector = xsInjectVectorArrayAtLeast(gXsInjectArgVector, args);
}

// Reads one literal of type `paramType` at byte `pos` into argument slot `argIndex`. Returns the
// position after it, or -1 when it would run past `size` (a string's length is checked first).
int xsInjectReadLiteral(int paramType = 0, int argIndex = 0, int pos = 0, int size = 0) {
    int length = 0;
    if (paramType == cXsInjectTypeString) {
        if (pos + 4 > size) {
            return (-1);
        }
        length = xsReadInt();
        if ((length < 0) || (length > size - pos - 4)) {
            return (-1);
        }
        xsSetFilePosition(pos);
        xsArraySetString(gXsInjectArgString, argIndex, xsReadString());
        return (pos + 4 + length);
    }
    if (paramType == cXsInjectTypeVector) {
        if (pos + 12 > size) {
            return (-1);
        }
        xsArraySetVector(gXsInjectArgVector, argIndex, xsReadVector());
        return (pos + 12);
    }
    if (pos + 4 > size) {
        return (-1);
    }
    if (paramType == cXsInjectTypeFloat) {
        xsArraySetFloat(gXsInjectArgFloat, argIndex, xsReadFloat());
    } else if (paramType == cXsInjectTypeBool) {
        xsArraySetBool(gXsInjectArgBool, argIndex, xsReadInt() != 0);
    } else {
        xsArraySetInt(gXsInjectArgInt, argIndex, xsReadInt());
    }
    return (pos + 4);
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
    int ref = -1;
    int paramType = 0;
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
            paramType = xsInjectParamType(fid, arg);
            if (tag == cXsInjectTagLiteral) {
                xsArraySetInt(gXsInjectArgRef, argBase, -1);
                pos = xsInjectReadLiteral(paramType, argBase, pos, size);
                if (pos < 0) {
                    return (cXsInjectTruncated);
                }
            } else if (tag == cXsInjectTagReference) {
                // A backstop for the driver's checks: only an earlier call of the same type.
                if (pos + 4 > size) {
                    return (cXsInjectTruncated);
                }
                ref = xsReadInt();
                pos = pos + 4;
                if ((ref < 0) || (ref >= call)) {
                    return (cXsInjectBadReference);
                }
                if (xsInjectReturnType(xsArrayGetInt(gXsInjectCallFn, ref)) != paramType) {
                    return (cXsInjectReferenceTypeMismatch);
                }
                xsArraySetInt(gXsInjectArgRef, argBase, ref);
            } else {
                return (cXsInjectBadTag);
            }
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

// Clears every result slot, so no value outlives its request.
void xsInjectClearResults() {
    int slot = 0;
    for (slot = 0; < xsArrayGetSize(gXsInjectResInt)) {
        xsArraySetInt(gXsInjectResInt, slot, 0);
    }
    for (slot = 0; < xsArrayGetSize(gXsInjectResFloat)) {
        xsArraySetFloat(gXsInjectResFloat, slot, 0.0);
    }
    for (slot = 0; < xsArrayGetSize(gXsInjectResBool)) {
        xsArraySetBool(gXsInjectResBool, slot, false);
    }
    for (slot = 0; < xsArrayGetSize(gXsInjectResString)) {
        xsArraySetString(gXsInjectResString, slot, "");
    }
    for (slot = 0; < xsArrayGetSize(gXsInjectResVector)) {
        xsArraySetVector(gXsInjectResVector, slot, vector(0.0, 0.0, 0.0));
    }
}

// Copies the referenced results into call #`call`'s argument slots. Parsing already checked each
// reference points to an earlier call whose return type is the parameter's type.
void xsInjectResolveReferences(int call = 0) {
    int fid = xsArrayGetInt(gXsInjectCallFn, call);
    int argc = xsArrayGetInt(gXsInjectCallArgc, call);
    int argBase = xsArrayGetInt(gXsInjectCallArgBase, call);
    int arg = 0;
    int index = 0;
    int ref = -1;
    int paramType = 0;
    while (arg < argc) {
        index = argBase + arg;
        ref = xsArrayGetInt(gXsInjectArgRef, index);
        if (ref >= 0) {
            paramType = xsInjectParamType(fid, arg);
            if (paramType == cXsInjectTypeInt) {
                xsArraySetInt(gXsInjectArgInt, index, xsArrayGetInt(gXsInjectResInt, ref));
            } else if (paramType == cXsInjectTypeFloat) {
                xsArraySetFloat(gXsInjectArgFloat, index, xsArrayGetFloat(gXsInjectResFloat, ref));
            } else if (paramType == cXsInjectTypeBool) {
                xsArraySetBool(gXsInjectArgBool, index, xsArrayGetBool(gXsInjectResBool, ref));
            } else if (paramType == cXsInjectTypeString) {
                xsArraySetString(gXsInjectArgString, index, xsArrayGetString(gXsInjectResString, ref));
            } else if (paramType == cXsInjectTypeVector) {
                xsArraySetVector(gXsInjectArgVector, index, xsArrayGetVector(gXsInjectResVector, ref));
            }
        }
        arg++;
    }
}

// Runs every staged call in order; call #n's result lands at index n of its return type's array,
// and a reference reads it from there when a later call runs. A return of -1 or false is a value:
// the module never judges one, and every call runs.
void xsInjectRunCalls() {
    int call = 0;
    while (call < gXsInjectCallCount) {
        xsInjectResolveReferences(call);
        xsInjectDispatch(xsArrayGetInt(gXsInjectCallFn, call), xsArrayGetInt(gXsInjectCallArgc, call),
            xsArrayGetInt(gXsInjectCallArgBase, call), call);
        call++;
    }
}

// Byte size of call #`call`'s entry as written: its status, then its value by return type. strLen
// counts bytes (observed live), matching xsWriteString's uint32 length plus raw bytes.
int xsInjectEntrySize(int call = 0) {
    int returnType = xsInjectReturnType(xsArrayGetInt(gXsInjectCallFn, call));
    if (returnType == cXsInjectTypeVoid) {
        return (4);
    }
    if (returnType == cXsInjectTypeString) {
        return (8 + strLen(xsArrayGetString(gXsInjectResString, call)));
    }
    if (returnType == cXsInjectTypeVector) {
        return (16);
    }
    return (8);
}

void xsInjectStoreResponse(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1,
    int entryCount = 0) {
    int call = 0;
    gXsInjectHaveResp = true;
    gXsInjectRespId = requestId;
    gXsInjectRespStatus = status;
    gXsInjectRespFailedCall = failedCall;
    gXsInjectRespFailedArg = failedArg;
    gXsInjectRespEntryCount = entryCount;
    // Measured once here, so a host write each tick costs no string scans.
    gXsInjectRespSize = cXsInjectSectionFixedBytes;
    while (call < entryCount) {
        gXsInjectRespSize = gXsInjectRespSize + xsInjectEntrySize(call);
        call++;
    }
}

// Writes call #`call`'s result from its return type's array; a void call writes nothing.
// xsInjectEntrySize mirrors this layout; change both together.
void xsInjectWriteResult(int call = 0) {
    int returnType = xsInjectReturnType(xsArrayGetInt(gXsInjectCallFn, call));
    if (returnType == cXsInjectTypeInt) {
        xsWriteInt(xsArrayGetInt(gXsInjectResInt, call));
    } else if (returnType == cXsInjectTypeFloat) {
        xsWriteFloat(xsArrayGetFloat(gXsInjectResFloat, call));
    } else if (returnType == cXsInjectTypeBool) {
        if (xsArrayGetBool(gXsInjectResBool, call)) {
            xsWriteInt(1);
        } else {
            xsWriteInt(0);
        }
    } else if (returnType == cXsInjectTypeString) {
        xsWriteString(xsArrayGetString(gXsInjectResString, call));
    } else if (returnType == cXsInjectTypeVector) {
        xsWriteVector(xsArrayGetVector(gXsInjectResVector, call));
    }
}

void xsInjectWriteSectionBody() {
    int call = 0;
    xsWriteInt(cXsInjectMagic);
    xsWriteInt(gXsInjectRespId);
    xsWriteInt(gXsInjectRespStatus);
    xsWriteInt(gXsInjectRespFailedCall);
    xsWriteInt(gXsInjectRespFailedArg);
    xsWriteInt(gXsInjectRespEntryCount);
    // One entry per call, in call order.
    while (call < gXsInjectRespEntryCount) {
        xsWriteInt(cXsInjectEntryOK);
        xsInjectWriteResult(call);
        call++;
    }
}

// Host mode: call once from main(). The module then never writes the game's .xsdat itself; the
// host carries the response by calling xsInjectWriteSection() on each of its writes.
void xsInjectUseHostWriter() {
    gXsInjectHosted = true;
}

// The write hook: appends the last stored response section to the file open for writing, at its
// current position. A host calls it just before its own xsCloseFile(). Writes nothing before the
// first response. A section that would push the file past the write limit (the host's bytes
// included) goes out as TooLarge with no entries; the calls have already run. If the host's own
// bytes leave no room even for that 32-byte section, it is still written: the host is over the
// limit either way.
void xsInjectWriteSection() {
    if (gXsInjectHaveResp == false) {
        return;
    }
    int bodyStart = xsGetFilePosition();
    if (bodyStart < 0) {
        return;  // no file open for writing
    }
    if (bodyStart + gXsInjectRespSize > cXsInjectWriteLimit) {
        // Kept as TooLarge, so every later host write agrees with the first.
        xsInjectStoreResponse(gXsInjectRespId, cXsInjectTooLarge, -1, -1, 0);
    }
    xsInjectWriteSectionBody();
    xsWriteInt(xsGetFilePosition() - bodyStart);
    xsWriteInt(cXsInjectMagic);
}

// Standalone: the module owns the game's .xsdat and writes the section alone, measured from 0.
void xsInjectWriteStandalone() {
    if (xsCreateFile(false) == false) {
        return;
    }
    xsInjectWriteSection();
    xsCloseFile();
}

// Stores a response; standalone writes it now, a host carries it on its next write.
void xsInjectRespond(int requestId = -1, int status = -1, int failedCall = -1, int failedArg = -1,
    int entryCount = 0) {
    xsInjectStoreResponse(requestId, status, failedCall, failedArg, entryCount);
    if (gXsInjectHosted == false) {
        xsInjectWriteStandalone();
    }
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

    xsInjectClearResults();
    // Running marks the request before call #0, so a call that kills the rule stays visible (a host
    // carries it only if a call stops the rule before the final response is stored).
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
