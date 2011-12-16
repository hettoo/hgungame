VERSION = 0.0-dev

VERSION_WORD = $(subst .,_,$(VERSION))
PK3 = hgg-$(VERSION_WORD).pk3

all: $(PK3)

$(PK3): $(shell find hgg/)
	rm -rf temp
	mkdir temp
	mkdir temp/progs
	mkdir temp/progs/gametypes
	rm -f *.pk3
	cp -r hgg/* temp/progs/gametypes
	cd temp && zip ../$(PK3) -r -xi *
	rm -r temp

local:
	rm -f ~/.warsow-0.6/basewsw/hgg-*.pk3
	rm -f ~/.warsow-0.6/basewsw/configs/server/gametypes/hgg_*.cfg
	cp *.pk3 ~/.warsow-0.6/basewsw/

dev: all local
	wsw-server

.PHONY: all local dev
