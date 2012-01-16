# You may have to edit these, either here or from the commandline using
# VARIABLE=value
WSW_DIR = ~/.warsow-0.6
MOD = promod
PORT = 44400
GT = hgg_ffa
INSTAGIB = 1
SERVER_CMD = wsw-server +set fs_game $(MOD) +set sv_port $(PORT) \
			 +set g_gametype $(GT) +set g_instagib $(INSTAGIB)

GT_DIR = gametype
TMP_DIR = tmp
BASE_MOD = basewsw
CONFIG_DIR = configs/server/gametypes
GLOBALS_FILE = progs/gametypes/hgg/base/globals.as
EVERY_PK3 = hgg-*.pk3
EVERY_CFG = hgg_*.cfg

VERSION = $(shell grep VERSION $(GT_DIR)/$(GLOBALS_FILE) \
		  | sed 's/.*"\(.*\)".*/\1/')
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

local: $(GT_PK3)
	cp $(GT_PK3) $(WSW_DIR)/$(BASE_MOD)/

production: local
	$(SERVER_CMD)

destroy:
	rm -f $(WSW_DIR)/$(BASE_MOD)/$(EVERY_PK3)
	rm -f $(WSW_DIR)/$(BASE_MOD)/$(CONFIG_DIR)/$(EVERY_CFG)
	rm -f $(WSW_DIR)/$(MOD)/$(CONFIG_DIR)/$(EVERY_CFG)

restart: destroy local

dev: restart
	$(SERVER_CMD)

.PHONY: all local production destroy restart dev
