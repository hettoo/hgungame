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

const int COUNTDOWN_START = 6;
const int COUNTDOWN_END = 4;
const int COUNTDOWN_SOUND_MAX = 3;

const String ONE_VS_ONE = "1v1! Good luck!";
const String LAST_PLAYER = S_COLOR_GREEN + "Last Player Standing!";

class HGG : HGGBase {
    int countdownStart;
    int countdownEnd;

    HGG() {
        countdownStart = UNKNOWN;
        countdownEnd = UNKNOWN;
    }

    void setGametypeSettings() {
        HGGBase::setGametypeSettings();

        gametype.isTeamBased = true;
        gametype.teamOnlyMinimap = true;

        gt.scorelimit = 21;
        gt.timelimit = 0;
        gt.countdownTime = 3;
    }

    void initGametype() {
        gt.name = "Clan Arena";
        gt.type = GT_CA;
        HGGBase::initGametype();
    }

    void startRound() {
        gametype.shootingDisabled = true;
        countdownStart = COUNTDOWN_START;
    }

    void countdownStarted() {
        gametype.shootingDisabled = true;
        lockTeams();
        randomAnnouncerSound("sounds/announcer/countdown/get_ready_to_fight0");
    }

    void genericPlaytimeStarted() {
        G_RemoveAllProjectiles();

        players.teamHUD = true;
        players.respawn();
        players.resetStats();
    }

    void playtimeStarted() {
        gt.setSpawnSystem(SPAWNSYSTEM_HOLD, true);
        HGGBase::playtimeStarted();
        startRound();
    }

    void newRound() {
        players.respawn();
        startRound();
    }

    void endRound() {
        G_RemoveDeadBodies();
        G_RemoveAllProjectiles();

        int countAlpha = players.countAlive(TEAM_ALPHA);
        int countBeta = players.countAlive(TEAM_BETA);

        if (countAlpha + countBeta == 0) {
            centerNotify("Draw Round!");
        } else if (countAlpha > 0) {
            if (countAlpha == 1 && players.count() > 2)
                players.getAlive(TEAM_ALPHA).client.addAward(LAST_PLAYER);
            players.teamScored(TEAM_ALPHA);
        } else {
            if (countBeta == 1 && players.count() > 2)
                players.getAlive(TEAM_BETA).client.addAward(LAST_PLAYER);
            players.teamScored(TEAM_BETA);
        }

        @alphaSpawn = null;
        @betaSpawn = null;
    }

    void oneVersus(int count, int team, Client @target) {
        Player @alive = players.getAlive(team, target);
        if (count == 1) {
            int other = otherTeam(team);
            Player @otherAlive = players.getAlive(other, target);
            notify(ONE_VS_ONE);
            alive.client.addAward(S_COLOR_SPECIAL + ONE_VS_ONE);
            otherAlive.client.addAward(S_COLOR_SPECIAL + ONE_VS_ONE);
        } else {
            alive.client.addAward("1v" + count + "! You're on your own!");
            players.sayTeam(team, "1v" + count + "! " + alive.client.get_name()
                    + " is on its own!");
        }
    }

    void checkTeams(Client @target) {
        int countAlpha = players.countAlive(TEAM_ALPHA, target);
        int countBeta = players.countAlive(TEAM_BETA, target);
        if (countAlpha == 0 || countBeta == 0) {
            gametype.shootingDisabled = true;
            countdownEnd = COUNTDOWN_END;
        } else if (countAlpha == 1 || countBeta == 1) {
            if (countAlpha == 1)
                oneVersus(countBeta, TEAM_ALPHA, target);
            else
                oneVersus(countAlpha, TEAM_BETA, target);
        }
    }

    void checkTeams() {
        checkTeams(null);
    }

    void countDownStart() {
        countdownStart--;
        int readyStart = COUNTDOWN_SOUND_MAX + 1;
        if (countdownStart == readyStart) {
            randomAnnouncerSound("sounds/announcer/countdown/ready0");
        } else if (countdownStart == 0) {
            countdownStart = UNKNOWN;
            gametype.shootingDisabled = false;
            randomAnnouncerSound("sounds/announcer/countdown/fight0");
            centerNotify("Fight!");
        } else if (countdownStart <= COUNTDOWN_SOUND_MAX) {
            randomAnnouncerSound("sounds/announcer/countdown/"
                    + countdownStart + "_0");
        }

        if (countdownStart <= readyStart && countdownStart > 0)
            centerNotify(countdownStart + "");
    }

    void countDownEnd() {
        countdownEnd--;
        if (countdownEnd == 2) {
            endRound();
        } else if (countdownEnd == 0) {
            countdownEnd = UNKNOWN;
            newRound();
        }
    }

    void newSecond() {
        HGGBase::newSecond();
        if (countdownStart != UNKNOWN)
            countDownStart();
        if (countdownEnd != UNKNOWN)
            countDownEnd();
    }

    void newSpectator(Client @client) {
        bool wasAlive = players.get(client.playerNum).alive;
        HGGBase::newSpectator(client);

        if(!forReal())
            return;

        if (wasAlive)
            checkTeams();
    }

    void killed(Client @attacker, Client @target, Client @inflictor) {
        HGGBase::killed(attacker, target, inflictor);

        if (!forReal())
            return;

        if (@attacker != null && @target != null)
            checkTeams(target);
    }
}

