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

class HGG : HGGBase {
    void setGametypeSettings() {
        HGGBase::setGametypeSettings();

        gametype.isTeamBased = true;
        gametype.hasChallengersQueue = true;
        gametype.maxPlayersPerTeam = 1;

        gt.hasChallengersQueue = true;
        gt.hasMapList = false;
        gt.scorelimit = 11;
        gt.timelimit = 0;
    }

    void initGametype() {
        gt.name = "Duel";
        gt.type = GT_DUEL;
        HGGBase::initGametype();
    }

    void playtimeStarted() {
        players.dummies.enable();
        HGGBase::playtimeStarted();
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);
        if (@target != null && @attacker != null && forReal())
            G_GetTeam(attacker.team).stats.addScore(1
                    - (@target == @attacker ? 2 : 0));
    }
}
