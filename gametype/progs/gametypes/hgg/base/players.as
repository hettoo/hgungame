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

const int EXP_AWARD_GREEN = 2;
const int EXP_AWARD_ORANGE = EXP_AWARD_GREEN;
const int EXP_AWARD_YELLOW = 4;
const int EXP_AWARD_BLUE = 6;
const int EXP_WEAK = 10;

class Players {
    Player[] players;
    int max;
    DB db;
    Ranks ranks;
    Weapons weapons;

    int best_score;
    int second_score;

    Players() {
        players.resize(maxClients);
        max = -1;

        best_score = -1;
        second_score = -1;
    }

    void init() {
        db.init();
        db.read();
    }

    Player @get(int playernum) {
        if (playernum < 0 || playernum > max)
            return null;
        return players[playernum];
    }

    void init_client(cClient @client) {
        int playernum = client.playerNum();
        if (playernum > max)
            max = playernum;
        get(playernum).init(client, db);
    }

    void welcome_all(cString &msg) {
        for (int i = 0; i <= max; i++)
            get(i).welcome(msg);
    }

    void reset() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            check_row(player.client, null);
            player.minutes_played = 0;
            player.set_score(0);
        }
    }

    void announce_row(cClient @target, cClient @attacker) {
        int row = get(target.playerNum()).row;
        target.addAward(S_COLOR_ACHIEVEMENT + "You made a row of " + S_COLOR_ROW
                + row + S_COLOR_ACHIEVEMENT + "!");
        cString msg = target.getName() + S_COLOR_ACHIEVEMENT + " made a row of "
            + S_COLOR_ROW + row + S_COLOR_ACHIEVEMENT + "!";
        if (@target == @attacker)
            msg += " He killed " + S_COLOR_BAD + "himself"
                + S_COLOR_ACHIEVEMENT + "!";
        else if (@attacker != null)
            msg += " He was killed by " + S_COLOR_RESET + attacker.getName()
                + S_COLOR_ACHIEVEMENT + "!";
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

    void award(cClient @client, int row, bool show, int weapon) {
        Player @player = get(client.playerNum());
        player.add_score(1);
        player.add_exp(row);

        player.update_hud_self();
        update_best(client.playerNum());
        if (player.score == best_score)
            update_hud();
        else if (player.score == second_score)
            update_hud_bests();

        int award = weapons.award(row);
        if (award == WEAP_NONE)
            return;

        if (award < WEAP_TOTAL)
            award_weapon(client, award, weapons.ammo(award), show);
        else
            get(client.playerNum()).show_row();

        if (weapons.weak(weapon)) {
            int award;
            for (int i = 0; i <= player.row
                    && (award = weapons.award(i)) != WEAP_TOTAL; i++) {
                if (weapons.heavy(award))
                    increase_ammo(client, award);
            }
            player.add_exp(EXP_WEAK);
        }
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
    }

    void killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        Player @player = get(target.playerNum());
        player.say("** You have been killed by " + attacker.getName());
        player.killed();
        check_row(target, attacker);

        killed_anyway(target, attacker, inflictor);
    }

    void exp_for_award(cClient @client, cString &award) {
        Player @player = get(client.playerNum());
        cString color = award.substr(0, 2);
        if (color == S_COLOR_GREEN)
            player.add_exp(EXP_AWARD_GREEN);
        else if (color == S_COLOR_ORANGE)
            player.add_exp(EXP_AWARD_ORANGE);
        else if (color == S_COLOR_YELLOW)
            player.add_exp(EXP_AWARD_YELLOW);
        else if (color == S_COLOR_BLUE)
            player.add_exp(EXP_AWARD_BLUE);
    }

    void check_decrease_ammo(cClient @client, int weapon) {
        if (weapon < WEAP_TOTAL && weapons.ammo(weapon) > 0) {
            if (!decrease_ammo(client, weapon) && client.weapon == weapon)
                weapons.select_best(client);
        }
    }

    void give_spawn_weapons(cClient @client) {
        weapons.give_default(client);
        for (int i = 1; i <= get(client.playerNum()).row; i++)
            award(client, i, false, WEAP_NONE);
        // FIXME: should we store those weapons? :-(
    }

    void respawn(cClient @client) {
        Player @player = get(client.playerNum());
        player.update_hud_self();
        player.update_hud_other(this);
        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
        if (!gametype.isInstagib())
            client.getEnt().health = NW_HEALTH;
    }

    void increase_minutes() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            if (@player.client != null && player.client.team != TEAM_SPECTATOR)
                player.add_minute();
        }
    }

    void update_best(int i) {
        Player @player = get(i);
        cClient @client = player.client;
        if (@client != null && client.team != TEAM_SPECTATOR) {
            if (player.score > best_score || best_score == UNKNOWN)
                best_score = player.score;
            else if (player.score > second_score || second_score == UNKNOWN)
                second_score = player.score;
        }
    }

    void update_best() {
        best_score = UNKNOWN;
        second_score = UNKNOWN;
        for (int i = 0; i <= max; i++)
            update_best(i);
    }

    void update_hud() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            player.update_hud_other(this);
        }
    }

    void update_hud_bests() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            if (player.score == best_score)
                player.update_hud_other(this);
        }
    }

    void new_player(cClient @client) {
        Player @player = get(client.playerNum());
        if (player.ip_check()) {
            player.sync_score();
            if (count() <= 2 || player.score > second_score) {
                update_best();
                update_hud();
            }
        }
    }

    void new_spectator(cClient @client) {
        Player @player = get(client.playerNum());
        check_row(client, null);
        if (player.score == best_score || player.score == second_score) {
            update_best();
            update_hud();
        }
    }

    void namechange(cClient @client) {
        init_client(client);
        Player @player = get(client.playerNum());
        player.ip_check();
    }

    void charge_gunblades() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            if (@player.client != null && player.client.state() >= CS_SPAWNED
                    && player.client.getEnt().team != TEAM_SPECTATOR)
                GENERIC_ChargeGunblade(player.client);
        }
    }

    int count() {
        int n = 0;
        for (int i = 0; i <= max; i++) {
            cClient @client = get(i).client;
            if (@client != null && client.team != TEAM_SPECTATOR)
                n++;
        }
        return n;
    }
}
