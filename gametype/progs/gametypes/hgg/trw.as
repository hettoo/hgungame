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

        gt.scorelimit = 11;
        gt.timelimit = 20;
    }

    void init_gametype() {
        gt.name = "Team Row War";
        gt.type = GT_DM;
        HGGBase::init_gametype();
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);
        Player @player = players.get(attacker.playerNum());
        if (player.row % SPECIAL_ROW == 0 && @attacker != @target && for_real())
            G_GetTeam(attacker.team).stats.addScore(1);
    }
}

