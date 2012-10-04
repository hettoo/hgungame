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

    int soundPM;

    Commands() {
        commands.resize(MAX_COMMANDS);
        size = 0;
        soundPM = G_SoundIndex("sounds/misc/timer_bip_bip");
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
        add("cvar <name> [value]", "Get or set a Cvar.", LEVEL_ADMIN);

        add("do <command>...", "Execute a server command.", LEVEL_ROOT);
        add("shutdown", "Shutdown the server.", LEVEL_ROOT);
    }

    void add(String &usage, String &description,
            int minLevel, bool subCommand) {
        @commands[size++] = Command(usage, description, minLevel, subCommand);
    }

    void add(String &usage, String &description,
            int minLevel) {
        add(usage, description, minLevel, true);
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
            return cmdCVarinfo(client, args, argc, players);

        bool subCommand = cmd == COMMAND_BASE;
        if (subCommand) {
            cmd = args.getToken(0);
            args = args.substr(cmd.len(), args.len());
            argc--;
        }
        Command @command = find(cmd);

        Player @player = players.get(client.playerNum);
        if (@player == null) {
        } else if (@command == null) {
            if (subCommand)
                cmdHelp(command, player, args, argc, players);
            else
                return false;
        } else if (player.state == AS_WRONG_IP
                && command.minLevel > LEVEL_GUEST) {
            player.sayBad("You are not identified.");
        } else if (player.account.level < command.minLevel) {
            player.sayBad("You need to be at least level " + command.minLevel
                    + " (" + highlight(
                        players.levels.name(command.minLevel).tolower())
                    + S_COLOR_BAD + ") to use this command.");
        } else if (!command.validUsage(argc)) {
            player.say(highlight("Usage") + ": " + fullUsage(command));
        } else {
            return handleBase(command, player, args, argc, players);
        }

        return true;
    }

    bool cmdCVarinfo(cClient @client, String &args, int argc,
            Players @players) {
        GENERIC_CheatVarResponse(client, "cvarinfo", args, argc);
        return true;
    }

    String @fullUsage(Command @command) {
        return "/" + (command.subCommand ? COMMAND_BASE + " " : "")
            + command.name + " " + command.usage;
    }

    bool handleBase(Command @command, Player @player, String &args, int argc,
            Players @players) {
        if (command.name == "gametype")
            cmdGametype(command, player, args, argc, players);
        else if (command.name == "listplayers")
            cmdListplayers(command, player, args, argc, players);
        else if (command.name == "pm")
            cmdPM(command, player, args, argc, players);
        else if (command.name == "stats")
            cmdStats(command, player, args, argc, players);
        else if (command.name == "ranking")
            cmdRanking(command, player, args, argc, players);
        else if (command.name == "register")
            cmdRegister(command, player, args, argc, players);
        else if (command.name == "identify")
            cmdIdentify(command, player, args, argc, players);
        else if (command.name == "whoami")
            cmdWhoami(command, player, args, argc, players);
        else if (command.name == "restart")
            cmdRestart(command, player, args, argc, players);
        else if (command.name == "nextmap")
            cmdNextmap(command, player, args, argc, players);
        else if (command.name == "putteam")
            cmdPutteam(command, player, args, argc, players);
        else if (command.name == "shuffle")
            cmdShuffle(command, player, args, argc, players);
        else if (command.name == "kick")
            cmdKick(command, player, args, argc, players);
        else if (command.name == "setlevel")
            cmdSetlevel(command, player, args, argc, players);
        else if (command.name == "toggledummies")
            cmdToggledummies(command, player, args, argc, players);
        else if (command.name == "lol")
            cmdLol(command, player, args, argc, players);
        else if (command.name == "map")
            cmdMap(command, player, args, argc, players);
        else if (command.name == "devmap")
            cmdDevmap(command, player, args, argc, players);
        else if (command.name == "cvar")
            cmdCVar(command, player, args, argc, players);
        else if (command.name == "shutdown")
            cmdShutdown(command, player, args, argc, players);
        else if (command.name == "do")
            cmdDo(command, player, args, argc, players);
        else
            cmdUnimplemented(command, player, args, argc, players);

        return true;
    }

    bool cmdGametype(Command @command, Player @player, String &args, int argc,
            Players @players) {
        Cvar mod("fs_game", "", 0);
        String manifest = gametype.get_manifest();

        player.say("Gametype " + gametype.get_name() + " : "
            + gametype.get_title() + "\n"
            + "----------------\n"
            + "Version: " + gametype.get_version() + "\n"
            + "Author: " + gametype.get_author() + "\n"
            + "Mod: " + mod.get_string()
            + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "")
            + "\n"
            + "----------------");

        return true;
    }

    void cmdRegister(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String password = args.getToken(0);
        if (player.state != AS_UNKNOWN) {
            player.sayBad("Your name is already registered.");
        } else if (@players.db.find(raw(player.client.get_name())) != null) {
            player.sayBad("This name has been registered by another player"
                    + " during this match.");
        } else if (raw(player.client.get_name()) == "player") {
            player.sayBad("You are not allowed to register this name.");
        } else if (password == "") {
            player.sayBad("Your password should not be empty.");
        } else if (password != args.getToken(1)) {
            player.sayBad("Passwords didn't match.");
        } else {
            player.setRegistered(password);
            players.db.add(player.account, false);
            player.administrate("You are now registered!");
            command.say(player.client.get_name() + " registered himself");
            players.tryUpdateRank(player);
        }
    }

    void cmdIdentify(Command @command, Player @player, String &args,
            int argc, Players @players) {
        if (player.state != AS_WRONG_IP) {
            player.sayBad("You did not need to identify.");
        } else if (args.getToken(0) != player.account.password) {
            player.sayBad("Wrong password.");
        } else {
            player.state = AS_IDENTIFIED;
            player.account.ip = getIP(player.client);
            player.administrate("IP changed successfully!");
            command.say(player.client.get_name() + " identified himself");
        }
    }

    void cmdWhoami(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.get_name() + " is a level "
                + player.account.level + " user ("
                + highlight(players.levels.name(player.account.level)) + ")");
    }

    void cmdListplayers(Command @command, Player @player, String &args,
            int argc, Players @players) {
        Table table;
        table.addColumn("id", 3);
        table.addColumn("name", 20);
        table.addColumn("clan", 7);
        table.addColumn("team", 12);
        table.addColumn("level", 6);
        if (player.state == AS_IDENTIFIED
                && player.account.level == LEVEL_ROOT)
            table.addColumn("ip", 16);
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null) {
                table.add(i);
                table.add(other.client.get_name());
                table.add(other.client.get_clanName());
                table.add(G_GetTeam(other.client.team).get_name());
                table.add(other.account.level);
                if (player.state == AS_IDENTIFIED
                        && player.account.level == LEVEL_ROOT)
                    table.add(getIP(other.client));
            }
        }
        player.print(table.getString());
    }

    void pmMessage(Player @from, Player @to, String &message,
            bool isSelfNotification) {
        to.say(from.client.get_name() + S_COLOR_PM + " " + (isSelfNotification
                    ? "<<" : ">>" ) + " " + S_COLOR_RESET + message);
    }

    void sendPM(Player @from, Player @to, String &message) {
        voice(to.client, soundPM);
        pmMessage(to, from, message, true);
        pmMessage(from, to, message, false);
    }

    void cmdPM(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int n = args.getToken(0).toInt();
        Player @other = players.get(n);
        if (@other == null || @other.client == null) {
            player.sayBad("Target player does not exist.");
        } else {
            String message = "";
            int pos = args.locate("" + n, 0) + 1;
            message = args.substr(pos,args.len());
            sendPM(player, other, message);
        }
    }

    void cmdStats(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int id;
        if (argc >= 1)
            id = args.getToken(0).toInt();
        else
            id = player.client.playerNum;
        Player @other = players.get(id);
        if (@other == null || @other.client == null) {
            player.sayBad("Target player does not exist.");
        } else {
            player.print(wrap("Stats for " + other.client.get_name()
                    + (raw(other.client.get_clanName()) == "" ? ""
                        : " of " + other.client.get_clanName()) + "\n"
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
                + "Minutes played: " + other.account.minutesPlayed + "\n"));
        }
    }

    void cmdRanking(Command @command, Player @player, String &args, int argc,
            Players @players) {
        Table table;
        table.addColumn("rank", 5);
        table.addColumn("account", 20);
        table.addColumn("row", 4);
        for (int i = players.db.ranking.size - 1; i >= 0; i--) {
            Account @account = players.db.ranking.get(i);
            if (@account != null) {
                table.add(account.rank);
                table.add(highlight(account.id));
                table.add(S_COLOR_ROW + account.row + S_COLOR_RESET);
            }
        }
        player.print(table.getString());
    }

    void cmdHelp(Command @command, Player @player, String &args, int argc,
            Players @players) {
        player.say("Available commands, sorted by level:");
        for (int level = 0; level <= player.account.level; level++) {
            bool first = true;
            for (int i = 0; i < size; i++) {
                if (commands[i].minLevel == level) {
                    if (first) {
                        player.say("\n" + highlight(players.levels.name(level)
                                + ":"));
                        first = false;
                    }
                    player.say(fullUsage(commands[i]) + "\n" + INDENT
                        + S_COLOR_DESCRIPTION + commands[i].description);
                }
            }
        }
    }

    void cmdRestart(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.get_name() + " is restarting the match");
        exec("match restart");
    }

    void cmdNextmap(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.get_name() + " is advancing the match");
        exec("match advance");
    }

    void cmdPutteam(Command @command, Player @player, String &args,
            int argc, Players @players) {
        int id = args.getToken(0).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.sayBad("Target player does not exist.");
        } else if (other.account.level >= player.account.level
                && player.client.playerNum != id) {
            player.sayBad("You can only change the team of people with lower"
                    + " levels than yours.");
        } else {
            String teamName = args.getToken(1);
            int team;
            if (teamName == "alpha") {
                team = TEAM_ALPHA;
            } else if (teamName == "beta") {
                team = TEAM_BETA;
            } else if (teamName == "spec") {
                team = TEAM_SPECTATOR;
            } else if (teamName == "players") {
                team = TEAM_PLAYERS;
            } else {
                player.sayBad("Invalid team.");
                return;
            }
            if (((team == TEAM_ALPHA || team == TEAM_BETA
                        && !gametype.isTeamBased)
                    || (team == TEAM_PLAYERS && gametype.isTeamBased))
                    && player.account.level < LEVEL_ADMIN) {
                player.sayBad("You can not do this.");
                return;
            }

            command.say(player.client.get_name() + " is putting "
                    + other.client.get_name() + " in team "
                    + G_GetTeam(team).get_name());
            other.putTeam(team);
        }
    }

    void cmdShuffle(Command @command, Player @player, String &args, int argc,
            Players @players) {
        if (!gametype.isTeamBased) {
            player.sayBad("This gametype is not team-based.");
        } else {
            command.say(player.client.get_name() + " is shuffling the teams.");
            players.shuffle();
        }
    }

    void cmdKick(Command @command, Player @player, String &args, int argc,
            Players @players) {
        int id = args.getToken(0).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.sayBad("Target player does not exist.");
        } else if (other.account.level >= player.account.level) {
            player.sayBad(
                    "You can only kick people with lower levels than yours.");
        } else {
            command.say(player.client.get_name() + " is kicking "
                    + other.client.get_name());
            exec("kick " + id);
        }
    }

    void cmdSetlevel(Command @command, Player @player, String &args,
            int argc, Players @players) {
        int id = args.getToken(0).toInt();
        int level = args.getToken(1).toInt();
        Player @other = players.get(id);
        if (@other == null) {
            player.sayBad("Target player does not exist.");
        } else if (other.state != AS_IDENTIFIED) {
            player.sayBad(
                    "This player is not registered or identified.");
        } else if (other.account.level >= player.account.level) {
            player.sayBad("You can only setlevel people with lower levels than"
                    + " yours.");
        } else if (level >= player.account.level) {
            player.sayBad(
                    "You can only set levels to lower levels than yours.");
        } else {
            command.say(player.client.get_name() + " set the level of "
                    + other.client.get_name() + " to " + level + " ("
                    + highlight(players.levels.name(level)) + ")");
            other.setLevel(level);
        }
    }

    void cmdToggledummies(Command @command, Player @player, String &args,
            int argc, Players @players) {
        players.dummies.toggle();
        command.say(player.client.get_name() + " " + (players.dummies.enabled
                    ? "enabled" : "disabled") + " dummmies");
    }

    void cmdLol(Command @command, Player @player, String &args, int argc,
            Players @players) {
        for (int i = 0; i < players.size; i++) {
            Player @other = players.get(i);
            if (@other != null && @other.client != null
                    && other.client.team != TEAM_SPECTATOR) {
                cEntity @ent = other.client.getEnt();
                Vec3 angles = ent.angles;
                for (int j = 0; j < 360; j += 60) {
                    angles.y = j;
                    G_FireGrenade(ent.origin, angles,
                            200, 100, 100, 100, 100, player.client.getEnt());
                }
            }
        }
        command.say(player.client.get_name() + " threw grenades at everyone");
    }

    void cmdMap(Command @command, Player @player, String &args, int argc,
            Players @players) {
        String @map = args.getToken(0);
        command.say(player.client.get_name() + " is changing to map " + map);
        exec("map", map);
    }

    void cmdDevmap(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String @map = args.getToken(0);
        command.say(player.client.get_name() + " is changing to devmap " + map);
        exec("devmap ", map);
    }

    void cmdCVar(Command @command, Player @player, String &args, int argc,
            Players @players) {
        String name = args.getToken(0);
        String cleanName = clean(name);
        Cvar cvar = Cvar(name, "", 0); // NOTE: resets the default value :-(
        if ((cleanName == "g_operator_password"
                    || cleanName == "rcon_password")
                && player.account.level < LEVEL_ROOT) {
            player.sayBad("Forget it.");
        } else if (argc == 1) {
            player.say(name + " is \"" + cvar.get_string() + "\"");
        } else if (clean(name).substr(0, 3) == "sv_"
                && player.account.level < LEVEL_ADMIN) {
            player.sayBad("Forget it.");
        } else {
            String value = args.getToken(1);
            cvar.set(value);
            if (cvar.get_string() != value)
                player.sayBad(
                        "Setting the Cvar seems to have failed. It's value is "
                        + cvar.get_string());
            else
                command.say(player.client.get_name() + " set " + name
                        + S_COLOR_RESET + " to \"" + value + S_COLOR_RESET
                        + "\"");
        }
    }

    void cmdShutdown(Command @command, Player @player, String &args,
            int argc, Players @players) {
        command.say(player.client.get_name() + " is shutting down the server");
        exec("quit");
    }

    void cmdDo(Command @command, Player @player, String &args,
            int argc, Players @players) {
        String @cmd = args.getToken(0);
        //command.say(player.client.get_name() + " is doing " + cmd);
        exec(cmd);
    }

    void cmdUnimplemented(Command @command, Player @player, String &args,
            int argc, Players @players) {
        player.say("Somehow this command was not implemented.\n"
                + "Please report this bug to a developer.");
    }
}
