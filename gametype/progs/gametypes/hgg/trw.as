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

class HGG : HGGBase {
    void set_gametype_settings() {
        HGGBase::set_gametype_settings();

        set_spawn_system(SPAWNSYSTEM_INSTANT);

        gametype.isTeamBased = true;
        gametype.hasChallengersQueue = false;
        gametype.maxPlayersPerTeam = 0;

        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = false;
        gametype.canShowMinimap = false;
        gametype.teamOnlyMinimap = true;
    }

    void init_gametype() {
        gt.name = "Team Row War";
        gt.type = GT_FFA;
        HGGBase::init_gametype();
    }

    void warmup_started() {
        HGGBase::warmup_started();
        CreateSpawnIndicators("info_player_deathmatch", TEAM_PLAYERS);
    }

    void countdown_started() {
        HGGBase::countdown_started();
        DeleteSpawnIndicators();
    }

    cString @scoreboard_message(int max_len) {
        cString board= "";
        scoreboard.add_team(board, TEAM_ALPHA, max_len, icons, players);
        scoreboard.add_team(board, TEAM_BETA, max_len, icons, players);
        return board;
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);
        Player @player = players.get(attacker.playerNum());
        if (player.row % SPECIAL_ROW == 0 && @attacker != @target)
            G_GetTeam(attacker.team).stats.addScore(1);
    }
}

