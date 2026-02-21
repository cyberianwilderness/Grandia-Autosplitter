/*
Grandia I LiveSplit Autosplitter
Author: l1ndblum

Working so far:
- Split 0 = LOCATION split using LocationVar2 + mapState + startVar
- Split 1+ = BOSS splits using end-of-battle EXP_Gained + Gold_Gained
- Sequential order enforced via bossIndex
- If expected EXP or Gold is 0, only the non-zero value is required
- Uses latches to prevent double splitting while values stay on screen
- Uses a TRUE 3-second cooldown (refresh-rate aware)
- DOES NOT AUTO-RESET

Notes:
- LocationVar1 is not used (per your testing). LocationVar2 + mapState + startVar are used for location splits.
- Add more location cases later by copying case 0’s pattern.
*/

state("grandia")
{
    // Location / state
    byte LocationVar2 : 0x23FA74;
    int  mapState     : 0x240EF4;
    int  startVar     : 0x240F1C;

    // End-of-battle reward values
    int  EXP_Gained   : 0x224384;
    int  Gold_Gained  : 0x224388;

    // Extras (optional viewer stuff)
    int  SueEXP       : 0x3000F0;
    int  JustinEXP    : 0x3000D8;
}

startup
{
    // Split sequence
    vars.bossIndex = 0;

    // Current target (boss)
    vars.expectedExp  = -1;
    vars.expectedGold = -1;

    // Current target (location)
    vars.isLocationSplit = false;
    vars.expectedLoc2 = -1;
    vars.expectedMapState = -1;
    vars.expectedStartVar = -1;

    vars.currentSplitName = "Unknown";

    // Refresh-rate aware cooldown
    vars.refreshHz = 60.0;
    vars.cooldown = 0;

    // Battle reward latch
    vars.lastHandledExp = -1;
    vars.lastHandledGold = -1;

    // Location latch (kept, but no longer required for correctness)
    vars.lastHandledLoc2 = -999999;
    vars.lastHandledMapState = -999999;
    vars.lastHandledStartVar = -999999;

    // -------------------------
    // ASLVarViewer fields
    // -------------------------
    vars.loc2 = 0; vars.loc2Old = 0;
    vars.ms   = 0; vars.msOld   = 0;
    vars.sv   = 0; vars.svOld   = 0;

    vars.expR  = 0; vars.expROld  = 0;
    vars.goldR = 0; vars.goldROld = 0;

    vars.justExp = 0; vars.justExpOld = 0;
    vars.sueExp  = 0; vars.sueExpOld  = 0;
}

