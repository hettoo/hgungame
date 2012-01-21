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

const int SPECIAL_ROW = 5;

class Players {
    Player@[] players;
    int size;
    DB db;
    Ranks ranks;
    Weapons weapons;

    bool first_blood;

    int best_score;
    int second_score;

    Players() {
        players.resize(maxClients);
        size = 0;

        first_blood = true;

        best_score = -1;
        second_score = -1;
    }

    void init() {
        db.init();
    }

    Player @get(int playernum) {
        if (playernum < 0 || playernum >= size)
            return null;
        return players[playernum];
    }

    void init_client(cClient @client) {
        int playernum = client.playerNum();
        Player @player = get(playernum);
        if (@player == null) {
            @players[playernum] = Player();
            if (playernum >= size)
                size = playernum + 1;
        }
        players[playernum].init(client, db);
    }

    void welcome_all(cString &msg) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null)
                get(i).welcome(msg);
        }
    }

    void reset() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                check_row(player.client, null);
                player.minutes_played = 0;
                player.set_score(0);
            }
        }
    }

    void announce_row(cClient @target, cClient @attacker) {
        int row = get(target.playerNum()).row;
        target.addAward(highlight("You made a row of " + highlight_row(row)
                    + "!"));
        cString msg = target.getName() + highlight(" made a row of "
            + highlight_row(row) + "!");
        if (@target == @attacker)
            msg += highlight(" He fragged ") + S_COLOR_BAD + "himself"
                + highlight("!");
        else if (@attacker != null)
            msg += highlight(" He was fragged by ") + attacker.getName()
                + highlight("!");
        notify(msg);
    }

    void check_row(cClient @target, cClient @attacker) {
        if (@target == null)
            return;

        Player @player = get(target.playerNum());
        player.update_row();
        if (player.row >= SPECIAL_ROW)
            announce_row(target, attacker);
        player.row = 0;
    }

    void award(cClient @client, int row, bool real, int weapon, int ammo) {
        Player @player = get(client.playerNum());
        if (real) {
            player.add_score(1);

            player.update_hud_self();
            update_best(client.playerNum());

            if (player.score == best_score)
                update_hud();
            else if (player.score == second_score)
                update_hud_bests();
        }

        int award = weapons.award(row);
        if (award == WEAP_NONE)
            return;

        if (award < WEAP_TOTAL)
            award_weapon(client, award,
                    ammo == INFINITY ? weapons.ammo(award) : ammo, real);
        else if (real)
            get(client.playerNum()).show_row();

        if (weapons.weak(weapon)) {
            int award;
            for (int i = 0; i <= player.row
                    && (award = weapons.award(i)) != WEAP_TOTAL; i++) {
                if (weapons.heavy(award))
                    increase_ammo(client, award);
            }
        }
    }

    void award(cClient @client, int row, bool real, int weapon) {
        award(client, row, true, weapon, INFINITY);
    }

    void award(cClient @client, int row, int weapon) {
        award(client, row, true, weapon);
    }

    void award(cClient @client, int weapon) {
        award(client, get(client.playerNum()).row, weapon);
    }

    void killed_anyway(cClient @target, cClient @attacker, cClient @inflictor) {
        if (@attacker == null || @attacker == @target)
            return;

        Player @player = get(attacker.playerNum());
        if (@target == null)
            player.center("YOU FRAGGED " + highlight("A DUMMY"));
        player.killer();
        int weapon = attacker.weapon; // FIXME: mod
        award(attacker, weapon);
        check_decrease_ammo(attacker, weapon);
        player.update_ammo();
        if (for_real() && first_blood) {
            attacker.addAward(highlight("First blood!"));
            notify(attacker.getName() + highlight(" drew first blood!"));
            first_blood = false;
        }
    }

    void killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        Player @player = get(target.playerNum());
        player.alive = false;
        if (@attacker != null)
            player.say("You have been fragged by " + attacker.getName());
        player.killed();
        check_row(target, attacker);

        killed_anyway(target, attacker, inflictor);
    }

    void check_decrease_ammo(cClient @client, int weapon) {
        if (weapon < WEAP_TOTAL && weapons.ammo(weapon) != INFINITY) {
            if (!decrease_ammo(client, weapon) && client.weapon == weapon)
                weapons.select_best(client);
        }
    }

    void give_spawn_weapons(cClient @client) {
        Player @player = get(client.playerNum());
        weapons.give_default(client);
        for (int i = 1; i <= player.row; i++) {
            int award = weapons.award(i);
            if (award < WEAP_TOTAL) {
                int ammo = player.get_ammo(award);
                award(client, i, false, WEAP_NONE,
                        weapons.ammo(award) == INFINITY
                        ? INFINITY : player.get_ammo(award));
            }
        }
    }

    void respawn(cClient @client) {
        Player @player = get(client.playerNum());
        player.alive = true;
        player.update_hud_self();
        player.update_hud_other(this);
        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
        if (!gametype.isInstagib())
            client.getEnt().health = NW_HEALTH;
    }

    void reset_stats() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null)
                player.client.stats.clear();
        }
    }

    void increase_minutes() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.team != TEAM_SPECTATOR)
                player.add_minute();
        }
    }

    void update_best(int i) {
        Player @player = get(i);
        if (@player != null) {
            cClient @client = player.client;
            if (@client != null && client.team != TEAM_SPECTATOR) {
                if (player.score > best_score || best_score == UNKNOWN)
                    best_score = player.score;
                else if (player.score > second_score || second_score == UNKNOWN)
                    second_score = player.score;
            }
        }
    }

    void update_best() {
        best_score = UNKNOWN;
        second_score = UNKNOWN;
        for (int i = 0; i < size; i++)
            update_best(i);
    }

    void update_hud() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null)
                player.update_hud_other(this);
        }
    }

    void update_hud_bests() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && player.score == best_score)
                player.update_hud_other(this);
        }
    }

    void new_player(cClient @client) {
        Player @player = get(client.playerNum());
        if (player.ip_check()) {
            cString ip = get_ip(player.client);
            cString password = cVar("rcon_password", "", 0).getString();
            if (!db.has_root && password != "" && player.state == DBI_UNKNOWN
                    && !client.isBot() && (ip == "127.0.0.1" || ip == "")) {
                player.dbitem.rank = RANK_ROOT;
                player.set_registered(password);
                db.add(player.dbitem);
                player.administrate("You have been auto-registered as Root!");
                player.say(S_COLOR_ADMINISTRATIVE
                        + "Your password has been set to your rcon_password");
            }
            player.sync_score();
            if (count() <= 2 || player.score > second_score) {
                update_best();
                update_hud();
            }
        }
    }

    void new_spectator(cClient @client) {
        Player @player = get(client.playerNum());
        player.alive = false;
        check_row(client, null);
        if (player.score == best_score || player.score == second_score) {
            update_best();
            update_hud();
        }
    }

    void namechange(cClient @client) {
        init_client(client);
        Player @player = get(client.playerNum());
        if (player.client.team != TEAM_SPECTATOR)
            player.ip_check();
    }

    void disconnect(cClient @client) {
        int playernum = client.playerNum();
        @players[playernum] = null;
        for (int i = playernum; i < size; i++) {
            if (@players[i] != null)
                return;
        }
        size = playernum;
    }

    void charge_gunblades() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.state() >= CS_SPAWNED
                    && player.client.getEnt().team != TEAM_SPECTATOR)
                GENERIC_ChargeGunblade(player.client);
        }
    }

    void team_scored(int team) {
        G_GetTeam(team).stats.addScore(1);

        random_announcer_sound(team, "sounds/announcer/ctf/score_team0");
        random_announcer_sound(other_team(team),
                "sounds/announcer/ctf/score_enemy0");
    }

    void respawn() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.team != TEAM_SPECTATOR)
                player.client.respawn(false);
        }
    }

    int count_alive(int team, cClient @target) {
        int n = 0;
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && @client != @target && client.team == team
                        && !client.getEnt().isGhosting())
                    n++;
            }
        }
        return n;
    }

    int count_alive(int team) {
        return count_alive(team, null);
    }

    Player @get_alive(int team, cClient @target) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && @client != @target && client.team == team
                        && !client.getEnt().isGhosting())
                    return player;
            }
        }
        return null;
    }

    Player @get_alive(int team) {
        return get_alive(team, null);
    }

    int count() {
        int n = 0;
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && client.team != TEAM_SPECTATOR)
                    n++;
            }
        }
        return n;
    }

    void say_team(int team, cString &msg) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && client.team == team)
                    player.say(msg);
            }
        }
    }
}
