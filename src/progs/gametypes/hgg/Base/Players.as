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

const int SPECIAL_ROW = 5;
const int MAX_PLAYERS = 256;

class Players {
    Player@[] players;
    int size;
    Database db;
    Levels levels;
    Weapons weapons;
    Dummies dummies;
    bool teamHUD;

    bool firstBlood;

    int bestScore;
    int secondScore;

    int matchTopRow;
    String[] matchTopRowPlayers;
    int matchTopRowPlayerCount;

    int soundDummyKilled;

    Players() {
        players.resize(MAX_PLAYERS);
        size = 0;
        teamHUD = false;

        firstBlood = true;

        bestScore = UNKNOWN;
        secondScore = UNKNOWN;

        matchTopRow = UNKNOWN;
        matchTopRowPlayers.resize(MAX_PLAYERS);

        soundDummyKilled = G_SoundIndex("sounds/misc/kill");
    }

    void init() {
        db.init();
    }

    Player @get(int playernum) {
        if (playernum < 0 || playernum >= size)
            return null;
        return players[playernum];
    }

    void initClient(cClient @client) {
        int playernum = client.playerNum;
        Player @player = get(playernum);
        if (@player == null) {
            @players[playernum] = Player();
            if (playernum >= size)
                size = playernum + 1;
        }
        players[playernum].init(client, db);
    }

