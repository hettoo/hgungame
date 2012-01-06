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

class Weapons {
    Weapons() {
    }

    /*
     * Returns the weapon to be rewarded after exactly the given amount of
     * frags. Returns WEAP_NONE if no weapons should be rewarded yet, or
     * WEAP_TOTAL if all weapons should have been rewarded already.
     */
    int award(int frags) {
        switch (frags) {
            case 0:
                return WEAP_NONE;
            case 1:
                return WEAP_ELECTROBOLT;
            case 2:
                return WEAP_GRENADELAUNCHER;
            case 3:
                return WEAP_ROCKETLAUNCHER;
            case 4:
                return WEAP_PLASMAGUN;
            case 5:
                return WEAP_LASERGUN;
            case 6:
                return WEAP_MACHINEGUN;
            case 7:
                return WEAP_RIOTGUN;
            case 8:
                return gametype.isInstagib() ? WEAP_GUNBLADE : WEAP_TOTAL;
        }

        return WEAP_TOTAL;
    }

    void select_best(cClient @client) {
        int best = WEAP_INSTAGUN;
        if (client.canSelectWeapon(WEAP_GUNBLADE))
            best = WEAP_GUNBLADE;

        int weapon;
        for (int i = 0; (weapon = award(i)) != WEAP_TOTAL; i++) {
            if (weapon != WEAP_NONE && weapon != WEAP_GUNBLADE
                    && client.canSelectWeapon(weapon))
                best = weapon;
        }
        client.selectWeapon(best);
    }

    void give_default(cClient @client) {
        if (gametype.isInstagib())
            give_weapon(client, WEAP_INSTAGUN, 0);
        else
            give_weapon(client, WEAP_GUNBLADE, 0);
    }

    bool heavy_weapon(int weapon) {
        return weapon == WEAP_MACHINEGUN || weapon == WEAP_RIOTGUN;
    }

    int ammo(int weapon) {
        return heavy_weapon(weapon) ? HEAVY_AMMO : 0;
    }
}
