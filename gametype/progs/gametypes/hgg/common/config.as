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

const cString CVAR_BASE = "g_hgg_";

enum hgg_cvars_e {
    CV_MOTD,
    CV_TOTAL
};

class Config {
    cVar[] cvars;

    Config() {
        cvars.resize(CV_TOTAL);
    }

    void init() {
        cvars[CV_MOTD].get(CVAR_BASE + "MOTD", "Have Fun!", CVAR_ARCHIVE);
    }

    cString @motd() {
        return cvars[CV_MOTD].getString();
    }
}
