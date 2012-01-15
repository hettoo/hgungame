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

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);

        if (!for_real())
            return;

        // NOTE: this needs to be checked when someone goes spec as well
        if (@attacker != null && @target != null) {
            int count_attacker = players.count_alive(attacker.team);
            int count_target = players.count_alive(target.team) - 1;
            if (count_target == 0) {
                G_RemoveDeadBodies();
                G_RemoveAllProjectiles();

                G_GetTeam(attacker.team).stats.addScore(1);

                @spawn_alpha = null;
                @spawn_beta = null;
                players.respawn();
            }
        }
    }
}

