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

const String NAME = "hGunGame";
const String VERSION = "0.1-dev";
const String AUTHOR = "^0<].^7h^2e^9tt^2o^7o^0.[>^7";

const int DATA_VERSION = 1;

const int NW_HEALTH = 20;
const int NW_HEALTH_BONUS = 10;
const int NW_ARMOR = 50;
const int NW_ARMOR_BONUS = 8;
const float MAX_ARMOR = 100.0;

const String S_COLOR_ITEM_AWARD = S_COLOR_GREEN;
const String S_COLOR_ROW = S_COLOR_ORANGE;
const String S_COLOR_BAD = S_COLOR_RED;
const String S_COLOR_RESET = S_COLOR_WHITE;
const String S_COLOR_PERSISTENT = S_COLOR_RESET;
const String S_COLOR_TEMPORARY = S_COLOR_GREY;
const String S_COLOR_ADMINISTRATIVE = S_COLOR_CYAN;
const String S_COLOR_HIGHLIGHT = S_COLOR_YELLOW;
const String S_COLOR_HIGHLIGHT_ROW = S_COLOR_RED;
const String S_COLOR_DESCRIPTION = S_COLOR_GREY;
const String S_COLOR_PM = S_COLOR_GREEN;
const String S_COLOR_SPECIAL = S_COLOR_ORANGE;
const String S_COLOR_RECORD = S_COLOR_GREEN;

const String COMMAND_BASE = "gt";

const String INDENT = "    ";

const float ATTN_UNHEARABLE = 999f;

const String DATA_DIR = "gtdata/";

const int UNKNOWN = -1;
const int INFINITY = -1;
const int END = -1;

String @dataFile(String &filename) {
    return DATA_DIR + gametype.getName() + "/"
        + (gametype.isInstagib() ? "insta" : "nw") + "/" + filename;
}

void stringAddMaxed(String &string, String &addition, int max) {
    if (string.len() + addition.len() <= max)
        string += addition;
}

bool isVowel(String character) {
    character = character.substr(0, 1).tolower();
    return character == "a" || character == "e" || character == "o"
        || character == "i" || character == "u";
}

String @clean(String &str) {
    return str.removeColorTokens().tolower();
}

String @removeAdditive(String &str) {
    if (str.substr(str.len() - 1, 1) == ")") {
        int i;
        String sub;
        for (i = str.len() - 2; (sub = str.substr(i, 1)) != "("; i--) {
            if (!sub.isNumerical())
                return str;
        }
        return str.substr(0, i);
    }
    return str;
}

String @raw(String &str) {
    return removeAdditive(clean(str));
}

String getIP(cClient @client) {
    String ip = client.getUserInfoKey("ip");
    ip = ip.substr(0, ip.locate(":", 0));
    return ip;
}

void giveWeapon(cClient @client, int weapon, int ammo) {
    client.inventoryGiveItem(weapon);

    cItem @item = G_GetItem(weapon);
    cItem @ammoItem = G_GetItem(item.ammoTag);
    cItem @weakAmmoItem = G_GetItem(item.weakAmmoTag);

    if (ammo == INFINITY) {
        client.inventorySetCount(ammoItem.tag,
                (weapon == WEAP_GUNBLADE ? 4 : INFINITE_AMMO));
        client.inventorySetCount(weakAmmoItem.tag, 0);
    } else {
        client.inventorySetCount(ammoItem.tag, ammo);
        client.inventorySetCount(weakAmmoItem.tag,
                (weapon == WEAP_GUNBLADE ? INFINITE_AMMO : 0));
    }
}

void showAward(cClient @client, String &msg) {
    client.addAward(S_COLOR_ITEM_AWARD + msg);
}

void showItemAward(cClient @client, int tag) {
    cItem @item = G_GetItem(tag);
    String name = item.getName().tolower();
    showAward(client, "You've got a" + (isVowel(item.getShortName()) ? "n"
                : "") + " " + name + "!");
}

void awardWeapon(cClient @client, int weapon, int ammo, bool show) {
    giveWeapon(client, weapon, ammo);
    if (show)
        showItemAward(client, weapon);
}

