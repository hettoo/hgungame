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

/*
 * The functions here are redirected to an instance of the HGG class. They are
 * documented in the file containing the HGGBase class.
 */

HGG hgg;

bool GT_Command(cClient @client, cString &cmd, cString &args, int argc) {
    return hgg.command(client, cmd, args, argc);
}

bool GT_UpdateBotStatus(cEntity @self) {
    return hgg.update_bot_status(self);
}

cEntity @GT_SelectSpawnPoint(cEntity @self) {
    return hgg.select_spawn_point(self);
}

cString @GT_ScoreboardMessage(int maxlen) {
    return hgg.scoreboard_message(maxlen);
}

void GT_scoreEvent(cClient @client, cString &score_event, cString &args) {
    hgg.score_event(client, score_event, args);
}

void GT_playerRespawn(cEntity @ent, int old_team, int new_team) {
    hgg.player_respawn(ent, old_team, new_team);
}

void GT_ThinkRules() {
    hgg.think_rules();
}

bool GT_MatchStateFinished(int new_match_state) {
    return hgg.match_state_finished(new_match_state);
}

void GT_MatchStateStarted() {
    switch (match.getState()) {
        case MATCH_STATE_WARMUP:
            hgg.warmup_started();
            break;

        case MATCH_STATE_COUNTDOWN:
            hgg.countdown_started();
            break;

        case MATCH_STATE_PLAYTIME:
            hgg.playtime_started();
            break;

        case MATCH_STATE_POSTMATCH:
            hgg.postmatch_started();
            break;
    }
}

void GT_Shutdown() {
    hgg.shutdown();
}

void GT_SpawnGametype() {
    hgg.spawn_gametype();
}

void GT_InitGametype() {
    hgg.init_gametype();
}

void dummy_die(cEntity @self, cEntity @inflictor, cEntity @attacker)
{
    hgg.dummy_killed(self, attacker, inflictor);
}
