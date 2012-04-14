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

const cString SB_BASE_LAYOUT = "%p 18 %n 112 %s 52 %i 39 %s 39 %l 52 %i 26";
const cString SB_BASE_TITLE = "L Name Clan Scr Row Ping Tm";

enum ScoreboardStates {
    SB_WARMUP,
    SB_MATCH,
    SB_POST
};

class Scoreboard {
    int state;

    int icon_yes;
    int icon_no;

    Scoreboard() {
        icon_yes = G_ImageIndex("gfx/hud/icons/vsay/yes");
        icon_no = G_ImageIndex("gfx/hud/icons/vsay/no");
    }

    void warmup_layout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT + " %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE + " R");
    }

    void match_layout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT + " %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE + " W");
    }

    void post_layout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT);
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE);
    }

    void set_layout(int new_state) {
        state = new_state;
        switch (state) {
            case SB_WARMUP:
                warmup_layout();
                break;
            case SB_MATCH:
                match_layout();
                break;
            case SB_POST:
                post_layout();
                break;
        }
    }

    void add_team(cString &scoreboard, int id, int max_len, Players @players) {
        cTeam @team = @G_GetTeam(id);
        string_add_maxed(scoreboard, "&t " + id + " " + team.stats.score + " "
                + team.ping + " ", max_len);
        add_team_players(scoreboard, id, max_len, players);
    }

    void add_team_players(cString &scoreboard, int id, int max_len,
            Players @players) {
        cTeam @team = @G_GetTeam(id);
        for (int i = 0; @team.ent(i) != null; i++)
            add_player(scoreboard, team.ent(i), max_len, players);
    }

    void add_player(cString &scoreboard, cEntity @ent, int max_len,
            Players @players) {
        Player @player = players.get(ent.client.playerNum());
        int id = ent.isGhosting() && for_real() ? -(ent.playerNum() + 1)
            : ent.playerNum();
        cString registered_color = player.state == AS_IDENTIFIED
            ? S_COLOR_PERSISTENT : S_COLOR_TEMPORARY;
        cString entry = "&p " + players.levels.icon(player.account.level) + " "
            + id + " " + ent.client.getClanName() + " " + ent.client.stats.score
            + " " + registered_color + player.account.row + " "
            + ent.client.ping + " " + player.minutes_played + " ";
        if (state == SB_WARMUP)
            entry += (ent.client.isReady() ? icon_yes : icon_no) + " ";
        else if (state == SB_MATCH)
            entry += players.weapons.icon(players.weapons.award(player.row))
                + " ";
        string_add_maxed(scoreboard, entry, max_len);
    }
}
