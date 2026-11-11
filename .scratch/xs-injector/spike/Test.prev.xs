include "./AP.xs";

void InitScenarioLocations() {
    return;
}

void GiveScenarioItems() {
    return;
}

void SetScenarioAge() {
    SetVanillaAge(IMPERIAL_AGE);
}

void SetPavilionLayout() {
    return;
}

void InitScenarioThreats() {
    return;
}

const int SPIKE_TRAIN_MENU = 0;

const int AP78_VERSION = 2;
const int AP78_RECORDS = 256;
const int AP78_FIELDS = 8;

const int REC_BOOT = 1;
const int REC_SEED = 2;
const int REC_ROW = 3;
const int REC_CASE = 4;
const int REC_STAGE = 5;
const int REC_RES = 6;
const int REC_COUNT = 7;
const int REC_LOC = 8;
const int REC_WONDER = 9;
const int REC_DONE = 10;
const int REC_DIAG = 11;
const int REC_TRACE = 12;
const int REC_RELIC = 13;
const int REC_PROBE = 14;
const int REC_GARRISON = 15;
const int REC_REVEALER = 16;
const int REC_WITHHELD = 17;
const int REC_FSETUP = 18;
const int REC_FDEF = 19;
const int REC_FUNIT = 20;
const int REC_FSLOT = 21;
const int REC_FSCAN = 22;
const int REC_FCOUNT = 23;
const int REC_FPOS = 24;
const int REC_FGAP = 25;
const int REC_FWONDERS = 26;
const int REC_FREVEAL = 27;

const int CASE_DM_ELSEWHERE = 0;
const int CASE_DM_ATTILA5 = 1;
const int CASE_LEITIS = 2;
const int CASE_SIEGE_RAM = 3;
const int CASE_SIEGE_ONAGER = 4;
const int CASE_LONG_SWORD = 5;
const int CASE_HALBERDIER = 6;
const int CASE_WONDER = 7;
const int CASE_RELIC = 8;
const int CASE_REVEALER = 9;
const int CASE_Q2 = 10;
const int CASE_Q4 = 11;
const int CASE_WITHHELD = 12;
const int CASE_FOUNDATION = 13;
const int CASE_COUNT = 14;
const int LAST_CASE = 13;
const int FIRST_CASE = 13;

const int ATTILA_5_SCENARIO = 105;
const int OTHER_SCENARIO = 101;

const int DM_FOOD = 7000;
const int DM_WOOD = 1000;
const int DM_STONE = 500;
const int DM_GOLD = 7250;

const int LEITIS_TYPE = 1236;
const int LEITIS_ITEM = 368;
const int LEITIS_LOCATION = 441;
const int LEITIS_SPAWN = 10;
const int MILITIA_TYPE = 74;

const int CAPPED_RAM_TYPE = 422;
const int SIEGE_RAM_TYPE = 548;
const int SIEGE_RAM_TECH = 255;
const int SIEGE_RAM_ITEM = 3684;
const int SIEGE_RAM_LOCATION = 363;

const int ONAGER_TYPE = 550;
const int SIEGE_ONAGER_TYPE = 588;
const int SIEGE_ONAGER_TECH = 320;
const int SIEGE_ONAGER_ITEM = 3694;
const int SIEGE_ONAGER_LOCATION = 376;

const int MAN_AT_ARMS_TYPE = 75;
const int LONG_SWORD_TYPE = 77;
const int LONG_SWORD_TECH = 207;
const int LONG_SWORD_ITEM = 3663;
const int LONG_SWORD_LOCATION = 320;

const int PIKEMAN_TYPE = 358;
const int HALBERDIER_TYPE = 359;
const int HALBERDIER_TECH = 429;
const int HALBERDIER_ITEM = 3721;
const int HALBERDIER_LOCATION = 341;

const int WONDER_OWNER = 2;
const int RELIC = 285;
const int ALL_RELICS_CAPTURED = 55;
const int RELIC_SAMPLE_SECONDS = 3;
const int RELIC_SAMPLE_CAP = 20;
const int RELIC_WATCH_SECONDS = 70;
const int RELIC_KILL_SECONDS = 35;

int revealerA = -1;
int revealerB = -1;
int revealerC = -1;
int relicSamples = 0;
int lastRelicSampleAt = 0;
int monasteryKilled = 0;
int scanClass = -1;
int scanType = -1;
int scanGaia = -1;
int scanMonastery = -1;
int lastClass = 0;
int lastType = 0;
int lastGaia = 0;
int lastMonastery = 0;
const int ATHEISM_BONUS = 1000;

const int SKIRMISHER_LINE_ITEM = 302;
const int MILITIA_LINE_ITEM = 315;
const int SPEARMAN_LINE_ITEM = 317;
const int MAN_AT_ARMS_TECH = 222;
const int PIKEMAN_TECH = 197;
const int PIKEMAN_TECH_ITEM = 3657;
const int MAN_AT_ARMS_TECH_ITEM = 3673;
const int SPEARMAN_TYPE = 93;
const int MILITIA_TYPE_Q2 = 74;
const int CAMEL_LINE_ITEM = 384;
const int ARCHER_LINE_ITEM = 300;

const int ELITE_SKIRM_ITEM = 3652;
const int ELITE_SKIRM_TECH = 98;
const int HEAVY_CAMEL_ITEM = 3677;
const int HEAVY_CAMEL_TECH = 236;
const int CROSSBOW_ITEM = 3653;
const int CROSSBOW_TECH = 100;
const int ARBALEST_ITEM = 3678;
const int ARBALEST_TECH = 237;

const int SPIKE_LOOK_SECONDS = 30;
const int SPIKE_SWEEP_SECONDS = 30;

int spikePhase = 0;
int spikePhaseAt = 0;

const int SPAWN_CAPACITY = 32;
const int SETTLE_SECONDS = 3;
const int CAVEMAN_SECONDS = 5;
const int APPLY_SECONDS = 4;
const int WONDER_SECONDS = 4;

int ap78Log = -1;
int ap78Count = 0;
int ap78Tick = 0;
int ap78Closed = 0;
int ap78Scan = -1;
int wonderScanArray = -1;
int revealerScanArray = -1;
int lastWonderCount = 0;
int lastRevealerCount = 0;

int spawnedIds = -1;
int spawnedCount = 0;

int caseIndex = 0;
int caseStage = 0;
int stageStartedAt = 0;
int stageEntered = 0;

int spotX = 0;
int spotZ = 0;

string timerMessageA = "";
string timerMessageB = "";

int wonderA = -1;
int wonderB = -1;

void ap78Write(int recType = 0, int v1 = 0, int v2 = 0, int v3 = 0, int v4 = 0, int v5 = 0) {
    if (ap78Count >= AP78_RECORDS) {
        return;
    }
    int base = ap78Count * AP78_FIELDS;
    xsArraySetInt(ap78Log, base + 0, recType);
    xsArraySetInt(ap78Log, base + 1, ap78Tick);
    xsArraySetInt(ap78Log, base + 2, xsGetGameTime());
    xsArraySetInt(ap78Log, base + 3, v1);
    xsArraySetInt(ap78Log, base + 4, v2);
    xsArraySetInt(ap78Log, base + 5, v3);
    xsArraySetInt(ap78Log, base + 6, v4);
    xsArraySetInt(ap78Log, base + 7, v5);
    ap78Count = ap78Count + 1;
}

