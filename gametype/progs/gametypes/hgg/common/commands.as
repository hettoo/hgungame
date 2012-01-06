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
    void init() {
        G_RegisterCommand("gametype");
        G_RegisterCommand("gt");
    }

    bool handle(cClient @client, cString &cmd, cString &args, int argc,
            Players @players) {
        if (cmd == "cvarinfo")
            return cmd_cvarinfo(client, args, argc, players);
        else if (cmd == "gametype")
            return cmd_gametype(client, args, argc, players);
        else if (cmd == "gt")
            return cmd_gt(client, args, argc, players);

        return false;
    }

    bool cmd_cvarinfo(cClient @client, cString &args, int argc,
            Players @players) {
        GENERIC_CheatVarResponse(client, "cvarinfo", args, argc);
        return true;
    }

    bool cmd_gametype(cClient @client, cString &args, int argc,
            Players @players) {
        cVar fs_game("fs_game", "", 0);
        cString manifest = gametype.getManifest();

        cString response = "Gametype " + gametype.getName() + " : "
            + gametype.getTitle() + "\n"
            + "----------------\n"
            + "Version: " + gametype.getVersion() + "\n"
            + "Author: " + gametype.getAuthor() + "\n"
            + "Mod: " + fs_game.getString()
            + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "")
            + "\n"
            + "----------------\n"
            + "Use /gt to see the gametype commands\n";

        G_PrintMsg(client.getEnt(), response);
        return true;
    }

    bool cmd_gt(cClient @client, cString &args, int argc, Players @players) {
        cString command = args.getToken(0);
        if (command == "register")
            cmd_gt_register(client, args, argc, players);
        else if (command == "identify")
            cmd_gt_identify(client, args, argc, players);
        else
            cmd_gt_help(client, args, argc, players);

        return true;
    }

    void cmd_gt_register(cClient @client, cString &args, int argc,
            Players @players) {
        Player @player = players.get(client.playerNum());
        cString password = args.getToken(1);
        if (player.state == DBI_UNKNOWN && password != ""
                && password == args.getToken(2)) {
            player.set_registered(password);
            players.db.add(player.dbitem);
        }
    }

    void cmd_gt_identify(cClient @client, cString &args, int argc,
            Players @players) {
        Player @player = players.get(client.playerNum());
        if (player.state == DBI_WRONG_IP
                && args.getToken(1) == player.dbitem.password) {
            player.state = DBI_IDENTIFIED;
            player.dbitem.ip = get_ip(client);
            client.addAward(S_COLOR_ADMINISTRATIVE + "IP changed successfully");
        }
    }

    void cmd_gt_help(cClient @client, cString &args, int argc,
            Players @players) {
        cString response = "Available /gt commands:\n"
            + "register <password> <password> -- register yourself\n"
            + "identify <password> -- identify yourself after an ip change\n";
        G_PrintMsg(client.getEnt(), response);
    }
}