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
    int row;
    int minutes_played;

    int score;

    int state;
    DBItem @dbitem;

    Player () {
        inited = false;
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
            if (get_ip(client) == dbitem.ip)
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

    void add_exp(int exp) {
        if (!for_real())
            return;

        dbitem.exp += exp;
        while (dbitem.exp >= exp_needed(dbitem.level + 1))
        {
            dbitem.exp -= exp_needed(++dbitem.level);
            if (state == DBI_IDENTIFIED)
                administrate("You are now a level " + dbitem.level + " user!");
        }
    }

    void update_hud_self() {
        if (client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL + client.playerNum() + 2;
        client.setHUDStat(STAT_MESSAGE_ALPHA, config_index);
        G_ConfigString(config_index, "- " + client.stats.score + " -");
    }

    void update_hud_other(Players @players) {
        if (@client == null || client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL;
        if (client.stats.score == players.best_score)
            config_index++;
        client.setHUDStat(STAT_MESSAGE_BETA, config_index);
        if (players.best_score == UNKNOWN
                || (score == players.best_score
                    && players.second_score == UNKNOWN) || players.count() == 0)
            G_ConfigString(config_index,"- ? -");
        else
            G_ConfigString(config_index, "- "
                    + (score == players.best_score ? players.second_score
                        : players.best_score) + " -");
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
