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

class Commands {
    Commands() {
    }

    ~Commands() {
    }

    bool handle(cClient @client, cString &cmd, cString &args, int argc) {
        if (cmd == "drop")
            return cmd_drop(client, args, argc);
        else if (cmd == "cvarinfo")
            return cmd_cvarinfo(client, args, argc);
        else if (cmd == "gametype")
            return cmd_gametype(client, args, argc);

        return false;
    }

    bool cmd_drop(cClient @client, cString &args, int argc) {
        cString token;
        for (int i = 0; i < argc; i++) {
            token = args.getToken(i);
            if (token.len() == 0)
                break;

            if (token == "fullweapon") {
                GENERIC_DropCurrentWeapon(client, true);
                GENERIC_DropCurrentAmmoStrong(client);
            } else if (token == "weapon") {
                GENERIC_DropCurrentWeapon(client, true);
            } else if (token == "strong") {
                GENERIC_DropCurrentAmmoStrong(client);
            } else {
                GENERIC_CommandDropItem(client, token);
            }
        }
        return true;
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
        response += "Gametype " + gametype.getName() + " : " + gametype.getTitle() + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.getVersion() + "\n";
        response += "Author: " + gametype.getAuthor() + "\n";
        response += "Mod: " + fs_game.getString() + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n";
        response += "----------------\n";

        G_PrintMsg(client.getEnt(), response);
        return true;
    }
}
