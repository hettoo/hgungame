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

enum LevelTypes {
    LEVEL_GUEST,
    LEVEL_REGULAR_USER,
    LEVEL_MEMBER,
    LEVEL_VIP,
    LEVEL_ADMIN,
    LEVEL_ROOT
};

class Levels {
    int icon_guest;
    int icon_regular_user;
    int icon_member;
    int icon_vip;
    int icon_admin;
    int icon_root;

    Levels() {
        icon_guest = G_ImageIndex("gfx/hud/icons/backpack/spawnbp");
        icon_regular_user = G_ImageIndex("gfx/hud/icons/backpack/electrobotbp");
        icon_member = G_ImageIndex("gfx/hud/icons/backpack/grenadebp");
        icon_vip = G_ImageIndex("gfx/hud/icons/backpack/rocketbp");
        icon_admin = G_ImageIndex("gfx/hud/icons/backpack/plasmabp");
        icon_root = G_ImageIndex("gfx/hud/icons/backpack/riotbp");
    }

    cString @name(int level) {
        switch (level) {
            case LEVEL_GUEST:
                return "Guest";
            case LEVEL_REGULAR_USER:
                return "Regular User";
            case LEVEL_MEMBER:
                return "Member";
            case LEVEL_VIP:
                return "VIP";
            case LEVEL_ADMIN:
                return "Admin";
            case LEVEL_ROOT:
                return "Root";
        }
        return "?";
    }

    int icon(int level) {
        switch (level) {
            case LEVEL_GUEST:
                return icon_guest;
            case LEVEL_REGULAR_USER:
                return icon_regular_user;
            case LEVEL_MEMBER:
                return icon_member;
            case LEVEL_VIP:
                return icon_vip;
            case LEVEL_ADMIN:
                return icon_admin;
            case LEVEL_ROOT:
                return icon_root;
        }
        return 0;
    }
}
