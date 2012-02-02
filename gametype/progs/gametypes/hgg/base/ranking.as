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

const int NO_RANK = -1;

class Ranking {
    Account@[] accounts;
    int size;

    Ranking(int items) {
        accounts.resize(items);
        size = items;
    }

    Account @get(int index) {
        return accounts[index];
    }

    void remove(Account @account) {
        for (int i = 0; i < size; i++) {
            if (@accounts[i] != null && accounts[i].id == account.id) {
                for (int j = i; j < size - 1; j++) {
                    @accounts[j] = @accounts[j + 1];
                    if (@accounts[j] != null)
                        accounts[j].rank = j + 1;
                }
                @accounts[size - 1] == null;
            }
        }
    }

    bool update(Account @account) {
        remove(account);
        int i = size - 1;
        while (i >= 0
                && (@accounts[i] == null || accounts[i].row < account.row))
            i--;
        i++;
        if (i < size) {
            if (@accounts[size - 1] != null)
                accounts[size - 1].rank = NO_RANK;
            for (int j = size - 1; j > i; j--) {
                @accounts[j] = @accounts[j - 1];
                if (@accounts[j] != null)
                    accounts[j].rank = j + 1;
            }
            @accounts[i] = @account;
            account.rank = i + 1;
            return true;
        }
        return false;
    }
}
