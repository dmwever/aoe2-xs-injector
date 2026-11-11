int gLab = -1;
int gVal = -1;
int gTxt = -1;
int gN = 0;
int gCap = 0;
int gStep = 0;
int gHold = 0;
int gHoldUntil = 0;
int gNextPoll = 0;

int B(bool b = false) {
    if (b) {
        return (1);
    }
    return (0);
}

void R(string lab = "", int v = 0, string s = "") {
    if (gN >= gCap) {
        gCap = gCap * 2;
        xsArrayResizeString(gLab, gCap);
        xsArrayResizeInt(gVal, gCap);
        xsArrayResizeString(gTxt, gCap);
    }
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

void ProbeOpen(string tag = "", string name = "") {
    bool ok = xsOpenFile(name);
    R(tag + ".open", B(ok), name);
    if (ok == false) {
        return;
    }
    int size = xsGetFileSize();
    R(tag + ".size", size, "");
    if (size >= 4) {
        R(tag + ".int0", xsReadInt(), "");
    }
    R(tag + ".close", B(xsCloseFile()), "");
}

void DumpOwn(string tag = "", int maxInts = 8) {
    bool ok = xsOpenFile(xsGetMapName(false));
    R(tag + ".open", B(ok), "");
    if (ok == false) {
        return;
    }
    int size = xsGetFileSize();
    R(tag + ".size", size, "");
    int n = size / 4;
    if (n > maxInts) {
        n = maxInts;
    }
    for (i = 0; < n) {
        R(tag + ".i" + i, xsReadInt(), "");
    }
    xsCloseFile();
}

void Step1() {
    R("map", 0, xsGetMapName(false));
    R("mapext", 0, xsGetMapName(true));
    R("own.create", B(xsCreateFile(false)), "");
    R("own.wint", B(xsWriteInt(111)), "");
    R("own.wstr", B(xsWriteString("own")), "");
    R("own.close", B(xsCloseFile()), "");
    ProbeOpen("own.mapname", xsGetMapName(false));
    ProbeOpen("own.default0", "default0");
    ProbeOpen("own.default1", "default1");
    ProbeOpen("own.xstesting", "XsTesting");
    ProbeOpen("missing", "spike_does_not_exist");
}

void Step2() {
    R("pos.open", B(xsOpenFile("spike_pos")), "");
    R("pos.size", xsGetFileSize(), "");
    R("pos.p0", xsGetFilePosition(), "");
    R("pos.int", xsReadInt(), "");
    R("pos.p1", xsGetFilePosition(), "");
    R("pos.float", bitCastToInt(xsReadFloat()), "");
    R("pos.p2", xsGetFilePosition(), "");
    R("pos.str", 0, xsReadString());
    R("pos.p3", xsGetFilePosition(), "");
    vector v = xsReadVector();
    R("pos.vx", bitCastToInt(xsVectorGetX(v)), "");
    R("pos.vz", bitCastToInt(xsVectorGetZ(v)), "");
    R("pos.p4", xsGetFilePosition(), "");
    R("pos.int2", xsReadInt(), "");
    R("pos.p5", xsGetFilePosition(), "");
    R("pos.set4", B(xsSetFilePosition(4)), "");
    R("pos.float@4", bitCastToInt(xsReadFloat()), "");
    R("pos.set0", B(xsSetFilePosition(0)), "");
    R("pos.offInt", B(xsOffsetFilePosition(cOffsetInteger, true)), "");
    R("pos.p6", xsGetFilePosition(), "");
    R("pos.offFloat", B(xsOffsetFilePosition(cOffsetFloat, true)), "");
    R("pos.p7", xsGetFilePosition(), "");
    R("pos.offStr", B(xsOffsetFilePosition(cOffsetString, true)), "");
    R("pos.p8", xsGetFilePosition(), "");
    R("pos.offVec", B(xsOffsetFilePosition(cOffsetVector, true)), "");
    R("pos.p9", xsGetFilePosition(), "");
    R("pos.offIntBack", B(xsOffsetFilePosition(cOffsetInteger, false)), "");
    R("pos.p10", xsGetFilePosition(), "");
    R("pos.setNeg", B(xsSetFilePosition(-1)), "");
    R("pos.p11", xsGetFilePosition(), "");
    R("pos.setPastEnd", B(xsSetFilePosition(1000)), "");
    R("pos.p12", xsGetFilePosition(), "");
    R("pos.close", B(xsCloseFile()), "");
    R("dts.int", xsGetDataTypeSize(cOffsetInteger), "");
    R("dts.float", xsGetDataTypeSize(cOffsetFloat), "");
    R("dts.str", xsGetDataTypeSize(cOffsetString), "");
    R("dts.vec", xsGetDataTypeSize(cOffsetVector), "");
}

void Step3() {
    R("eof.open", B(xsOpenFile("spike_eof")), "");
    R("eof.size", xsGetFileSize(), "");
    R("eof.int0", xsReadInt(), "");
    R("eof.p1", xsGetFilePosition(), "");
    R("eof.intPast", xsReadInt(), "");
    R("eof.p2", xsGetFilePosition(), "");
    R("eof.intPast2", xsReadInt(), "");
    R("eof.p3", xsGetFilePosition(), "");
    R("eof.floatPast", bitCastToInt(xsReadFloat()), "");
    R("eof.p4", xsGetFilePosition(), "");
    vector v = xsReadVector();
    R("eof.vecPastX", bitCastToInt(xsVectorGetX(v)), "");
    R("eof.vecPastY", bitCastToInt(xsVectorGetY(v)), "");
    R("eof.vecPastZ", bitCastToInt(xsVectorGetZ(v)), "");
    R("eof.p5", xsGetFilePosition(), "");
    R("eof.set2", B(xsSetFilePosition(2)), "");
    R("eof.intPartial", xsReadInt(), "");
    R("eof.p6", xsGetFilePosition(), "");
    R("eof.close", B(xsCloseFile()), "");
    R("empty.open", B(xsOpenFile("spike_empty")), "");
    R("empty.size", xsGetFileSize(), "");
    R("empty.int", xsReadInt(), "");
    R("empty.p", xsGetFilePosition(), "");
    R("empty.close", B(xsCloseFile()), "");
}

void Step4() {
    R("nest.openA", B(xsOpenFile("spike_a")), "");
    R("nest.readA", xsReadInt(), "");
    R("nest.openB", B(xsOpenFile("spike_b")), "");
    R("nest.sizeAfterB", xsGetFileSize(), "");
    R("nest.posAfterB", xsGetFilePosition(), "");
    R("nest.readAfterB", xsReadInt(), "");
    R("nest.close1", B(xsCloseFile()), "");
    R("nest.readAfterClose1", xsReadInt(), "");
    R("nest.close2", B(xsCloseFile()), "");
    R("nest2.openA", B(xsOpenFile("spike_a")), "");
    R("nest2.create", B(xsCreateFile(false)), "");
    R("nest2.write", B(xsWriteInt(555)), "");
    R("nest2.read", xsReadInt(), "");
    R("nest2.close", B(xsCloseFile()), "");
    DumpOwn("nest2.own", 4);
    R("nest3.create", B(xsCreateFile(false)), "");
    R("nest3.write1", B(xsWriteInt(1)), "");
    R("nest3.openB", B(xsOpenFile("spike_b")), "");
    R("nest3.read", xsReadInt(), "");
    R("nest3.write2", B(xsWriteInt(2)), "");
    R("nest3.close", B(xsCloseFile()), "");
    DumpOwn("nest3.own", 4);
    ProbeOpen("nest3.a", "spike_a");
}

void Step5() {
    R("app.create1", B(xsCreateFile(false)), "");
    xsWriteInt(1);
    xsWriteString("A");
    R("app.close1", B(xsCloseFile()), "");
    R("app.create2", B(xsCreateFile(true)), "");
    xsWriteInt(2);
    xsWriteString("B");
    R("app.close2", B(xsCloseFile()), "");
    R("app.open", B(xsOpenFile(xsGetMapName(false))), "");
    R("app.size", xsGetFileSize(), "");
    R("app.i1", xsReadInt(), "");
    R("app.s1", 0, xsReadString());
    R("app.i2", xsReadInt(), "");
    R("app.s2", 0, xsReadString());
    R("app.close3", B(xsCloseFile()), "");
}

void Step6() {
    DumpOwn("ext.before", 8);
    R("ext.create", B(xsCreateFile(true)), "");
    xsWriteInt(3);
    R("ext.close", B(xsCloseFile()), "");
    DumpOwn("ext.after", 8);
}

void HoldRead(string name = "") {
    R(name + ".open", B(xsOpenFile(name)), "");
    R(name + ".size0", xsGetFileSize(), "");
    R(name + ".int0", xsReadInt(), "");
    R(name + ".t0", xsGetWorldTime(), "");
    gHold = 1;
    gHoldUntil = xsGetWorldTime() + 12000;
}

void ReleaseRead(string name = "") {
    R(name + ".t1", xsGetWorldTime(), "");
    R(name + ".size1", xsGetFileSize(), "");
    R(name + ".pos1", xsGetFilePosition(), "");
    R(name + ".int1", xsReadInt(), "");
    R(name + ".int2", xsReadInt(), "");
    R(name + ".int3", xsReadInt(), "");
    R(name + ".pos2", xsGetFilePosition(), "");
    R(name + ".set0", B(xsSetFilePosition(0)), "");
    R(name + ".int0again", xsReadInt(), "");
    R(name + ".close", B(xsCloseFile()), "");
    ProbeOpen(name + ".fresh", name);
}

void HoldWrite() {
    R("hw.create", B(xsCreateFile(false)), "");
    xsWriteInt(1111);
    xsWriteString("holding");
    R("hw.t0", xsGetWorldTime(), "");
    gHold = 2;
    gHoldUntil = xsGetWorldTime() + 12000;
}

void ReleaseWrite() {
    R("hw.t1", xsGetWorldTime(), "");
    R("hw.write2", B(xsWriteInt(2222)), "");
    R("hw.close", B(xsCloseFile()), "");
    DumpOwn("hw.own", 6);
}

void StrRow(string tag = "", string s = "", bool keepText = true) {
    int n = strLen(s);
    string t = "";
    if (keepText) {
        t = s;
    }
    R(tag + ".len", n, t);
    if (n >= 1) {
        R(tag + ".ord0", ord(strCharAt(s, 0)), "");
    }
    if (n >= 2) {
        R(tag + ".ord1", ord(strCharAt(s, 1)), "");
    }
}

void Step12() {
    R("str.open", B(xsOpenFile("spike_str")), "");
    R("str.size", xsGetFileSize(), "");
    StrRow("str.ascii", xsReadString(), true);
    StrRow("str.e_acute", xsReadString(), true);
    StrRow("str.cjk", xsReadString(), true);
    StrRow("str.percent", xsReadString(), true);
    StrRow("str.latin1byte", xsReadString(), true);
    StrRow("str.l255", xsReadString(), false);
    StrRow("str.l4096", xsReadString(), false);
    StrRow("str.l65536", xsReadString(), false);
    R("str.pos", xsGetFilePosition(), "");
    R("str.close", B(xsCloseFile()), "");
    StrRow("chr233", chr(233), true);
    StrRow("chr26085", chr(26085), true);
    StrRow("chr0", chr(0), true);
}

void Step13() {
    R("bigstr.open", B(xsOpenFile("spike_bigstr")), "");
    R("bigstr.size", xsGetFileSize(), "");
    string s = xsReadString();
    R("bigstr.len", strLen(s), "");
    R("bigstr.pos", xsGetFilePosition(), "");
    R("bigstr.close", B(xsCloseFile()), "");
}

void BigRead(string tag = "", string name = "") {
    R(tag + ".open", B(xsOpenFile(name)), "");
    int size = xsGetFileSize();
    R(tag + ".size", size, "");
    int n = size / 4;
    int t0 = xsGetWorldTime();
    int count = 0;
    int mix = 0;
    int last = -1;
    for (i = 0; < n) {
        last = xsReadInt();
        mix = mix + last;
        count++;
    }
    R(tag + ".count", count, "");
    R(tag + ".mix", mix, "");
    R(tag + ".last", last, "");
    R(tag + ".pos", xsGetFilePosition(), "");
    R(tag + ".ms", xsGetWorldTime() - t0, "");
    R(tag + ".close", B(xsCloseFile()), "");
}

void Step16() {
    R("eofstr.open", B(xsOpenFile("spike_eof")), "");
    R("eofstr.int0", xsReadInt(), "");
    string s = xsReadString();
    R("eofstr.len", strLen(s), "");
    R("eofstr.pos", xsGetFilePosition(), "");
    R("eofstr.close", B(xsCloseFile()), "");
}

void Step17() {
    R("badstr.open", B(xsOpenFile("spike_badstr")), "");
    R("badstr.size", xsGetFileSize(), "");
    string s = xsReadString();
    R("badstr.len", strLen(s), "");
    R("badstr.pos", xsGetFilePosition(), "");
    R("badstr.close", B(xsCloseFile()), "");
}

void Step18() {
    R("nofile.close", B(xsCloseFile()), "");
    R("nofile.read", xsReadInt(), "");
    R("nofile.pos", xsGetFilePosition(), "");
    R("nofile.size", xsGetFileSize(), "");
    R("nofile.write", B(xsWriteInt(7)), "");
}

void RunStep(int step = 0) {
    if (step == 1) { Step1(); }
    if (step == 2) { Step2(); }
    if (step == 3) { Step3(); }
    if (step == 4) { Step4(); }
    if (step == 5) { Step5(); }
    if (step == 6) { Step6(); }
    if (step == 7) { HoldRead("spike_hold7"); }
    if (step == 8) { HoldRead("spike_hold8"); }
    if (step == 9) { HoldRead("spike_hold9"); }
    if (step == 10) { HoldRead("spike_hold10"); }
    if (step == 11) { HoldWrite(); }
    if (step == 12) { Step12(); }
    if (step == 13) { Step13(); }
    if (step == 14) { BigRead("big100k", "spike_big100k"); }
    if (step == 15) { BigRead("big400k", "spike_big400k"); }
    if (step == 16) { Step16(); }
    if (step == 17) { Step17(); }
    if (step == 18) { Step18(); }
    if (step == 99) { R("done", gN, ""); }
}

void ReleaseHold() {
    if (gHold == 1) {
        ReleaseRead("spike_hold" + gStep);
    }
    if (gHold == 2) {
        ReleaseWrite();
    }
    gHold = 0;
    R("release", gStep, "");
}

rule SpikePoll
    active
    highFrequency
{
    int now = xsGetWorldTime();
    if (now < gNextPoll) {
        return;
    }
    gNextPoll = now + 250;
    if (gHold != 0) {
        if (now >= gHoldUntil) {
            ReleaseHold();
            FlushLog();
            xsChatData("spike released hold " + gStep);
        }
        return;
    }
    bool ok = xsOpenFile("spike_ctl");
    if (ok == false) {
        return;
    }
    int step = -1;
    if (xsGetFileSize() >= 4) {
        step = xsReadInt();
    }
    xsCloseFile();
    if (step <= 0 || step == gStep) {
        return;
    }
    gStep = step;
    R("step", step, "");
    R("t", now, "");
    xsChatData("spike step " + step);
    RunStep(step);
    if (gHold == 0 && step != 5) {
        FlushLog();
    }
}

void main() {
    gCap = 256;
    gLab = xsArrayCreateString(gCap, "", "spikeLab");
    gVal = xsArrayCreateInt(gCap, 0, "spikeVal");
    gTxt = xsArrayCreateString(gCap, "", "spikeTxt");
    R("boot", xsGetWorldTime(), xsGetMapName(false));
    FlushLog();
    xsChatData("spike booted: " + xsGetMapName(false));
}
