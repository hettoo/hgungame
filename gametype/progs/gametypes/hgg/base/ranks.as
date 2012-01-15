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

enum RankTypes {
    RANK_GUEST,
    RANK_REGULAR_USER,
    RANK_MEMBER,
    RANK_VIP,
    RANK_ADMIN,
    RANK_ROOT
};

class Ranks {
    int icon_guest;
    int icon_regular_user;
    int icon_member;
    int icon_vip;
    int icon_admin;
    int icon_root;

    Ranks() {
        icon_guest = G_ImageIndex("gfx/hud/icons/backpack/spawnbp");
        icon_regular_user = G_ImageIndex("gfx/hud/icons/backpack/electrobotbp");
        icon_member = G_ImageIndex("gfx/hud/icons/backpack/grenadebp");
        icon_vip = G_ImageIndex("gfx/hud/icons/backpack/rocketbp");
        icon_admin = G_ImageIndex("gfx/hud/icons/backpack/plasmabp");
        icon_root = G_ImageIndex("gfx/hud/icons/backpack/riotbp");
    }

    cString @name(int rank) {
        switch (rank) {
            case RANK_GUEST:
                return "Guest";
            case RANK_REGULAR_USER:
                return "Regular User";
            case RANK_MEMBER:
                return "Member";
            case RANK_VIP:
                return "VIP";
            case RANK_ADMIN:
                return "Admin";
            case RANK_ROOT:
                return "Root";
        }
        return "?";
    }

    int icon(int rank) {
        switch (rank) {
            case RANK_GUEST:
                return icon_guest;
            case RANK_REGULAR_USER:
                return icon_regular_user;
            case RANK_MEMBER:
                return icon_member;
            case RANK_VIP:
                return icon_vip;
            case RANK_ADMIN:
                return icon_admin;
            case RANK_ROOT:
                return icon_root;
        }
        return 0;
    }
}
