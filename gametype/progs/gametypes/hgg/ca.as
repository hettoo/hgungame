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

        gametype.isTeamBased = true;
        gametype.teamOnlyMinimap = true;
    }

    void init_gametype() {
        gt.name = "Clan Arena";
        gt.type = GT_CA;
        HGGBase::init_gametype();
    }

    void playtime_started() {
        set_spawn_system(SPAWNSYSTEM_HOLD, true);
        HGGBase::playtime_started();
    }

    void check_teams(int penalty_team) {
        int count_alpha = players.count_alive(TEAM_ALPHA)
            - (penalty_team == TEAM_ALPHA ? 1 : 0);
        int count_beta = players.count_alive(TEAM_BETA)
            - (penalty_team == TEAM_BETA ? 1 : 0);
        if (count_alpha == 0 || count_beta == 0) {
            G_RemoveDeadBodies();
            G_RemoveAllProjectiles();

            if (count_alpha + count_beta == 0)
                center_notify("Draw Round!");
            else if (count_alpha > 0)
                G_GetTeam(TEAM_ALPHA).stats.addScore(1);
            else
                G_GetTeam(TEAM_BETA).stats.addScore(1);

            @spawn_alpha = null;
            @spawn_beta = null;
            players.respawn();
        }
    }

    void new_spectator(cClient @client) {
        HGGBase::new_spectator(client);
        check_teams(0);
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);

        if (!for_real())
            return;

        // NOTE: this needs to be checked when someone goes spec as well
        if (@attacker != null && @target != null)
            check_teams(target.team);
    }
}

