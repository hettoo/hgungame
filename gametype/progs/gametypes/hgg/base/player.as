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

enum DBItemStates {
    DBI_UNKNOWN,
    DBI_WRONG_IP,
    DBI_IDENTIFIED
};

class Player {
    bool inited;
    cClient @client;
    bool alive;
    int[] ammo;
    int row;
    int minutes_played;

    int score;

    int state;
    DBItem @dbitem;

    Player () {
        inited = false;
        alive = false;
        ammo.resize(WEAP_TOTAL);
    }

    void init(cClient @new_client, DB @db) {
        bool update = @client == @new_client;
        if (!update) {
            if (@new_client == null || inited)
                return;
            else
                inited = true;

            @client = @new_client;
            row = 0;
            minutes_played = 0;
            score = 0;
        }

        DBItem @backup = @dbitem;
        @dbitem = db.find(raw(client.getName()));
        if (@dbitem == null) {
            if (!update || state != DBI_UNKNOWN) {
                state = DBI_UNKNOWN;
                @dbitem = @DBItem();
                dbitem.init(client);
            } else {
                @dbitem = @backup;
            }
        } else {
            cString ip = get_ip(client);
            if (ip == dbitem.ip || (ip == "" && dbitem.ip == "127.0.0.1"))
                state = DBI_IDENTIFIED;
            else
                state = DBI_WRONG_IP;
        }
    }

    void reset_row() {
        row = 0;
    }

    void force_spec(cString &msg) {
        client.team = TEAM_SPECTATOR;
        client.respawn(true);
        client.addAward(S_COLOR_BAD + msg);
    }

    bool ip_check() {
        if (state == DBI_WRONG_IP) {
            force_spec("Wrong IP");
            return false;
        }
        return true;
    }

    void set_registered(cString &password) {
        state = DBI_IDENTIFIED;
        dbitem.set_password(password);
    }

    void set_level(int level) {
        administrate("You are now a level " + level + " user!");
        dbitem.level = level;
    }

    void instruct() {
        say("Fork me on GitHub: github.com/hettoo/hgungame");
        say(S_COLOR_SPECIAL + "Welcome " + S_COLOR_RESET + client.getName()
                + S_COLOR_SPECIAL + " and have fun!");
        say(S_COLOR_SPECIAL + "Use /" + COMMAND_BASE
                + " to see the commands you may use here!");
    }

    void welcome(cString &msg) {
        if (@client != null && client.team != TEAM_SPECTATOR)
            client.addAward(msg);
    }

    void sync_score() {
        client.stats.setScore(score);
    }

    void add_score(int n) {
        score += n;
        sync_score();
    }

    void set_score(int n) {
        score = n;
        sync_score();
    }

    void show_row() {
        client.addAward(S_COLOR_ROW + row + "!");
    }

    void killer() {
        row++;
        dbitem.add_kill();
    }

    void update_ammo() {
        for (int i = 0; i < WEAP_TOTAL; i++)
            ammo[i] = ammo(client, i);
    }

    void killed() {
        dbitem.add_death();
    }

    void add_minute() {
        minutes_played++;
        dbitem.add_minute();
    }

    void update_row() {
        if (for_real())
            dbitem.update_row(row);
    }

    int get_ammo(int weapon) {
        return ammo[weapon];
    }

    void update_hud_self() {
        if (client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL + client.playerNum() + 2;
        client.setHUDStat(STAT_MESSAGE_ALPHA, config_index);
        G_ConfigString(config_index, "\\ " + score + " /");
    }

    void update_hud_other(Players @players) {
        if (@client == null || client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL;
        if (score == players.best_score)
            config_index++;
        client.setHUDStat(STAT_MESSAGE_BETA, config_index);
        if (players.best_score == UNKNOWN
                || (score == players.best_score
                    && players.second_score == UNKNOWN) || players.count() == 0)
            G_ConfigString(config_index, "\\ ? /");
        else
            G_ConfigString(config_index, "\\ "
                    + (score == players.best_score ? players.second_score
                        : players.best_score) + " /");
    }

    void update_hud_teams(int count_alpha, int count_beta) {
        client.setHUDStat(STAT_MESSAGE_ALPHA, CS_GENERAL);
        G_ConfigString(CS_GENERAL, "- " + count_alpha + " -");
        client.setHUDStat(STAT_MESSAGE_BETA, CS_GENERAL + 1);
        G_ConfigString(CS_GENERAL + 1, "- " + count_beta + " -");
    }

    void print(cString &msg) {
        client.printMessage(msg);
    }

    void center(cString &msg) {
        G_CenterPrintMsg(client.getEnt(), msg);
    }

    void say(cString &msg) {
        print(msg + "\n");
    }

    void say_bad(cString &msg) {
        say(S_COLOR_BAD + msg);
    }

    void administrate(cString &msg) {
        client.addAward(S_COLOR_ADMINISTRATIVE + msg);
    }
}
