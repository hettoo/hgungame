# hGunGame

Series of Warsow gametype scripts.

## Usage

Read the head of the makefile to see what variables you can set per server. It
is recommended to use `make` to run your servers.

Use `make local` to just create and copy the pk3 file, so you can create a
personal server from your client. If you can't use make, just put the content
of the gametype/ folder in a zip file, rename it to .pk3 and put it in your
basewsw/ folder.

Use `make dev` to remove config files and run the server once. This is used for
testing.

Use `make production` to run the server once.
Use `make productionloop` to repeat running the server, so that it will restart
when it is shutdown or it crashes. Note that this disables input from the
console (you can use rcon and the builtin administration system though).

You can run multiple servers on the same machine like this:

```sh
make productionloop GT=hgg_ffa PORT=44400 NAME='hGunGame FFA Server' &
make productionloop GT=hgg_ca PORT=44401 NAME='hGunGame CA Server' &
```

This will keep two servers (one for FFA and one for CA) running in the
background.

I would recommend a `basewsw/dedicated_autoexec.cfg` that looks something like
this:

```
set sv_maxclients 20

set g_disable_vote_gametype 1
set g_disable_vote_challengers_queue 1
set g_disable_vote_allow_falldamage 1
set g_disable_vote_allow_selfdamage 1
set g_disable_vote_allow_teamdamage 1
set g_disable_vote_instashield 1
set g_disable_vote_instajump 1
set g_disable_vote_maxteamplayers 1
set g_disable_vote_timelimit 1
set g_disable_vote_warmup_timelimit 1
set g_disable_vote_scorelimit 1
set g_disable_vote_kickban 1
```
