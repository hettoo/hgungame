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

/*
 * The functions here are redirected to an instance of the HGG class. They are
 * documented in the file containing the HGGBase class.
 */

HGG hgg;

bool GT_Command(Client @client, const String &cmd, const String &args, int argc) {
    return hgg.command(client, cmd, args, argc);
}

bool GT_UpdateBotStatus(Entity @self) {
    return hgg.updateBotStatus(self);
}

Entity @GT_SelectSpawnPoint(Entity @self) {
    return hgg.selectSpawnPoint(self);
}

String @GT_ScoreboardMessage(uint maxlen) {
    return hgg.scoreboardMessage(maxlen);
}

void GT_ScoreEvent(Client @client, const String &scoreEvent, const String &args) {
    hgg.scoreEvent(client, scoreEvent, args);
}

void GT_PlayerRespawn(Entity @ent, int oldTeam, int newTeam) {
    hgg.playerRespawn(ent, oldTeam, newTeam);
}

void GT_ThinkRules() {
    hgg.thinkRules();
}

bool GT_MatchStateFinished(int newMatchState) {
    return hgg.matchStateFinished(newMatchState);
}

void GT_MatchStateStarted() {
    switch (match.getState()) {
        case MATCH_STATE_WARMUP:
            hgg.warmupStarted();
            break;
        case MATCH_STATE_COUNTDOWN:
            hgg.countdownStarted();
            break;
        case MATCH_STATE_PLAYTIME:
            hgg.playtimeStarted();
            break;
        case MATCH_STATE_POSTMATCH:
            hgg.postmatchStarted();
            break;
    }
}

void GT_Shutdown() {
    hgg.shutdown();
}

void GT_SpawnGametype() {
    hgg.spawnGametype();
}

void GT_InitGametype() {
    hgg.initGametype();
}

void dummy_die(Entity @self, Entity @inflictor, Entity @attacker)
{
    hgg.dummyKilled(self, attacker, inflictor);
}
