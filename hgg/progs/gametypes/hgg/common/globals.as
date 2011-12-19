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

const int DB_VERSION = 0;

const int SPECIAL_ROW = 5;
const int INFINITE_AMMO = 99;
const int HEAVY_AMMO = 7;

const cString S_COLOR_ITEM_AWARD = S_COLOR_GREEN;
const cString S_COLOR_ACHIEVEMENT = S_COLOR_YELLOW;
const cString S_COLOR_ROW = S_COLOR_ORANGE;
const cString S_COLOR_BAD = S_COLOR_RED;
const cString S_COLOR_RESET = S_COLOR_WHITE;
const cString S_COLOR_PERSISTENT = S_COLOR_RESET;
const cString S_COLOR_NOT_PERSISTENT = S_COLOR_GREY;

const int MAX_DB_ITEMS = 2048;

const cString CVAR_BASE = "g_hgg_";

const cString CONFIGS_DIR = "configs/server/gametypes/";

enum hgg_cvars_e {
    CV_MOTD,
    CV_TOTAL
};

enum hgg_gametype_e {
    GT_FFA,
    GT_CA
};

enum hgg_dbitem_states_e {
    DBI_UNKNOWN,
    DBI_WRONG_IP,
    DBI_IDENTIFIED
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

void charge_gunblades() {
    for (int i = 0; i < maxClients; i++) {
        cEntity @ent = @G_GetClient(i).getEnt();
        if (ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR)
            GENERIC_ChargeGunblade(ent.client);
    }
}

bool is_vowel(cString character) {
    character = character.substr(0,1).tolower();
    return character == "a" || character == "e" || character == "o"
        || character == "i" || character == "u";
}

cString @raw(cString &str) {
    return str.removeColorTokens().tolower();
}

cString get_ip(cClient @client) {
    return ""; // TODO
}

void give_weapon(cClient @client, int weapon, int ammo) {
    client.inventoryGiveItem(weapon);

    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    cItem @weak_ammo_item = G_GetItem(item.weakAmmoTag);

    if (ammo == 0) {
        client.inventorySetCount(ammo_item.tag,
                (weapon == WEAP_GUNBLADE ? 4 : INFINITE_AMMO));
        client.inventorySetCount(weak_ammo_item.tag, 0);
    }
    else{
        client.inventorySetCount(ammo_item.tag, ammo);
        client.inventorySetCount(weak_ammo_item.tag,
                (weapon == WEAP_GUNBLADE ? INFINITE_AMMO : 0));
    }
}

void show_award(cClient @client, cString &msg) {
    client.addAward(S_COLOR_ITEM_AWARD + msg);
}

void show_item_award(cClient @client, int tag) {
    cItem @item = G_GetItem(tag);
    cString name = item.getName().tolower();
    show_award(client, "You've got a" + (is_vowel(item.getShortName()) ? "n"
                : "") + " " + name + "!");
}

void award_weapon(cClient @client, int weapon, int ammo, bool show) {
    give_weapon(client, weapon, ammo);
    if (show)
        show_item_award(client, weapon);
}

void award_weapon(cClient @client, int weapon, int ammo) {
    award_weapon(client, weapon, ammo, true);
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

void say(cClient @client, cString &msg) {
    client.printMessage(msg + "\n");
}

void debug(cString &msg) {
    G_Print(msg + "\n");
}
