/*
Copyright (C) 2012 hettoo

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

const cString CONFIGS_DIR = "configs/server/gametypes/";

enum Gametypes {
    GT_FFA,
    GT_CA,
    GT_DM,
    GT_DUEL
};

class Gametype {
    int type;
    cString name;
    cString file;

    bool has_challengers_queue;
    bool has_map_list;

    void init() {
        name = "???";
        file = CONFIGS_DIR + gametype.getName() + ".cfg";

        has_challengers_queue = false;
        has_map_list = true;
    }

    cString @map_list() {
        if (!has_map_list)
            return "";

        switch (type) {
            case GT_FFA:
                return "bipbeta2 .curved babyimstiffbeta2a yeahwhatevahb2"
                    + " inkfinal sandboxb5";
            case GT_CA:
                return "wca1 wca2 wca3";
            case GT_DM:
                return "wdm1 wdm2 wdm3 wdm4 wdm5 wdm6 wdm7 wdm8 wdm9 wdm10"
                    + " wdm11 wdm12 wdm13 wdm14 wdm15 wdm16 wdm17";
        }

        return "wca3";
    }

    void check_default_config() {
        if (G_FileExists(file))
            return;

        cString maps = map_list();

        cString config = "// '" + gametype.getTitle()
            + "' gametype configuration file\n"
            + "\n"
            + "// map rotation\n"
            + "set g_maplist \"" + maps + "\"\n"
            + "set g_maprotation " + (has_map_list ? 1 : 0)
            + " // 0 = same map, 1 = in order, 2 = random\n"
            + "\n"
            + "// game settings\n"
            + "set g_scorelimit 0\n"
            + "set g_timelimit 15\n"
            + "set g_warmup_timelimit 1\n"
            + "set g_match_extendedtime 0\n"
            + "set g_allow_falldamage 0\n"
            + "set g_allow_selfdamage 0\n"
            + "set g_allow_stun 1\n"
            + "set g_teams_maxplayers 0\n"
            + "set g_countdown_time 5\n"
            + "set g_instajump 1\n"
            + "set g_instashield 0\n"
            + "set g_allow_falldamage 0\n"
            + "set g_allow_selfdamage 0\n"
            + "set g_allow_teamdamage 0\n"
            + "set g_maxtimeouts 3 // -1 = unlimited\n"
            + "set g_challengers_queue " + (has_challengers_queue ? 1 : 0)
            + "\n"
            + "\n"
            + "echo \"" + gametype.getName() + ".cfg executed\"\n";

        G_WriteFile(file, config);
        G_Print("Created default config file for '" + gametype.getName()
                + "'\n");
        G_CmdExecute("exec " + file + " silent");
    }
}