void ap78Flush() {
    bool created = xsCreateFile(false);
    if (created == false) {
        xsChatData("<RED>AP78: could not create the .xsdat file");
        return;
    }
    xsWriteString("AP78");
    xsWriteInt(AP78_VERSION);
    xsWriteInt(AP78_RECORDS);
    for (i = 0; < AP78_RECORDS * AP78_FIELDS) {
        xsWriteInt(xsArrayGetInt(ap78Log, i));
    }
    xsWriteString(timerMessageA);
    xsWriteString(timerMessageB);
    xsWriteString("END");
    xsWriteInt(ap78Count);
    xsWriteInt(424242);
    xsCloseFile();
}

int resourceInt(int attribute = -1) {
    return (xsCeilToInt(xsPlayerAttribute(1, attribute)));
}

void recordResources(int tag = 0) {
    ap78Write(REC_RES, resourceInt(cAttributeFood), resourceInt(cAttributeWood),
              resourceInt(cAttributeStone), resourceInt(cAttributeGold), tag);
}

int researchCount() {
    return (xsCeilToInt(xsPlayerAttribute(1, cAttributeResearchCount)));
}

void rememberSpawn(int unitId = -1) {
    if (unitId < 0 || spawnedCount >= SPAWN_CAPACITY) {
        return;
    }
    xsArraySetInt(spawnedIds, spawnedCount, unitId);
    spawnedCount = spawnedCount + 1;
}

void spawnOne(int typeId = -1, int offsetX = 0, int offsetZ = 0, bool immune = true) {
    vector position = xsVectorSet(1.0 * (spotX + offsetX), 1.0 * (spotZ + offsetZ), 0.0);
    int unitId = xsCreateUnit(typeId, 1, position, false, false, false);
    if (unitId < 0) {
        return;
    }
    if (immune) {
        MarkUnitCavemanImmune(unitId);
    }
    rememberSpawn(unitId);
}

void clearSpawned() {
    for (i = 0; < spawnedCount) {
        int unitId = xsArrayGetInt(spawnedIds, i);
        if (unitId >= 0 && xsDoesUnitExist(unitId)) {
            xsRemoveUnit(unitId);
        }
        xsArraySetInt(spawnedIds, i, -1);
    }
    spawnedCount = 0;
}

int currentTypeOf(int unitId = -1) {
    if (unitId < 0 || xsDoesUnitExist(unitId) == false) {
        return (-1);
    }
    int copyId = xsGetUnitCopyId(unitId);
    if (copyId > 0) {
        return (copyId);
    }
    return (xsGetUnitObjectId(unitId));
}

int countSpawnedOfType(int typeId = -1) {
    int found = 0;
    for (i = 0; < spawnedCount) {
        if (currentTypeOf(xsArrayGetInt(spawnedIds, i)) == typeId) {
            found = found + 1;
        }
    }
    return (found);
}

float tileCentre(int tile = 0) {
    return (1.0 * tile + 0.5);
}

int boolInt(bool value = false) {
    if (value) {
        return (1);
    }
    return (0);
}

void recordLocation(int locationId = -1, int caseId = 0) {
    ap78Write(REC_LOC, locationId, boolInt(IsScenarioLocationComplete(locationId)),
              researchCount(), caseId, 0);
}

void setTechDone(int techId = -1) {
    xsEffectAmount(cModifyTech, techId, cAttrSetState, STATE_ENABLE, 1);
    xsEffectAmount(cModifyTech, techId, cAttrSetState, STATE_DONE, 1);
}

void startStage(int stage = 0) {
    caseStage = stage;
    stageEntered = 0;
}

void nextCase() {
    clearSpawned();
    caseIndex = caseIndex + 1;
    startStage(0);
}

bool enterStage() {
    if (stageEntered == 1) {
        return (false);
    }
    stageEntered = 1;
    stageStartedAt = xsGetGameTime();
    return (true);
}

bool waited(int seconds = 0) {
    return (xsGetGameTime() - stageStartedAt >= seconds);
}

void runUpgradeCase(int caseId = 0, int baseType = -1, int upgradedType = -1,
                    int techId = -1, int itemId = -1, int locationId = -1) {
    if (caseStage == 0) {
        if (enterStage()) {
            spawnOne(baseType, 0, 0, true);
            spawnOne(baseType, 1, 0, true);
            spawnOne(baseType, 2, 0, true);
            ap78Write(REC_CASE, caseId, baseType, spawnedCount, researchCount(),
                      xsGetTechState(techId, 1));
            UnlockTech(itemId - TECH_ITEM_OFFSET);
            recordLocation(locationId, caseId);
        }
        if (waited(SETTLE_SECONDS)) {
            startStage(1);
        }
        return;
    }
    if (caseStage == 1) {
        if (enterStage()) {
            ap78Write(REC_STAGE, caseId, 1, researchCount(), xsGetTechState(techId, 1),
                      countSpawnedOfType(upgradedType));
            recordLocation(locationId, caseId);
            setTechDone(techId);
        }
        if (waited(APPLY_SECONDS)) {
            startStage(2);
        }
        return;
    }
    if (enterStage()) {
        ap78Write(REC_COUNT, caseId, countSpawnedOfType(baseType),
                  countSpawnedOfType(upgradedType), researchCount(),
                  xsGetTechState(techId, 1));
        recordLocation(locationId, caseId);
    }
    if (waited(1)) {
        nextCase();
    }
}

void runReverseUpgradeCase(int caseId = 0, int baseType = -1, int upgradedType = -1,
                           int techId = -1, int itemId = -1, int locationId = -1) {
    if (caseStage == 0) {
        if (enterStage()) {
            spawnOne(baseType, 0, 2, true);
            spawnOne(baseType, 1, 2, true);
            spawnOne(baseType, 2, 2, true);
            ap78Write(REC_CASE, caseId, baseType, spawnedCount, researchCount(),
                      xsGetTechState(techId, 1));
            setTechDone(techId);
            recordLocation(locationId, caseId);
        }
        if (waited(SETTLE_SECONDS)) {
            startStage(1);
        }
        return;
    }
    if (caseStage == 1) {
        if (enterStage()) {
            ap78Write(REC_STAGE, caseId, 1, researchCount(), xsGetTechState(techId, 1),
                      countSpawnedOfType(upgradedType));
            recordLocation(locationId, caseId);
            UnlockTech(itemId - TECH_ITEM_OFFSET);
        }
        if (waited(APPLY_SECONDS)) {
            startStage(2);
        }
        return;
    }
    if (enterStage()) {
        ap78Write(REC_COUNT, caseId, countSpawnedOfType(baseType),
                  countSpawnedOfType(upgradedType), researchCount(),
                  xsGetTechState(techId, 1));
        recordLocation(locationId, caseId);
    }
    if (waited(1)) {
        nextCase();
    }
}

