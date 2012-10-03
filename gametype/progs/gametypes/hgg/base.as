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
 * This is the base class on which all hgg gametypes are based. It handles all
 * callbacks and connects them to the subclasses.
 */

const float DUMMY_WEIGHT_MULTIPLIER = 0.4f;

class HGGBase {
    Gametype gt;
    Players players;
    Scoreboard scoreboard;
    Commands commands;

    cEntity @spawn_alpha;
    cEntity @spawn_beta;

    uint last_second;
    uint last_minute_second;

    /*
     * Initializes the variables that can be initialized already.
     */
    HGGBase() {
        @spawn_alpha = null;
        @spawn_beta = null;

        last_second = 0;
        last_minute_second = 0;
    }

    /*
     * The map entities have just been spawned. The level is initialized for
     * playing, but nothing has yet started.
     */
    void spawn_gametype() {
    }

    /*
     * When this function is called the weights of items have been reset to
     * their default values, this means, the weights *are set*, and what this
     * function does is scaling them depending on the current bot status.
     * Player, and non-item entities don't have any weight set. So they will be
     * ignored by the bot unless a weight is assigned here.
     */
    bool update_bot_status(cEntity @self) {
        GENERIC_UpdateBotStatus(self);
        cEntity @goal;
        cBot @bot = self.client.getBot();
        float offensiveness = GENERIC_OffensiveStatus(self);
        for (int i = 0; (@goal = bot.getGoalEnt(i)) != null; i++) {
            if (goal.getClassname() == "dummy")
                bot.setGoalWeight(i, DUMMY_WEIGHT_MULTIPLIER
                        * GENERIC_PlayerWeight(self, goal) * offensiveness);
        }
        return true;
    }

    /*
     * Select a spawning point for a player.
     */
    cEntity @select_spawn_point(cEntity @self) {
        cEntity @random = GENERIC_SelectBestRandomSpawnPoint(self,
                "info_player_deathmatch");
        if (gt.spawn_system != SPAWNSYSTEM_INSTANT && gametype.isTeamBased) {
            if (@spawn_alpha == null) {
                @spawn_alpha = random;
                cEntity @max;
                int max_dist = UNKNOWN;
                do {
                    @spawn_beta = G_FindEntityWithClassname(spawn_beta,
                            "info_player_deathmatch");
                    if (@spawn_beta != null) {
                        int dist = spawn_alpha.getOrigin().distance(
                                spawn_beta.getOrigin());
                        if (dist > max_dist || max_dist == UNKNOWN) {
                            @max = spawn_beta;
                            max_dist = dist;
                        }
                    }
                } while (@spawn_beta != null);
                @spawn_beta = max;
            }
            return self.client.team == TEAM_ALPHA ? spawn_alpha : spawn_beta;
        }
        return random;
    }

    /*
     * A client has issued a command.
     */
    bool command(cClient @client, String &cmd, String &args, int argc) {
        return commands.handle(client, cmd, args, argc, players);
    }

    /*
     * The warmup has started.
     */
    void warmup_started() {
        scoreboard.set_layout(SB_WARMUP);
        CreateSpawnIndicators("info_player_deathmatch", gametype.isTeamBased
                ? TEAM_BETA : TEAM_PLAYERS);
        players.dummies.spawn();
        GENERIC_SetUpWarmup();
    }
    
    /*
     * The countdown has started.
     */
    void countdown_started() {
        players.welcome_all(gt.motd());
        GENERIC_SetUpCountdown();
    }

    /*
     * Calls the generic match setup function so that it can be overloaded.
     */
    void generic_playtime_started () {
        players.dummies.spawn();
        GENERIC_SetUpMatch();
    }

    /*
     * The match has started.
     */
    void playtime_started() {
        last_second = levelTime / 1000;
        last_minute_second = last_second;
        scoreboard.set_layout(SB_MATCH);
        DeleteSpawnIndicators();
        players.update_best();
        players.update_hud();
        generic_playtime_started();
    }

    /*
     * The postmatch has started.
     */
    void postmatch_started() {
        scoreboard.set_layout(SB_POST);
        GENERIC_SetUpEndMatch();
        players.show_match_top_row();
    }

    /*
     * The game has detected the end of the match state, but it doesn't advance
     * it before calling this function. This function must give permission to
     * move into the next state by returning true.
     */
    bool match_state_finished(int new_match_state) {
        if (match.getState() <= MATCH_STATE_WARMUP
                && new_match_state > MATCH_STATE_WARMUP
                && new_match_state < MATCH_STATE_POSTMATCH)
            match.startAutorecord();
        else if (match.getState() == MATCH_STATE_POSTMATCH)
            match.stopAutorecord();

        if (new_match_state == MATCH_STATE_PLAYTIME
                || new_match_state == MATCH_STATE_POSTMATCH) {
            players.check_rows();
            if (new_match_state == MATCH_STATE_PLAYTIME)
                players.reset();
        }

        return true;
    }

