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

const String DB_FILE = "users_";

const int MAX_DB_ITEMS = 2048;
const int TOP_PLAYERS = 100;

class Database {
    Account@[] accounts;
    int size;
    bool hasRoot;
    String fileName;
    Ranking @ranking;

    Database() {
        accounts.resize(MAX_DB_ITEMS);
        size = 0;
        hasRoot = false;
        @ranking = Ranking(TOP_PLAYERS);
    }

    void init() {
        fileName = dataFile(DB_FILE + DATA_VERSION);
    }

    void read() {
        size = 0;
        hasRoot = false;
        String file = G_LoadFile(fileName);

        int index = 0;
        Account @account;
        do { 
            @account = Account();
            index = account.read(file, index);
            if (index != END)
                add(account);
        } while (index != END);
    }

    int add(Account @account, bool updateRanking) {
        if (account.ip == "")
            account.ip = "127.0.0.1";
        int index = size++;
        @accounts[index] = @account;
        if (account.level == LEVEL_ROOT)
            hasRoot = true;
        if (updateRanking)
            ranking.update(account);
        return index;
    }

    int add(Account @account) {
        return add(account, true);
    }

    Account @find(String &id) {
        for (int i = 0; i < size; i++) {
            if (accounts[i].id == id)
                return accounts[i];
        }
        return null;
    }

    void write() {
        String file = "// " + gametype.getName() + " user database version "
            + DATA_VERSION + "\n";
        for (int i = 0; i < size; i++)
            accounts[i].write(file);
        G_WriteFile(fileName, file);
    }
}
