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

const cString DUMMY_MODEL = "bigvic";

class Dummy {
    cEntity @ent;
    cVec3 pos;
    cVec3 mins;
    cVec3 maxs;

    Dummy() {
        mins.set(-20, -20, -20);
        maxs.set(20, 20, 48);
    }

    void init(cEntity @spawn) {
        pos = spawn.getOrigin();
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
        ent.takeDamage = 1;
        ent.nextThink = levelTime + 1;
        ent.linkEntity();
    }
}
