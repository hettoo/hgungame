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

bool GT_Command(cClient @client, cString &cmd, cString &args, int argc) {
    return hgg.command(client, cmd, args, argc);
}

/*
 * When this function is called the weights of items have been reset to their
 * default values, this means, the weights *are set*, and what this function
 * does is scaling them depending on the current bot status. Player, and
 * non-item entities don't have any weight set. So they will be ignored by the
 * bot unless a weight is assigned here.
 */
bool GT_UpdateBotStatus(cEntity @self) {
    return hgg.update_bot_status(self);
}

/*
 * Select a spawning point for a player.
 */
cEntity @GT_SelectSpawnPoint(cEntity @self) {
    return hgg.select_spawn_point(self);
}

/*
 * Create the scoreboard contents.
 */
cString @GT_ScoreboardMessage(int maxlen) {
    return hgg.scoreboard_message(maxlen);
}

/*
 * Some game actions trigger score events. These are events not related to
 * killing opponents, like capturing a flag.
 * Warning: client can be null.
 */
void GT_scoreEvent(cClient @client, cString &score_event, cString &args) {
    hgg.score_event(client, score_event, args);
}

/* A player is being respawned. This can happen from several ways, as dying,
 * changing team, being moved to ghost state, be placed in respawn queue, being
 * spawned from spawn queue, etc.
 */
void GT_playerRespawn(cEntity @ent, int old_team, int new_team) {
    hgg.player_respawn(ent, old_team, new_team);
}

/*
 * Thinking function. Called each frame.
 */
void GT_ThinkRules() {
    hgg.think_rules();
}

/*
 * The game has detected the end of the match state, but it
 * doesn't advance it before calling this function.
 * This function must give permission to move into the next
 * state by returning true.
 */
bool GT_MatchStateFinished(int new_match_state) {
    return hgg.match_state_finished(new_match_state);
}

/*
 * The match state has just moved into a new state. Here is the
 * place to set up the new state rules.
 */
void GT_MatchStateStarted() {
    hgg.match_state_started();
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

/*
 * The gametype is shutting down cause of a match restart or map change.
 */
void GT_Shutdown() {
    hgg.shutdown();
}

/*
 * The map entities have just been spawned. The level is initialized for
 * playing, but nothing has yet started.
 */
void GT_SpawnGametype() {
    hgg.spawn_gametype();
}

/*
 * Important: This function is called before any entity is spawned, and
 * spawning entities from it is forbidden. If you want to make any entity
 * spawning at initialization do it in GT_SpawnGametype, which is called
 * right after the map entities spawning.
 */
void GT_InitGametype() {
    hgg.init_gametype();
}