    void reset() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                checkRow(player.client, null);
                player.minutesPlayed = 0;
                player.setScore(0);
            }
        }
    }

    void announceRow(cClient @target, cClient @attacker) {
        int row = get(target.playerNum).row;
        target.addAward(highlight("You made a row of " + highlightRow(row)
                    + "!"));
        String msg = target.get_name() + highlight(" made a row of "
            + highlightRow(row) + "!");
        if (@target == @attacker)
            msg += highlight(" He fragged ") + S_COLOR_BAD + "himself"
                + highlight("!");
        else if (@attacker != null)
            msg += highlight(" He was fragged by ") + attacker.get_name()
                + highlight("!");
        notify(msg);
    }

    void tryUpdateRank(Player @player) {
        int oldRank = player.account.rank;
        if (db.ranking.update(player.account)) {
            if (player.account.rank != oldRank) {
                player.client.addAward(S_COLOR_RECORD
                        + "You claimed server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
                notify(player.client.get_name() + S_COLOR_RECORD
                        + " claimed server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
            } else {
                notify(player.client.get_name() + S_COLOR_RECORD
                        + " still holds server rank "
                        + highlight(player.account.rank)
                        + S_COLOR_RECORD + "!");
            }
        }
    }

    void checkRow(cClient @target, cClient @attacker) {
        if (@target == null)
            return;

        Player @player = get(target.playerNum);
        bool newRecord = player.updateRow() && player.state == AS_IDENTIFIED;
        if (player.row >= SPECIAL_ROW)
            announceRow(target, attacker);
        if (newRecord) {
            target.addAward(S_COLOR_RECORD + "Personal record!");
            tryUpdateRank(player);
        }
        if (forReal()
                && (player.row >= matchTopRow || matchTopRow == UNKNOWN)) {
            if (player.row == matchTopRow) {
                bool hasMatchTopRow = false;
                for (int i = 0; i < matchTopRowPlayerCount; i++) {
                    if (matchTopRowPlayers[i] == player.client.get_name())
                        hasMatchTopRow = true;
                }
                if (!hasMatchTopRow)
                    matchTopRowPlayers[matchTopRowPlayerCount++]
                        = player.client.get_name();
            } else {
                matchTopRow = player.row;
                matchTopRowPlayerCount = 1;
                matchTopRowPlayers[0] = player.client.get_name();
            }
        }
        player.row = 0;
    }

    void showMatchTopRow() {
        if (matchTopRow == UNKNOWN)
            return;
        String msg = highlight("Match top row: " + highlightRow(matchTopRow)
                + " frags by ");
        for (int i = 0; i < matchTopRowPlayerCount; i++) {
            msg += matchTopRowPlayers[i];
            if (i < matchTopRowPlayerCount - 1) {
                if (i == matchTopRowPlayerCount - 2)
                    msg += highlight(" and ");
                else
                    msg += highlight(", ");
            }
        }
        notify(msg);
    }

    void checkRows() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null)
                checkRow(player.client, null);
        }
    }

    void award(cClient @client, int row, bool real, int weapon, int ammo) {
        Player @player = get(client.playerNum);
        if (real) {
            player.addScore(1);
            if (!gametype.get_isInstagib()) {
                client.getEnt().health += NW_HEALTH_BONUS;
                float newArmor = client.armor + NW_ARMOR_BONUS;
                if (newArmor < MAX_ARMOR)
                    client.armor = newArmor;
                else
                    client.armor = MAX_ARMOR;
            }

            if (teamHUD) {
                updateHUDTeams(otherTeam(client.team));
            } else {
                player.updateHUDSelf();
                updateBest();

                if (player.score == bestScore)
                    updateHUD();
                else if (player.score == secondScore)
                    updateHUDBests();
            }
        }

        int award = weapons.award(row);
        if (award == WEAP_NONE)
            return;

        if (award < WEAP_TOTAL)
            awardWeapon(client, award,
                    ammo == INFINITY ? weapons.ammo(award) : ammo, real);
        else if (real)
            get(client.playerNum).showRow();

        if (weapons.weak(weapon)) {
            int award;
            for (int i = 0; i <= player.row
                    && (award = weapons.award(i)) != WEAP_TOTAL; i++) {
                if (weapons.heavy(award))
                    increaseAmmo(client, award);
            }
        }
    }

    void award(cClient @client, int row, bool real, int weapon) {
        award(client, row, true, weapon, INFINITY);
    }

    void award(cClient @client, int row, int weapon) {
        award(client, row, true, weapon);
    }

    void award(cClient @client, int weapon) {
        award(client, get(client.playerNum).row, weapon);
    }

    void killedAnyway(cClient @target, cClient @attacker, cClient @inflictor) {
        if (@attacker == null || @attacker == @target)
            return;

        Player @player = get(attacker.playerNum);
        if (@target == null)
            player.center("YOU FRAGGED " + highlight("A DUMMY"));
        player.killer();
        int weapon = attacker.weapon; // FIXME: mod
        award(attacker, weapon);
        checkDecreaseAmmo(attacker, weapon);
        player.updateAmmo();
        if (forReal() && firstBlood) {
            attacker.addAward(highlight("First blood!"));
            notify(attacker.get_name() + highlight(" drew first blood!"));
            firstBlood = false;
        }
    }

    void killed(cClient @target, cClient @attacker, cClient @inflictor) {
        if (match.getState() > MATCH_STATE_PLAYTIME || @target == null)
            return;

        Player @player = get(target.playerNum);
        player.alive = false;
        if (@attacker != null)
            player.say("You have been fragged by " + attacker.get_name());
        player.killed();
        checkRow(target, attacker);

        killedAnyway(target, attacker, inflictor);
    }

    void checkDecreaseAmmo(cClient @client, int weapon) {
        if (weapon < WEAP_TOTAL && weapons.ammo(weapon) != INFINITY) {
            if (!decreaseAmmo(client, weapon) && client.weapon == weapon)
                weapons.selectBest(client);
        }
    }

    void giveSpawnWeapons(cClient @client) {
        Player @player = get(client.playerNum);
        weapons.giveDefault(client);
        for (int i = 1; i <= player.row; i++) {
            int award = weapons.award(i);
            if (award < WEAP_TOTAL) {
                int ammo = player.getAmmo(award);
                award(client, i, false, WEAP_NONE,
                        weapons.ammo(award) == INFINITY
                        ? INFINITY : player.getAmmo(award));
            }
        }
    }

    void respawn(cClient @client) {
        Player @player = get(client.playerNum);
        player.alive = true;

        if (teamHUD) {
            updateHUDTeams();
        } else {
            player.updateHUDSelf();
            player.updateHUDOther(this);
        }

        giveSpawnWeapons(client);
        weapons.selectBest(client);
        client.getEnt().respawnEffect();
        if (!gametype.get_isInstagib()) {
            client.getEnt().health = NW_HEALTH;
            client.armor = NW_ARMOR;
        }
    }

    void resetStats() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null)
                player.client.stats.clear();
        }
    }

    void newSecond() {
        dummies.newSecond();
    }

    void newMinute() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.team != TEAM_SPECTATOR)
                player.addMinute();
        }
    }

    void updateBest(int i) {
        Player @player = get(i);
        if (@player != null) {
            cClient @client = player.client;
            if (@client != null && client.team != TEAM_SPECTATOR) {
                if (player.score >= bestScore || bestScore == UNKNOWN) {
                    secondScore = bestScore;
                    bestScore = player.score;
                } else if (player.score > secondScore
                        || secondScore == UNKNOWN) {
                    secondScore = player.score;
                }
            }
        }
    }

    void updateBest() {
        bestScore = UNKNOWN;
        secondScore = UNKNOWN;
        for (int i = 0; i < size; i++)
            updateBest(i);
    }

    void updateHUD() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null)
                player.updateHUDOther(this);
        }
    }

    void updateHUDBests() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && player.score == bestScore)
                player.updateHUDOther(this);
        }
    }

    void updateHUDTeams(Player @player, int penaltyTeam) {
        player.updateHUDTeams(countAlive(TEAM_ALPHA)
                - (penaltyTeam == TEAM_ALPHA ? 1 : 0),
                countAlive(TEAM_BETA)
                - (penaltyTeam == TEAM_BETA ? 1 : 0));
    }

    void updateHUDTeams(Player @player) {
        updateHUDTeams(player, GS_MAX_TEAMS);
    }

    void updateHUDTeams(int penaltyTeam) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && player.client.team != TEAM_SPECTATOR)
                updateHUDTeams(player, penaltyTeam);
        }
    }

    void updateHUDTeams() {
        updateHUDTeams(GS_MAX_TEAMS);
    }

    void newPlayer(cClient @client) {
        Player @player = get(client.playerNum);
        if (player.ipCheck()) {
            String ip = getIP(player.client);
            String password = Cvar("rcon_password", "", 0).get_string();
            if (!db.hasRoot && player.state == AS_UNKNOWN && !client.isBot()
                    && (ip == "127.0.0.1" || ip == "")) {
                if (password == "") {
                    player.say(S_COLOR_ADMINISTRATIVE
                            + "Please set your servers rcon_password and rejoin"
                            + " a players team to auto-register as "
                            + levels.name(LEVEL_ROOT) + ".");
                } else {
                    player.account.level = LEVEL_ROOT;
                    player.setRegistered(password);
                    db.add(player.account, false);
                    player.administrate("You have been auto-registered as "
                            + levels.name(LEVEL_ROOT));
                    player.say(S_COLOR_ADMINISTRATIVE + "Your password has been"
                            + " set to your rcon_password.");
                    tryUpdateRank(player);
                }
            }
            player.syncScore();
            player.instruct(levels.greeting(player.account.level, "") != "");
            player.greet(levels);

            if (teamHUD) {
                updateHUDTeams(player);
            } else {
                if (count() <= 2 || player.score > secondScore) {
                    updateBest();
                    updateHUD();
                }
            }
        }
    }

    void newSpectator(cClient @client) {
        Player @player = get(client.playerNum);
        player.alive = false;
        checkRow(client, null);
        if (player.score == bestScore || player.score == secondScore) {
            updateBest();
            updateHUD();
        }
    }

    void namechange(cClient @client) {
        initClient(client);
        Player @player = get(client.playerNum);
        if (player.client.team != TEAM_SPECTATOR)
            player.ipCheck();
    }

    void disconnect(cClient @client) {
        int playernum = client.playerNum;
        @players[playernum] = null;
        for (int i = playernum; i < size; i++) {
            if (@players[i] != null)
                return;
        }
        size = playernum;
    }

    void fixHealth() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.state() >= CS_SPAWNED) {
                cEntity @ent = player.client.getEnt();
                if (ent.team != TEAM_SPECTATOR && ent.health > ent.maxHealth)
                    ent.health -= (frameTime * 0.001f);
            }
        }
    }

    void chargeGunblades() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.state() >= CS_SPAWNED
                    && player.client.getEnt().team != TEAM_SPECTATOR)
                GENERIC_ChargeGunblade(player.client);
        }
    }

    void teamScored(int team) {
        G_GetTeam(team).stats.addScore(1);

        randomAnnouncerSound(team, "sounds/announcer/ctf/score_team0");
        randomAnnouncerSound(otherTeam(team),
                "sounds/announcer/ctf/score_enemy0");
    }

    void respawn() {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null
                    && player.client.team != TEAM_SPECTATOR)
                player.client.respawn(false);
        }
    }

    int countAlive(int team, cClient @target) {
        int n = 0;
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && @client != @target && client.team == team
                        && !client.getEnt().isGhosting())
                    n++;
            }
        }
        return n;
    }

    int countAlive(int team) {
        return countAlive(team, null);
    }

    Player @getAlive(int team, cClient @target) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && @client != @target && client.team == team
                        && !client.getEnt().isGhosting())
                    return player;
            }
        }
        return null;
    }

    Player @getAlive(int team) {
        return getAlive(team, null);
    }

    int count() {
        int n = 0;
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && client.team != TEAM_SPECTATOR)
                    n++;
            }
        }
        return n;
    }

    void sayTeam(int team, String &msg) {
        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null) {
                cClient @client = player.client;
                if (@client != null && client.team == team)
                    player.say(msg);
            }
        }
    }

    void shuffle() {
        int[] total;
        int totalSize = 0;
        total.resize(size);

        for (int i = 0; i < size; i++) {
            Player @player = get(i);
            if (@player != null && @player.client != null) {
                if (player.client.team == TEAM_ALPHA
                        || player.client.team == TEAM_BETA)
                    total[totalSize++] = i;
            }
        }

        int countAlpha = 0;
        int countBeta = 0;
        for (int i = 0; i < totalSize; i++) {
            Player @player = get(i);
            bool equal = countAlpha == countBeta;
            if (countAlpha == totalSize / 2 && !equal) {
                player.putTeam(TEAM_BETA);
                countBeta++;
            } else if (countBeta == totalSize / 2 && !equal) {
                player.putTeam(TEAM_ALPHA);
                countAlpha++;
            } else if (brandom(0, 2) < 1) {
                player.putTeam(TEAM_ALPHA);
                countAlpha++;
            } else {
                player.putTeam(TEAM_BETA);
                countBeta++;
            }
        }
    }

    void dummyKilled(int id, cClient @attacker, cClient @inflictor) {
        painSound(attacker, soundDummyKilled);
        killedAnyway(null, attacker, inflictor);
        Dummy @dummy = dummies.get(id);
        dummy.die();
    }
}
