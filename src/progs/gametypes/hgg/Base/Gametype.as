/*
Copyright (C) 2012 Gerco van Heerdt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

const String CONFIGS_DIR = "configs/server/gametypes/";

const String CVAR_BASE = "g_hgg_";

enum Gametypes {
    GT_FFA,
    GT_CA,
    GT_DM,
    GT_DUEL
};

enum CVars {
    CV_ROOT,
    CV_ROOT_PASSWORD,
    CV_TOTAL
};

class Gametype {
    int type;
    String name;
    String file;

    bool hasChallengersQueue;
    bool hasMapList;
    int scorelimit;
    int timelimit;
    int countdownTime;

    int spawnSystem;

    Cvar[] cvars;

    void init() {
        name = "???";
        file = CONFIGS_DIR + gametype.get_name() + ".cfg";

        hasChallengersQueue = false;
        hasMapList = true;
        scorelimit = 0;
        timelimit = 15;
        countdownTime = 5;

        cvars.resize(CV_TOTAL);
        cvars[CV_ROOT]= Cvar(CVAR_BASE + "root", "", CVAR_ARCHIVE);
        cvars[CV_ROOT_PASSWORD] = Cvar(CVAR_BASE + "rootPassword", "",
                CVAR_ARCHIVE);
    }

    void setSpawnSystem(int newSpawnSystem, bool deadCam) {
        spawnSystem = newSpawnSystem;
        for (int team = 0; team < GS_MAX_TEAMS; team++) {
            if (team != TEAM_SPECTATOR)
                gametype.setTeamSpawnsystem(team, spawnSystem, 0, 0, deadCam);
        }
    }

    void setDefaults() {
        setSpawnSystem(SPAWNSYSTEM_INSTANT, false);

        gametype.isRace = false;
        gametype.hasChallengersQueue = false;
        gametype.maxPlayersPerTeam = 0;

        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = false;
        gametype.canShowMinimap = false;
        gametype.teamOnlyMinimap = false;

        gametype.spawnableItemsMask = 0;
        gametype.respawnableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        gametype.pickableItemsMask = gametype.spawnableItemsMask;

        gametype.ammoRespawn = 0;
        gametype.armorRespawn = 0;
        gametype.weaponRespawn = 0;
        gametype.healthRespawn = 0;
        gametype.powerupRespawn = 0;
        gametype.megahealthRespawn = 0;
        gametype.ultrahealthRespawn = 0;

        gametype.countdownEnabled = false;
        gametype.mathAbortDisabled = false;
        gametype.shootingDisabled = false;
        gametype.infiniteAmmo = true;
        gametype.canForceModels = true;

        gametype.spawnpointRadius = 256;

        if (gametype.get_isInstagib())
            gametype.spawnpointRadius *= 2;
    }

    void setInfo() {
        gametype.set_title(NAME + " " + name);
        gametype.set_version(VERSION);
        gametype.set_author(AUTHOR);
    }

    String @mapList() {
        if (!hasMapList)
            return "";

        String ffaMaps = "cwl4 50u1ca1 yeahwhatevahb2 jerms_ca1 inkfinal"
            + " sandboxb5";
        switch (type) {
            case GT_FFA:
                return ffaMaps;
            case GT_CA:
                return "wca1 " + ffaMaps;
            case GT_DM:
                return "wdm1 wdm2 wdm3 wdm4 wdm5 wdm6 wdm7 wdm8 wdm9 wdm10"
                    + " wdm11 wdm12 wdm13 wdm14 wdm15 wdm16 wdm17";
        }

        return "wca3";
    }

    String @CvarDefaults() {
        String total = "";
        for (int i = 0; i < CV_TOTAL; i++)
            total += "set " + cvars[i].get_name() + " \""
                + cvars[i].get_defaultString() + "\"\n";
        return total;
    }

    void checkDefaultConfig() {
        if (G_FileExists(file))
            return;

        String maps = mapList();

        String config = "// '" + gametype.get_title()
            + "' gametype configuration file\n"
            + "\n"
            + "// map rotation\n"
            + "set g_maplist \"" + maps + "\"\n"
            + "set g_maprotation " + (hasMapList ? 1 : 0)
            + " // 0 = same map, 1 = in order, 2 = random\n"
            + "\n"
            + "// gametype specific settings\n"
            + CvarDefaults()
            + "\n"
            + "// game settings\n"
            + "set g_scorelimit " + scorelimit + "\n"
            + "set g_timelimit " + timelimit + "\n"
            + "set g_warmup_timelimit 1\n"
            + "set g_match_extendedtime 0\n"
            + "set g_allow_falldamage 0\n"
            + "set g_allow_selfdamage 0\n"
            + "set g_allow_stun 1\n"
            + "set g_teams_maxplayers " + gametype.maxPlayersPerTeam + "\n"
            + "set g_countdown_time " + countdownTime + "\n"
            + "set g_instajump 1\n"
            + "set g_instashield 0\n"
            + "set g_allow_falldamage 0\n"
            + "set g_allow_selfdamage 0\n"
            + "set g_allow_teamdamage 0\n"
            + "set g_maxtimeouts 3 // -1 = unlimited\n"
            + "set g_challengers_queue " + (hasChallengersQueue ? 1 : 0)
            + "\n"
            + "\n"
            + "echo \"" + gametype.get_name() + ".cfg executed\"\n";

        G_WriteFile(file, config);
        G_Print("Created default config file for '" + gametype.get_name()
                + "'\n");
        G_CmdExecute("exec " + file + " silent");
    }

    String @root() {
        return cvars[CV_ROOT].get_string();
    }

    String @rootPassword() {
        return cvars[CV_ROOT_PASSWORD].get_string();
    }
}
