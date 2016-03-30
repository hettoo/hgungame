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

const int INFINITE_AMMO = 99;
const int HEAVY_AMMO = 6;

class Weapons {
    int iconInstagun;
    int iconElectro;
    int iconGrenade;
    int iconRocket;
    int iconPlasma;
    int iconLaser;
    int iconMachinegun;
    int iconRiot;
    int iconGunblade;
    int iconMax;

    Weapons() {
        iconInstagun = G_ImageIndex("gfx/hud/icons/weapon/instagun");
        iconElectro = G_ImageIndex("gfx/hud/icons/weapon/electro");
        iconGrenade = G_ImageIndex("gfx/hud/icons/weapon/grenade");
        iconRocket = G_ImageIndex("gfx/hud/icons/weapon/rocket");
        iconPlasma = G_ImageIndex("gfx/hud/icons/weapon/plasma");
        iconLaser = G_ImageIndex("gfx/hud/icons/weapon/laser");
        iconMachinegun = G_ImageIndex("gfx/hud/icons/weapon/machinegun");
        iconRiot = G_ImageIndex("gfx/hud/icons/weapon/riot");
        iconGunblade = G_ImageIndex("gfx/hud/icons/weapon/gunblade");
        iconMax = G_ImageIndex("gfx/hud/icons/powerup/quad");
    }

    int icon(int weapon) {
        switch (weapon) {
            case WEAP_NONE:
                return gametype.get_isInstagib() ? iconInstagun : iconGunblade;
            case WEAP_INSTAGUN:
                return iconInstagun;
            case WEAP_GUNBLADE:
                return iconGunblade;
            case WEAP_ELECTROBOLT:
                return iconElectro;
            case WEAP_GRENADELAUNCHER:
                return iconGrenade;
            case WEAP_ROCKETLAUNCHER:
                return iconRocket;
            case WEAP_PLASMAGUN:
                return iconPlasma;
            case WEAP_LASERGUN:
                return iconLaser;
            case WEAP_MACHINEGUN:
                return iconMachinegun;
            case WEAP_RIOTGUN:
                return iconRiot;
            case WEAP_TOTAL:
                return iconMax;
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

    void selectBest(Client @client) {
        int best = gametype.get_isInstagib() ? WEAP_INSTAGUN : WEAP_GUNBLADE;

        int weapon;
        for (int i = 0; (weapon = award(i)) != WEAP_TOTAL; i++) {
            if (weapon != WEAP_NONE && client.canSelectWeapon(weapon))
                best = weapon;
        }
        client.selectWeapon(best);
    }

    void giveDefault(Client @client) {
        if (gametype.get_isInstagib())
            giveWeapon(client, WEAP_INSTAGUN, INFINITY);
        else
            giveWeapon(client, WEAP_GUNBLADE, INFINITY);
    }

    bool heavy(int weapon) {
        return gametype.get_isInstagib()
            && (weapon == WEAP_MACHINEGUN || weapon == WEAP_RIOTGUN);
    }

    bool weak(int weapon) {
        return gametype.get_isInstagib()
            && (weapon == WEAP_INSTAGUN || weapon == WEAP_ELECTROBOLT
                    || weapon == WEAP_GUNBLADE);
    }

    int ammo(int weapon) {
        return heavy(weapon) ? HEAVY_AMMO : INFINITY;
    }
}