void runDeathmatchCase(int caseId = 0, int targetScenario = 0) {
    if (enterStage()) {
        scenarioId = targetScenario;
        ap78Write(REC_CASE, caseId, targetScenario, 0, 0, 0);
        recordResources(caseId * 2);
        Attila5Deathmatch();
        recordResources(caseId * 2 + 1);
    }
    if (waited(1)) {
        nextCase();
    }
}

void runLeitisCase() {
    if (caseStage == 0) {
        if (enterStage()) {
            for (i = 0; < LEITIS_SPAWN) {
                spawnOne(LEITIS_TYPE, i, 4, false);
            }
            ap78Write(REC_CASE, CASE_LEITIS, LEITIS_TYPE, spawnedCount,
                      findUnit(LEITIS_TYPE), AP_TS_MODE);
            UnlockUnitItem(LEITIS_ITEM);
        }
        if (waited(CAVEMAN_SECONDS)) {
            startStage(1);
        }
        return;
    }
    if (enterStage()) {
        ap78Write(REC_COUNT, CASE_LEITIS, countSpawnedOfType(LEITIS_TYPE),
                  countSpawnedOfType(MILITIA_TYPE), spawnedCount, AP_US_CAVEMAN);
        recordLocation(LEITIS_LOCATION, CASE_LEITIS);
    }
    if (waited(1)) {
        nextCase();
    }
}

int countWonders() {
    int found = xsGetPlayerUnitIds(WONDER_OWNER, WONDER, wonderScanArray);
    if (found >= 0) {
        wonderScanArray = found;
        lastWonderCount = xsArrayGetSize(found);
    }
    return (lastWonderCount);
}

int countRevealers() {
    int found = xsGetPlayerUnitIds(THREATENED_PLAYER, MAP_REVEALER, revealerScanArray);
    if (found >= 0) {
        revealerScanArray = found;
        lastRevealerCount = xsArrayGetSize(found);
    }
    return (lastRevealerCount);
}

int buildPointsOf(int unitId = -1) {
    if (unitId < 0 || xsDoesUnitExist(unitId) == false) {
        return (-1);
    }
    return (xsCeilToInt(xsGetUnitBuildPoints(unitId)));
}

void recordWonderSlots(int tag = 0) {
    for (slot = 0; < THREAT_WONDER_CAPACITY) {
        ap78Write(REC_WONDER, slot,
                  xsCeilToInt(xsUnsyncGetTimerTimeRemaining(slot, cTimerUnitYears, -1)),
                  tag, 0, 0);
    }
    ap78Write(REC_STAGE, CASE_WONDER, tag, countWonders(), countRevealers(),
              ThreatBaseYears());
    ap78Write(REC_DIAG, CASE_WONDER, tag, boolInt(xsGetPlayerInGame(WONDER_OWNER)),
              buildPointsOf(wonderA),
              xsCeilToInt(xsGetObjectAttribute(WONDER_OWNER, WONDER, cTrainTime, 0)));
    int ownerOfA = -1;
    if (wonderA >= 0 && xsDoesUnitExist(wonderA)) {
        ownerOfA = xsGetUnitOwner(wonderA);
    }
    ap78Write(REC_TRACE, CASE_WONDER, tag, xsGetNumPlayers(), ownerOfA,
              FindWonderSlot(wonderA));
    ap78Write(REC_TRACE, CASE_WONDER, 100 + tag,
              boolInt(IsWonderComplete(wonderA, WONDER_OWNER)),
              CountdownYears(0.0), FindWonderSlot(wonderB));
}

void runWonderCase() {
    if (caseStage == 0) {
        if (enterStage()) {
            wonderA = xsCreateUnit(WONDER, WONDER_OWNER,
                                   xsVectorSet(tileCentre(spotX + 8), tileCentre(spotZ + 8), 0.0),
                                   false, false, false);
            ap78Write(REC_CASE, CASE_WONDER, WONDER, wonderA, WONDER_OWNER, 0);
            EnableWonderThreat(WONDER_OWNER);
        }
        if (waited(WONDER_SECONDS)) {
            startStage(1);
        }
        return;
    }
    if (caseStage == 1) {
        if (enterStage()) {
            timerMessageA = WonderTimerMessage(WONDER_OWNER);
            recordWonderSlots(1);
            wonderB = xsCreateUnit(WONDER, WONDER_OWNER,
                                   xsVectorSet(tileCentre(spotX + 16), tileCentre(spotZ + 8), 0.0),
                                   false, false, false);
        }
        if (waited(WONDER_SECONDS)) {
            startStage(2);
        }
        return;
    }
    if (caseStage == 2) {
        if (enterStage()) {
            recordWonderSlots(2);
            xsEffectAmount(cModResource, cAttributeHunWonderBonus, cAttributeAdd,
                           1.0 * ATHEISM_BONUS, WONDER_OWNER);
        }
        if (waited(WONDER_SECONDS)) {
            startStage(3);
        }
        return;
    }
    if (caseStage == 3) {
        if (enterStage()) {
            timerMessageB = WonderTimerMessage(WONDER_OWNER);
            recordWonderSlots(3);
            if (wonderA >= 0 && xsDoesUnitExist(wonderA)) {
                xsRemoveUnit(wonderA);
            }
        }
        if (waited(WONDER_SECONDS)) {
            startStage(4);
        }
        return;
    }
    if (enterStage()) {
        recordWonderSlots(4);
        if (wonderB >= 0 && xsDoesUnitExist(wonderB)) {
            xsRemoveUnit(wonderB);
        }
    }
    if (waited(1)) {
        nextCase();
    }
}

const int AP84_SETTLE_SECONDS = 4;

int ap84Foundation = -1;
int ap84Completed = -1;
int ap84BegunOk = 0;
int ap84ScanWonder = -1;
int ap84ScanBuilding = -1;
int ap84ScanMisc = -1;
int ap84ScanFlag = -1;
int ap84ScanAll = -1;
int ap84QueryArray = -1;
int ap84QuerySize = -1;
int ap84SetPointsOk = 0;
int ap84GridFoundation = -1;
int ap84GridSlot = -1;
int ap84LoneRevealer = -1;

int ap84Query(int queryId = 0, int arrayId = -1) {
    int found = xsGetPlayerUnitIds(WONDER_OWNER, queryId, arrayId);
    if (found < 0) {
        ap84QueryArray = -1;
        ap84QuerySize = -1;
        return (arrayId);
    }
    ap84QueryArray = found;
    ap84QuerySize = xsArrayGetSize(found);
    return (found);
}

int ap84CountOfType(int typeId = -1) {
    if (ap84QueryArray < 0) {
        return (-1);
    }
    int found = 0;
    for (i = 0; < ap84QuerySize) {
        int unitId = xsArrayGetInt(ap84QueryArray, i);
        if (unitId >= 0 && xsGetUnitObjectId(unitId) == typeId) {
            found = found + 1;
        }
    }
    return (found);
}

int ap84Holds(int unitId = -1) {
    if (ap84QueryArray < 0 || unitId < 0) {
        return (0);
    }
    for (i = 0; < ap84QuerySize) {
        if (xsArrayGetInt(ap84QueryArray, i) == unitId) {
            return (1);
        }
    }
    return (0);
}

