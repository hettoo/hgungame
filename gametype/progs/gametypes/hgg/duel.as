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
        gametype.hasChallengersQueue = true;
        gametype.maxPlayersPerTeam = 1;

        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = false;
        gametype.canShowMinimap = false;
        gametype.teamOnlyMinimap = false;

        gt.has_challengers_queue = true;
        gt.has_map_list = false;
    }

    void init_gametype() {
        gt.name = "Duel";
        gt.type = GT_DUEL;
        HGGBase::init_gametype();
    }

    void warmup_started() {
        HGGBase::warmup_started();
        CreateSpawnIndicators("info_player_deathmatch", TEAM_BETA);
    }

    void countdown_started() {
        HGGBase::countdown_started();
        DeleteSpawnIndicators();
    }

    void playtime_started() {
        HGGBase::playtime_started();
        dummies.init();
        dummies.spawn();
    }

    cString @scoreboard_message(int max_len) {
        cString board= "";
        scoreboard.add_team(board, TEAM_ALPHA, max_len, players);
        scoreboard.add_team(board, TEAM_BETA, max_len, players);
        return board;
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);
        if (@target != null && @target != @attacker)
            G_GetTeam(attacker.team).stats.addScore(1);
    }
}
