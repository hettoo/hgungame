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

class HGGGlobal {
    Config config;
    Gametype gt;
    Players players;
    Scoreboard scoreboard;
    Icons icons;
    Commands commands;

    void spawn_gametype() {
    }

    bool update_bot_status(cEntity @self) {
        return GENERIC_UpdateBotStatus(self);
    }

    cEntity @select_spawn_point(cEntity @self) {
        return GENERIC_SelectBestRandomSpawnPoint(self,
                "info_player_deathmatch");
    }

    bool command(cClient @client, cString &cmd, cString &args, int argc) {
        return commands.handle(client, cmd, args, argc, players);
    }

    void match_state_started() {
    }

    void warmup_started() {
        scoreboard.set_layout(SB_WARMUP);
        GENERIC_SetUpWarmup();
    }
    
    void countdown_started() {
        players.welcome_all(config.motd());
        GENERIC_SetUpCountdown();
    }

    void playtime_started() {
        players.reset();
        scoreboard.set_layout(SB_MATCH);
        GENERIC_SetUpMatch();
    }

    void postmatch_started() {
        scoreboard.set_layout(SB_POST);
        GENERIC_SetUpEndMatch();
    }

    bool match_state_finished(int new_match_state) {
        if (match.getState() <= MATCH_STATE_WARMUP
                && new_match_state > MATCH_STATE_WARMUP
                && new_match_state < MATCH_STATE_POSTMATCH)
            match.startAutorecord();

        if (match.getState() == MATCH_STATE_POSTMATCH)
            match.stopAutorecord();

        return true;
    }

    void shutdown() {
        players.db.write();
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        players.killed(target, attacker, inflictor);
    }

    void score_event(cClient @client, cString &score_event, cString &args) {
        if (score_event == "kill") {
            cClient @target = G_GetEntity(args.getToken(0).toInt()).client;
            cClient @inflictor = G_GetEntity(args.getToken(1).toInt()).client;
            killed(client, target, inflictor);
        }
    }

    void set_gametype_settings() {
        gametype.setTitle("hGunGame " + gt.name);
        gametype.setVersion("0.0-dev");
        gametype.setAuthor("^0<].^7h^2e^9tt^2o^7o^0.[>^7");

        gametype.isRace = false;

        gametype.spawnableItemsMask = 0;
        gametype.respawnableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        gametype.pickableItemsMask = gametype.spawnableItemsMask;

        gametype.ammoRespawn = 0;
        gametype.armorRespawn = 0;
        gametype.weaponRespawn = 0;
        gametype.healthRespawn = 0;
        gametype.powerupRespawn = 0;
        gametype.megahealthRespawn = 0;
        gametype.ultrahealthRespawn = 0;

        gametype.countdownEnabled = false;
        gametype.mathAbortDisabled = false;
        gametype.shootingDisabled = false;
        gametype.infiniteAmmo = false;
        gametype.canForceModels = true;

        gametype.spawnpointRadius = 256;

        if (gametype.isInstagib())
            gametype.spawnpointRadius *= 2;
    }

    void init_gametype() {
        players.init();
        config.init();
        set_gametype_settings();
        gt.init();
        gt.check_default_config();

        commands.init();

        debug("Gametype '" + gametype.getTitle() + "' initialized");
    }

    void think_rules() {
        if (match.scoreLimitHit() || match.timeLimitHit()
                || match.suddenDeathFinished())
            match.launchState(match.getState() + 1);

        if (match.getState() >= MATCH_STATE_POSTMATCH)
            return;

        GENERIC_Think();

        charge_gunblades();

        players.check_minute();
    }

    void new_player(cClient @client) {
        players.init_client(client);
        Player @player = players.get(client.playerNum());
        if (player.state == DBI_WRONG_IP)
            player.force_spec("Wrong IP");
    }

    void new_spectator(cClient @client) {
    }

    void player_respawn(cEntity @ent, int old_team, int new_team) {
        if (old_team == TEAM_SPECTATOR && new_team != TEAM_SPECTATOR)
            new_player(ent.client);
        else if (old_team != TEAM_SPECTATOR && new_team == TEAM_SPECTATOR)
            new_spectator(ent.client);

        if (new_team != TEAM_SPECTATOR)
            players.respawn(ent.client);
    }

}

