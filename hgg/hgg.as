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
    Weapons weapons;
    Gametype gt;
    Icons icons;
    Commands commands;

    int max_playernum;
    int[] rows;

    HGGGlobal() {
        max_playernum = 0;
        rows.resize(maxClients);
    }

    void spawn_gametype() {
    }

    bool update_bot_status(cEntity @self) {
        return GENERIC_UpdateBotStatus(self);
    }

    cEntity @select_spawn_point(cEntity @self) {
        return GENERIC_SelectBestRandomSpawnPoint(self, "info_player_deathmatch");
    }

    bool command(cClient @client, cString &cmd, cString &args, int argc) {
        return commands.handle(client, cmd, args, argc);
    }

    void match_state_started() {
    }

    void warmup_started() {
        GENERIC_SetUpWarmup();
    }
    
    void welcome(cClient @client) {
        client.addAward(config.motd());
    }

    void welcome_all() {
        for (int i = 0; i <= max_playernum; i++) {
            cEntity @ent = G_GetEntity(i);
            if (@ent != null && @ent.client != null)
                welcome(ent.client);
        }
    }

    void countdown_started() {
        welcome_all();
        GENERIC_SetUpCountdown();
    }

    void reset_rows() {
        for (int i = 0; i <= max_playernum; i++)
            rows[i] = 0;
    }

    void playtime_started() {
        reset_rows();
        GENERIC_SetUpMatch();
    }

    void postmatch_started() {
        GENERIC_SetUpEndMatch();
    }

    bool match_state_finished(int new_match_state) {
        if (match.getState() <= MATCH_STATE_WARMUP && new_match_state > MATCH_STATE_WARMUP
                && new_match_state < MATCH_STATE_POSTMATCH)
            match.startAutorecord();

        if (match.getState() == MATCH_STATE_POSTMATCH)
            match.stopAutorecord();

        return true;
    }

    void shutdown() {
    }

    void score_event(cClient @client, cString &score_event, cString &args) {
        if (score_event == "kill") {
            cClient @target = G_GetEntity(args.getToken(0).toInt()).client;
            cClient @inflictor = G_GetEntity(args.getToken(1).toInt()).client;

            player_killed(target, client, inflictor);
        } else if (score_event == "award") {
        }
    }

    void set_gametype_settings() {
        gametype.setTitle("hGunGame " + gt.name);
        gametype.setVersion("0.0-dev");
        gametype.setAuthor("^0<].^7h^2e^9tt^2o^7o^0.[>");

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

        set_spawn_system(SPAWNSYSTEM_INSTANT);
    }

    void init_gametype() {
        set_gametype_settings();
        config.init();
        gt.check_default_config();

        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %l 48 %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Frags Row Ping R");

        G_RegisterCommand("drop");
        G_RegisterCommand("gametype");

        G_Print("Gametype '" + gametype.getTitle() + "' initialized\n");
    }

    void scoreboard_add_team_entry(cString &scoreboard, int id, int max_len) {
        cTeam @team = @G_GetTeam(id);
        string_add_maxed(scoreboard, "&t " + id + " " + team.stats.score + " " + team.ping + " ", max_len);
    }

    void scoreboard_add_team_player_entries(cString &scoreboard, int id, int max_len) {
        cTeam @team = @G_GetTeam(id);
        for (int i = 0; @team.ent(i) != null; i++)
            scoreboard_add_player_entry(scoreboard, team.ent(i), max_len);
    }

    void scoreboard_add_player_entry(cString &scoreboard, cEntity @ent, int max_len) {
        int readyIcon = 0;
        if (ent.client.isReady())
            readyIcon = icons.yes;
        cString entry = "&p " + ent.playerNum() + " " + ent.client.getClanName()
            + " " + ent.client.stats.score + " " + "0" + " " + ent.client.ping + " "
            + readyIcon + " ";
        string_add_maxed(scoreboard, entry, max_len);
    }

    void think_rules() {
        if (match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished())
            match.launchState(match.getState() + 1);

        if (match.getState() >= MATCH_STATE_POSTMATCH)
            return;

        GENERIC_Think();

        for (int i = 0; i < maxClients; i++) {
            cEntity @ent = @G_GetClient(i).getEnt();
            if (ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR) {
                GENERIC_ChargeGunblade(ent.client);
            }
        }
    }

    void init_client(cClient @client){
        int playernum = client.playerNum();
        if(playernum > max_playernum)
            max_playernum = playernum;
    }

    void new_player(cClient @client) {
        init_client(client);
    }

    void new_spectator(cClient @client) {
    }

    void give_spawn_weapons(cClient @client) {
        weapons.give_default(client);
    }

    void respawn(cClient @client) {
        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
    }

    void player_respawn(cEntity @ent, int old_team, int new_team) {
        if (old_team == TEAM_SPECTATOR)
            new_player(ent.client);
        else if (new_team == TEAM_SPECTATOR)
            new_spectator(ent.client);

        if (new_team != TEAM_SPECTATOR)
            respawn(ent.client);
    }

    void check_decrease_ammo(cClient @client, int weapon) {
        if (weapon < WEAP_TOTAL && weapons.ammo(weapon) > 0) {
            if (!decrease_ammo(client, weapon) && client.weapon == weapon)
                weapons.select_best(client);
        }
    }

    void announce_row(cClient @target, cClient @attacker) {
        int row = rows[target.playerNum()];
        target.addAward(S_COLOR_ACHIEVEMENT + "You made a row of " + S_COLOR_ROW + row + S_COLOR_ACHIEVEMENT + "!");
        cString msg = target.getName() + S_COLOR_ACHIEVEMENT + " made a row of " + S_COLOR_ROW + row + S_COLOR_ACHIEVEMENT + "!";
        if (@attacker != null)
            msg += " He was killed by " + S_COLOR_RESET + attacker.getName() + S_COLOR_ACHIEVEMENT + "!";
        else if (@target == @attacker)
            msg += " He killed " + S_COLOR_BAD + "himself" + S_COLOR_ACHIEVEMENT + "!";
        notify(msg);
    }

    void check_row(cClient @target, cClient @attacker) {
        if (rows[target.playerNum()] >= SPECIAL_ROW)
            announce_row(target, attacker);
        rows[target.playerNum()] = 0;
    }

    void show_row(cClient @client) {
        client.addAward(S_COLOR_ROW + rows[client.playerNum()] + "!");
    }

    void award(cClient @client, int row) {
        client.stats.addScore(1);
        int weapon = weapons.award(row);
        if (weapon == WEAP_NONE)
            return;

        if (weapon < WEAP_TOTAL)
            award_weapon(client, weapon, weapons.ammo(weapon));
        else
            show_row(client);
    }

    void award(cClient @client) {
        award(client, rows[client.playerNum()]);
    }

    void player_killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        target.printMessage("** You have been killed by " + attacker.getName() + "\n");
        check_row(target, attacker);

        if (@attacker == null || @attacker == @target)
            return;

        rows[attacker.playerNum()]++;
        award(attacker);
        check_decrease_ammo(attacker, attacker.weapon); // TODO: mod
    }
}