init
{
    /*
     ____________________________________________________________________________
    |                                                                            |
    |    Boss reward definitions                                                 |
    |                                                                            |
    |    Experience                  |        Gold                               |
    |____________________________________________________________________________|
    */

    vars.RockBird_EXP = 30;              vars.RockBird_Gold = 150;
    vars.OrcKing_EXP = 78;               vars.OrcKing_Gold = 490;
    vars.SquidKing_EXP = 74;             vars.SquidKing_Gold = 1000;
    vars.Chang_EXP = 235;                vars.Chang_Gold = 0;
    vars.Ganymede_EXP = 1000;            vars.Ganymede_Gold = 2000;

    // --- Location split placeholder: Feena’s House / Herb Mountain end ---

    vars.Saki_EXP = 15;                  vars.Saki_Gold = 100;
    vars.Nana_EXP = 15;                  vars.Nana_Gold = 100;
    vars.Mio_EXP = 15;                   vars.Mio_Gold = 100;

    // --- Location split placeholder: Dight Village (Gadwin 1) ---

    vars.Serpent_EXP = 2530;             vars.Serpent_Gold = 2880;
    vars.Madragon_EXP = 1450;            vars.Madragon_Gold = 4500;
    vars.MassacreMachine1_EXP = 1000;    vars.MassacreMachine1_Gold = 2000;
    vars.MassacreMachine2_EXP = 1200;    vars.MassacreMachine2_Gold = 2000;
    vars.Gadwin2_EXP = 4000;             vars.Gadwin2_Gold = 0;
    vars.Grinwhale_EXP = 4400;           vars.Grinwhale_Gold = 6000;
    vars.Arm1_EXP = 1000;                vars.Arm1_Gold = 1800;
    vars.Milda_EXP = 2300;               vars.Milda_Gold = 0;
    vars.GaiaBattler1_EXP = 5700;        vars.GaiaBattler1_Gold = 7800;
    vars.GaiaBattler2_EXP = 6300;        vars.GaiaBattler2_Gold = 8600;
    vars.RuinGuard_EXP = 7950;           vars.RuinGuard_Gold = 5160;
    vars.Trinity_EXP = 9600;             vars.Trinity_Gold = 10320;
    vars.Baal1_EXP = 4500;               vars.Baal1_Gold = 3000;
    vars.Hydra_EXP = 5000;               vars.Hydra_Gold = 7500;
    vars.GreatSusanoo_EXP = 3000;        vars.GreatSusanoo_Gold = 0;
    vars.Ax2_EXP = 1000;                 vars.Ax2_Gold = 10000;
    vars.IronBall_EXP = 1000;            vars.IronBall_Gold = 0;
    vars.PhantomDragon_EXP = 2000;       vars.PhantomDragon_Gold = 0;
    vars.GaiaBattler3_EXP = 6300;        vars.GaiaBattler3_Gold = 12900;

    // --- Location split placeholder: Spiriti Sanctuary entry ---

    vars.MageKing_EXP = 3405;            vars.MageKing_Gold = 9600;
    vars.GaiaBattler4_EXP = 6300;        vars.GaiaBattler4_Gold = 12900;
    vars.Mullen_EXP = 5682;              vars.Mullen_Gold = 0;
    vars.GaiaTrent_EXP = 5765;           vars.GaiaTrent_Gold = 14400;
    vars.GaiaArmor_EXP = 7000;           vars.GaiaArmor_Gold = 14920;

    // --- Final location split placeholder: Spirit Stone Chamber / Gaia ---
}

isLoading
{
    // Keep as-is if you like; adjust once confirmed.
    return current.mapState == 1;
}

