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

const cString NAME = "hGunGame";
const cString VERSION = "0.1-dev";
const cString AUTHOR = "^0<].^7h^2e^9tt^2o^7o^0.[>^7";

const int NW_HEALTH = 30;

const cString S_COLOR_ITEM_AWARD = S_COLOR_GREEN;
const cString S_COLOR_ROW = S_COLOR_ORANGE;
const cString S_COLOR_BAD = S_COLOR_RED;
const cString S_COLOR_RESET = S_COLOR_WHITE;
const cString S_COLOR_PERSISTENT = S_COLOR_RESET;
const cString S_COLOR_TEMPORARY = S_COLOR_GREY;
const cString S_COLOR_ADMINISTRATIVE = S_COLOR_CYAN;
const cString S_COLOR_HIGHLIGHT = S_COLOR_YELLOW;
const cString S_COLOR_HIGHLIGHT_ROW = S_COLOR_RED;
const cString S_COLOR_DESCRIPTION = S_COLOR_GREY;
const cString S_COLOR_PM = S_COLOR_GREEN;
const cString S_COLOR_SPECIAL = S_COLOR_ORANGE;

const cString INDENT = "    ";

const float ATTN_UNHEARABLE = 999f;

const cString DATA_DIR = "gtdata/";

const int UNKNOWN = -1;
const int INFINITY = -1;

void string_add_maxed(cString &string, cString &addition, int max) {
    if (string.len() + addition.len() <= max)
        string += addition;
}

bool is_vowel(cString character) {
    character = character.substr(0, 1).tolower();
    return character == "a" || character == "e" || character == "o"
        || character == "i" || character == "u";
}

cString @raw(cString &str) {
    return str.removeColorTokens().tolower();
}

cString get_ip(cClient @client) {
    cString ip = client.getUserInfoKey("ip");
    ip = ip.substr(0, ip.locate(":", 0));
    return ip;
}

void give_weapon(cClient @client, int weapon, int ammo) {
    client.inventoryGiveItem(weapon);

    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    cItem @weak_ammo_item = G_GetItem(item.weakAmmoTag);

    if (ammo == INFINITY) {
        client.inventorySetCount(ammo_item.tag,
                (weapon == WEAP_GUNBLADE ? 4 : INFINITE_AMMO));
        client.inventorySetCount(weak_ammo_item.tag, 0);
    } else {
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

int ammo(cClient @client, int weapon) {
    if (weapon == WEAP_NONE)
        return INFINITY;
    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    return client.inventoryCount(ammo_item.tag);
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

bool increase_ammo(cClient @client, int weapon) {
    if(weapon == WEAP_NONE)
        return false;

    cItem @item = G_GetItem(weapon);
    cItem @ammo_item = G_GetItem(item.ammoTag);
    int ammo = client.inventoryCount(ammo_item.tag) + 1;
    client.inventorySetCount(ammo_item.tag, ammo);

    return true;
}

bool for_real() {
    return match.getState() == MATCH_STATE_PLAYTIME;
}

int other_team(int team) {
    return team == TEAM_ALPHA ? TEAM_BETA : TEAM_ALPHA;
}

cString @fixed_field(cString &text, int size) {
    cString field;
    cString replacement = "..";
    int real_size = 0;
    int no_color_size = 0;
    bool stopped = false;
    cString backup_field = "";
    int backup_size = 0;
    while (real_size < text.len()) {
        if (no_color_size == size) {
            field = backup_field + S_COLOR_RESET + replacement;
            break;
        } else {
            cString next = text.substr(real_size, 1);
            field += next;

            if (next == "^")
                no_color_size--;
            else
                no_color_size++;

            real_size++;
            while (backup_field.removeColorTokens().len()
                    < no_color_size - replacement.removeColorTokens().len()) {
                backup_field += field.substr(backup_size, 1);
                backup_size++;
            }
        }
    }
    while (no_color_size < size) {
        field += " ";
        no_color_size++;
    }
    field += " ";
    return field;
}

void lock_teams() {
    for (int team = 0; team < GS_MAX_TEAMS; team++) {
        if (team != TEAM_SPECTATOR)
            G_GetTeam(team).lock();
    }
}

cString @wrap(cString &s) {
    return "\n" + s + "\n";
}

cString @fixed_field(int n, int size) {
    return fixed_field(n + "", size);
}

cString @highlight(cString &s) {
    return S_COLOR_HIGHLIGHT + s + S_COLOR_RESET;
}

cString @highlight_row(int row) {
    return S_COLOR_HIGHLIGHT_ROW + row + S_COLOR_HIGHLIGHT;
}

void notify(cString &msg) {
    G_PrintMsg(null, msg + "\n");
}

void center_notify(cString &msg) {
    G_CenterPrintMsg(null, msg + "\n");
}

void debug(cString &msg) {
    G_Print(msg + "\n");
}

void random_announcer_sound(int team, cString &sound) {
    G_AnnouncerSound(null, G_SoundIndex(sound + int(brandom(1, 2))), team,
            false, null);
}

void random_announcer_sound(cString &sound) {
    random_announcer_sound(GS_MAX_TEAMS, sound);
}

void sound(cClient @client, int sound, int channel) {
    G_Sound(client.getEnt(), channel, sound, ATTN_UNHEARABLE);
}

void voice(cClient @client, int sound) {
    sound(client, sound, CHAN_VOICE);
}

void pain_sound(cClient @client, int sound) {
    sound(client, sound, CHAN_PAIN);
}

void exec(cString &cmd){
    G_CmdExecute(cmd + "\n");
}

void exec(cString &cmd, cString &arg) {
    exec(cmd + " \"" + arg + "\"");
}