void awardWeapon(cClient @client, int weapon, int ammo) {
    awardWeapon(client, weapon, ammo, true);
}

int ammo(cClient @client, int weapon) {
    if (weapon == WEAP_NONE)
        return INFINITY;
    cItem @item = G_GetItem(weapon);
    cItem @ammoItem = G_GetItem(item.ammoTag);
    return client.inventoryCount(ammoItem.tag);
}

bool decreaseAmmo(cClient @client, int weapon) {
    if(weapon == WEAP_NONE)
        return false;

    cItem @item = G_GetItem(weapon);
    cItem @ammoItem = G_GetItem(item.ammoTag);
    int ammo = client.inventoryCount(ammoItem.tag) - 1;
    if (ammo >= 0) {
        client.inventorySetCount(ammoItem.tag, ammo);
        if (ammo > 0)
            return true;
    }

    return false;
}

bool increaseAmmo(cClient @client, int weapon) {
    if(weapon == WEAP_NONE)
        return false;

    cItem @item = G_GetItem(weapon);
    cItem @ammoItem = G_GetItem(item.ammoTag);
    int ammo = client.inventoryCount(ammoItem.tag) + 1;
    client.inventorySetCount(ammoItem.tag, ammo);

    return true;
}

bool forReal() {
    return match.getState() == MATCH_STATE_PLAYTIME;
}

int otherTeam(int team) {
    return team == TEAM_ALPHA ? TEAM_BETA : TEAM_ALPHA;
}

String @fixedField(String &text, int size) {
    String field;
    String replacement = "..";
    int realSize = 0;
    int noColorSize = 0;
    bool stopped = false;
    String backupField = "";
    int backupSize = 0;
    while (realSize < text.len()) {
        if (noColorSize == size) {
            field = backupField + S_COLOR_RESET + replacement;
            break;
        } else {
            String next = text.substr(realSize, 1);
            field += next;

            if (next == "^")
                noColorSize--;
            else
                noColorSize++;

            realSize++;
            while (backupField.removeColorTokens().len()
                    < noColorSize - replacement.removeColorTokens().len()) {
                backupField += field.substr(backupSize, 1);
                backupSize++;
            }
        }
    }
    while (noColorSize < size) {
        field += " ";
        noColorSize++;
    }
    field += " ";
    return field;
}

void lockTeams() {
    for (int team = 0; team < GS_MAX_TEAMS; team++) {
        if (team != TEAM_SPECTATOR)
            G_GetTeam(team).lock();
    }
}

String @wrap(String &s) {
    return "\n" + s + "\n";
}

String @fixedField(int n, int size) {
    return fixedField(n + "", size);
}

String @highlight(String &s) {
    return S_COLOR_HIGHLIGHT + s + S_COLOR_RESET;
}

String @highlight(int i) {
    return highlight(i + "");
}

String @highlightRow(int row) {
    return S_COLOR_HIGHLIGHT_ROW + row + S_COLOR_HIGHLIGHT;
}

void notify(String &msg) {
    if (msg != "")
        G_PrintMsg(null, msg + "\n");
}

void centerNotify(String &msg) {
    G_CenterPrintMsg(null, msg + "\n");
}

void debug(String &msg) {
    G_Print(msg + "\n");
}

void randomAnnouncerSound(int team, String &sound) {
    G_AnnouncerSound(null, G_SoundIndex(sound + int(brandom(1, 2))), team,
            false, null);
}

void randomAnnouncerSound(String &sound) {
    randomAnnouncerSound(GS_MAX_TEAMS, sound);
}

void sound(cClient @client, int sound, int channel) {
    G_Sound(client.getEnt(), channel, sound, ATTN_UNHEARABLE);
}

void voice(cClient @client, int sound) {
    sound(client, sound, CHAN_VOICE);
}

void painSound(cClient @client, int sound) {
    sound(client, sound, CHAN_PAIN);
}

void exec(String &cmd){
    G_CmdExecute(cmd + "\n");
}

void exec(String &cmd, String &arg) {
    exec(cmd + " \"" + arg + "\"");
}
