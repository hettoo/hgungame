# hGunGame

Series of Warsow gametype scripts.

# Usage

Read the head of the makefile to see what variables you can set per server. It
is recommended to use `make` to run your servers.

Use `make local` to just create and copy the pk3 file, so you can create a
personal server from your client. If you can't use make, just put the content
of the gametype/ folder in a zip file, rename it to .pk3 and put it in your
basewsw folder.

Use `make dev` to remove config files and run the server once. This is used for
testing.

Use `make production` to run the server once.
Use `make productionloop` to repeat running the server, in case it crashes. Note
that this disables input from the console (you can use rcon and the builtin
administration system though).

Assuming you named it server.sh, put it in your home directory and you've cloned
hGunGame into ~/hgungame/, if you want multiple servers running on the same
machine, you could do something like this:

```sh
cd hgungame/
make productionloop GT=hgg_ffa PORT=44400 NAME='hGunGame FFA Server' &
make productionloop GT=hgg_ca PORT=44401 NAME='hGunGame CA Server' &
```

This will repeatedly run two servers (one for FFA and one for CA) in the
background. If you have access to the root account on your server, you can now
insert the following into your /etc/rc.local:

```sh
su username -c 'cd; sh server.sh'
```

And it will be run every time after a reboot.