    /*
     * The gametype is shutting down cause of a match restart or map change.
     */
    void shutdown() {
        players.db.write();
    }

    /*
     * A player has been killed.
     */
    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        players.killed(target, attacker, inflictor);
    }

    /*
     * Some game actions trigger score events. There are events not related to
     * killing opponents, like capturing a flag.
     * Warning: client can be null.
     */
    void score_event(cClient @client, String &score_event, String &args) {
        if (score_event == "kill") {
            cEntity @target = G_GetEntity(args.getToken(0).toInt());
            cEntity @inflictor = G_GetEntity(args.getToken(1).toInt());

            cClient @target_client = null;
            cClient @inflictor_client = null;
            if (@target != null)
                @target_client = target.client;
            if (@inflictor != null)
                @inflictor_client = inflictor.client;

            killed(client, target_client, inflictor_client);
        } else if (score_event == "userinfochanged") {
            players.namechange(client);
        } else if (score_event == "disconnect") {
            players.disconnect(client);
        }
    }

    /*
     * Sets the gametype settings.
     */
    void set_gametype_settings() {
        gt.set_defaults();
    }

    /*
     * Add the root account from the cVars if there is no root yet and the
     * account name is not empty.
     */
    void check_root() {
        if (!players.db.has_root && gt.root() != "") {
            Account @root = Account();
            root.id = gt.root();
            root.password = gt.root_password();
            players.db.add(root);
        }
    }

    /*
     * Important: This function is called before any entity is spawned, and
     * spawning entities from it is forbidden. If you want to make any entity
     * spawning at initialization do it in GT_SpawnGametype, which is called
     * right after the map entities spawning.
     */
    void init_gametype() {
        players.init();
        players.db.read();

        gt.set_info();
        gt.init();
        check_root();
        set_gametype_settings();
        gt.check_default_config();

        commands.init();

        debug("Gametype '" + gametype.getTitle() + "' initialized");
    }

    /*
     * Thinking function. Called each frame.
     */
    void think_rules() {
        if (match.scoreLimitHit() || match.timeLimitHit()
                || match.suddenDeathFinished())
            match.launchState(match.getState() + 1);

        if (match.getState() >= MATCH_STATE_POSTMATCH)
            return;

        GENERIC_Think();
        if (!gametype.isInstagib())
            players.fix_health();
        players.charge_gunblades();
        check_time();
    }

    /*
     * Someone moved from the spectators to a player team.
     */
    void new_player(cClient @client) {
        players.new_player(client);
    }

    /*
     * Someone moved from a player team to the spectators.
     */
    void new_spectator(cClient @client) {
        players.new_spectator(client);
    }

    /*
     * A non-spectator is respawning.
     */
    void respawn(cClient @client) {
        players.respawn(client);
    }

    /*
     * A player is being respawned. This can happen from several ways, as dying,
     * changing team, being moved to ghost state, be placed in respawn queue,
     * being spawned from spawn queue, etc.
     */
    void player_respawn(cEntity @ent, int old_team, int new_team) {
        if (old_team == TEAM_SPECTATOR && new_team != TEAM_SPECTATOR)
            new_player(ent.client);
        else if (old_team != TEAM_SPECTATOR && new_team == TEAM_SPECTATOR)
            new_spectator(ent.client);

        if (new_team != TEAM_SPECTATOR)
            respawn(ent.client);
    }

    /*
     * A new minute has started.
     */
    void new_minute() {
        players.new_minute();
    }

    /*
     * A new second has started.
     */
    void new_second() {
        players.new_second();
        uint minute_second = last_minute_second + 60;
        if (last_second == minute_second) {
            new_minute();
            last_minute_second = minute_second;
        }
    }

    /*
     * Checks for new seconds and minutes.
     */
    void check_time() {
        uint second = levelTime / 1000;
        if (second != last_second) {
            last_second = second;
            new_second();
        }
    }

    /*
     * Create the scoreboard contents.
     */
    String @scoreboard_message(int max_len) {
        String board = "";
        if (gametype.isTeamBased) {
            scoreboard.add_team(board, TEAM_ALPHA, max_len, players);
            scoreboard.add_team(board, TEAM_BETA, max_len, players);
        } else {
            scoreboard.add_team(board, TEAM_PLAYERS, max_len, players);
        }
        return board;
    }

    /*
     * A dummy has been killed.
     */
    void dummy_killed(cEntity @self, cEntity @attacker, cEntity @inflictor) {
        players.dummy_killed(self.count, attacker.client, inflictor.client);
    }
}

