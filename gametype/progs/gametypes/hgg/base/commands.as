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

const cString COMMAND_BASE = "gt";

const int MAX_COMMANDS = 64;

class Commands {
    Command@[] commands;
    int size;

    int sound_pm;

    Commands() {
        commands.resize(MAX_COMMANDS);
        size = 0;
        sound_pm = G_SoundIndex("sounds/misc/timer_bip_bip");
    }

    void init() {
        G_RegisterCommand("gametype");
        G_RegisterCommand(COMMAND_BASE);

        add("listplayers", "", "list all players with their ids", RANK_GUEST);
        add("pm", "<id> <message>...", "send a message to a player",
                RANK_GUEST);
        add("register", "<password> <password>", "register yourself",
                RANK_GUEST);
        add("identify", "<password>", "identify yourself after an ip change",
                RANK_GUEST);
    }

    void add(cString &name, cString &usage, cString &description,
            int min_rank) {
        @commands[size++] = Command(name, usage, description, min_rank);
    }

    Command @find(cString &name) {
        for (int i = 0; i < size; i++) {
            if (commands[i].name == name)
                return commands[i];
        }

        return null;
    }

    bool handle(cClient @client, cString &cmd, cString &args, int argc,
            Players @players) {
        if (cmd == "cvarinfo")
            return cmd_cvarinfo(client, args, argc, players);
        else if (cmd == "gametype")
            return cmd_gametype(client, args, argc, players);
        else if (cmd == COMMAND_BASE)
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
            + "Use /" + COMMAND_BASE + " to see the gametype commands\n";

        G_PrintMsg(client.getEnt(), response);
        return true;
    }

    cString @cmd_with_usage(Command @command) {
        return command.name + " " + command.usage;
    }

    bool cmd_gt(cClient @client, cString &args, int argc, Players @players) {
        Command @command = find(args.getToken(0));
        Player @player = players.get(client.playerNum());
        if (@command == null) {
            cmd_gt_help(player, args, argc, players);
        } else {
            if (command.valid_usage(argc - 1)) {
                if (command.name == "listplayers")
                    cmd_gt_listplayers(player, args, argc, players);
                else if (command.name == "pm")
                    cmd_gt_pm(player, args, argc, players);
                else if (command.name == "register")
                    cmd_gt_register(player, args, argc, players);
                else if (command.name == "identify")
                    cmd_gt_identify(player, args, argc, players);
                else
                    cmd_gt_unimplemented(player, args, argc, players);
            } else {
                say(player.client, S_COLOR_HIGHLIGHT + "Usage" + S_COLOR_RESET
                        + ": " + cmd_with_usage(command));
            }
        }

        return true;
    }

    void cmd_gt_register(Player @player, cString &args, int argc,
            Players @players) {
        cString password = args.getToken(1);
        if (player.state != DBI_UNKNOWN) {
            say_bad(player.client, "Your name is already registered.");
        } else if (password == "") {
            say_bad(player.client, "Your password should not be empty.");
        } else if (password != args.getToken(2)) {
            say_bad(player.client, "Passwords didn't match.");
        } else {
            player.set_registered(password);
            players.db.add(player.dbitem);
        }
    }

    void cmd_gt_identify(Player @player, cString &args, int argc,
            Players @players) {
        if (player.state != DBI_WRONG_IP) {
            say_bad(player.client, "You did not need to identify.");
        } else if (args.getToken(1) != player.dbitem.password) {
            say_bad(player.client, "Wrong password.");
        } else {
            player.state = DBI_IDENTIFIED;
            player.dbitem.ip = get_ip(player.client);
            administrate(player.client, "IP changed successfully");
        }
    }

    void cmd_gt_listplayers(Player @player, cString &args, int argc,
            Players @players) {
        cString list = "";
        list += fixed_field("id", 3);
        list += fixed_field("name", 20);
        list += fixed_field("clan", 7);
        list += fixed_field("rank", 4);
        list += fixed_field("level", 5);
        list += "\n";
        bool first = true;
        for (int i = 0; i <= players.max; i++) {
            Player @player = players.get(i);
            if (@player.client != null) {
                if (!first)
                    list += "\n";
                list += fixed_field(i, 3);
                list += fixed_field(player.client.getName(), 20);
                list += fixed_field(player.client.getClanName(), 7);
                list += fixed_field(player.dbitem.rank, 4);
                list += fixed_field(player.dbitem.level, 5);
                first = false;
            }
        }
        print(player.client, list);
    }

    void pm_message(cClient @from, cClient @to, cString &message,
            bool is_self_notification) {
        say(to, from.getName() + S_COLOR_PM + " " + (is_self_notification
                    ? "<<" : ">>" ) + " " + S_COLOR_RESET + message);
    }

    void send_pm(cClient @from, cClient @to, cString &message) {
        G_Sound(to.getEnt(), CHAN_VOICE, sound_pm, 0.0f);
        pm_message(to, from, message, true);
        pm_message(from, to, message, false);
    }

    void cmd_gt_pm(Player @player, cString &args, int argc, Players @players) {
        int n = args.getToken(1).toInt();
        Player @other = players.get(n);
        if (@other == null || @other.client == null) {
            say_bad(player.client, "Target player does not exist.");
        } else {
            cString message = "";
            int pos = args.locate("" + n, 0) + 1;
            message = args.substr(pos,args.len());
            send_pm(player.client, other.client, message);
        }
    }

    void cmd_gt_help(Player @player, cString &args, int argc,
            Players @players) {
        cString response = "Available /" + COMMAND_BASE
            + " commands, sorted by rank:\n";
        for (int rank = 0; rank <= player.dbitem.rank; rank++) {
            bool first = true;
            for (int i = 0; i < size; i++) {
                if (commands[i].min_rank == rank) {
                    if (first) {
                        response += "\n" + S_COLOR_HIGHLIGHT + rank_name(rank)
                            + ":\n" + S_COLOR_RESET;
                        first = false;
                    }
                    response += cmd_with_usage(commands[i]) + "\n" + INDENT
                        + S_COLOR_DESCRIPTION + commands[i].description + "\n";
                }
            }
        }
        print(player.client, response);
    }

    void cmd_gt_unimplemented(Player @player, cString &args, int argc,
            Players @players) {
        say(player.client, "Somehow this command was not implemented.\n"
                + "Please report this bug to a developer.");
    }
}