int ap84FootprintTiles() {
    return (xsCeilToInt(2.0 * xsGetObjectAttribute(WONDER_OWNER, WONDER, cUnitSizeX, 0)));
}

void ap84RecordUnit(int tag = 0, int which = 0, int unitId = -1) {
    if (unitId < 0 || xsDoesUnitExist(unitId) == false) {
        ap78Write(REC_FUNIT, tag, which, 0, -1, -1);
        ap78Write(REC_FREVEAL, tag, which, -1, -1, -1);
        ap78Write(REC_FSLOT, tag, which, -1, -1, -1);
        ap78Write(REC_FPOS, tag, which, -1, -1, 0);
        return;
    }
    ap78Write(REC_FUNIT, tag, which, 1, xsGetUnitObjectId(unitId), buildPointsOf(unitId));
    int held = FindWonderSlot(unitId);
    int kind = 0;
    if (held >= 0) {
        kind = WonderSlotRevealKind(held);
    }
    ap78Write(REC_FREVEAL, tag, which, held, kind, buildPointsOf(unitId));
    ap78Write(REC_FSLOT, tag, which, FindWonderSlot(unitId),
              boolInt(IsWonderComplete(unitId, WONDER_OWNER)), xsGetUnitOwner(unitId));
    vector spot = xsGetUnitPosition(unitId);
    ap78Write(REC_FPOS, tag, which, xsCeilToInt(xsVectorGetX(spot)),
              xsCeilToInt(xsVectorGetY(spot)), xsCeilToInt(xsVectorGetZ(spot)));
}

void ap84RecordScan(int tag = 0, int queryId = 0) {
    ap78Write(REC_FSCAN, tag, queryId, ap84QuerySize, ap84Holds(ap84Foundation),
              ap84Holds(ap84Completed));
}

void ap84Probe(int tag = 0) {
    ap84RecordUnit(tag, 0, ap84Foundation);
    ap84RecordUnit(tag, 1, ap84Completed);

    ap84ScanWonder = ap84Query(WONDER, ap84ScanWonder);
    ap84RecordScan(tag, WONDER);
    ap84ScanBuilding = ap84Query(cBuildingClass, ap84ScanBuilding);
    ap84RecordScan(tag, cBuildingClass);
    ap84ScanMisc = ap84Query(cMiscBuildingClass, ap84ScanMisc);
    ap84RecordScan(tag, cMiscBuildingClass);
    ap84ScanFlag = ap84Query(cFlagClassOffset + cFlagClassBuilding, ap84ScanFlag);
    ap84RecordScan(tag, cFlagClassOffset + cFlagClassBuilding);
    ap84ScanAll = ap84Query(-1, ap84ScanAll);
    ap84RecordScan(tag, -1);
    ap78Write(REC_FWONDERS, tag, ap84CountOfType(WONDER), ap84QuerySize, 0, 0);

    ap78Write(REC_FCOUNT, tag, xsGetObjectCount(WONDER_OWNER, WONDER),
              xsGetObjectCountTotal(WONDER_OWNER, WONDER),
              xsGetObjectCount(WONDER_OWNER, cBuildingClass), countRevealers());
    ap78Write(REC_FGAP, tag, CountOwnerFoundations(WONDER_OWNER),
              CountOwnerFoundations(THREATENED_PLAYER),
              boolInt(xsGetPlayerInGame(WONDER_OWNER)),
              xsGetObjectCount(WONDER_OWNER, -1));
}

void ap84Cleanup() {
    RemoveRevealer(ap84LoneRevealer);
    if (ap84GridFoundation >= 0 && xsDoesUnitExist(ap84GridFoundation)) {
        xsRemoveUnit(ap84GridFoundation);
    }
    if (ap84Foundation >= 0 && xsDoesUnitExist(ap84Foundation)) {
        xsRemoveUnit(ap84Foundation);
    }
    if (ap84Completed >= 0 && xsDoesUnitExist(ap84Completed)) {
        xsRemoveUnit(ap84Completed);
    }
}

void runFoundationCase() {
    if (caseStage == 0) {
        if (enterStage()) {
            ap84Probe(0);
            ap84Foundation = xsCreateUnit(WONDER, WONDER_OWNER,
                                          xsVectorSet(tileCentre(spotX + 18), tileCentre(spotZ + 18), 0.0),
                                          true, false, false);
            ap78Write(REC_FSETUP, 0, ap84Foundation, ap84Completed, ap84FootprintTiles(),
                      WONDER_OWNER);
            ap78Write(REC_FDEF,
                      xsCeilToInt(100.0 * xsGetObjectAttribute(WONDER_OWNER, WONDER,
                                                               cUnitSizeX, 0)),
                      xsCeilToInt(100.0 * xsGetObjectAttribute(WONDER_OWNER, WONDER,
                                                               cUnitSizeY, 0)),
                      xsCeilToInt(100.0 * xsGetObjectAttribute(WONDER_OWNER, WONDER,
                                                               cClearanceSizeX, 0)),
                      xsCeilToInt(100.0 * xsGetObjectAttribute(WONDER_OWNER, WONDER,
                                                               cClearanceSizeY, 0)),
                      xsCeilToInt(xsGetObjectAttribute(WONDER_OWNER, WONDER, cTrainTime, 0)));
            EnableWonderThreat(WONDER_OWNER);
            xsChatData("<YELLOW>AP84: a Wonder FOUNDATION for P2 is up at ("
                       + (spotX + 18) + "," + (spotZ + 18) + "). Nothing else exists yet.");
        }
        if (waited(AP84_SETTLE_SECONDS)) {
            startStage(1);
        }
        return;
    }
    if (caseStage == 1) {
        if (enterStage()) {
            ap84Probe(1);
            ap84Completed = xsCreateUnit(WONDER, WONDER_OWNER,
                                         xsVectorSet(tileCentre(spotX + 36), tileCentre(spotZ + 18), 0.0),
                                         false, false, false);
            xsChatData("<YELLOW>AP84: a COMPLETED Wonder for P2 is up at ("
                       + (spotX + 36) + "," + (spotZ + 18) + ") as the control.");
        }
        if (waited(AP84_SETTLE_SECONDS)) {
            startStage(2);
        }
        return;
    }
    if (caseStage == 2) {
        if (enterStage()) {
            ap84Probe(2);
            float begun = 0.1 * xsGetObjectAttribute(WONDER_OWNER, WONDER, cTrainTime, 0);
            if (ap84Foundation >= 0 && xsDoesUnitExist(ap84Foundation)) {
                ap84BegunOk = boolInt(xsSetUnitBuildPoints(ap84Foundation, begun));
            }
            ap78Write(REC_FSETUP, 2, ap84BegunOk, xsCeilToInt(begun), 0, 0);
            xsChatData("<YELLOW>AP84: the first foundation is now 10% built. It should light up "
                       + "Wonder-sized, and nothing more.");
        }
        if (waited(AP84_SETTLE_SECONDS)) {
            startStage(3);
        }
        return;
    }
    if (caseStage == 3) {
        if (enterStage()) {
            ap84Probe(3);
            ap84GridFoundation = xsCreateUnit(WONDER, WONDER_OWNER,
                                              xsVectorSet(tileCentre(spotX - 20),
                                                          tileCentre(spotZ + 10), 0.0),
                                              true, false, false);
            ap84GridSlot = FindWonderSlot(ap84GridFoundation);
            ap84LoneRevealer = RevealAround(xsVectorSet(tileCentre(spotX - 20),
                                                        tileCentre(spotZ - 10), 0.0),
                                            THREAT_FOUNDATION_LOS);
            RepinRevealers();
            ap78Write(REC_FSETUP, 5, ap84GridFoundation, ap84GridSlot, ap84LoneRevealer,
                      THREAT_FOUNDATION_LOS);
            xsChatData("<YELLOW>AP84: a second foundation at (" + (spotX - 20) + ","
                       + (spotZ + 10) + "). The mod should find it and lay its own grid.");
            xsChatData("<YELLOW>Is its whole construction site lit, and how far past it does "
                       + "the light go? A lone LOS-1 revealer sits 20 tiles south of it - "
                       + "count its lit tiles and say what shape they make.");
        }
        if (waited(AP84_SETTLE_SECONDS)) {
            startStage(4);
        }
        return;
    }
    if (caseStage == 4) {
        if (enterStage()) {
            ap84Probe(4);
            float required = xsGetObjectAttribute(WONDER_OWNER, WONDER, cTrainTime, 0);
            if (ap84Foundation >= 0 && xsDoesUnitExist(ap84Foundation)) {
                ap84SetPointsOk = boolInt(xsSetUnitBuildPoints(ap84Foundation, required));
                xsEffectAmount(cSetUnitAttribute, ap84Foundation, cHitpoints,
                               xsGetObjectAttribute(WONDER_OWNER, WONDER, cHitpoints, 0),
                               WONDER_OWNER);
            }
            ap78Write(REC_FSETUP, 3, ap84SetPointsOk, xsCeilToInt(required), 0, 0);
            xsChatData("<YELLOW>AP84: drove the foundation's build points to " + required
                       + ". Does it finish?");
        }
        if (waited(AP84_SETTLE_SECONDS)) {
            startStage(5);
        }
        return;
    }
    if (enterStage()) {
        ap84Probe(5);
        ap84Cleanup();
    }
    if (waited(1)) {
        nextCase();
    }
}

