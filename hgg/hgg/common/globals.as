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

HGG hgg;

const int SPECIAL_ROW = 5;
const int INFINITE_AMMO = 99;
const int HEAVY_AMMO = 7;

const cString S_COLOR_ITEM_AWARD = S_COLOR_GREEN;
const cString S_COLOR_ACHIEVEMENT = S_COLOR_YELLOW;
const cString S_COLOR_ROW = S_COLOR_ORANGE;
const cString S_COLOR_BAD = S_COLOR_RED;
const cString S_COLOR_RESET = S_COLOR_WHITE;

const cString CVAR_BASE = "g_hgg_";

enum hgg_cvars_e {
    CV_MOTD,
    CV_TOTAL
};

enum hgg_gametype_e {
    GT_FFA,
    GT_CA
};

void string_add_maxed(cString &string, cString &addition, int max) {
    if (string.len() + addition.len() <= max)
        string += addition;
}

void set_spawn_system(int spawn_system) {
    for (int team = 0; team < GS_MAX_TEAMS; team++) {
        if (team != TEAM_SPECTATOR)
            gametype.setTeamSpawnsystem(team, spawn_system, 0, 0, false);
    }
}

bool is_vowel(cString character) {
    character = character.substr(0,1).tolower();
    return character == "a" || character == "e" || character == "o" || character == "i" || character == "u";
}

void give_weapon(cClient @client, int weapon, int ammo) {
    client.inventoryGiveItem(weapon);

    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    cItem @weak_ammo_item = G_GetItem(item.weakAmmoTag);

    if (ammo == 0) {
        client.inventorySetCount(ammo_item.tag, (weapon == WEAP_GUNBLADE ? 4 : INFINITE_AMMO));
        client.inventorySetCount(weak_ammo_item.tag, 0);
    }
    else{
        client.inventorySetCount(ammo_item.tag, ammo);
        client.inventorySetCount(weak_ammo_item.tag, (weapon == WEAP_GUNBLADE ? INFINITE_AMMO : 0));
    }
}

void show_item_award(cClient @client, int tag) {
    cItem @item = G_GetItem(tag);
    cString name = item.getName().tolower();
    client.addAward(S_COLOR_ITEM_AWARD + "You've got a" + (is_vowel(item.getShortName()) ? "n" : "") + " " + name + "!");
}

void award_weapon(cClient @client, int weapon, int ammo) {
    give_weapon(client, weapon, ammo);
    show_item_award(client, weapon);
}

bool decrease_ammo(cClient @client, int weapon) {
    if(weapon == WEAP_NONE)
        return false;

    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    int ammo = client.inventoryCount(ammo_item.tag) - 1;
    if (ammo >= 0) {
        client.inventorySetCount(ammo_item.tag, ammo);
        if (ammo > 0)
            return true;
    }
    return false;
}

void notify(cString &msg) {
    G_PrintMsg(null, msg + "\n");
}
