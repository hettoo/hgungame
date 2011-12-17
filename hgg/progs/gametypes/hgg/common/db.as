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

class DB {
    DBItem[] items;
    int size;
    bool has_root;

    DB() {
        items.resize(MAX_DB_ITEMS);
        size = 0;
        has_root = false;
    }

    void read() {
        size = -1;
        cString file = G_LoadFile(CONFIGS_DIR + gametype.getName() + "/data/db_" + DB_VERSION);

        int index;
        int new_index = 0;
        do {
            index = new_index;
            new_index = items[++size].read(file, index);
        } while (new_index > index);
    }

    DBItem @find(cString &id) {
        for (int i = 0; i < size; i++) {
            if (items[i].id == id)
                return items[i];
        }
        return null;
    }

    void write() {
        cString file = "// " + gametype.getName() + " user database\n";
        for (int i = 0; i < size; i++)
            items[i].write(file);
        G_WriteFile(CONFIGS_DIR + gametype.getName() + "/data/db_" + DB_VERSION, file);
    }

}
