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

enum AccountStates {
    AS_UNKNOWN,
    AS_WRONG_IP,
    AS_IDENTIFIED
};

class Player {
    bool inited;
    cClient @client;
    bool alive;
    bool greeted;
    int[] ammo;
    int row;
    int minutes_played;

    int score;

    int state;
    Account @account;

    Player () {
        inited = false;
        alive = false;
        greeted = false;
        ammo.resize(WEAP_TOTAL);
    }

    void init(cClient @new_client, DataBase @db) {
        bool update = @client == @new_client;
        if (!update) {
            if (@new_client == null || inited)
                return;
            else
                inited = true;

            @client = @new_client;
            row = 0;
            minutes_played = 0;
            score = 0;
        }

        Account @backup = @account;
        @account = db.find(raw(client.getName()));
        if (@account == null) {
            if (!update || state != AS_UNKNOWN) {
                state = AS_UNKNOWN;
                @account = @Account();
                account.init(client);
            } else {
                @account = @backup;
            }
        } else {
            String ip = get_ip(client);
            if (ip == account.ip || (ip == "" && account.ip == "127.0.0.1"))
                state = AS_IDENTIFIED;
            else
                state = AS_WRONG_IP;
        }
    }

    void reset_row() {
        row = 0;
    }

    void put_team(int team, bool ghost) {
        client.team = team;
        client.respawn(ghost);
    }

    void put_team(int team) {
        put_team(team, team == TEAM_SPECTATOR || client.getEnt().isGhosting());
    }

    void force_spec(String &msg) {
        put_team(TEAM_SPECTATOR, true);
        client.addAward(S_COLOR_BAD + msg);
    }

    bool ip_check() {
        if (state == AS_WRONG_IP) {
            force_spec("Wrong IP");
            return false;
        }
        return true;
    }

    void set_registered(String &password) {
        state = AS_IDENTIFIED;
        account.set_password(password);
    }

    void set_level(int level) {
        administrate("You are now a level " + level + " user!");
        account.level = level;
    }

    void greet(Levels @levels) {
        if (!greeted && state == AS_IDENTIFIED) {
            notify(levels.greeting(account.level, client.getName()));
            greeted = true;
        }
    }

    void instruct(bool greeted) {
        say("Fork me on GitHub: github.com/hettoo/hgungame");
        if (!greeted)
            say(S_COLOR_SPECIAL + "Welcome " + S_COLOR_RESET + client.getName()
                    + S_COLOR_SPECIAL + " and have fun!");
        say(S_COLOR_SPECIAL + "Use /" + COMMAND_BASE
                + " to see the commands you may use here!");
    }

    void welcome(String &msg) {
        if (@client != null && client.team != TEAM_SPECTATOR)
            client.addAward(msg);
    }

    void sync_score() {
        client.stats.setScore(score);
    }

    void add_score(int n) {
        score += n;
        sync_score();
    }

    void set_score(int n) {
        score = n;
        sync_score();
    }

    void show_row() {
        client.addAward(S_COLOR_ROW + row + "!");
    }

    void killer() {
        row++;
        account.add_kill();
    }

    void update_ammo() {
        for (int i = 0; i < WEAP_TOTAL; i++)
            ammo[i] = ammo(client, i);
    }

    void killed() {
        account.add_death();
    }

    void add_minute() {
        minutes_played++;
        account.add_minute();
    }

    bool update_row() {
        if (for_real())
            return account.update_row(row);
        return false;
    }

    int get_ammo(int weapon) {
        return ammo[weapon];
    }

    void update_hud_self() {
        if (client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL + client.playerNum() + 2;
        client.setHUDStat(STAT_MESSAGE_ALPHA, config_index);
        G_ConfigString(config_index, "[ " + score + " ]");
    }

    void update_hud_other(Players @players) {
        if (@client == null || client.team == TEAM_SPECTATOR)
            return;

        int config_index = CS_GENERAL;
        if (score == players.best_score)
            config_index++;
        client.setHUDStat(STAT_MESSAGE_BETA, config_index);
        if (players.best_score == UNKNOWN
                || (score == players.best_score
                    && players.second_score == UNKNOWN) || players.count() == 0)
            G_ConfigString(config_index, "[ ? ]");
        else
            G_ConfigString(config_index, "[ "
                    + (score == players.best_score ? players.second_score
                        : players.best_score) + " ]");
    }

    void update_hud_teams(int count_alpha, int count_beta) {
        client.setHUDStat(STAT_MESSAGE_ALPHA, CS_GENERAL);
        G_ConfigString(CS_GENERAL, "- " + count_alpha + " -");
        client.setHUDStat(STAT_MESSAGE_BETA, CS_GENERAL + 1);
        G_ConfigString(CS_GENERAL + 1, "- " + count_beta + " -");
    }

    void print(String &msg) {
        client.printMessage(msg);
    }

    void center(String &msg) {
        G_CenterPrintMsg(client.getEnt(), msg);
    }

    void say(String &msg) {
        print(msg + "\n");
    }

    void say_bad(String &msg) {
        say(S_COLOR_BAD + msg);
    }

    void administrate(String &msg) {
        client.addAward(S_COLOR_ADMINISTRATIVE + msg);
    }
}
