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

const int MAX_DUMMIES = 128;

class Dummies {
    Dummy[] dummies;
    int size;
    bool enabled;

    Dummies() {
        dummies.resize(MAX_DUMMIES);
        enabled = false;
    }

    void init() {
        cEntity @spawn = null;
        size = 0;
        do {
            @spawn = @G_FindEntityWithClassname(@spawn, "info_player_deathmatch");
            if (@spawn != null)
                dummies[size++].init(spawn);
        } while (@spawn != null);
    }

    void enable() {
        enabled = true;
        init();
    }

    void spawn() {
        if (enabled) {
            for (int i = 0; i < size; i++)
                dummies[i].spawn();
        }
    }
}
