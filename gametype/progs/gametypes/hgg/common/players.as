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

const int SPECIAL_ROW = 5;

class Players {
    Player[] players;
    int max;
    DB db;
    Weapons weapons;

    uint last_time;

    Players() {
        players.resize(maxClients);
        max = -1;

        last_time = 0;
    }

    void init() {
        db.init();
        db.read();
    }

    Player @get(int playernum) {
        return players[playernum];
    }

    void init_client(cClient @client){
        int playernum = client.playerNum();
        get(playernum).init(client, db);
        if (playernum > max)
            max = playernum;
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

    void award(cClient @client, int row, bool show) {
        Player @player = get(client.playerNum());
        player.add_score(1);
        player.add_exp(row);
        int weapon = weapons.award(row);
        if (weapon == WEAP_NONE)
            return;

        if (weapon < WEAP_TOTAL)
            award_weapon(client, weapon, weapons.ammo(weapon), show);
        else
            get(client.playerNum()).show_row();
    }

    void award(cClient @client, int row) {
        award(client, row, true);
    }

    void award(cClient @client) {
        award(client, get(client.playerNum()).row);
    }

    void killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        say(target, "** You have been killed by " + attacker.getName());
        get(target.playerNum()).killed();
        check_row(target, attacker);

        if (@attacker == null || @attacker == @target)
            return;

        get(attacker.playerNum()).killer();
        award(attacker);
        check_decrease_ammo(attacker, attacker.weapon); // TODO: mod
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
            award(client, i, false);
    }

    void respawn(cClient @client) {
        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
    }

    void increase_minutes() {
        for (int i = 0; i <= max; i++) {
            Player @player = get(i);
            if (@player.client != null && player.client.team != TEAM_SPECTATOR)
                player.add_minute();
        }
    }

    void check_minute() {
        uint time = levelTime / 60000;
        if (time != last_time) {
            increase_minutes();
            last_time = time;
        }
    }

}
