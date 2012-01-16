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

    void playtime_started() {
        set_spawn_system(SPAWNSYSTEM_HOLD, true);
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

        if (count_alpha + count_beta == 0)
            center_notify("Draw Round!");
        else if (count_alpha > 0)
            players.team_scored(TEAM_ALPHA);
        else
            players.team_scored(TEAM_BETA);

        @spawn_alpha = null;
        @spawn_beta = null;
    }

    void check_teams(int penalty_team) {
        int count_alpha = players.count_alive(TEAM_ALPHA)
            - (penalty_team == TEAM_ALPHA ? 1 : 0);
        int count_beta = players.count_alive(TEAM_BETA)
            - (penalty_team == TEAM_BETA ? 1 : 0);
        if (count_alpha == 0 || count_beta == 0) {
            gametype.shootingDisabled = true;
            countdown_end = COUNTDOWN_END;
        }
    }

    void show_sound(cString &sound) {
        G_AnnouncerSound(null,
                G_SoundIndex(sound + int(brandom(1, 2))), GS_MAX_TEAMS, false,
                null);
    }

    void show_counter(int countdown, cString &sound) {
        show_sound(sound);
        center_notify(countdown + "");
    }

    void count_down_start() {
        countdown_start--;
        if (countdown_start == COUNTDOWN_START - 1) {
            show_sound("sounds/announcer/countdown/ready0");
        } else if (countdown_start == 0) {
            countdown_start = UNKNOWN;
            gametype.shootingDisabled = false;
            G_AnnouncerSound(null,
                    G_SoundIndex("sounds/announcer/countdown/fight0"
                        + int(brandom(1, 2))), GS_MAX_TEAMS, false, null);
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
        HGGBase::new_spectator(client);
        check_teams(0);
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        HGGBase::killed(attacker, target, inflictor);

        if (!for_real())
            return;

        if (@attacker != null && @target != null)
            check_teams(target.team);
    }
}

