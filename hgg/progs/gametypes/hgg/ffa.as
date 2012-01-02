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

class HGG : HGGGlobal {
    void set_gametype_settings() {
        HGGGlobal::set_gametype_settings();

        set_spawn_system(SPAWNSYSTEM_INSTANT);

        gametype.isTeamBased = false;
        gametype.hasChallengersQueue = false;
        gametype.maxPlayersPerTeam = 0;

        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = false;
        gametype.canShowMinimap = false;
        gametype.teamOnlyMinimap = false;
    }

    void init_gametype() {
        gt.name = "FFA";
        gt.type = GT_FFA;
        HGGGlobal::init_gametype();
    }

    void warmup_started() {
        HGGGlobal::warmup_started();
        CreateSpawnIndicators("info_player_deathmatch", TEAM_PLAYERS);
    }

    void countdown_started() {
        HGGGlobal::countdown_started();
        DeleteSpawnIndicators();
    }

    cString @scoreboard_message(int max_len) {
        cString board= "";
        scoreboard.add_team(board, TEAM_PLAYERS, max_len, icons, players);
        return board;
    }
}

