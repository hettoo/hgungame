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
    DBItem @dbitem;

    void init(cClient @new_client, DB @db) {
        @client = @new_client;
        row = 0;
        minutes_played = 0;

        @dbitem = db.find(raw(client.getName()), get_ip(client));
        if (@dbitem == null)
            dbitem = DBItem();
    }

    void welcome(cString &msg) {
        client.addAward(msg);
    }

    void show_row() {
        client.addAward(S_COLOR_ROW + row + "!");
    }

}
