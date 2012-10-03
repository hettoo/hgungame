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
        G_RegisterCommand(COMMAND_BASE);

        add("gametype", "See some global gametype info.", LEVEL_GUEST, false);
        add("listplayers", "List all players with their ids.", LEVEL_GUEST,
                false);
        add("pm <id> <message>...", "Send a message to a player.", LEVEL_GUEST,
                false);
        add("stats [id]", "Show the statistics of a player.", LEVEL_GUEST);
        add("ranking", "List all top ranked accounts with their row.",
                LEVEL_GUEST);
        add("register <password> <password>", "Register yourself.",
                LEVEL_GUEST);
        add("identify <password>", "Identify yourself after an ip change.",
                LEVEL_GUEST);

        add("whoami", "Announces your level.", LEVEL_REGULAR_USER);
        add("putteam <id> <alpha|beta|spec|players>", "Put a player in a team.",
                LEVEL_REGULAR_USER);

        add("shuffle", "Randomly shuffle the teams.", LEVEL_MEMBER);
        add("restart", "Restart this match.", LEVEL_MEMBER);
        add("nextmap", "Proceed to the next map.", LEVEL_MEMBER);
        add("kick <id>", "Kick a player.", LEVEL_MEMBER);

        add("map <mapname>", "Change the current map.", LEVEL_VIP);
        add("setlevel <id> <level>", "Set the level of a player.", LEVEL_VIP);
        add("toggledummies", "Toggle spawning dummy models.", LEVEL_VIP);
        add("lol", "Throw grenades.", LEVEL_VIP);

        add("devmap <mapname>", "Change the current map and enable cheats.",
                LEVEL_ADMIN);
        add("cvar <name> [value]", "Get or set a cVar.", LEVEL_ADMIN);

        add("do <command>...", "Execute a server command.", LEVEL_ROOT);
        add("shutdown", "Shutdown the server.", LEVEL_ROOT);
    }

    void add(String &usage, String &description,
            int min_level, bool sub_command) {
        @commands[size++] = Command(usage, description, min_level, sub_command);
    }

    void add(String &usage, String &description,
            int min_level) {
        add(usage, description, min_level, true);
    }

    Command @find(String &name) {
        for (int i = 0; i < size; i++) {
            if (commands[i].name == name)
                return commands[i];
        }

        return null;
    }

    bool handle(cClient @client, String &cmd, String &args, int argc,
            Players @players) {
        if (cmd == "cvarinfo")
            return cmd_cvarinfo(client, args, argc, players);

        bool sub_command = cmd == COMMAND_BASE;
        if (sub_command) {
            cmd = args.getToken(0);
            args = args.substr(cmd.len(), args.len());
            argc--;
        }
        Command @command = find(cmd);

        Player @player = players.get(client.playerNum());
        if (@player == null) {
        } else if (@command == null) {
            if (sub_command)
                cmd_help(command, player, args, argc, players);
            else
                return false;
        } else if (player.state == AS_WRONG_IP
                && command.min_level > LEVEL_GUEST) {
            player.say_bad("You are not identified.");
        } else if (player.account.level < command.min_level) {
            player.say_bad("You need to be at least level " + command.min_level
                    + " (" + highlight(
                        players.levels.name(command.min_level).tolower())
                    + S_COLOR_BAD + ") to use this command.");
        } else if (!command.valid_usage(argc)) {
            player.say(highlight("Usage") + ": " + full_usage(command));
        } else {
            return handle_base(command, player, args, argc, players);
        }

        return true;
    }

    bool cmd_cvarinfo(cClient @client, String &args, int argc,
            Players @players) {
        GENERIC_CheatVarResponse(client, "cvarinfo", args, argc);
        return true;
    }

    String @full_usage(Command @command) {
        return "/" + (command.sub_command ? COMMAND_BASE + " " : "")
            + command.name + " " + command.usage;
    }

    bool handle_base(Command @command, Player @player, String &args, int argc,
            Players @players) {
        if (command.name == "gametype")
            cmd_gametype(command, player, args, argc, players);
        else if (command.name == "listplayers")
            cmd_listplayers(command, player, args, argc, players);
        else if (command.name == "pm")
            cmd_pm(command, player, args, argc, players);
        else if (command.name == "stats")
            cmd_stats(command, player, args, argc, players);
        else if (command.name == "ranking")
            cmd_ranking(command, player, args, argc, players);
        else if (command.name == "register")
            cmd_register(command, player, args, argc, players);
        else if (command.name == "identify")
            cmd_identify(command, player, args, argc, players);
        else if (command.name == "whoami")
            cmd_whoami(command, player, args, argc, players);
        else if (command.name == "restart")
            cmd_restart(command, player, args, argc, players);
        else if (command.name == "nextmap")
            cmd_nextmap(command, player, args, argc, players);
        else if (command.name == "putteam")
            cmd_putteam(command, player, args, argc, players);
        else if (command.name == "shuffle")
            cmd_shuffle(command, player, args, argc, players);
        else if (command.name == "kick")
            cmd_kick(command, player, args, argc, players);
        else if (command.name == "setlevel")
            cmd_setlevel(command, player, args, argc, players);
        else if (command.name == "toggledummies")
            cmd_toggledummies(command, player, args, argc, players);
        else if (command.name == "lol")
            cmd_lol(command, player, args, argc, players);
        else if (command.name == "map")
            cmd_map(command, player, args, argc, players);
        else if (command.name == "devmap")
            cmd_devmap(command, player, args, argc, players);
        else if (command.name == "cvar")
            cmd_cvar(command, player, args, argc, players);
        else if (command.name == "shutdown")
            cmd_shutdown(command, player, args, argc, players);
        else if (command.name == "do")
            cmd_do(command, player, args, argc, players);
        else
            cmd_unimplemented(command, player, args, argc, players);

        return true;
    }

    bool cmd_gametype(Command @command, Player @player, String &args, int argc,
            Players @players) {
        cVar fs_game("fs_game", "", 0);
        String manifest = gametype.getManifest();

        player.say("Gametype " + gametype.getName() + " : "
            + gametype.getTitle() + "\n"
            + "----------------\n"
            + "Version: " + gametype.getVersion() + "\n"
            + "Author: " + gametype.getAuthor() + "\n"
            + "Mod: " + fs_game.getString()
            + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "")
            + "\n"
            + "----------------");

        return true;
    }

    void cmd_register(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String password = args.getToken(0);
        if (player.state != AS_UNKNOWN) {
            player.say_bad("Your name is already registered.");
        } else if (@players.db.find(raw(player.client.getName())) != null) {
            player.say_bad("This name has been registered by another player"
                    + " during this match.");
        } else if (raw(player.client.getName()) == "player") {
            player.say_bad("You are not allowed to register this name.");
        } else if (password == "") {
            player.say_bad("Your password should not be empty.");
        } else if (password != args.getToken(1)) {
            player.say_bad("Passwords didn't match.");
        } else {
            player.set_registered(password);
            players.db.add(player.account, false);
            player.administrate("You are now registered!");
            command.say(player.client.getName() + " registered himself");
            players.try_update_rank(player);
        }
    }

    void cmd_identify(Command @command, Player @player, String &args,
            int argc, Players @players) {
        if (player.state != AS_WRONG_IP) {
            player.say_bad("You did not need to identify.");
        } else if (args.getToken(0) != player.account.password) {
            player.say_bad("Wrong password.");
        } else {
            player.state = AS_IDENTIFIED;
            player.account.ip = get_ip(player.client);
            player.administrate("IP changed successfully!");
            command.say(player.client.getName() + " identified himself");
        }
    }

    void cmd_whoami(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is a level "
                + player.account.level + " user ("
                + highlight(players.levels.name(player.account.level)) + ")");
    }

    void cmd_listplayers(Command @command, Player @player, String &args,
            int argc, Players @players) {
        Table table;
        table.add_column("id", 3);
        table.add_column("name", 20);
        table.add_column("clan", 7);
        table.add_column("team", 12);
        table.add_column("level", 6);
        if (player.state == AS_IDENTIFIED
                && player.account.level == LEVEL_ROOT)
            table.add_column("ip", 16);
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null) {
                table.add(i);
                table.add(other.client.getName());
                table.add(other.client.getClanName());
                table.add(G_GetTeam(other.client.team).getName());
                table.add(other.account.level);
                if (player.state == AS_IDENTIFIED
                        && player.account.level == LEVEL_ROOT)
                    table.add(get_ip(other.client));
            }
        }
        player.print(table.string());
    }

    void pm_message(Player @from, Player @to, String &message,
            bool is_self_notification) {
        to.say(from.client.getName() + S_COLOR_PM + " " + (is_self_notification
                    ? "<<" : ">>" ) + " " + S_COLOR_RESET + message);
    }

    void send_pm(Player @from, Player @to, String &message) {
        voice(to.client, sound_pm);
        pm_message(to, from, message, true);
        pm_message(from, to, message, false);
    }

    void cmd_pm(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int n = args.getToken(0).toInt();
        Player @other = players.get(n);
        if (@other == null || @other.client == null) {
            player.say_bad("Target player does not exist.");
        } else {
            String message = "";
            int pos = args.locate("" + n, 0) + 1;
            message = args.substr(pos,args.len());
            send_pm(player, other, message);
        }
    }

    void cmd_stats(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int id;
        if (argc >= 1)
            id = args.getToken(0).toInt();
        else
            id = player.client.playerNum();
        Player @other = players.get(id);
        if (@other == null || @other.client == null) {
            player.say_bad("Target player does not exist.");
        } else {
            player.print(wrap("Stats for " + other.client.getName()
                    + (raw(other.client.getClanName()) == "" ? ""
                        : " of " + other.client.getClanName()) + "\n"
                + "Level: " + other.account.level + " ("
                + highlight(players.levels.name(other.account.level)) + ")\n"
                + "Top row: " + S_COLOR_ROW + other.account.row
                + S_COLOR_RESET + "\n"
                + (other.account.rank == NO_RANK ? ""
                    : "Rank: " + highlight(other.account.rank) + "\n")
                + "Kills / deaths: " + other.account.kills
                + " / " + other.account.deaths + " (" + highlight("" +
                        float(other.account.kills) / (other.account.deaths == 0
                            ? 1 : other.account.deaths)) + ")\n"
                + "Minutes played: " + other.account.minutes_played + "\n"));
        }
    }

    void cmd_ranking(Command @command, Player @player, String &args, int argc,
            Players @players) {
        Table table;
        table.add_column("rank", 5);
        table.add_column("account", 20);
        table.add_column("row", 4);
        for (int i = players.db.ranking.size - 1; i >= 0; i--) {
            Account @account = players.db.ranking.get(i);
            if (@account != null) {
                table.add(account.rank);
                table.add(highlight(account.id));
                table.add(S_COLOR_ROW + account.row + S_COLOR_RESET);
            }
        }
        player.print(table.string());
    }

    void cmd_help(Command @command, Player @player, String &args, int argc,
            Players @players) {
        player.say("Available commands, sorted by level:");
        for (int level = 0; level <= player.account.level; level++) {
            bool first = true;
            for (int i = 0; i < size; i++) {
                if (commands[i].min_level == level) {
                    if (first) {
                        player.say("\n" + highlight(players.levels.name(level)
                                + ":"));
                        first = false;
                    }
                    player.say(full_usage(commands[i]) + "\n" + INDENT
                        + S_COLOR_DESCRIPTION + commands[i].description);
                }
            }
        }
    }

    void cmd_restart(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is restarting the match");
        exec("match restart");
    }

    void cmd_nextmap(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is advancing the match");
        exec("match advance");
    }

    void cmd_putteam(Command @command, Player @player, String &args,
            int argc, Players @players) {
        int id = args.getToken(0).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.say_bad("Target player does not exist.");
        } else if (other.account.level >= player.account.level
                && player.client.playerNum() != id) {
            player.say_bad("You can only change the team of people with lower"
                    + " levels than yours.");
        } else {
            String team_name = args.getToken(1);
            int team;
            if (team_name == "alpha") {
                team = TEAM_ALPHA;
            } else if (team_name == "beta") {
                team = TEAM_BETA;
            } else if (team_name == "spec") {
                team = TEAM_SPECTATOR;
            } else if (team_name == "players") {
                team = TEAM_PLAYERS;
            } else {
                player.say_bad("Invalid team.");
                return;
            }
            if (((team == TEAM_ALPHA || team == TEAM_BETA
                        && !gametype.isTeamBased)
                    || (team == TEAM_PLAYERS && gametype.isTeamBased))
                    && player.account.level < LEVEL_ADMIN) {
                player.say_bad("You can not do this.");
                return;
            }

            command.say(player.client.getName() + " is putting "
                    + other.client.getName() + " in team "
                    + G_GetTeam(team).getName());
            other.put_team(team);
        }
    }

    void cmd_shuffle(Command @command, Player @player, String &args, int argc,
            Players @players) {
        if (!gametype.isTeamBased) {
            player.say_bad("This gametype is not team-based.");
        } else {
            command.say(player.client.getName() + " is shuffling the teams.");
            players.shuffle();
        }
    }

    void cmd_kick(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int id = args.getToken(0).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.say_bad("Target player does not exist.");
        } else if (other.account.level >= player.account.level) {
            player.say_bad(
                    "You can only kick people with lower levels than yours.");
        } else {
            command.say(player.client.getName() + " is kicking "
                    + other.client.getName());
            exec("kick " + id);
        }
    }

    void cmd_setlevel(Command @command, Player @player, String &args,
            int argc, Players @players) {
        int id = args.getToken(0).toInt();
        int level = args.getToken(1).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.say_bad("Target player does not exist.");
        } else if (other.state != AS_IDENTIFIED) {
            player.say_bad(
                    "This player is not registered or identified.");
        } else if (other.account.level >= player.account.level) {
            player.say_bad("You can only setlevel people with lower levels than"
                    + " yours.");
        } else if (level >= player.account.level) {
            player.say_bad(
                    "You can only set levels to lower levels than yours.");
        } else {
            command.say(player.client.getName() + " set the level of "
                    + other.client.getName() + " to " + level + " ("
                    + highlight(players.levels.name(level)) + ")");
            other.set_level(level);
        }
    }

    void cmd_toggledummies(Command @command, Player @player, String &args,
            int argc, Players @players) {
        players.dummies.toggle();
        command.say(player.client.getName() + " " + (players.dummies.enabled
                    ? "enabled" : "disabled") + " dummmies");
    }

    void cmd_lol(Command @command, Player @player, String &args, int argc,
            Players @players) {
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null
                    && other.client.team != TEAM_SPECTATOR) {
                cEntity @ent = other.client.getEnt();
                Vec3 angles = ent.getAngles();
                for (int j = 0; j < 360; j += 60) {
                    angles.y = j;
                    G_FireGrenade(ent.getOrigin(), angles,
                            200, 100, 100, 100, 100, player.client.getEnt());
                }
            }
        }
        command.say(player.client.getName() + " threw grenades at everyone");
    }

    void cmd_map(Command @command, Player @player, String &args, int argc,
            Players @players) {
        String @map = args.getToken(0);
        command.say(player.client.getName() + " is changing to map " + map);
        exec("map", map);
    }

    void cmd_devmap(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String @map = args.getToken(0);
        command.say(player.client.getName() + " is changing to devmap " + map);
        exec("devmap ", map);
    }

    void cmd_cvar(Command @command, Player @player, String &args, int argc,
            Players @players) {
        String name = args.getToken(0);
        String clean_name = clean(name);
        cVar @cvar = cVar(name, "", 0); // NOTE: resets the default value :-(
        if ((clean_name == "g_operator_password"
                    || clean_name == "rcon_password")
                && player.account.level < LEVEL_ROOT) {
            player.say_bad("Forget it.");
        } else if (argc == 1) {
            player.say(name + " is \"" + cvar.getString() + "\"");
        } else if (clean(name).substr(0, 3) == "sv_"
                && player.account.level < LEVEL_ADMIN) {
            player.say_bad("Forget it.");
        } else {
            String value = args.getToken(1);
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

    void cmd_shutdown(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.getName() + " is shutting down the server");
        exec("quit");
    }

    void cmd_do(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String @cmd = args.getToken(0);
        //command.say(player.client.getName() + " is doing " + cmd);
        exec(cmd);
    }

    void cmd_unimplemented(Command @command, Player @player, String &args,
            int argc, Players @players) {
        player.say("Somehow this command was not implemented.\n"
                + "Please report this bug to a developer.");
    }
}
