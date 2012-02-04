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

const int SPECIAL_ROW = 5;
const int MAX_PLAYERS = 256;

class Players {
    Player@[] players;
    int size;
    DataBase db;
    Levels levels;
    Weapons weapons;
    Dummies dummies;
    bool team_hud;

    bool first_blood;

    int best_score;
    int second_score;

    int match_top_row;
    cString[] match_top_row_players;
    int match_top_row_player_count;

    int sound_dummy_killed;

    Players() {
        players.resize(MAX_PLAYERS);
        size = 0;
        team_hud = false;

        first_blood = true;

        best_score = UNKNOWN;
        second_score = UNKNOWN;

        match_top_row = UNKNOWN;
        match_top_row_players.resize(MAX_PLAYERS);

        sound_dummy_killed = G_SoundIndex("sounds/misc/kill");
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

    void try_update_rank(Player @player) {
        int old_rank = player.account.rank;
        if (db.ranking.update(player.account)) {
            if (player.account.rank != old_rank) {
                player.client.addAward(S_COLOR_RECORD
                        + "You claimed server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
                notify(player.client.getName() + S_COLOR_RECORD
                        + " claimed server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
            } else {
                notify(player.client.getName() + S_COLOR_RECORD
                        + " still holds server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
            }
        }
    }

    void check_row(cClient @target, cClient @attacker) {
        if (@target == null)
            return;

        Player @player = get(target.playerNum());
        bool new_record = player.update_row() && player.state == AS_IDENTIFIED;
        if (player.row >= SPECIAL_ROW)
            announce_row(target, attacker);
        if (new_record) {
            target.addAward(S_COLOR_RECORD + "Personal record!");
            try_update_rank(player);
        }
        if (for_real()
                && (player.row >= match_top_row || match_top_row == UNKNOWN)) {
            if (player.row == match_top_row) {
                bool has_match_top_row = false;
                for (int i = 0; i < match_top_row_player_count; i++) {
                    if (match_top_row_players[i] == player.client.getName())
                        has_match_top_row = true;
                }
                if (!has_match_top_row)
                    match_top_row_players[match_top_row_player_count++]
                        = player.client.getName();
            } else {
                match_top_row = player.row;
                match_top_row_player_count = 1;
                match_top_row_players[0] = player.client.getName();
            }
        }
        player.row = 0;
    }

    void show_match_top_row() {
        if (match_top_row == UNKNOWN)
            return;
        cString msg = highlight("Match top row: " + highlight_row(match_top_row)
                + " frags by ");
        for (int i = 0; i < match_top_row_player_count; i++) {
            msg += match_top_row_players[i];
            if (i < match_top_row_player_count - 1) {
                if (i == match_top_row_player_count - 2)
                    msg += highlight(" and ");
                else
                    msg += highlight(", ");
            }
        }
        notify(msg);
    }

    void check_rows() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null)
                check_row(player.client, null);
        }
    }

    void award(cClient @client, int row, bool real, int weapon, int ammo) {
        Player @player = get(client.playerNum());
        if (real) {
            player.add_score(1);
            if (!gametype.isInstagib()) {
                client.getEnt().health += NW_HEALTH_BONUS;
                float new_armor = client.armor + NW_ARMOR_BONUS;
                if (new_armor < MAX_ARMOR)
                    client.armor = new_armor;
                else
                    client.armor = MAX_ARMOR;
            }

            if (team_hud) {
                update_hud_teams(other_team(client.team));
            } else {
                player.update_hud_self();
                update_best();

                if (player.score == best_score)
                    update_hud();
                else if (player.score == second_score)
                    update_hud_bests();
            }
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

        if (team_hud) {
            update_hud_teams();
        } else {
            player.update_hud_self();
            player.update_hud_other(this);
        }

        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
        if (!gametype.isInstagib()) {
            client.getEnt().health = NW_HEALTH;
            client.armor = NW_ARMOR;
        }
    }

    void reset_stats() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null)
                player.client.stats.clear();
        }
    }

    void new_second() {
        dummies.new_second();
    }

    void new_minute() {
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
                if (player.score >= best_score || best_score == UNKNOWN) {
                    second_score = best_score;
                    best_score = player.score;
                } else if (player.score > second_score
                        || second_score == UNKNOWN) {
                    second_score = player.score;
                }
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

    void update_hud_teams(Player @player, int penalty_team) {
        player.update_hud_teams(count_alive(TEAM_ALPHA)
                - (penalty_team == TEAM_ALPHA ? 1 : 0),
                count_alive(TEAM_BETA)
                - (penalty_team == TEAM_BETA ? 1 : 0));
    }

    void update_hud_teams(Player @player) {
        update_hud_teams(player, GS_MAX_TEAMS);
    }

    void update_hud_teams(int penalty_team) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && player.client.team != TEAM_SPECTATOR)
                update_hud_teams(player, penalty_team);
        }
    }

    void update_hud_teams() {
        update_hud_teams(GS_MAX_TEAMS);
    }

    void new_player(cClient @client) {
        Player @player = get(client.playerNum());
        if (player.ip_check()) {
            cString ip = get_ip(player.client);
            cString password = cVar("rcon_password", "", 0).getString();
            if (!db.has_root && player.state == AS_UNKNOWN && !client.isBot()
                    && (ip == "127.0.0.1" || ip == "")) {
                if (password == "") {
                    player.say(S_COLOR_ADMINISTRATIVE
                            + "Please set your rcon_password and rejoin a"
                            + " players team to auto-register as "
                            + levels.name(LEVEL_ROOT) + ".");
                } else {
                    player.account.level = LEVEL_ROOT;
                    player.set_registered(password);
                    db.add(player.account, false);
                    player.administrate("You have been auto-registered as "
                            + levels.name(LEVEL_ROOT));
                    player.say(S_COLOR_ADMINISTRATIVE + "Your password has been"
                            + " set to your rcon_password.");
                    try_update_rank(player);
                }
            }
            player.sync_score();
            player.instruct(levels.greeting(player.account.level, "") != "");
            player.greet(levels);

            if (team_hud) {
                update_hud_teams(player);
            } else {
                if (count() <= 2 || player.score > second_score) {
                    update_best();
                    update_hud();
                }
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

    void fix_health() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.state() >= CS_SPAWNED) {
                cEntity @ent = player.client.getEnt();
                if (ent.team != TEAM_SPECTATOR && ent.health > ent.maxHealth)
                    ent.health -= (frameTime * 0.001f);
            }
        }
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

    void shuffle() {
        int[] total;
        int total_size = 0;
        total.resize(size);

        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null) {
                if (player.client.team == TEAM_ALPHA
                        || player.client.team == TEAM_BETA)
                    total[total_size++] = i;
            }
        }

        int count_alpha = 0;
        int count_beta = 0;
        for (int i = 0; i < total_size; i++) {
            Player @player = get(i);
            bool equal = count_alpha == count_beta;
            if (count_alpha == total_size / 2 && !equal) {
                player.put_team(TEAM_BETA);
                count_beta++;
            } else if (count_beta == total_size / 2 && !equal) {
                player.put_team(TEAM_ALPHA);
                count_alpha++;
            } else if (brandom(0, 2) < 1) {
                player.put_team(TEAM_ALPHA);
                count_alpha++;
            } else {
                player.put_team(TEAM_BETA);
                count_beta++;
            }
        }
    }

    void dummy_killed(int id, cClient @attacker, cClient @inflictor) {
        pain_sound(attacker, sound_dummy_killed);
        killed_anyway(null, attacker, inflictor);
        Dummy @dummy = dummies.get(id);
        dummy.die();
    }
}
