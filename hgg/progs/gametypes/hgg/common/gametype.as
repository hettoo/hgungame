/*
Copyright (C) 2011 hettoo

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

class Gametype {
    int type;
    cString name;
    cString file;

    void init() {
        name = "???";
        file = CONFIGS_DIR + gametype.getName() + ".cfg";
    }

    cString @recommend_default_map_list() {
        switch (type) {
            case GT_FFA:
                return "wca1 wca2 wca3";
            case GT_CA:
                return "wca1 wca2 wca3";
        }

        return "wca3";
    }

    void check_default_config() {
        if (G_FileExists(file))
            return;

        cString map_list = recommend_default_map_list();

        cString config = "// '" + gametype.getTitle()
            + "' gametype configuration file\n"
            + "\n"
            + "// map rotation\n"
            + "set g_maplist \"" + map_list + "\"\n"
            + "set g_maprotation 1 // 0 = same map, 1 = in order, 2 = random\n"
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
            + "set g_maxtimeouts 3 // -1 = unlimited\n"
            + "set g_challengers_queue 0\n"
            + "\n"
            + "echo \"" + gametype.getName() + ".cfg executed\"\n";

        G_WriteFile(file, config);
        G_Print("Created default config file for '" + gametype.getName()
                + "'\n");
        G_CmdExecute("exec " + file + " silent");
    }
}
