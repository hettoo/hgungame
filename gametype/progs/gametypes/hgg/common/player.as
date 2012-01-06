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

enum hgg_dbitem_states_e {
    DBI_UNKNOWN,
    DBI_WRONG_IP,
    DBI_IDENTIFIED
};

class Player {
    cClient @client;
    int row;
    int minutes_played;

    int score;

    int state;
    DBItem @dbitem;

    void init(cClient @new_client, DB @db) {
        @client = @new_client;
        row = 0;
        minutes_played = 0;

        score = 0;

        @dbitem = db.find(raw(client.getName()));
        if (@dbitem == null) {
            @dbitem = @DBItem();
            state = DBI_UNKNOWN;
            dbitem.init(client);
        }
        else {
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

    void set_registered(cString &password) {
        state = DBI_IDENTIFIED;
        dbitem.set_password(password);
        client.addAward(S_COLOR_ADMINISTRATIVE + "You are now registered");
    }

    void welcome(cString &msg) {
        if (client.team != TEAM_SPECTATOR)
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
                client.addAward(S_COLOR_ADMINISTRATIVE + "You are now a level "
                        + dbitem.level + " user!");
        }
    }

    void update_hud_self() {
        if (client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL + client.playerNum() + 2;
        client.setHUDStat(STAT_MESSAGE_ALPHA, config_index);
        G_ConfigString(config_index, "- " + client.stats.score + " -");
    }

    void update_hud_other(int best_score, int second_score) {
        if (@client == null || client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL;
        if (client.stats.score == best_score)
            config_index++;
        client.setHUDStat(STAT_MESSAGE_BETA, config_index);
        if (best_score == UNKNOWN
                || (score == best_score && second_score == UNKNOWN)
                || count_players() == 0)
            G_ConfigString(config_index,"- ? -");
        else
            G_ConfigString(config_index, "- "
                    + (score == best_score ? second_score : best_score) + " -");
    }

}
