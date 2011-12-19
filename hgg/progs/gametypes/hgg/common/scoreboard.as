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

class Scoreboard {
    Scoreboard() {
        // Assuming 13 px per char, 18 px for images and less than 100 minutes
        // playtime.

        G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT,
                "%n 114 %s 26 %s 52 %i 39 %s 39 %i 26 %l 52 %p 18");
        G_ConfigString(CS_SCB_PLAYERTAB_TITLES,
                "Name Lv Clan Frags Row Time Ping R");

    }

    void add_team(cString &scoreboard, int id, int max_len,
            Icons @icons, Players @players) {
        cTeam @team = @G_GetTeam(id);
        string_add_maxed(scoreboard, "&t " + id + " " + team.stats.score + " "
                + team.ping + " ", max_len);
        add_team_players(scoreboard, id, max_len, icons, players);
    }

    void add_team_players(cString &scoreboard, int id, int max_len,
            Icons @icons, Players @players) {
        cTeam @team = @G_GetTeam(id);
        for (int i = 0; @team.ent(i) != null; i++)
            add_player(scoreboard, team.ent(i), max_len, icons, players);
    }

    void add_player(cString &scoreboard, cEntity @ent, int max_len,
            Icons @icons, Players @players) {
        int readyIcon = 0;
        Player @player = players.get(ent.client.playerNum());
        cString registered_color = player.dbitem.state == DBI_IDENTIFIED
            ? S_COLOR_PERSISTENT : S_COLOR_NOT_PERSISTENT;
        if (ent.client.isReady())
            readyIcon = icons.yes;
        cString entry = "&p " + ent.playerNum() + " " + registered_color
            + player.dbitem.level + " " + ent.client.getClanName() + " "
            + ent.client.stats.score + " " + registered_color
            + player.dbitem.row + " " + player.minutes_played + " "
            + ent.client.ping + " " + readyIcon + " ";
        string_add_maxed(scoreboard, entry, max_len);
    }
}