update
{
    // Refresh-rate aware cooldown
    vars.refreshHz = refreshRate > 0 ? refreshRate : 60.0;
    if (vars.cooldown > 0) vars.cooldown--;

    // -------------------------
    // ASLVarViewer feed
    // -------------------------
    vars.loc2Old = vars.loc2;  vars.loc2 = current.LocationVar2;
    vars.msOld   = vars.ms;    vars.ms   = current.mapState;
    vars.svOld   = vars.sv;    vars.sv   = current.startVar;

    vars.expROld  = vars.expR;   vars.expR  = current.EXP_Gained;
    vars.goldROld = vars.goldR;  vars.goldR = current.Gold_Gained;

    vars.justExpOld = vars.justExp; vars.justExp = current.JustinEXP;
    vars.sueExpOld  = vars.sueExp;  vars.sueExp  = current.SueEXP;

    // -------------------------
    // Reset targets each tick
    // -------------------------
    vars.expectedExp  = -1;
    vars.expectedGold = -1;

    vars.isLocationSplit = false;
    vars.expectedLoc2 = -1;
    vars.expectedMapState = -1;
    vars.expectedStartVar = -1;

    vars.currentSplitName = "Unknown";

    switch ((int)vars.bossIndex)
    {
        // ==========================================================
        // SPLIT 0: LOCATION SPLIT
        // ==========================================================
        case 0:
            vars.currentSplitName = "[Location] Marna Road";
            vars.isLocationSplit = true;

            vars.expectedLoc2 = 220;
            vars.expectedMapState = 126;
            vars.expectedStartVar = 17;
            break;

        // ==========================================================
        // BOSS SPLITS
        // ==========================================================
        case 1:  vars.currentSplitName = "Rock Bird";        vars.expectedExp = vars.RockBird_EXP;        vars.expectedGold = vars.RockBird_Gold;        break;
        case 2:  vars.currentSplitName = "Orc King";         vars.expectedExp = vars.OrcKing_EXP;         vars.expectedGold = vars.OrcKing_Gold;         break;
        case 3:  vars.currentSplitName = "Squid King";       vars.expectedExp = vars.SquidKing_EXP;       vars.expectedGold = vars.SquidKing_Gold;       break;
        case 4:  vars.currentSplitName = "Chang";            vars.expectedExp = vars.Chang_EXP;           vars.expectedGold = vars.Chang_Gold;           break;
        case 5:  vars.currentSplitName = "Ganymede";         vars.expectedExp = vars.Ganymede_EXP;        vars.expectedGold = vars.Ganymede_Gold;        break;

        case 6:  vars.currentSplitName = "Saki";             vars.expectedExp = vars.Saki_EXP;            vars.expectedGold = vars.Saki_Gold;            break;
        case 7:  vars.currentSplitName = "Nana";             vars.expectedExp = vars.Nana_EXP;            vars.expectedGold = vars.Nana_Gold;            break;
        case 8:  vars.currentSplitName = "Mio";              vars.expectedExp = vars.Mio_EXP;             vars.expectedGold = vars.Mio_Gold;             break;

        case 9:  vars.currentSplitName = "Serpent";          vars.expectedExp = vars.Serpent_EXP;         vars.expectedGold = vars.Serpent_Gold;         break;
        case 10: vars.currentSplitName = "Madragon";         vars.expectedExp = vars.Madragon_EXP;        vars.expectedGold = vars.Madragon_Gold;        break;

        case 11: vars.currentSplitName = "Massacre Machine 1"; vars.expectedExp = vars.MassacreMachine1_EXP; vars.expectedGold = vars.MassacreMachine1_Gold; break;
        case 12: vars.currentSplitName = "Massacre Machine 2"; vars.expectedExp = vars.MassacreMachine2_EXP; vars.expectedGold = vars.MassacreMachine2_Gold; break;

        case 13: vars.currentSplitName = "Gadwin";           vars.expectedExp = vars.Gadwin2_EXP;         vars.expectedGold = vars.Gadwin2_Gold;         break;
        case 14: vars.currentSplitName = "Grinwhale";        vars.expectedExp = vars.Grinwhale_EXP;       vars.expectedGold = vars.Grinwhale_Gold;       break;

        case 15: vars.currentSplitName = "Arm";              vars.expectedExp = vars.Arm1_EXP;            vars.expectedGold = vars.Arm1_Gold;            break;
        case 16: vars.currentSplitName = "Milda";            vars.expectedExp = vars.Milda_EXP;           vars.expectedGold = vars.Milda_Gold;           break;

        case 17: vars.currentSplitName = "Gaia Battler 1";   vars.expectedExp = vars.GaiaBattler1_EXP;    vars.expectedGold = vars.GaiaBattler1_Gold;    break;
        case 18: vars.currentSplitName = "Gaia Battler 2";   vars.expectedExp = vars.GaiaBattler2_EXP;    vars.expectedGold = vars.GaiaBattler2_Gold;    break;

        case 19: vars.currentSplitName = "Ruin Guard";       vars.expectedExp = vars.RuinGuard_EXP;       vars.expectedGold = vars.RuinGuard_Gold;       break;
        case 20: vars.currentSplitName = "Trinity";          vars.expectedExp = vars.Trinity_EXP;         vars.expectedGold = vars.Trinity_Gold;         break;

        case 21: vars.currentSplitName = "Baal";             vars.expectedExp = vars.Baal1_EXP;           vars.expectedGold = vars.Baal1_Gold;           break;
        case 22: vars.currentSplitName = "Hydra";            vars.expectedExp = vars.Hydra_EXP;           vars.expectedGold = vars.Hydra_Gold;           break;

        case 23: vars.currentSplitName = "Great Susano-o";   vars.expectedExp = vars.GreatSusanoo_EXP;    vars.expectedGold = vars.GreatSusanoo_Gold;    break;
        case 24: vars.currentSplitName = "Ax";               vars.expectedExp = vars.Ax2_EXP;             vars.expectedGold = vars.Ax2_Gold;             break;
        case 25: vars.currentSplitName = "Iron Ball";        vars.expectedExp = vars.IronBall_EXP;        vars.expectedGold = vars.IronBall_Gold;        break;
        case 26: vars.currentSplitName = "Phantom Dragon";   vars.expectedExp = vars.PhantomDragon_EXP;   vars.expectedGold = vars.PhantomDragon_Gold;   break;

        case 27: vars.currentSplitName = "Gaia Battler 3";   vars.expectedExp = vars.GaiaBattler3_EXP;    vars.expectedGold = vars.GaiaBattler3_Gold;    break;
        case 28: vars.currentSplitName = "Mage King";        vars.expectedExp = vars.MageKing_EXP;        vars.expectedGold = vars.MageKing_Gold;        break;

        case 29: vars.currentSplitName = "Gaia Battler 4";   vars.expectedExp = vars.GaiaBattler4_EXP;    vars.expectedGold = vars.GaiaBattler4_Gold;    break;
        case 30: vars.currentSplitName = "Mullen";           vars.expectedExp = vars.Mullen_EXP;          vars.expectedGold = vars.Mullen_Gold;          break;

        case 31: vars.currentSplitName = "Gaia Trent";       vars.expectedExp = vars.GaiaTrent_EXP;       vars.expectedGold = vars.GaiaTrent_Gold;       break;
        case 32: vars.currentSplitName = "Gaia Armor";       vars.expectedExp = vars.GaiaArmor_EXP;       vars.expectedGold = vars.GaiaArmor_Gold;       break;

        default:
            vars.expectedExp = -1;
            vars.expectedGold = -1;
            vars.currentSplitName = "Done";
            break;
    }

    return true;
}

