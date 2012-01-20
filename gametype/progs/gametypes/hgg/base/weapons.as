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

const int INFINITE_AMMO = 99;
const int HEAVY_AMMO = 6;

class Weapons {
    int icon_instagun;
    int icon_electro;
    int icon_grenade;
    int icon_rocket;
    int icon_plasma;
    int icon_laser;
    int icon_machinegun;
    int icon_riot;
    int icon_gunblade;
    int icon_max;

    Weapons() {
        icon_instagun = G_ImageIndex("gfx/hud/icons/weapon/instagun");
        icon_electro = G_ImageIndex("gfx/hud/icons/weapon/electro");
        icon_grenade = G_ImageIndex("gfx/hud/icons/weapon/grenade");
        icon_rocket = G_ImageIndex("gfx/hud/icons/weapon/rocket");
        icon_plasma = G_ImageIndex("gfx/hud/icons/weapon/plasma");
        icon_laser = G_ImageIndex("gfx/hud/icons/weapon/laser");
        icon_machinegun = G_ImageIndex("gfx/hud/icons/weapon/machinegun");
        icon_riot = G_ImageIndex("gfx/hud/icons/weapon/riot");
        icon_gunblade = G_ImageIndex("gfx/hud/icons/weapon/gunblade");
        icon_max = G_ImageIndex("gfx/hud/icons/powerup/quad");
    }

    int icon(int weapon) {
        switch (weapon) {
            case WEAP_NONE:
                return gametype.isInstagib() ? icon_instagun : icon_gunblade;
            case WEAP_INSTAGUN:
                return icon_instagun;
            case WEAP_GUNBLADE:
                return icon_gunblade;
            case WEAP_ELECTROBOLT:
                return icon_electro;
            case WEAP_GRENADELAUNCHER:
                return icon_grenade;
            case WEAP_ROCKETLAUNCHER:
                return icon_rocket;
            case WEAP_PLASMAGUN:
                return icon_plasma;
            case WEAP_LASERGUN:
                return icon_laser;
            case WEAP_MACHINEGUN:
                return icon_machinegun;
            case WEAP_RIOTGUN:
                return icon_riot;
            case WEAP_TOTAL:
                return icon_max;
        }
        return 0;
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
        }

        return WEAP_TOTAL;
    }

    void select_best(cClient @client) {
        int best = gametype.isInstagib() ? WEAP_INSTAGUN : WEAP_GUNBLADE;

        int weapon;
        for (int i = 0; (weapon = award(i)) != WEAP_TOTAL; i++) {
            if (weapon != WEAP_NONE && client.canSelectWeapon(weapon))
                best = weapon;
        }
        client.selectWeapon(best);
    }

    void give_default(cClient @client) {
        if (gametype.isInstagib())
            give_weapon(client, WEAP_INSTAGUN, INFINITY);
        else
            give_weapon(client, WEAP_GUNBLADE, INFINITY);
    }

    bool heavy(int weapon) {
        return weapon == WEAP_MACHINEGUN || weapon == WEAP_RIOTGUN;
    }

    bool weak(int weapon) {
        return weapon == WEAP_INSTAGUN || weapon == WEAP_ELECTROBOLT
            || weapon == WEAP_GUNBLADE;
    }

    int ammo(int weapon) {
        return heavy(weapon) ? HEAVY_AMMO : INFINITY;
    }
}
