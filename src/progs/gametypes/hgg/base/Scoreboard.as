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

    int iconYes;
    int iconNo;

    Scoreboard() {
        iconYes = G_ImageIndex("gfx/hud/icons/vsay/yes");
        iconNo = G_ImageIndex("gfx/hud/icons/vsay/no");
    }

    void warmupLayout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT + " %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE + " R");
    }

    void matchLayout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT + " %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE + " W");
    }

    void postLayout() {
        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, SB_BASE_LAYOUT);
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES, SB_BASE_TITLE);
    }

    void setLayout(int newState) {
        state = newState;
        switch (state) {
            case SB_WARMUP:
                warmupLayout();
                break;
            case SB_MATCH:
                matchLayout();
                break;
            case SB_POST:
                postLayout();
                break;
        }
    }

    void addTeam(cString &scoreboard, int id, int maxLen, Players @players) {
        cTeam @team = @G_GetTeam(id);
        stringAddMaxed(scoreboard, "&t " + id + " " + team.stats.score + " "
                + team.ping + " ", maxLen);
        addTeamPlayers(scoreboard, id, maxLen, players);
    }

    void addTeamPlayers(cString &scoreboard, int id, int maxLen,
            Players @players) {
        cTeam @team = @G_GetTeam(id);
        for (int i = 0; @team.ent(i) != null; i++)
            addPlayer(scoreboard, team.ent(i), maxLen, players);
    }

    void addPlayer(cString &scoreboard, cEntity @ent, int maxLen,
            Players @players) {
        Player @player = players.get(ent.client.playerNum());
        int id = ent.isGhosting() && forReal() ? -(ent.playerNum() + 1)
            : ent.playerNum();
        cString registeredColor = player.state == AS_IDENTIFIED
            ? S_COLOR_PERSISTENT : S_COLOR_TEMPORARY;
        cString entry = "&p " + players.levels.icon(player.account.level) + " "
            + id + " " + ent.client.getClanName() + " " + ent.client.stats.score
            + " " + registeredColor + player.account.row + " "
            + ent.client.ping + " " + player.minutesPlayed + " ";
        if (state == SB_WARMUP)
            entry += (ent.client.isReady() ? iconYes : iconNo) + " ";
        else if (state == SB_MATCH)
            entry += players.weapons.icon(players.weapons.award(player.row))
                + " ";
        stringAddMaxed(scoreboard, entry, maxLen);
    }
}
