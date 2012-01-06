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
}
