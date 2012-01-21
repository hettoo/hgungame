# hGunGame

Series of Warsow gametype scripts.

# Usage

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

If you want multiple servers running on the same machine, you could put a script
like this in your home directory:

```sh
cd hgungame/
make productionloop GT=hgg_ffa PORT=44400 NAME='hGunGame FFA Server' &
make productionloop GT=hgg_ca PORT=44401 NAME='hGunGame CA Server' &
```

Note that it assumes hGunGame is cloned into the hgungame/ folder in your home
directory. This will repeatedly run two servers (one for FFA and one for CA) in
the background. If you have access to the root account on your server and you
named the above script `server.sh`, you can now insert the following into your
`/etc/rc.local` script:

```sh
su username -c 'cd; sh server.sh'
```

And it will be run every time after a reboot.

I would recommend a basewsw/dedicated_autoexec.cfg that looks something like
this:

```cfg
set sv_public 1
set sv_uploads 1
set sv_uploads_from_server 0
set sv_uploads_baseurl "http://warsow-esport.net/~warsow05/mirror/"
set sv_maxclients 24
set sv_pure 0

set rcon_password ""
set g_operator_password ""

set sv_skilllevel 0
set g_numbots 0

set sv_defaultmap "wdm2"

set g_disable_vote_gametype 1
set g_disable_vote_challengers_queue 1
set g_disable_vote_allow_falldamage 1
set g_disable_vote_allow_selfdamage 1
set g_disable_vote_allow_teamdamage 1
set g_disable_vote_allow_uneven 1
set g_disable_vote_instashield 1
set g_disable_vote_instajump 1
set g_disable_vote_maxteamplayers 1
set g_disable_vote_timelimit 1
set g_disable_vote_warmup_timelimit 1
set g_disable_vote_scorelimit 1
set g_disable_vote_kickban 1
```
