# You may have to edit these
MOD = promod
WSW_DIR = ~/.warsow-0.6
SERVER_CMD = wsw-server

VERSION = 0.0-dev

GT_DIR = gametype
TMP_DIR = tmp
BASE_MOD = basewsw
CONFIG_DIR = configs/server/gametypes

VERSION_WORD = $(subst .,_,$(VERSION))
GT_PK3 = hgg-$(VERSION_WORD).pk3

all: $(GT_PK3)

$(GT_PK3): $(shell find $(GT_DIR)/)
	rm -rf $(TMP_DIR)
	mkdir $(TMP_DIR)
	rm -f *.pk3
	cp -r $(GT_DIR)/* $(TMP_DIR)/
	cd $(TMP_DIR); zip ../$(GT_PK3) -r -xi *
	rm -r $(TMP_DIR)

local:
	rm -f $(WSW_DIR)/$(BASE_MOD)/hgg-*.pk3
	rm -f $(WSW_DIR)/$(BASE_MOD)/$(CONFIG_DIR)/hgg_*.cfg
	rm -f $(WSW_DIR)/$(MOD)/$(CONFIG_DIR)/hgg_*.cfg
	cp $(GT_PK3) $(WSW_DIR)/$(BASE_MOD)/

dev: all local
	$(SERVER_CMD)

.PHONY: all local dev