void placeBuilding(int typeId = -1, int offsetX = 0) {
    int unitId = xsCreateUnit(typeId, 1,
                              xsVectorSet(1.0 * (spotX + offsetX), 1.0 * (spotZ + 6), 0.0),
                              false, false, false);
    if (unitId < 0) {
        xsChatData("<RED>SPIKE 80: could not place building type " + typeId);
    }
}

void openTrainMenuSpike() {
    clearSpawned();
    UnlockUnitItem(SKIRMISHER_LINE_ITEM);
    UnlockUnitItem(CAMEL_LINE_ITEM);
    UnlockUnitItem(ARCHER_LINE_ITEM);
    placeBuilding(ARCHERY_RANGE, -8);
    placeBuilding(STABLE, 4);
    xsChatData("<YELLOW>SPIKE 80 phase 1: P1 civ is " + xsGetPlayerCivilization(1)
               + " (12 = Mongols). No upgrade is researched yet.");
    xsChatData("<YELLOW>Archery Range: which archer and which skirmisher does it offer?");
    xsChatData("<YELLOW>Stable: which camel does it offer?");
    xsChatData("<YELLOW>Upgrades land in " + SPIKE_LOOK_SECONDS + " seconds. Look now.");
}

void researchTech(int itemId = -1, int techId = -1) {
    if (AP_TS_MODE != TECHSANITY_NONE) {
        UnlockTech(itemId - TECH_ITEM_OFFSET);
    }
    xsEffectAmount(cModifyTech, techId, cAttrSetState, STATE_DONE, 1);
}

void researchUpgrade(int itemId = -1, int techId = -1) {
    UnlockTech(itemId - TECH_ITEM_OFFSET);
    setTechDone(techId);
}

void deliverEveryUnitItem() {
    int delivered = 0;
    for (i = 0; < unitTableCount) {
        int list = idList(getUnit(i), "itemIds");
        for (j = 0; < UNIT_ITEM_CAPACITY) {
            int itemId = xsArrayGetInt(list, j);
            if (itemId < 0) {
                break;
            }
            UnlockUnitItem(itemId);
            delivered = delivered + 1;
        }
    }
    xsChatData("<YELLOW>SWEEP: delivered " + delivered + " unit items across "
               + unitTableCount + " rows.");
}

void researchEveryUpgrade() {
    int upgrades = 0;
    for (pass = 0; < 5) {
        for (i = 0; < TECH_CAPACITY) {
            vector tech = getTech(i);
            if (tech == cInvalidVector) {
                continue;
            }
            if (structGetBool(tech, "isUpgrade") == false) {
                continue;
            }
            if (pass == 0) {
                upgrades = upgrades + 1;
                if (AP_TS_MODE != TECHSANITY_NONE) {
                    UnlockTech(structGetInt(tech, "itemId") - TECH_ITEM_OFFSET);
                }
            }
            int id = structGetInt(tech, "id");
            if (xsGetTechState(id, 1) == cTechStateDone) {
                continue;
            }
            xsEffectAmount(cModifyTech, id, cAttrSetState, STATE_DONE, 1);
        }
    }

    int researched = 0;
    for (k = 0; < TECH_CAPACITY) {
        vector counted = getTech(k);
        if (counted == cInvalidVector) {
            continue;
        }
        if (structGetBool(counted, "isUpgrade") == false) {
            continue;
        }
        if (xsGetTechState(structGetInt(counted, "id"), 1) == cTechStateDone) {
            researched = researched + 1;
        }
    }
    xsChatData("<YELLOW>SWEEP: " + researched + " of " + upgrades
               + " upgrade techs reached Done. The rest are Disabled for this civ.");
}

void placeEveryTrainer() {
    placeBuilding(BARRACKS, -12);
    placeBuilding(ARCHERY_RANGE, -8);
    placeBuilding(STABLE, -4);
    placeBuilding(SIEGE_WORKSHOP, 0);
    placeBuilding(CASTLE, 5);
    placeBuilding(MONASTERY, 10);
    placeBuilding(DOCK, 14);
}

void spikeUpgradeStepOne() {
    researchUpgrade(ELITE_SKIRM_ITEM, ELITE_SKIRM_TECH);
    researchUpgrade(HEAVY_CAMEL_ITEM, HEAVY_CAMEL_TECH);
    researchUpgrade(CROSSBOW_ITEM, CROSSBOW_TECH);
    xsChatData("<YELLOW>SPIKE 80 phase 2: Elite Skirmisher, Heavy Camel Rider and "
               + "Crossbowman are now researched.");
    xsChatData("<YELLOW>Does each building now offer the upgraded unit? Look again.");
    xsChatData("<YELLOW>Arbalester lands in " + SPIKE_LOOK_SECONDS + " seconds.");
}

