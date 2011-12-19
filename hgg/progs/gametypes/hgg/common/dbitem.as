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

class DBItem {
    int state;

    cString id;
    cString ip;
    cString password;

    int title;
    int level;
    int exp;
    int row;
    int total_kills;
    int total_deaths;
    int total_minutes_played;

    DBItem() {
        state = DBI_UNKNOWN;

        id = "";
        ip = "";
        password = "";

        title = 0;
        level = 0;
        exp = 0;
        row = 0;
        total_kills = 0;
        total_deaths = 0;
        total_minutes_played = 0;
    }

    int read(cString &file, int index) {
        if (file.getToken(index) == "")
            return index;

        id = file.getToken(index++);
        ip = file.getToken(index++);
        password = file.getToken(index++);

        title = file.getToken(index++).toInt();
        level = file.getToken(index++).toInt();
        row = file.getToken(index++).toInt();
        total_kills = file.getToken(index++).toInt();
        total_deaths = file.getToken(index++).toInt();
        total_minutes_played = file.getToken(index++).toInt();

        return index;
    }

    void write(cString &file) {
        file += "\"" + id + "\" ";
        file += "\"" + ip + "\" ";
        file += "\"" + password + "\" ";

        file += "\"" + title + "\" ";
        file += "\"" + level + "\" ";
        file += "\"" + row + "\" ";
        file += "\"" + total_kills + "\" ";
        file += "\"" + total_deaths + "\" ";
        file += "\"" + total_minutes_played + "\"\n";
    }

}
