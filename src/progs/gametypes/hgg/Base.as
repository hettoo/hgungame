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

    cEntity @alphaSpawn;
    cEntity @betaSpawn;

    uint lastSecond;
    uint lastMinuteSecond;

    /*
     * Initializes the variables that can be initialized already.
     */
    HGGBase() {
        @alphaSpawn = null;
        @betaSpawn = null;

        lastSecond = 0;
        lastMinuteSecond = 0;
    }

    /*
     * The map entities have just been spawned. The level is initialized for
     * playing, but nothing has yet started.
     */
    void spawnGametype() {
    }

    /*
     * When this function is called the weights of items have been reset to
     * their default values, this means, the weights *are set*, and what this
     * function does is scaling them depending on the current bot status.
     * Player, and non-item entities don't have any weight set. So they will be
     * ignored by the bot unless a weight is assigned here.
     */
    bool updateBotStatus(cEntity @self) {
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
    cEntity @selectSpawnPoint(cEntity @self) {
        cEntity @random = GENERIC_SelectBestRandomSpawnPoint(self,
                "info_player_deathmatch");
        if (gt.spawnSystem != SPAWNSYSTEM_INSTANT && gametype.isTeamBased) {
            if (@alphaSpawn == null) {
                @alphaSpawn = random;
                cEntity @max;
                int maxDist = UNKNOWN;
                do {
                    @betaSpawn = G_FindEntityWithClassname(betaSpawn,
                            "info_player_deathmatch");
                    if (@betaSpawn != null) {
                        int dist = alphaSpawn.getOrigin().distance(
                                betaSpawn.getOrigin());
                        if (dist > maxDist || maxDist == UNKNOWN) {
                            @max = betaSpawn;
                            maxDist = dist;
                        }
                    }
                } while (@betaSpawn != null);
                @betaSpawn = max;
            }
            return self.client.team == TEAM_ALPHA ? alphaSpawn : betaSpawn;
        }
        return random;
    }

    /*
     * A client has issued a command.
     */
    bool command(cClient @client, cString &cmd, cString &args, int argc) {
        return commands.handle(client, cmd, args, argc, players);
    }

    /*
     * The warmup has started.
     */
    void warmupStarted() {
        scoreboard.setLayout(SB_WARMUP);
        CreateSpawnIndicators("info_player_deathmatch", gametype.isTeamBased
                ? TEAM_BETA : TEAM_PLAYERS);
        players.dummies.spawn();
        GENERIC_SetUpWarmup();
    }
    
    /*
     * The countdown has started.
     */
    void countdownStarted() {
        players.welcomeAll(gt.motd());
        players.setMatchStartTime();
        GENERIC_SetUpCountdown();
    }

    /*
     * Calls the generic match setup function so that it can be overloaded.
     */
    void genericPlaytimeStarted () {
        players.dummies.spawn();
        GENERIC_SetUpMatch();
    }

    /*
     * The match has started.
     */
    void playtimeStarted() {
        lastSecond = levelTime / 1000;
        lastMinuteSecond = lastSecond;
        scoreboard.setLayout(SB_MATCH);
        DeleteSpawnIndicators();
        players.updateBest();
        players.updateHUD();
        genericPlaytimeStarted();
    }

    /*
     * The postmatch has started.
     */
    void postmatchStarted() {
        scoreboard.setLayout(SB_POST);
        GENERIC_SetUpEndMatch();
        players.showMatchTopRow();
    }

    /*
     * The game has detected the end of the match state, but it doesn't advance
     * it before calling this function. This function must give permission to
     * move into the next state by returning true.
     */
    bool matchStateFinished(int newMatchState) {
        if (match.getState() <= MATCH_STATE_WARMUP
                && newMatchState > MATCH_STATE_WARMUP
                && newMatchState < MATCH_STATE_POSTMATCH)
            match.startAutorecord();
        else if (match.getState() == MATCH_STATE_POSTMATCH)
            match.stopAutorecord();

        if (match.getState() == MATCH_STATE_COUNTDOWN
                && newMatchState < MATCH_STATE_COUNTDOWN)
            players.setRecorded(false);

        if (newMatchState == MATCH_STATE_PLAYTIME
                || newMatchState == MATCH_STATE_POSTMATCH) {
            players.checkRows();
            if (newMatchState == MATCH_STATE_PLAYTIME)
                players.reset();
        }

        return true;
    }

    /*
     * The gametype is shutting down cause of a match restart or map change.
     */
    void shutdown() {
        players.shutdown();
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
    void scoreEvent(cClient @client, cString &scoreEvent, cString &args) {
        if (scoreEvent == "kill") {
            cEntity @target = G_GetEntity(args.getToken(0).toInt());
            cEntity @inflictor = G_GetEntity(args.getToken(1).toInt());

            cClient @targetClient = null;
            cClient @inflictorClient = null;
            if (@target != null)
                @targetClient = target.client;
            if (@inflictor != null)
                @inflictorClient = inflictor.client;

            killed(client, targetClient, inflictorClient);
        } else if (scoreEvent == "userinfochanged") {
            players.namechange(client);
        } else if (scoreEvent == "disconnect") {
            players.disconnect(client);
        }
    }

    /*
     * Sets the gametype settings.
     */
    void setGametypeSettings() {
        gt.setDefaults();
    }

    /*
     * Add the root account from the cVars if there is no root yet and the
     * account name is not empty.
     */
    void checkRoot() {
        if (!players.db.hasRoot && gt.root() != "") {
            Account @root = Account();
            root.id = gt.root();
            root.password = gt.rootPassword();
            players.db.add(root);
        }
    }

    /*
     * Important: This function is called before any entity is spawned, and
     * spawning entities from it is forbidden. If you want to make any entity
     * spawning at initialization do it in GT_SpawnGametype, which is called
     * right after the map entities spawning.
     */
    void initGametype() {
        players.init();
        players.db.read();

        gt.setInfo();
        gt.init();
        checkRoot();
        setGametypeSettings();
        gt.checkDefaultConfig();

        commands.init();

        debug("Gametype '" + gametype.getTitle() + "' initialized");
    }

    /*
     * Thinking function. Called each frame.
     */
    void thinkRules() {
        if (match.scoreLimitHit() || match.timeLimitHit()
                || match.suddenDeathFinished())
            match.launchState(match.getState() + 1);

        if (match.getState() >= MATCH_STATE_POSTMATCH)
            return;

        GENERIC_Think();
        if (!gametype.isInstagib())
            players.fixHealth();
        players.chargeGunblades();
        checkTime();
    }

    /*
     * Someone moved from the spectators to a player team.
     */
    void newPlayer(cClient @client) {
        players.newPlayer(client);
    }

    /*
     * Someone moved from a player team to the spectators.
     */
    void newSpectator(cClient @client) {
        players.newSpectator(client);
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
    void playerRespawn(cEntity @ent, int oldTeam, int newTeam) {
        if (oldTeam == TEAM_SPECTATOR && newTeam != TEAM_SPECTATOR)
            newPlayer(ent.client);
        else if (oldTeam != TEAM_SPECTATOR && newTeam == TEAM_SPECTATOR)
            newSpectator(ent.client);

        if (newTeam != TEAM_SPECTATOR)
            respawn(ent.client);
    }

    /*
     * A new minute has started.
     */
    void newMinute() {
        players.newMinute();
    }

    /*
     * A new second has started.
     */
    void newSecond() {
        players.newSecond();
        uint minuteSecond = lastMinuteSecond + 60;
        if (lastSecond == minuteSecond) {
            newMinute();
            lastMinuteSecond = minuteSecond;
        }
    }

    /*
     * Checks for new seconds and minutes.
     */
    void checkTime() {
        uint second = levelTime / 1000;
        if (second != lastSecond) {
            lastSecond = second;
            newSecond();
        }
    }

    /*
     * Create the scoreboard contents.
     */
    cString @scoreboardMessage(int maxLen) {
        cString board = "";
        if (gametype.isTeamBased) {
            scoreboard.addTeam(board, TEAM_ALPHA, maxLen, players);
            scoreboard.addTeam(board, TEAM_BETA, maxLen, players);
        } else {
            scoreboard.addTeam(board, TEAM_PLAYERS, maxLen, players);
        }
        return board;
    }

    /*
     * A dummy has been killed.
     */
    void dummyKilled(cEntity @self, cEntity @attacker, cEntity @inflictor) {
        players.dummyKilled(self.count, attacker.client, inflictor.client);
    }
}

