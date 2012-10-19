# You may want to edit these, either here or from the commandline using
# VARIABLE=value
WSW_DIR = ~/.warsow-1.0
EXECUTE_DIR = .
EXECUTABLE = wsw-server
MOD = basewsw
NAME = hGunGame Server
GT = hgg_ffa
PORT = 44400
INSTAGIB = 1

NORMAL_INPUT = { echo set sv_hostname '"$(NAME)"' && cat; }
LOOP_INPUT = { echo set sv_hostname '"$(NAME)"'; }
CD = cd $(EXECUTE_DIR)
SERVER_CMD = $(EXECUTABLE) +set fs_game $(MOD) +set sv_port $(PORT) \
			 +set g_gametype $(GT) +set g_instagib $(INSTAGIB)

THIS = Makefile
GT_DIR = src
TMP_DIR = tmp
BASE_MOD = basewsw
CONFIG_DIR = configs/server/gametypes
GLOBALS_FILE = progs/gametypes/hgg/Base/globals.as
EVERY_PK3 = hgg-*.pk3
EVERY_CFG = hgg_*.cfg

VERSION = $(shell grep VERSION $(GT_DIR)/$(GLOBALS_FILE) \
		  | head -n1 | sed 's/.*"\(.*\)".*/\1/')
VERSION_WORD = $(subst .,_,$(VERSION))
GT_PK3 = hgg-$(VERSION_WORD).pk3

all: $(GT_PK3)

$(GT_PK3): $(shell find $(GT_DIR)/) $(THIS)
	rm -rf $(TMP_DIR)
	mkdir $(TMP_DIR)
	rm -f *.pk3
	cp -r $(GT_DIR)/* $(TMP_DIR)/
	cd $(TMP_DIR); zip ../$(GT_PK3) -r -xi *
	rm -r $(TMP_DIR)

local: $(GT_PK3)
	mkdir -p $(WSW_DIR)/$(BASE_MOD)/
	cp $(GT_PK3) $(WSW_DIR)/$(BASE_MOD)/

production: local
	$(CD) && $(NORMAL_INPUT) | $(SERVER_CMD)

productionloop: local
	$(CD) && while true; do $(LOOP_INPUT) | $(SERVER_CMD); done

clean:
	rm -f *.pk3

destroy:
	rm -f $(WSW_DIR)/$(BASE_MOD)/$(EVERY_PK3)
	rm -f $(WSW_DIR)/$(BASE_MOD)/$(CONFIG_DIR)/$(EVERY_CFG)
	rm -f $(WSW_DIR)/$(MOD)/$(CONFIG_DIR)/$(EVERY_CFG)

restart: destroy local

dev: restart
	$(CD) && $(NORMAL_INPUT) | $(SERVER_CMD)

.PHONY: all local production productionloop clean destroy restart dev
