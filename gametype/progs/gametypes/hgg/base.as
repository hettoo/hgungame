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

const float DUMMY_WEIGHT_MULTIPLIER = 0.4f;

class HGGBase {
    Gametype gt;
    Players players;
    Scoreboard scoreboard;
    Commands commands;
    Dummies dummies;

    int sound_dummy_killed;

    uint last_second;
    uint last_minute_second;

    HGGBase() {
        sound_dummy_killed = G_SoundIndex("sounds/misc/kill");

        last_second = 0;
        last_minute_second = 0;
    }

    void spawn_gametype() {
    }

    bool update_bot_status(cEntity @self) {
        GENERIC_UpdateBotStatus(self);
        cEntity @goal;
        cBot @bot = self.client.getBot();
        float offensiveness = GENERIC_OffensiveStatus(self);
        for (int i = 0; (@goal = bot.getGoalEnt(i)) != null; i++) {
            if (goal.getClassname() == "dummy")
                bot.setGoalWeight(i, DUMMY_WEIGHT_MULTIPLIER
                        * GENERIC_PlayerWeight(self, goal) * offensiveness);
        }
        return true;
    }

    cEntity @select_spawn_point(cEntity @self) {
        return GENERIC_SelectBestRandomSpawnPoint(self,
                "info_player_deathmatch");
    }

    bool command(cClient @client, cString &cmd, cString &args, int argc) {
        return commands.handle(client, cmd, args, argc, players);
    }

    void match_state_started() {
    }

    void warmup_started() {
        scoreboard.set_layout(SB_WARMUP);
        GENERIC_SetUpWarmup();
    }
    
    void countdown_started() {
        players.welcome_all(gt.motd());
        GENERIC_SetUpCountdown();
    }

    void playtime_started() {
        last_second = levelTime / 1000;
        last_minute_second = last_second;
        scoreboard.set_layout(SB_MATCH);
        players.update_best();
        players.update_hud();
        GENERIC_SetUpMatch();
    }

    void postmatch_started() {
        scoreboard.set_layout(SB_POST);
        GENERIC_SetUpEndMatch();
    }

    bool match_state_finished(int new_match_state) {
        if (match.getState() <= MATCH_STATE_WARMUP
                && new_match_state > MATCH_STATE_WARMUP
                && new_match_state < MATCH_STATE_POSTMATCH)
            match.startAutorecord();

        if (match.getState() == MATCH_STATE_POSTMATCH)
            match.stopAutorecord();

        if (new_match_state == MATCH_STATE_PLAYTIME)
            players.reset();

        return true;
    }

    void shutdown() {
        players.db.write();
    }

    void killed(cClient @attacker, cClient @target, cClient @inflictor) {
        players.killed(target, attacker, inflictor);
    }

    void score_event(cClient @client, cString &score_event, cString &args) {
        if (score_event == "kill") {
            cClient @target = G_GetEntity(args.getToken(0).toInt()).client;
            cClient @inflictor = G_GetEntity(args.getToken(1).toInt()).client;
            killed(client, target, inflictor);
        } else if (score_event == "userinfochanged") {
            players.namechange(client);
        } else if (score_event == "disconnect") {
            players.disconnect(client);
        }
    }

    void set_gametype_settings() {
        gt.set_defaults();
    }

    void check_root() {
        if (!players.db.has_root && gt.root() != "") {
            DBItem @root = DBItem();
            root.id = gt.root();
            root.password = gt.root_password();
            players.db.add(root);
        }
    }

    void init_gametype() {
        players.init();
        players.db.read();

        gt.set_info();
        gt.init();
        check_root();
        set_gametype_settings();
        gt.check_default_config();

        commands.init();

        debug("Gametype '" + gametype.getTitle() + "' initialized");
    }

    void think_rules() {
        if (match.scoreLimitHit() || match.timeLimitHit()
                || match.suddenDeathFinished())
            match.launchState(match.getState() + 1);

        if (match.getState() >= MATCH_STATE_POSTMATCH)
            return;

        GENERIC_Think();
        players.charge_gunblades();
        check_time();
    }

    void player_respawn(cEntity @ent, int old_team, int new_team) {
        if (old_team == TEAM_SPECTATOR && new_team != TEAM_SPECTATOR)
            players.new_player(ent.client);
        else if (old_team != TEAM_SPECTATOR && new_team == TEAM_SPECTATOR)
            players.new_spectator(ent.client);

        if (new_team != TEAM_SPECTATOR)
            players.respawn(ent.client);
    }

    void check_time() {
        uint second = levelTime / 1000;
        if (second != last_second) {
            uint minute_second = last_minute_second + 60;
            if (second == minute_second) {
                players.increase_minutes();
                dummies.spawn();
                last_minute_second = minute_second;
            }
            last_second = second;
        }
    }

    void dummy_killed(cEntity @self, cEntity @attacker, cEntity @inflictor) {
        G_Sound(attacker, CHAN_PAIN, sound_dummy_killed, ATTN_UNHEARABLE);
        players.killed_anyway(null, attacker.client, inflictor.client);
        self.freeEntity();
        @self = null;
    }
}

