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

class Command {
    cString name;
    cString description;
    cString short_description;
}

class Commands {
    Commands() {
    }

    ~Commands() {
    }

    bool handle(cClient @client, cString &cmd, cString &args, int argc) {
        if (cmd == "cvarinfo")
            return cmd_cvarinfo(client, args, argc);
        else if (cmd == "gametype")
            return cmd_gametype(client, args, argc);
        else if (cmd == "commands")
            return cmd_commands(client, args, argc);

        return false;
    }

    bool cmd_cvarinfo(cClient @client, cString &args, int argc) {
        GENERIC_CheatVarResponse(client, "cvarinfo", args, argc);
        return true;
    }

    bool cmd_gametype(cClient @client, cString &args, int argc) {
        cString response = "";
        cVar fs_game("fs_game", "", 0);
        cString manifest = gametype.getManifest();

        response += "\n";
        response += "Gametype " + gametype.getName() + " : "
            + gametype.getTitle() + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.getVersion() + "\n";
        response += "Author: " + gametype.getAuthor() + "\n";
        response += "Mod: " + fs_game.getString()
            + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "")
            + "\n";
        response += "----------------\n";

        G_PrintMsg(client.getEnt(), response);
        return true;
    }

    bool cmd_commands(cClient @client, cString &args, int argc) {
        cString response = "";
        return true;
    }
}
