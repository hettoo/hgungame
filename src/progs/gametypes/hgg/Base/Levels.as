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

enum LevelTypes {
    LEVEL_GUEST,
    LEVEL_REGULAR_USER,
    LEVEL_MEMBER,
    LEVEL_VIP,
    LEVEL_ADMIN,
    LEVEL_ROOT
};

class Levels {
    int iconGuest;
    int iconRegularUser;
    int iconMember;
    int iconVip;
    int iconAdmin;
    int iconRoot;

    Levels() {
        iconGuest = G_ImageIndex("gfx/hud/icons/backpack/spawnbp");
        iconRegularUser = G_ImageIndex("gfx/hud/icons/backpack/electrobotbp");
        iconMember = G_ImageIndex("gfx/hud/icons/backpack/grenadebp");
        iconVip = G_ImageIndex("gfx/hud/icons/backpack/rocketbp");
        iconAdmin = G_ImageIndex("gfx/hud/icons/backpack/plasmabp");
        iconRoot = G_ImageIndex("gfx/hud/icons/backpack/riotbp");
    }

    const String @name(int level) {
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

    const String @greeting(int level, const String @player) {
        switch (level) {
            case LEVEL_REGULAR_USER:
                return S_COLOR_SPECIAL + "Welcome " + highlight(name(level))
                    + " " + player + S_COLOR_SPECIAL + "!";
            case LEVEL_MEMBER:
                return S_COLOR_SPECIAL + "All welcome " + highlight(name(level))
                    + " " + player + S_COLOR_SPECIAL + " to the game!";
            case LEVEL_VIP:
                return S_COLOR_SPECIAL + "Ohohhh! " + highlight(name(level))
                    + " " + player + S_COLOR_SPECIAL + " entered the game!";
            case LEVEL_ADMIN:
                return S_COLOR_SPECIAL + "Stand up! " + highlight(name(level))
                    + " " + player + S_COLOR_SPECIAL + " entered the game!";
            case LEVEL_ROOT:
                return S_COLOR_SPECIAL + "Attention! " + highlight(name(level))
                    + " " + player + S_COLOR_SPECIAL + " entered the game!";
        }
        return "";
    }

    int icon(int level) {
        switch (level) {
            case LEVEL_GUEST:
                return iconGuest;
            case LEVEL_REGULAR_USER:
                return iconRegularUser;
            case LEVEL_MEMBER:
                return iconMember;
            case LEVEL_VIP:
                return iconVip;
            case LEVEL_ADMIN:
                return iconAdmin;
            case LEVEL_ROOT:
                return iconRoot;
        }
        return 0;
    }
}
