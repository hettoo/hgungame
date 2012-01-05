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

class Icons {
    int yes;
    int no;

    int instagun;
    int electro;
    int grenade;
    int rocket;
    int plasma;
    int laser;
    int machinegun;
    int riot;
    int gunblade;
    int max;

    int guest;
    int member;
    int vip;
    int admin;
    int root;

    Icons() {
        yes = G_ImageIndex("gfx/hud/icons/vsay/yes");
        no = G_ImageIndex("gfx/hud/icons/vsay/no");

        instagun = G_ImageIndex("gfx/hud/icons/weapon/instagun");
        electro = G_ImageIndex("gfx/hud/icons/weapon/electro");
        grenade = G_ImageIndex("gfx/hud/icons/weapon/grenade");
        rocket = G_ImageIndex("gfx/hud/icons/weapon/rocket");
        plasma = G_ImageIndex("gfx/hud/icons/weapon/plasma");
        laser = G_ImageIndex("gfx/hud/icons/weapon/laser");
        machinegun = G_ImageIndex("gfx/hud/icons/weapon/machinegun");
        riot = G_ImageIndex("gfx/hud/icons/weapon/riot");
        gunblade = G_ImageIndex("gfx/hud/icons/weapon/gunblade");
        max = G_ImageIndex("gfx/hud/icons/powerup/quad");

        guest = G_ImageIndex("gfx/hud/icons/health/5");
        member = G_ImageIndex("gfx/hud/icons/health/25");
        vip = G_ImageIndex("gfx/hud/icons/health/50");
        admin = G_ImageIndex("gfx/hud/icons/health/100");
        root = G_ImageIndex("gfx/hud/icons/health/100ultra");
    }

    int weapon(int weapon) {
        switch (weapon) {
            case WEAP_NONE:
                return gametype.isInstagib() ? instagun : gunblade;
            case WEAP_INSTAGUN:
                return instagun;
            case WEAP_ELECTROBOLT:
                return electro;
            case WEAP_GRENADELAUNCHER:
                return grenade;
            case WEAP_ROCKETLAUNCHER:
                return rocket;
            case WEAP_PLASMAGUN:
                return plasma;
            case WEAP_LASERGUN:
                return laser;
            case WEAP_MACHINEGUN:
                return machinegun;
            case WEAP_RIOTGUN:
                return riot;
            case WEAP_GUNBLADE:
                return gunblade;
            case WEAP_TOTAL:
                return max;
        }
        return no;
    }
}
