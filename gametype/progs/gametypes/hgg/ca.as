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

const int COUNTDOWN_START = 6;
const int COUNTDOWN_END = 4;
const int COUNTDOWN_SOUND_MAX = 3;

const cString ONE_VS_ONE = "1v1! Good luck!";
const cString LAST_PLAYER = S_COLOR_GREEN + "Last Player Standing!";

class HGG : HGGBase {
    int countdown_start;
    int countdown_end;

    HGG() {
        countdown_start = UNKNOWN;
        countdown_end = UNKNOWN;
    }

    void set_gametype_settings() {
        HGGBase::set_gametype_settings();

        gametype.isTeamBased = true;
        gametype.teamOnlyMinimap = true;
    }

    void init_gametype() {
        gt.name = "Clan Arena";
        gt.type = GT_CA;
        HGGBase::init_gametype();
    }

    void start_round() {
        gametype.shootingDisabled = true;
        countdown_start = COUNTDOWN_START;
    }

    void countdown_started() {
        gametype.shootingDisabled = true;
        lock_teams();
        random_announcer_sound(
                "sounds/announcer/countdown/get_ready_to_fight0");
    }

    void generic_playtime_started() {
        G_RemoveAllProjectiles();
        players.respawn();
        players.reset_stats();
    }

    void playtime_started() {
        gt.set_spawn_system(SPAWNSYSTEM_HOLD, true);
        HGGBase::playtime_started();
        start_round();
    }

    void new_round() {
        players.respawn();
        start_round();
    }

    void end_round() {
        G_RemoveDeadBodies();
        G_RemoveAllProjectiles();

        int count_alpha = players.count_alive(TEAM_ALPHA);
        int count_beta = players.count_alive(TEAM_BETA);

        if (count_alpha + count_beta == 0) {
            center_notify("Draw Round!");
        } else if (count_alpha > 0) {
            if (count_alpha == 1 && players.count() > 2)
                players.get_alive(TEAM_ALPHA).client.addAward(LAST_PLAYER);
            players.team_scored(TEAM_ALPHA);
        } else {
            if (count_beta == 1 && players.count() > 2)
                players.get_alive(TEAM_BETA).client.addAward(LAST_PLAYER);
            players.team_scored(TEAM_BETA);
        }

        @spawn_alpha = null;
        @spawn_beta = null;
    }

    void one_versus(int count, int team, cClient @target) {
        Player @alive = players.get_alive(team, target);
        if (count == 1) {
            int other_team = other_team(team);
            Player @other_alive = players.get_alive(other_team, target);
            notify(ONE_VS_ONE);
            alive.client.addAward(S_COLOR_SPECIAL + ONE_VS_ONE);
            other_alive.client.addAward(S_COLOR_SPECIAL + ONE_VS_ONE);
        } else {
            alive.client.addAward("1v" + count + "! You're on your own!");
            players.say_team(team, "1v" + count + "! " + alive.client.getName()
                    + " is on its own!");
        }
    }

    void check_teams(cClient @target) {
        int count_alpha = players.count_alive(TEAM_ALPHA, target);
        int count_beta = players.count_alive(TEAM_BETA, target);
        if (count_alpha == 0 || count_beta == 0) {
            gametype.shootingDisabled = true;
            countdown_end = COUNTDOWN_END;
        } else if (count_alpha == 1 || count_beta == 1) {
            if (count_alpha == 1)
                one_versus(count_beta, TEAM_ALPHA, target);
            else
                one_versus(count_alpha, TEAM_BETA, target);
        }
    }

    void check_teams() {
        check_teams(null);
    }

    void show_counter(int countdown, cString &sound) {
        random_announcer_sound(sound);
        center_notify(countdown + "");
    }

    void count_down_start() {
        countdown_start--;
        if (countdown_start == COUNTDOWN_START - 2) {
            random_announcer_sound("sounds/announcer/countdown/ready0");
        } else if (countdown_start == 0) {
            countdown_start = UNKNOWN;
            gametype.shootingDisabled = false;
            random_announcer_sound("sounds/announcer/countdown/fight0");
            center_notify("Fight!");
        } else if (countdown_start <= COUNTDOWN_SOUND_MAX) {
            show_counter(countdown_start, "sounds/announcer/countdown/"
                    + countdown_start + "_0");
        }
    }

    void count_down_end() {
        countdown_end--;
        if (countdown_end == 2) {
            end_round();
        } else if (countdown_end == 0) {
            countdown_end = UNKNOWN;
            new_round();
        }
    }

    void new_second() {
        HGGBase::new_second();
        if (countdown_start != UNKNOWN)
            count_down_start();
        if (countdown_end != UNKNOWN)
            count_down_end();
    }

    void new_spectator(cClient @client) {
        bool was_alive = players.get(client.playerNum()).alive;
        HGGBase::new_spectator(client);

        if(!for_real())
            return;

        if (was_alive)
            check_teams();
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);

        if (!for_real())
            return;

        if (@attacker != null && @target != null)
            check_teams(target);
    }
}

