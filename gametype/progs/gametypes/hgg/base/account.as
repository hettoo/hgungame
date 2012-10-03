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

class Account {
    String id;
    String ip;
    String password;

    int level;
    int row;
    int rank;
    int kills;
    int deaths;
    int minutes_played;

    Account() {
        id = "";
        ip = "";
        password = "";

        level = 0;
        row = 0;
        rank = NO_RANK;
        kills = 0;
        deaths = 0;
        minutes_played = 0;
    }

    void init(cClient @client) {
        id = raw(client.getName());
        ip = get_ip(client);
    }

    void set_password(String &new_password) {
        password = new_password;
    }

    int read(String &file, int index) {
        if (file.getToken(index) == "")
            return END;

        id = file.getToken(index++);
        ip = file.getToken(index++);
        password = file.getToken(index++);

        level = file.getToken(index++).toInt();
        row = file.getToken(index++).toInt();
        rank = file.getToken(index++).toInt();
        kills = file.getToken(index++).toInt();
        deaths = file.getToken(index++).toInt();
        minutes_played = file.getToken(index++).toInt();

        return index;
    }

    void write(String &file) {
        file += "\"" + id + "\" ";
        file += "\"" + ip + "\" ";
        file += "\"" + password + "\" ";

        file += "\"" + level + "\" ";
        file += "\"" + row + "\" ";
        file += "\"" + rank + "\" ";
        file += "\"" + kills + "\" ";
        file += "\"" + deaths + "\" ";
        file += "\"" + minutes_played + "\"\n";
    }

    void add_kill() {
        if (for_real())
            kills++;
    }

    void add_death() {
        if (for_real())
            deaths++;
    }

    void add_minute() {
        if (for_real())
            minutes_played++;
    }

    bool update_row(int new_row) {
        if (new_row > row) {
            row = new_row;
            return true;
        }
        return false;
    }
}