void spikeUpgradeStepTwo() {
    researchUpgrade(ARBALEST_ITEM, ARBALEST_TECH);
    xsChatData("<YELLOW>SPIKE 80 phase 3: Arbalester is now researched - a second upgrade "
               + "step on the same line.");
    xsChatData("<YELLOW>Does the Archery Range offer Arbalester? Look again, then quit.");
}

void openSweepPhaseOne() {
    clearSpawned();
    deliverEveryUnitItem();
    placeEveryTrainer();
    xsChatData("<YELLOW>SWEEP phase 1: P1 civ is " + xsGetPlayerCivilization(1)
               + " (12 = Mongols). Every line item is in, no upgrade is researched.");
    xsChatData("<YELLOW>Check each building against the phase 1 column of expected_menus.py.");
    xsChatData("<YELLOW>Upgrades land in " + SPIKE_SWEEP_SECONDS + " seconds.");
}

void openSweepPhaseTwo() {
    researchEveryUpgrade();
    ap78Write(REC_DONE, CASE_COUNT, ap78Count, 0, 0, 0);
    if (ap78Closed == 0) {
        ap78Closed = 1;
        ap78Flush();
    }
    xsChatData("<YELLOW>SWEEP phase 2: every upgrade in the table is researched.");
    xsChatData("<YELLOW>Check each building against the phase 2 column, then quit.");
}

void runTrainMenuSpike() {
    if (spikePhase == 0) {
        if (SPIKE_TRAIN_MENU == 2) {
            openSweepPhaseOne();
        } else {
            openTrainMenuSpike();
        }
        spikePhase = 1;
        spikePhaseAt = xsGetGameTime();
        return;
    }
    int wait = SPIKE_LOOK_SECONDS;
    if (SPIKE_TRAIN_MENU == 2) {
        wait = SPIKE_SWEEP_SECONDS;
    }
    if (xsGetGameTime() - spikePhaseAt < wait) {
        return;
    }
    if (spikePhase == 1) {
        if (SPIKE_TRAIN_MENU == 2) {
            openSweepPhaseTwo();
            spikePhase = 3;
        } else {
            spikeUpgradeStepOne();
            spikePhase = 2;
        }
        spikePhaseAt = xsGetGameTime();
        return;
    }
    if (spikePhase == 2) {
        spikeUpgradeStepTwo();
        spikePhase = 3;
        spikePhaseAt = xsGetGameTime();
        return;
    }
    xsDisableRule("AP78Harness");
}

int relicScanArray = -1;
int lastRelicCount = 0;

int probeClass(int owner = -1) {
    int found = xsGetPlayerUnitIds(owner, cRelicClass, scanClass);
    if (found >= 0) {
        scanClass = found;
        lastClass = xsArrayGetSize(found);
    }
    return (lastClass);
}

int probeType(int owner = -1) {
    int found = xsGetPlayerUnitIds(owner, RELIC, scanType);
    if (found >= 0) {
        scanType = found;
        lastType = xsArrayGetSize(found);
    }
    return (lastType);
}

int probeGaia() {
    int found = xsGetPlayerUnitIds(0, cRelicClass, scanGaia);
    if (found >= 0) {
        scanGaia = found;
        lastGaia = xsArrayGetSize(found);
    }
    return (lastGaia);
}

int probeMonasteries(int owner = -1) {
    int found = xsGetPlayerUnitIds(owner, MONASTERY, scanMonastery);
    if (found >= 0) {
        scanMonastery = found;
        lastMonastery = xsArrayGetSize(found);
    }
    return (lastMonastery);
}

int firstMonasteryOf(int owner = -1) {
    int found = xsGetPlayerUnitIds(owner, MONASTERY, scanMonastery);
    if (found >= 0) {
        scanMonastery = found;
    }
    if (scanMonastery < 0 || xsArrayGetSize(scanMonastery) == 0) {
        return (-1);
    }
    return (xsArrayGetInt(scanMonastery, 0));
}

int countRelics(int owner = -1) {
    int found = xsGetPlayerUnitIds(owner, cRelicClass, relicScanArray);
    if (found >= 0) {
        relicScanArray = found;
        lastRelicCount = xsArrayGetSize(found);
    }
    return (lastRelicCount);
}

void recordGarrison(int tag = 0) {
    int found = xsGetPlayerUnitIds(0, cRelicClass, scanGaia);
    if (found >= 0) {
        scanGaia = found;
    }
    if (scanGaia < 0) {
        return;
    }
    int relics = xsArrayGetSize(scanGaia);
    for (i = 0; < relics) {
        int relicId = xsArrayGetInt(scanGaia, i);
        if (relicId < 0) {
            continue;
        }
        int containerId = xsGetGarrisonedInUnitId(relicId);
        int objectId = -1;
        int owner = -1;
        if (containerId >= 0 && xsDoesUnitExist(containerId)) {
            objectId = xsGetUnitObjectId(containerId);
            owner = xsGetUnitOwner(containerId);
        }
        ap78Write(REC_GARRISON, tag, relicId, containerId, objectId, owner);
    }
}

void recordRelicState(int tag = 0) {
    int players = xsGetNumPlayers();
    for (slot = 0; < players) {
        int player = slot + 1;
        ap78Write(REC_RELIC, tag, player,
                  xsCeilToInt(xsPlayerAttribute(player, ALL_RELICS_CAPTURED)),
                  countRelics(player), xsGetObjectCount(player, MONASTERY));
    }
    for (other = 0; < players) {
        int who = other + 1;
        ap78Write(REC_PROBE, tag, who, probeClass(who), probeType(who),
                  probeMonasteries(who));
    }
    ap78Write(REC_PROBE, tag, 0, probeGaia(), xsGetObjectCount(1, RELIC),
              xsGetObjectCount(WONDER_OWNER, RELIC));
    recordGarrison(tag);
    ap78Write(REC_TRACE, CASE_RELIC, 200 + tag, FindRelicHolder(), players, monasteryKilled);
    ap78Write(REC_TRACE, CASE_RELIC, 300 + tag,
              xsCeilToInt(xsUnsyncGetTimerTimeRemaining(THREAT_WONDER_CAPACITY,
                                                        cTimerUnitYears, -1)),
              0, 0);
}

void recordUnitRow(int typeId = -1) {
    int index = findUnit(typeId);
    if (index < 0) {
        ap78Write(REC_ROW, typeId, -1, -1, -1, -1);
        return;
    }
    vector unit = getUnit(index);
    ap78Write(REC_ROW, typeId, structGetInt(unit, "locationId"),
              structGetInt(unit, "lineId"), structGetInt(unit, "tier"),
              structGetInt(unit, "upgradeItemId"));
}

