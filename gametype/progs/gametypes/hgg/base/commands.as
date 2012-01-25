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

        add("listplayers", "List all players with their ids.", RANK_GUEST);
        add("pm <id> <message>...", "Send a message to a player.", RANK_GUEST);
        add("stats [id]", "Show the statistics of a player.", RANK_GUEST);
        add("register <password> <password>", "Register yourself.", RANK_GUEST);
        add("identify <password>", "Identify yourself after an ip change.",
                RANK_GUEST);

        add("showoff", "Announces your rank.", RANK_REGULAR_USER);

        add("kick <id>", "Kick a player.", RANK_MEMBER);
        add("restart", "Restart this map.", RANK_MEMBER);
        add("nextmap", "Proceed to the next map.", RANK_MEMBER);

        add("map <mapname>", "Change the current map.", RANK_VIP);
        add("setrank <id> <rank>", "Set the rank of a player.", RANK_VIP);
        add("lol", "Throw grenades.", RANK_VIP);

        add("devmap <mapname>", "Change the current map and enable cheats.",
                RANK_ADMIN);
        add("cvar <name> [value]", "Get / set a cVar.", RANK_ADMIN);

        add("shutdown", "Shutdown the server.", RANK_ROOT);
    }

    void add(cString &usage, cString &description,
            int min_rank) {
        @commands[size++] = Command(usage, description, min_rank);
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
        if (@player == null) {
        } else if (@command == null) {
            cmd_gt_help(command, player, args, argc, players);
        } else if (player.state == DBI_WRONG_IP
                && command.min_rank > RANK_GUEST) {
            player.say_bad("You are not identified.");
        } else if (player.dbitem.rank < command.min_rank) {
            player.say_bad("You need to be at least rank " + command.min_rank
                    + " ("
                    + highlight(players.ranks.name(command.min_rank).tolower())
                    + S_COLOR_BAD + ") to use this command.");
        } else if (command.valid_usage(argc - 1)) {
            if (command.name == "listplayers")
                cmd_gt_listplayers(command, player, args, argc, players);
            else if (command.name == "pm")
                cmd_gt_pm(command, player, args, argc, players);
            else if (command.name == "stats")
                cmd_gt_stats(command, player, args, argc, players);
            else if (command.name == "register")
                cmd_gt_register(command, player, args, argc, players);
            else if (command.name == "identify")
                cmd_gt_identify(command, player, args, argc, players);
            else if (command.name == "showoff")
                cmd_gt_showoff(command, player, args, argc, players);
            else if (command.name == "restart")
                cmd_gt_restart(command, player, args, argc, players);
            else if (command.name == "nextmap")
                cmd_gt_nextmap(command, player, args, argc, players);
            else if (command.name == "kick")
                cmd_gt_kick(command, player, args, argc, players);
            else if (command.name == "setrank")
                cmd_gt_setrank(command, player, args, argc, players);
            else if (command.name == "lol")
                cmd_gt_lol(command, player, args, argc, players);
            else if (command.name == "map")
                cmd_gt_map(command, player, args, argc, players);
            else if (command.name == "devmap")
                cmd_gt_devmap(command, player, args, argc, players);
            else if (command.name == "cvar")
                cmd_gt_cvar(command, player, args, argc, players);
            else if (command.name == "shutdown")
                cmd_gt_shutdown(command, player, args, argc, players);
            else
                cmd_gt_unimplemented(command, player, args, argc, players);
        } else {
            player.say(highlight("Usage") + ": " + cmd_with_usage(command));
        }

        return true;
    }

    void cmd_gt_register(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        cString password = args.getToken(1);
        if (player.state != DBI_UNKNOWN) {
            player.say_bad("Your name is already registered.");
        } else if (raw(player.client.getName()) == "player") {
            player.say_bad("You are not allowed to register this name.");
        } else if (password == "") {
            player.say_bad("Your password should not be empty.");
        } else if (password != args.getToken(2)) {
            player.say_bad("Passwords didn't match.");
        } else {
            player.set_registered(password);
            players.db.add(player.dbitem);
            player.administrate("You are now registered!");
            command.say(player.client.getName() + " registered himself");
        }
    }

    void cmd_gt_identify(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        if (player.state != DBI_WRONG_IP) {
            player.say_bad("You did not need to identify.");
        } else if (args.getToken(1) != player.dbitem.password) {
            player.say_bad("Wrong password.");
        } else {
            player.state = DBI_IDENTIFIED;
            player.dbitem.ip = get_ip(player.client);
            player.administrate("IP changed successfully!");
            command.say(player.client.getName() + " identified himself");
        }
    }

    void cmd_gt_showoff(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is a rank " + player.dbitem.rank
                + " user (" + highlight(players.ranks.name(player.dbitem.rank))
                        + ")");
    }

    void cmd_gt_listplayers(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        cString list = "";
        list += fixed_field("id", 3);
        list += fixed_field("name", 20);
        list += fixed_field("clan", 7);
        list += fixed_field("rank", 4);
        if (player.state == DBI_IDENTIFIED && player.dbitem.rank == RANK_ROOT)
            list += fixed_field("ip", 16);
        list += "\n";
        bool first = true;
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null) {
                if (!first)
                    list += "\n";
                list += fixed_field(i, 3);
                list += fixed_field(other.client.getName(), 20);
                list += fixed_field(other.client.getClanName(), 7);
                list += fixed_field(other.dbitem.rank, 4);
                if (player.state == DBI_IDENTIFIED
                        && player.dbitem.rank == RANK_ROOT)
                    list += fixed_field(get_ip(other.client), 16);
                first = false;
            }
        }
        player.print(list);
    }

    void pm_message(Player @from, Player @to, cString &message,
            bool is_self_notification) {
        to.say(from.client.getName() + S_COLOR_PM + " " + (is_self_notification
                    ? "<<" : ">>" ) + " " + S_COLOR_RESET + message);
    }

    void send_pm(Player @from, Player @to, cString &message) {
        voice(to.client, sound_pm);
        pm_message(to, from, message, true);
        pm_message(from, to, message, false);
    }

    void cmd_gt_pm(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        int n = args.getToken(1).toInt();
        Player @other = players.get(n);
        if (@other == null || @other.client == null) {
            player.say_bad("Target player does not exist.");
        } else {
            cString message = "";
            int pos = args.locate("" + n, 0) + 1;
            message = args.substr(pos,args.len());
            send_pm(player, other, message);
        }
    }

    void cmd_gt_stats(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        int n;
        if (argc > 1)
            n = args.getToken(1).toInt();
        else
            n = player.client.playerNum();
        Player @other = players.get(n);
        if (@other == null || @other.client == null) {
            player.say_bad("Target player does not exist.");
        } else {
            player.print(wrap("Stats for " + other.client.getName()
                    + (raw(other.client.getClanName()) == "" ? ""
                        : " of " + other.client.getClanName()) + "\n"
                + "Rank: " + other.dbitem.rank + " ("
                + highlight(players.ranks.name(other.dbitem.rank)) + ")\n"
                + "Top row: " + other.dbitem.row + "\n"
                + "Kills / deaths: " + other.dbitem.kills + " / "
                + other.dbitem.deaths + " (" + (float(other.dbitem.kills)
                            / (other.dbitem.deaths == 0 ? 1
                                : other.dbitem.deaths)) + ")\n"
                + "Minutes played: " + other.dbitem.minutes_played + "\n"));
        }
    }

    void cmd_gt_help(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        cString response = "Available /" + COMMAND_BASE
            + " commands, sorted by rank:\n";
        for (int rank = 0; rank <= player.dbitem.rank; rank++) {
            bool first = true;
            for (int i = 0; i < size; i++) {
                if (commands[i].min_rank == rank) {
                    if (first) {
                        response += "\n" + highlight(players.ranks.name(rank)
                                + ":\n");
                        first = false;
                    }
                    response += cmd_with_usage(commands[i]) + "\n" + INDENT
                        + S_COLOR_DESCRIPTION + commands[i].description + "\n";
                }
            }
        }
        player.print(response);
    }

    void cmd_gt_restart(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is restarting the match");
        exec("match restart");
    }

    void cmd_gt_nextmap(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is advancing the match");
        exec("match advance");
    }

    void cmd_gt_kick(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        int id = args.getToken(1).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.say_bad("Target player does not exist.");
        } else if (other.dbitem.rank >= player.dbitem.rank) {
            player.say_bad(
                    "You can only kick people with lower ranks than yours.");
        } else {
            command.say(player.client.getName() + " is kicking "
                    + other.client.getName());
            exec("kick " + id);
        }
    }

    void cmd_gt_setrank(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        int id = args.getToken(1).toInt();
        int rank = args.getToken(2).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.say_bad("Target player does not exist.");
        } else if (other.state != DBI_IDENTIFIED) {
            player.say_bad(
                    "This player is not registered or identified.");
        } else if (other.dbitem.rank >= player.dbitem.rank) {
            player.say_bad(
                    "You can only setrank people with lower ranks than yours.");
        } else if (rank >= player.dbitem.rank) {
            player.say_bad(
                    "You can only set ranks to lower ranks than yours.");
        } else {
            command.say(player.client.getName() + " set the rank of "
                    + other.client.getName() + " to " + rank + " ("
                    + highlight(players.ranks.name(rank)) + ")");
            other.set_rank(rank);
        }
    }

    void cmd_gt_lol(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null
                    && other.client.team != TEAM_SPECTATOR) {
                cEntity @ent = other.client.getEnt();
                cVec3 @angles = ent.getAngles();
                for (int j = 0; j < 360; j += 60) {
                    angles.y = j;
                    G_FireGrenade(ent.getOrigin(), angles,
                            200, 100, 100, 100, 100, player.client.getEnt());
                }
            }
        }
        command.say(player.client.getName() + " threw grenades at everyone");
    }

    void cmd_gt_map(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        cString @map = args.getToken(1);
        command.say(player.client.getName() + " is changing to map " + map);
        exec("map", map);
    }

    void cmd_gt_devmap(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        cString @map = args.getToken(1);
        command.say(player.client.getName() + " is changing to devmap " + map);
        exec("devmap ", map);
    }

    void cmd_gt_cvar(Command @command, Player @player, cString &args, int argc,
            Players @players) {
        cString name = args.getToken(1);
        cVar @cvar = cVar(name, "", 0); // NOTE: resets the default value :-(
        if ((raw(name) == "g_operator_password" && player.dbitem.rank < RANK_VIP)
                || (raw(name) == "rcon_password"
                    && player.dbitem.rank < RANK_ROOT)) {
            player.say_bad("Forget it.");
        } else if (argc == 2) {
            player.say(name + " is \"" + cvar.getString() + "\"");
        } else if (raw(name).substr(0, 3) == "sv_"
                && player.dbitem.rank < RANK_ADMIN) {
            player.say_bad("Forget it.");
        } else {
            cString value = args.getToken(2);
            cvar.set(value);
            if (cvar.getString() != value)
                player.say_bad(
                        "Setting the cVar seems to have failed. It's value is "
                        + cvar.getString());
            else
                command.say(player.client.getName() + " set " + name
                        + S_COLOR_RESET + " to \"" + value + S_COLOR_RESET
                        + "\"");
        }
    }

    void cmd_gt_shutdown(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is shutting down the server");
        exec("quit");
    }

    void cmd_gt_unimplemented(Command @command, Player @player, cString &args,
            int argc, Players @players) {
        player.say("Somehow this command was not implemented.\n"
                + "Please report this bug to a developer.");
    }
}
