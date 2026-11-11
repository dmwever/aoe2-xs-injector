int gAI = -1;
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

void Dispatch(int fid = -1, int argc = 0) {
    switch (fid) {
        case 0: {
            if (argc == 1) {
                xsDisableRule(xsArrayGetString(gAS, 0));
            }
        }
        case 1: {
            if (argc == 0) {
                xsDisableSelf();
            }
        }
        case 2: {
            if (argc == 1) {
                xsEnableRule(xsArrayGetString(gAS, 0));
            }
        }
        case 3: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsIsRuleEnabled(xsArrayGetString(gAS, 0)));
            }
        }
        case 4: {
            if (argc == 2) {
                xsSetRulePriority(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 5: {
            if (argc == 1) {
                xsSetRulePrioritySelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 6: {
            if (argc == 2) {
                xsSetRuleMinInterval(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 7: {
            if (argc == 1) {
                xsSetRuleMinIntervalSelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 8: {
            if (argc == 2) {
                xsSetRuleMaxInterval(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 9: {
            if (argc == 1) {
                xsSetRuleMaxIntervalSelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 10: {
            if (argc == 1) {
                xsEnableRuleGroup(xsArrayGetString(gAS, 0));
            }
        }
        case 11: {
            if (argc == 1) {
                xsDisableRuleGroup(xsArrayGetString(gAS, 0));
            }
        }
        case 12: {
            if (argc == 1) {
                xsIsRuleGroupEnabled(xsArrayGetString(gAS, 0));
            }
        }
        case 13: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetX(xsArrayGetVector(gAV, 0)));
            }
        }
        case 14: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetY(xsArrayGetVector(gAV, 0)));
            }
        }
        case 15: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetZ(xsArrayGetVector(gAV, 0)));
            }
        }
        case 16: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetX(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 17: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetY(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 18: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetZ(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 19: {
            if (argc == 3) {
                xsArraySetVector(gRV, 0, xsVectorSet(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1), xsArrayGetFloat(gAF, 2)));
            }
        }
        case 20: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorLength(xsArrayGetVector(gAV, 0)));
            }
        }
        case 21: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsVectorNormalize(xsArrayGetVector(gAV, 0)));
            }
        }
        case 22: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 23: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 24: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 25: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 26: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 27: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 28: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2)));
            }
        }
        case 29: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 30: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 31: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2)));
            }
        }
        case 32: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayGetInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 33: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsArrayGetFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 34: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayGetBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 35: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsArrayGetString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 36: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsArrayGetVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 37: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 38: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 39: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 40: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 41: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 42: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayGetSize(xsArrayGetInt(gAI, 0)));
            }
        }
        case 43: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, abs(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 44: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, sqrt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 45: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, pow(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 46: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, sin(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 47: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, cos(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 48: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, tan(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 49: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, asin(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 50: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, acos(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 51: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, atan(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 52: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, atan2(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 53: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, atan2v(xsArrayGetVector(gAV, 0)));
            }
        }
        case 54: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, exp(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 55: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, ceil(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 56: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, floor(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 57: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, bitCastToFloat(xsArrayGetInt(gAI, 0)));
            }
        }
        case 58: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, bitCastToInt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 59: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsCeilToInt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 60: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, ln(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 61: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, log2(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 62: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, log10(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 63: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, round(xsArrayGetFloat(gAF, 0)));
            }
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, round(xsArrayGetFloat(gAF, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 64: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, radians(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 65: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, degrees(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 66: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, dist(xsArrayGetVector(gAV, 0), xsArrayGetVector(gAV, 1)));
            }
        }
        case 67: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitAnd(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 68: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitOr(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 69: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitXor(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 70: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitLsh(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 71: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitRsh(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 72: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, bitNot(xsArrayGetInt(gAI, 0)));
            }
        }
        case 73: {
            if (argc == 0) {
                xsArraySetInt(gRI, 0, xsGetRandomNumber());
            }
        }
        case 74: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetRandomNumberLH(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 75: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetRandomNumberMax(xsArrayGetInt(gAI, 0)));
            }
        }
        case 76: {
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsResearchTechnology(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1), xsArrayGetBool(gAB, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 77: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetString(gRS, 0, xsGetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 78: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetTechState(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 79: {
            if (argc == 4) {
                xsArraySetInt(gRI, 0, xsGetTechAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 80: {
            if (argc == 3) {
                xsSetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2));
            }
        }
        case 81: {
            if (argc == 3) {
                xsSetTechDescription(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2));
            }
        }
        case 82: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsInitiateResearch(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 83: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsHasResearchedLocalTechnology(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 84: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsResearchLocalTechnology(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 85: {
            if (argc == 4) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3));
            }
            if (argc == 5) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3), xsArrayGetInt(gAI, 4));
            }
            if (argc == 6) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3), xsArrayGetInt(gAI, 4), xsArrayGetInt(gAI, 5));
            }
        }
        case 86: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetPlayerUnitIds(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsGetPlayerUnitIds(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 87: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetHandicapMultiplier(xsArrayGetInt(gAI, 0)));
            }
        }
        case 88: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetWorldPlayerId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 89: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerCivilization(xsArrayGetInt(gAI, 0)));
            }
        }
        case 90: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsGetPlayerInGame(xsArrayGetInt(gAI, 0)));
            }
        }
        case 91: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerNumberOfTechs(xsArrayGetInt(gAI, 0)));
            }
        }
        case 92: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsPlayerAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 93: {
            if (argc == 3) {
                xsSetPlayerAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2));
            }
        }
        case 94: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetPlayerName(xsArrayGetInt(gAI, 0)));
            }
        }
        case 95: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerType(xsArrayGetInt(gAI, 0)));
            }
        }
        case 96: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetDiplomacy(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 97: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetDiplomacy(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsSetDiplomacy(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetBool(gAB, 3)));
            }
        }
        case 98: {
            if (argc == 0) {
                xsArraySetInt(gRI, 0, xsGetDifficulty());
            }
        }
        case 99: {
            if (argc == 1) {
                xsDeclareVictory(xsArrayGetInt(gAI, 0));
            }
            if (argc == 2) {
                xsDeclareVictory(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1));
            }
        }
        case 100: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetPlayerCivName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetPlayerCivName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 101: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetPlayerCivName(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 102: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetPlayerName(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 103: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetPlayerColor(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 104: {
            if (argc == 2) {
                xsSetChatToPlayer(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1));
            }
        }
        case 105: {
            if (argc == 2) {
                xsTaskAmount(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1));
            }
        }
        case 106: {
            if (argc == 0) {
                xsResetTaskAmount();
            }
        }
        case 107: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectTaskCount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 108: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitTaskCount(xsArrayGetInt(gAI, 0)));
            }
        }
        case 109: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsObjectTaskAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 110: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsUnitTaskAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 111: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetTaskAmount(xsArrayGetInt(gAI, 0)));
            }
        }
        case 112: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsModifyObjectTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsModifyObjectTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetBool(gAB, 3)));
            }
        }
        case 113: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsModifyUnitTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsModifyUnitTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 114: {
            if (argc == 2) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1));
            }
            if (argc == 3) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2));
            }
            if (argc == 4) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3));
            }
        }
        case 115: {
            if (argc == 2) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1));
            }
            if (argc == 3) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2));
            }
            if (argc == 4) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3));
            }
        }
        case 116: {
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2)));
            }
            if (argc == 4) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3)));
            }
            if (argc == 5) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3), xsArrayGetBool(gAB, 4)));
            }
            if (argc == 6) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3), xsArrayGetBool(gAB, 4), xsArrayGetBool(gAB, 5)));
            }
        }
        case 117: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsRemoveUnit(xsArrayGetInt(gAI, 0)));
            }
        }
        case 118: {
            if (argc == 4) {
                xsArraySetFloat(gRF, 0, xsGetObjectAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 119: {
            if (argc == 3) {
                xsArraySetFloat(gRF, 0, xsGetUnitAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 120: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsDoesUnitExist(xsArrayGetInt(gAI, 0)));
            }
        }
        case 121: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitOwner(xsArrayGetInt(gAI, 0)));
            }
        }
        case 122: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsGetUnitPosition(xsArrayGetInt(gAI, 0)));
            }
        }
        case 123: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitPosition(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitPosition(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 124: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetUnitName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 125: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetObjectName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetString(gRS, 0, xsGetObjectName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 126: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitTargetUnitId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 127: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsGetUnitMoveTarget(xsArrayGetInt(gAI, 0)));
            }
        }
        case 128: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitGroupId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 129: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsGetGroupMoveTarget(xsArrayGetInt(gAI, 0)));
            }
        }
        case 130: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsIsObjectAvailable(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 131: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetUnitHitpoints(xsArrayGetInt(gAI, 0)));
            }
        }
        case 132: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitHitpoints(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 133: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetUnitBuildPoints(xsArrayGetInt(gAI, 0)));
            }
        }
        case 134: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitBuildPoints(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 135: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitObjectId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 136: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitCopyId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 137: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectCopyId(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 138: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitClass(xsArrayGetInt(gAI, 0)));
            }
        }
        case 139: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectClass(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 140: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitType(xsArrayGetInt(gAI, 0)));
            }
        }
        case 141: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectType(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 142: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetUnitAttributeTypesHeld(xsArrayGetInt(gAI, 0)));
            }
        }
        case 143: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetUnitAttributeHeld(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsGetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 144: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 145: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetUnitCharge(xsArrayGetInt(gAI, 0)));
            }
        }
        case 146: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitCharge(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 147: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetGarrisonedInUnitId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 148: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetGarrisonedUnitIds(xsArrayGetInt(gAI, 0)));
            }
        }
        case 149: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectCount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 150: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetObjectCountTotal(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 151: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3)));
            }
            if (argc == 5) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3), xsArrayGetInt(gAI, 4)));
            }
            if (argc == 6) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3), xsArrayGetInt(gAI, 4), xsArrayGetInt(gAI, 5)));
            }
        }
        case 152: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsIsObjectValid(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 153: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerNumberOfObjects(xsArrayGetInt(gAI, 0)));
            }
        }
        case 154: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsTrainObject(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 155: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitGatherPoint(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitGatherPoint(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 156: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsGetUnitGatherPoint(xsArrayGetInt(gAI, 0)));
            }
        }
        case 157: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitCaption(xsArrayGetInt(gAI, 0)));
            }
        }
        case 158: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitCaption(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 159: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitName(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 160: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitCivName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetUnitCivName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 161: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitCivName(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 162: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitPlayerName(xsArrayGetInt(gAI, 0)));
            }
        }
        case 163: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitPlayerName(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
        }
        case 164: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetObjectDescription(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 165: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsGetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetFloat(gRF, 0, xsGetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 166: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsSetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 167: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitOwner(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitOwner(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 168: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 169: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsStopUnit(xsArrayGetInt(gAI, 0)));
            }
        }
        case 170: {
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2)));
            }
            if (argc == 4) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3)));
            }
            if (argc == 5) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3), xsArrayGetBool(gAB, 4)));
            }
            if (argc == 6) {
                xsArraySetInt(gRI, 0, xsCreateUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2), xsArrayGetBool(gAB, 3), xsArrayGetBool(gAB, 4), xsArrayGetBool(gAB, 5)));
            }
        }
        case 171: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3)));
            }
            if (argc == 5) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3), xsArrayGetInt(gAI, 4)));
            }
            if (argc == 6) {
                xsArraySetBool(gRB, 0, xsObjectHasAction(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3), xsArrayGetInt(gAI, 4), xsArrayGetInt(gAI, 5)));
            }
        }
        case 172: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetMapName(xsArrayGetBool(gAB, 0)));
            }
        }
        case 173: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 174: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateFloat(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 175: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateBool(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 176: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateString(xsArrayGetInt(gAI, 0), xsArrayGetString(gAS, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 177: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsArrayCreateVector(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 178: {
            if (argc == 4) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3));
            }
            if (argc == 5) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3), xsArrayGetInt(gAI, 4));
            }
            if (argc == 6) {
                xsEffectAmount(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetFloat(gAF, 3), xsArrayGetInt(gAI, 4), xsArrayGetInt(gAI, 5));
            }
        }
        case 179: {
            if (argc == 2) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1));
            }
            if (argc == 3) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2));
            }
            if (argc == 4) {
                xsTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3));
            }
        }
        case 180: {
            if (argc == 2) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1));
            }
            if (argc == 3) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2));
            }
            if (argc == 4) {
                xsRemoveTask(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3));
            }
        }
        case 181: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsFlashUnit(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 182: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, round(xsArrayGetFloat(gAF, 0)));
            }
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, round(xsArrayGetFloat(gAF, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 183: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetString(gRS, 0, xsGetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 184: {
            if (argc == 0) {
                xsArraySetInt(gRI, 0, xsGetGameTime());
            }
        }
        case 185: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetPlayerUnitIds(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetInt(gRI, 0, xsGetPlayerUnitIds(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 186: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetDiplomacy(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsSetDiplomacy(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetBool(gAB, 3)));
            }
        }
        case 187: {
            if (argc == 1) {
                xsDeclareVictory(xsArrayGetInt(gAI, 0));
            }
            if (argc == 2) {
                xsDeclareVictory(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1));
            }
        }
        case 188: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetPlayerCivName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetPlayerCivName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 189: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsModifyObjectTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsModifyObjectTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetBool(gAB, 3)));
            }
        }
        case 190: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsModifyUnitTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsModifyUnitTasks(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 191: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitPosition(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitPosition(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 192: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetUnitName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 193: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetObjectName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetString(gRS, 0, xsGetObjectName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 194: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetUnitAttributeHeld(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsGetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 195: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitAttributeHeld(xsArrayGetInt(gAI, 0), xsArrayGetFloat(gAF, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 196: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitGatherPoint(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitGatherPoint(xsArrayGetInt(gAI, 0), xsArrayGetVector(gAV, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 197: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetUnitCivName(xsArrayGetInt(gAI, 0)));
            }
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsGetUnitCivName(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1)));
            }
        }
        case 198: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsGetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetFloat(gRF, 0, xsGetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 199: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2)));
            }
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsSetUnitProperty(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 200: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsSetUnitOwner(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsSetUnitOwner(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 201: {
            if (argc == 1) {
                xsDisableRule(xsArrayGetString(gAS, 0));
            }
        }
        case 202: {
            if (argc == 0) {
                xsDisableSelf();
            }
        }
        case 203: {
            if (argc == 1) {
                xsEnableRule(xsArrayGetString(gAS, 0));
            }
        }
        case 204: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsIsRuleEnabled(xsArrayGetString(gAS, 0)));
            }
        }
        case 205: {
            if (argc == 2) {
                xsSetRulePriority(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 206: {
            if (argc == 1) {
                xsSetRulePrioritySelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 207: {
            if (argc == 2) {
                xsSetRuleMinInterval(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 208: {
            if (argc == 1) {
                xsSetRuleMinIntervalSelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 209: {
            if (argc == 2) {
                xsSetRuleMaxInterval(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1));
            }
        }
        case 210: {
            if (argc == 1) {
                xsSetRuleMaxIntervalSelf(xsArrayGetInt(gAI, 0));
            }
        }
        case 211: {
            if (argc == 1) {
                xsEnableRuleGroup(xsArrayGetString(gAS, 0));
            }
        }
        case 212: {
            if (argc == 1) {
                xsDisableRuleGroup(xsArrayGetString(gAS, 0));
            }
        }
        case 213: {
            if (argc == 1) {
                xsIsRuleGroupEnabled(xsArrayGetString(gAS, 0));
            }
        }
        case 214: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetX(xsArrayGetVector(gAV, 0)));
            }
        }
        case 215: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetY(xsArrayGetVector(gAV, 0)));
            }
        }
        case 216: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorGetZ(xsArrayGetVector(gAV, 0)));
            }
        }
        case 217: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetX(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 218: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetY(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 219: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsVectorSetZ(xsArrayGetVector(gAV, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 220: {
            if (argc == 3) {
                xsArraySetVector(gRV, 0, xsVectorSet(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1), xsArrayGetFloat(gAF, 2)));
            }
        }
        case 221: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsVectorLength(xsArrayGetVector(gAV, 0)));
            }
        }
        case 222: {
            if (argc == 1) {
                xsArraySetVector(gRV, 0, xsVectorNormalize(xsArrayGetVector(gAV, 0)));
            }
        }
        case 223: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 224: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2)));
            }
        }
        case 225: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetBool(gAB, 2)));
            }
        }
        case 226: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2)));
            }
        }
        case 227: {
            if (argc == 3) {
                xsArraySetBool(gRB, 0, xsArraySetVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetVector(gAV, 2)));
            }
        }
        case 228: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsArrayGetInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 229: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsArrayGetFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 230: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayGetBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 231: {
            if (argc == 2) {
                xsArraySetString(gRS, 0, xsArrayGetString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 232: {
            if (argc == 2) {
                xsArraySetVector(gRV, 0, xsArrayGetVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 233: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeInt(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 234: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeFloat(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 235: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeBool(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 236: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeString(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 237: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsArrayResizeVector(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 238: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsArrayGetSize(xsArrayGetInt(gAI, 0)));
            }
        }
        case 239: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, abs(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 240: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, sqrt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 241: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, pow(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 242: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, sin(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 243: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, cos(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 244: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, tan(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 245: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, asin(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 246: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, acos(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 247: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, atan(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 248: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, strLen(xsArrayGetString(gAS, 0)));
            }
        }
        case 249: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, atan2(xsArrayGetFloat(gAF, 0), xsArrayGetFloat(gAF, 1)));
            }
        }
        case 250: {
            if (argc == 3) {
                xsArraySetString(gRS, 0, strSubstring(xsArrayGetString(gAS, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2)));
            }
        }
        case 251: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, atan2v(xsArrayGetVector(gAV, 0)));
            }
        }
        case 252: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, exp(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 253: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, ceil(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 254: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, floor(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 255: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, bitCastToFloat(xsArrayGetInt(gAI, 0)));
            }
        }
        case 256: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, bitCastToInt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 257: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsCeilToInt(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 258: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, ln(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 259: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, log2(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 260: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, log10(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 261: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, radians(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 262: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, degrees(xsArrayGetFloat(gAF, 0)));
            }
        }
        case 263: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, dist(xsArrayGetVector(gAV, 0), xsArrayGetVector(gAV, 1)));
            }
        }
        case 264: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitAnd(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 265: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitOr(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 266: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitXor(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 267: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitLsh(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 268: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, bitRsh(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 269: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, bitNot(xsArrayGetInt(gAI, 0)));
            }
        }
        case 270: {
            if (argc == 0) {
                xsArraySetInt(gRI, 0, xsGetRandomNumber());
            }
        }
        case 271: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetRandomNumberLH(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 272: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetRandomNumberMax(xsArrayGetInt(gAI, 0)));
            }
        }
        case 273: {
            if (argc == 4) {
                xsArraySetBool(gRB, 0, xsResearchTechnology(xsArrayGetInt(gAI, 0), xsArrayGetBool(gAB, 1), xsArrayGetBool(gAB, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 274: {
            if (argc == 2) {
                xsArraySetInt(gRI, 0, xsGetTechState(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 275: {
            if (argc == 4) {
                xsArraySetInt(gRI, 0, xsGetTechAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetInt(gAI, 2), xsArrayGetInt(gAI, 3)));
            }
        }
        case 276: {
            if (argc == 3) {
                xsSetTechName(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2));
            }
        }
        case 277: {
            if (argc == 3) {
                xsSetTechDescription(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetString(gAS, 2));
            }
        }
        case 278: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsInitiateResearch(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 279: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsHasResearchedLocalTechnology(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 280: {
            if (argc == 2) {
                xsArraySetBool(gRB, 0, xsResearchLocalTechnology(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 281: {
            if (argc == 1) {
                xsArraySetFloat(gRF, 0, xsGetHandicapMultiplier(xsArrayGetInt(gAI, 0)));
            }
        }
        case 282: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetWorldPlayerId(xsArrayGetInt(gAI, 0)));
            }
        }
        case 283: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerCivilization(xsArrayGetInt(gAI, 0)));
            }
        }
        case 284: {
            if (argc == 1) {
                xsArraySetBool(gRB, 0, xsGetPlayerInGame(xsArrayGetInt(gAI, 0)));
            }
        }
        case 285: {
            if (argc == 1) {
                xsArraySetInt(gRI, 0, xsGetPlayerNumberOfTechs(xsArrayGetInt(gAI, 0)));
            }
        }
        case 286: {
            if (argc == 2) {
                xsArraySetFloat(gRF, 0, xsPlayerAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1)));
            }
        }
        case 287: {
            if (argc == 3) {
                xsSetPlayerAttribute(xsArrayGetInt(gAI, 0), xsArrayGetInt(gAI, 1), xsArrayGetFloat(gAF, 2));
            }
        }
        case 288: {
            if (argc == 1) {
                xsArraySetString(gRS, 0, xsGetPlayerName(xsArrayGetInt(gAI, 0)));
            }
        }
    }
}

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
    R("cases", 289, "");
    R("callsites", 373, "");

    Dispatch(184, 0);
    R("xsGetGameTime", xsArrayGetInt(gRI, 0), "");

    xsArraySetString(gAS, 0, "abcd");
    Dispatch(248, 1);
    R("strLen", xsArrayGetInt(gRI, 0), "");

    xsArraySetString(gAS, 0, "abcdef");
    xsArraySetInt(gAI, 1, 1);
    xsArraySetInt(gAI, 2, 4);
    Dispatch(250, 3);
    R("strSubstring", 0, xsArrayGetString(gRS, 0));

    xsArraySetFloat(gAF, 0, 2.5);
    xsArraySetFloat(gAF, 1, 1.25);
    xsArraySetFloat(gAF, 2, 3.0);
    Dispatch(19, 3);
    R("xsVectorSet.y", bitCastToInt(xsVectorGetY(xsArrayGetVector(gRV, 0))), "");

    xsArraySetFloat(gAF, 0, 2.567);
    Dispatch(63, 1);
    R("round1", bitCastToInt(xsArrayGetFloat(gRF, 0)), "");
    xsArraySetInt(gAI, 1, 2);
    Dispatch(63, 2);
    R("round2", bitCastToInt(xsArrayGetFloat(gRF, 0)), "");

    xsArraySetBool(gAB, 0, false);
    Dispatch(172, 1);
    R("xsGetMapName", 0, xsArrayGetString(gRS, 0));

    R("done", gN, "");
    FlushLog();
    xsChatData("run B done: " + xsGetMapName(false));
}