void main() {
    ap78Log = xsArrayCreateInt(AP78_RECORDS * AP78_FIELDS, 0, "ap78-log");
    ap78Scan = xsArrayCreateInt(1, -1, "ap78-scan");
    wonderScanArray = xsArrayCreateInt(1, -1, "ap78-wonder-scan");
    revealerScanArray = xsArrayCreateInt(1, -1, "ap78-revealer-scan");
    relicScanArray = xsArrayCreateInt(1, -1, "ap78-relic-scan");
    ap84ScanWonder = xsArrayCreateInt(1, -1, "ap84-scan-wonder");
    ap84ScanBuilding = xsArrayCreateInt(1, -1, "ap84-scan-building");
    ap84ScanMisc = xsArrayCreateInt(1, -1, "ap84-scan-misc");
    ap84ScanFlag = xsArrayCreateInt(1, -1, "ap84-scan-flag");
    ap84ScanAll = xsArrayCreateInt(1, -1, "ap84-scan-all");
    spawnedIds = xsArrayCreateInt(SPAWN_CAPACITY, -1, "ap78-spawned");

    spotX = xsGetMapWidth() / 2;
    spotZ = xsGetMapHeight() / 2;

    caseIndex = FIRST_CASE;

    initializeStructsScript();
    InitLocations();
    InitBuildsanity();
    InitAges();
    InitTechsanity();
    if (AP_TS_MODE == TECHSANITY_NONE) {
        InitTechsanityStructs();
        LoadTechTable();
    }
    InitUnitsanity();
    InitCaveman();
    InitProfessions();
    InitVictoryThreats();
    startupGranted = 1;

    timerMessageA = "";
    timerMessageB = "";

    ap78Write(REC_BOOT, AP_US_MODE, AP_US_CAVEMAN, AP_TS_MODE, unitTableCount,
              xsGetPlayerCivilization(1));
    ap78Write(REC_SEED, AP_SEED_HIGH, AP_SEED_LOW, AP_US_VILLAGER, apVanillaAge,
              boolInt(unitsanityReady));

    recordUnitRow(LEITIS_TYPE);
    recordUnitRow(SIEGE_RAM_TYPE);
    recordUnitRow(SIEGE_ONAGER_TYPE);
    recordUnitRow(LONG_SWORD_TYPE);
    recordUnitRow(HALBERDIER_TYPE);

    if (SPIKE_TRAIN_MENU == 0) {
        xsChatData("<YELLOW>AP78 v1 running, cases " + FIRST_CASE + " to "
                   + (CASE_COUNT - 1) + ". Leave it alone until the green line.");
    }
    xsEnableRule("AP78Harness");
}

