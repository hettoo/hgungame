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

const cString DUMMY_MODEL = "bigvic";
const int DUMMY_RESPAWN = 40;

class Dummy {
    cEntity @ent;
    int id;
    cVec3 pos;
    cVec3 mins;
    cVec3 maxs;
    int respawn;

    Dummy() {
        mins.set(-20, -20, -20);
        maxs.set(20, 20, 48);
        respawn = UNKNOWN;
    }

    void init(cEntity @spawn, int new_id) {
        pos = spawn.getOrigin();
        id = new_id;
    }

    void spawn() {
        if (@ent != null)
            ent.freeEntity();
        @ent = @G_SpawnEntity("dummy");
        ent.type = ET_GENERIC;
        ent.modelindex = G_ModelIndex("models/players/" + DUMMY_MODEL
                + "/tris.skm");
        ent.team = TEAM_PLAYERS;
        ent.setSize(mins, maxs);
        ent.setOrigin(pos);
        ent.solid = SOLID_YES;
        ent.clipMask = MASK_PLAYERSOLID;
        ent.moveType = MOVETYPE_TOSS;
        ent.svflags &= ~SVF_NOCLIENT;
        ent.health = gametype.isInstagib() ? 100 : NW_HEALTH;
        ent.mass = 400;
        ent.takeDamage = 1;
        ent.nextThink = levelTime + 1;
        ent.count = id;
        ent.linkEntity();
    }

    void die() {
        if (@ent != null) {
            ent.freeEntity();
            @ent = null;
            respawn = DUMMY_RESPAWN;
        }
    }

    void new_second() {
        if (respawn != UNKNOWN) {
            respawn--;
            if (respawn == 0) {
                spawn();
                respawn = UNKNOWN;
            }
        }
    }
}