start
{
    // Start when your startVar indicates "in-game"
    return current.startVar == 1;
}

split
{
    if (vars.cooldown > 0) return false;

    // --------------------------
    // LOCATION SPLIT (ENTRY TRIGGER)
    // --------------------------
    if (vars.isLocationSplit)
    {
        bool nowMatch =
            current.LocationVar2 == vars.expectedLoc2 &&
            current.mapState     == vars.expectedMapState &&
            current.startVar     == vars.expectedStartVar;

        bool wasMatch =
            old.LocationVar2 == vars.expectedLoc2 &&
            old.mapState     == vars.expectedMapState &&
            old.startVar     == vars.expectedStartVar;

        // split only when entering this location triple
        if (nowMatch && !wasMatch)
        {
            // record last handled (optional, kept for your debugging)
            vars.lastHandledLoc2 = current.LocationVar2;
            vars.lastHandledMapState = current.mapState;
            vars.lastHandledStartVar = current.startVar;

            vars.bossIndex++;
            vars.cooldown = (int)(vars.refreshHz * 3.0);
            return true;
        }

        return false;
    }

    // --------------------------
    // BATTLE SPLITS
    // --------------------------
    int gotExp  = current.EXP_Gained;
    int gotGold = current.Gold_Gained;

    // If no reward is present, do nothing
    if (gotExp == 0 && gotGold == 0) return false;

    // Reward latch: prevent splitting again while sitting on reward screen
    if (gotExp == vars.lastHandledExp && gotGold == vars.lastHandledGold) return false;

    int needExp  = vars.expectedExp;
    int needGold = vars.expectedGold;

    // If no expected target is set, do not split
    if (needExp < 0 && needGold < 0) return false;

    // -1 = invalid/not set => FAIL
    //  0 = ignore this value => PASS
    bool expOk =
        (needExp == 0) ? true :
        (needExp > 0)  ? (gotExp == needExp) :
        false;

    bool goldOk =
        (needGold == 0) ? true :
        (needGold > 0)  ? (gotGold == needGold) :
        false;

    if (expOk && goldOk)
    {
        vars.lastHandledExp = gotExp;
        vars.lastHandledGold = gotGold;

        vars.bossIndex++;
        vars.cooldown = (int)(vars.refreshHz * 3.0);
        return true;
    }

    return false;
}

// NO AUTO RESET
reset
{
    return false;
}