rule AP78Harness
    inactive
    minInterval 1
    maxInterval 1
    group AP78
{
    ap78Tick = ap78Tick + 1;

    if (SPIKE_TRAIN_MENU != 0) {
        runTrainMenuSpike();
        return;
    }

    if (caseIndex > LAST_CASE) {
        ap78Write(REC_DONE, CASE_COUNT, ap78Count, 0, 0, 0);
        if (ap78Closed == 0) {
            ap78Closed = 1;
            ap78Flush();
            xsChatData("<GREEN>AP78 done, file closed. " + ap78Count
                       + " records. Quit the scenario now.");
        }
        xsDisableRule("AP78Harness");
        return;
    }

    if (caseIndex == CASE_DM_ELSEWHERE) {
        runDeathmatchCase(CASE_DM_ELSEWHERE, OTHER_SCENARIO);
        return;
    }
    if (caseIndex == CASE_DM_ATTILA5) {
        runDeathmatchCase(CASE_DM_ATTILA5, ATTILA_5_SCENARIO);
        return;
    }
    if (caseIndex == CASE_LEITIS) {
        runLeitisCase();
        return;
    }
    if (caseIndex == CASE_Q2) {
        if (caseStage == 0) {
            if (enterStage()) {
                ap78Write(REC_CASE, CASE_Q2, PIKEMAN_TECH, MAN_AT_ARMS_TECH,
                          xsGetTechState(PIKEMAN_TECH, 1), xsGetTechState(MAN_AT_ARMS_TECH, 1));
                researchTech(PIKEMAN_TECH_ITEM, PIKEMAN_TECH);
                UnlockUnitItem(MILITIA_LINE_ITEM);
                spawnOne(SPEARMAN_TYPE, 0, 3, true);
                spawnOne(SPEARMAN_TYPE, 1, 3, true);
                spawnOne(MILITIA_TYPE_Q2, 2, 3, true);
                spawnOne(MILITIA_TYPE_Q2, 3, 3, true);
                placeBuilding(BARRACKS, 0);
                xsChatData("<YELLOW>Q2 phase 1: Pikeman RESEARCHED but no spearman item; "
                           + "militia item HELD but no upgrade.");
                xsChatData("<YELLOW>Barracks should offer Militia, and nothing on the "
                           + "spearman slot. Look.");
            }
            if (waited(30)) {
                startStage(1);
            }
            return;
        }
        if (enterStage()) {
            UnlockUnitItem(SPEARMAN_LINE_ITEM);
            researchTech(MAN_AT_ARMS_TECH_ITEM, MAN_AT_ARMS_TECH);
            ap78Write(REC_CASE, CASE_Q2, PIKEMAN_TECH, MAN_AT_ARMS_TECH,
                      xsGetTechState(PIKEMAN_TECH, 1), xsGetTechState(MAN_AT_ARMS_TECH, 1));
            xsChatData("<YELLOW>Q2 phase 2: spearman item arrived AFTER its research; "
                       + "Man-at-Arms researched AFTER its item.");
            xsChatData("<YELLOW>Both slots should show the upgraded unit: PIKEMAN and "
                       + "MAN-AT-ARMS. Look, then quit.");
        }
        if (waited(15)) {
            ap78Write(REC_COUNT, CASE_Q2, countSpawnedOfType(SPEARMAN_TYPE),
                      countSpawnedOfType(PIKEMAN_TYPE), countSpawnedOfType(MILITIA_TYPE_Q2),
                      countSpawnedOfType(MAN_AT_ARMS_TYPE));
            nextCase();
        }
        return;
    }

    if (caseIndex == CASE_Q4) {
        if (caseStage == 0) {
            if (enterStage()) {
                int cleared = 0;
                for (i = 0; < unitTableCount) {
                    vector unit = getUnit(i);
                    if (structGetInt(unit, "tier") > 0) {
                        setObjectDisable(structGetInt(unit, "typeId"), 0.0, false);
                        cleared = cleared + 1;
                    }
                }
                ap78Write(REC_CASE, CASE_Q4, cleared, unitTableCount,
                          xsGetTechState(MAN_AT_ARMS_TECH, 1), 0);
                placeBuilding(BARRACKS, 0);
                xsChatData("<YELLOW>Q4 phase 1: every tier>0 row had its disabled flag "
                           + "cleared (" + cleared + " rows). No militia item is held.");
                xsChatData("<YELLOW>Barracks should offer NOTHING on the militia slot. Look.");
            }
            if (waited(30)) {
                startStage(1);
            }
            return;
        }
        if (enterStage()) {
            xsEffectAmount(cModifyTech, MAN_AT_ARMS_TECH, cAttrSetState, STATE_DONE, 1);
            ap78Write(REC_CASE, CASE_Q4, 0, 0, xsGetTechState(MAN_AT_ARMS_TECH, 1), 1);
            xsChatData("<YELLOW>Q4 phase 2: Man-at-Arms researched, Militia still locked and "
                       + "no item held.");
            xsChatData("<YELLOW>Does the Barracks now offer MAN-AT-ARMS? Look, then quit.");
        }
        if (waited(15)) {
            nextCase();
        }
        return;
    }

    if (caseIndex == CASE_WITHHELD) {
        if (enterStage()) {
            int withheld = 0;
            int granted = 0;
            for (i = 0; < TECH_CAPACITY) {
                vector tech = getTech(i);
                if (tech == cInvalidVector) {
                    continue;
                }
                if (structGetBool(tech, "isUpgrade") == false) {
                    continue;
                }
                if (structGetInt(tech, "age") >= apVanillaAge) {
                    continue;
                }
                int state = xsGetTechState(structGetInt(tech, "id"), 1);
                if (state == cTechStateDone) {
                    granted = granted + 1;
                } else {
                    withheld = withheld + 1;
                }
                ap78Write(REC_WITHHELD, structGetInt(tech, "id"), structGetInt(tech, "age"),
                          state, apVanillaAge, AP_US_CAVEMAN);
            }
            ap78Write(REC_CASE, CASE_WITHHELD, withheld, granted, apVanillaAge, AP_US_CAVEMAN);
            UnlockUnitItem(SKIRMISHER_LINE_ITEM);
            placeBuilding(ARCHERY_RANGE, 0);
            xsChatData("<YELLOW>WITHHELD: " + withheld + " upgrade techs below age "
                       + apVanillaAge + " are not researched, " + granted + " are.");
            xsChatData("<YELLOW>Archery Range should offer SKIRMISHER, not Elite Skirmisher. "
                       + "Look, then quit.");
        }
        if (waited(15)) {
            nextCase();
        }
        return;
    }

    if (caseIndex == CASE_REVEALER) {
        if (caseStage == 0) {
            if (enterStage()) {
                revealerA = RevealAround(xsVectorSet(1.0 * (spotX - 20),
                                                     1.0 * (spotZ - 20), 0.0), 3);
                revealerB = RevealAround(xsVectorSet(1.0 * spotX,
                                                     1.0 * (spotZ - 20), 0.0), 3);
                revealerC = RevealAround(xsVectorSet(1.0 * (spotX + 20),
                                                     1.0 * (spotZ - 20), 0.0), 3);
                ap78Write(REC_REVEALER, 0, revealerA, revealerB, revealerC, 0);
                xsChatData("<YELLOW>REVEALER SPIKE: three patches north of centre - "
                           + "LEFT, MIDDLE, RIGHT.");
                xsChatData("<YELLOW>In 15s: LEFT gets xsRemoveUnit, MIDDLE gets hitpoints 0, "
                           + "RIGHT gets line of sight 0.");
                xsChatData("<YELLOW>Tell me which ones go dark.");
            }
            if (waited(15)) {
                startStage(1);
            }
            return;
        }
        if (caseStage == 1) {
            if (enterStage()) {
                ap78Write(REC_REVEALER, 1, boolInt(xsDoesUnitExist(revealerA)),
                          boolInt(xsDoesUnitExist(revealerB)),
                          boolInt(xsDoesUnitExist(revealerC)), 0);
                xsRemoveUnit(revealerA);
                xsEffectAmount(cSetUnitAttribute, revealerB, cHitpoints, 0.0,
                               THREATENED_PLAYER);
                xsEffectAmount(cSetUnitAttribute, revealerC, cLineOfSight, 0.0,
                               THREATENED_PLAYER);
                xsChatData("<YELLOW>REVEALER SPIKE: applied. Which patches went dark?");
            }
            if (waited(20)) {
                startStage(2);
            }
            return;
        }
        if (enterStage()) {
            ap78Write(REC_REVEALER, 2, boolInt(xsDoesUnitExist(revealerA)),
                      boolInt(xsDoesUnitExist(revealerB)),
                      boolInt(xsDoesUnitExist(revealerC)), 0);
        }
        if (waited(1)) {
            nextCase();
        }
        return;
    }

    if (caseIndex == CASE_RELIC) {
        if (enterStage()) {
            ap78Write(REC_CASE, CASE_RELIC, RELIC, MONASTERY, WONDER_OWNER, 0);
            EnableRelicThreat();
            EnableWonderThreat(WONDER_OWNER);
            xsChatData("<YELLOW>CASE_RELIC: relic threat ARMED. Watch P2's monastery.");
            xsChatData("<YELLOW>When the monk banks the relic, fog should lift 5 tiles around "
                       + "the monastery and a Relics timer should appear.");
            xsChatData("<YELLOW>At " + RELIC_KILL_SECONDS + "s the monastery dies - the reveal "
                       + "and the timer should both go away.");
            recordRelicState(0);
            relicSamples = 1;
            lastRelicSampleAt = xsGetGameTime();
        }
        if (xsGetGameTime() - lastRelicSampleAt >= RELIC_SAMPLE_SECONDS
            && relicSamples < RELIC_SAMPLE_CAP) {
            lastRelicSampleAt = xsGetGameTime();
            recordRelicState(relicSamples);
            relicSamples = relicSamples + 1;
        }
        if (monasteryKilled == 0 && waited(RELIC_KILL_SECONDS)) {
            int target = firstMonasteryOf(WONDER_OWNER);
            monasteryKilled = 1;
            if (target >= 0) {
                xsEffectAmount(cSetUnitAttribute, target, cHitpoints, 0.0, WONDER_OWNER);
                xsChatData("<YELLOW>CASE_RELIC: drove P2's monastery to 0 hit points, "
                           + "watching what attribute 55 does next.");
            } else {
                xsChatData("<RED>CASE_RELIC: no monastery found to destroy.");
            }
        }
        if (waited(RELIC_WATCH_SECONDS)) {
            nextCase();
        }
        return;
    }

    if (caseIndex == CASE_FOUNDATION) {
        runFoundationCase();
        return;
    }
    if (caseIndex == CASE_SIEGE_RAM) {
        runUpgradeCase(CASE_SIEGE_RAM, CAPPED_RAM_TYPE, SIEGE_RAM_TYPE, SIEGE_RAM_TECH,
                       SIEGE_RAM_ITEM, SIEGE_RAM_LOCATION);
        return;
    }
    if (caseIndex == CASE_SIEGE_ONAGER) {
        runUpgradeCase(CASE_SIEGE_ONAGER, ONAGER_TYPE, SIEGE_ONAGER_TYPE, SIEGE_ONAGER_TECH,
                       SIEGE_ONAGER_ITEM, SIEGE_ONAGER_LOCATION);
        return;
    }
    if (caseIndex == CASE_LONG_SWORD) {
        runUpgradeCase(CASE_LONG_SWORD, MAN_AT_ARMS_TYPE, LONG_SWORD_TYPE, LONG_SWORD_TECH,
                       LONG_SWORD_ITEM, LONG_SWORD_LOCATION);
        return;
    }
    if (caseIndex == CASE_HALBERDIER) {
        runReverseUpgradeCase(CASE_HALBERDIER, PIKEMAN_TYPE, HALBERDIER_TYPE, HALBERDIER_TECH,
                              HALBERDIER_ITEM, HALBERDIER_LOCATION);
        return;
    }
    runWonderCase();
}
