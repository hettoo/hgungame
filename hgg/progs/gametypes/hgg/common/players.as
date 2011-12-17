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

class Players {
    int max;
    Player[] players;
    Weapons weapons;

    Players() {
        max = 0;
        players.resize(maxClients);
    }

    Player @get(int playernum) {
        return players[playernum];
    }

    void init(cClient @client){
        int playernum = client.playerNum();
        get(playernum).init(client);
        if(playernum > max)
            max = playernum;
    }

    void welcome_all(cString &msg) {
        for (int i = 0; i <= max; i++)
            get(i).welcome(msg);
    }

    void reset_rows() {
        for (int i = 0; i <= max; i++)
            get(i).row = 0;
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
        if (get(target.playerNum()).row >= SPECIAL_ROW)
            announce_row(target, attacker);
        get(target.playerNum()).row = 0;
    }

    void award(cClient @client, int row) {
        client.stats.addScore(1);
        int weapon = weapons.award(row);
        if (weapon == WEAP_NONE)
            return;

        if (weapon < WEAP_TOTAL)
            award_weapon(client, weapon, weapons.ammo(weapon));
        else
            get(client.playerNum()).show_row();
    }

    void award(cClient @client) {
        award(client, get(client.playerNum()).row);
    }

    void killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        say(target, "** You have been killed by " + attacker.getName());
        check_row(target, attacker);

        if (@attacker == null || @attacker == @target)
            return;

        players[attacker.playerNum()].row++;
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
    }

    void respawn(cClient @client) {
        give_spawn_weapons(client);
        weapons.select_best(client);
        client.getEnt().respawnEffect();
    }

}
