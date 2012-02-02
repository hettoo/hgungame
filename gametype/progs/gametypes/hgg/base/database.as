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

const cString DB_FILE = "users_";

const int MAX_DB_ITEMS = 2048;
const int TOP_PLAYERS = 100;

class DataBase {
    Account@[] accounts;
    int size;
    bool has_root;
    cString file_name;
    Ranking @ranking;

    DataBase() {
        accounts.resize(MAX_DB_ITEMS);
        size = 0;
        has_root = false;
        @ranking = Ranking(TOP_PLAYERS);
    }

    void init() {
        file_name = data_file(DB_FILE + DATA_VERSION);
    }

    void read() {
        size = 0;
        has_root = false;
        cString file = G_LoadFile(file_name);

        int index = 0;
        Account @account;
        do { 
            @account = Account();
            index = account.read(file, index);
            if (index != END)
                add(account);
        } while (index != END);
    }

    int add(Account @account) {
        if (account.ip == "")
            account.ip = "127.0.0.1";
        int index = size++;
        @accounts[index] = @account;
        if (account.level == LEVEL_ROOT)
            has_root = true;
        ranking.update(account);
        return index;
    }

    Account @find(cString &id) {
        for (int i = 0; i < size; i++) {
            if (accounts[i].id == id)
                return accounts[i];
        }
        return null;
    }

    void write() {
        cString file = "// " + gametype.getName() + " user database version "
            + DATA_VERSION + "\n";
        for (int i = 0; i < size; i++)
            accounts[i].write(file);
        G_WriteFile(file_name, file);
    }
}
