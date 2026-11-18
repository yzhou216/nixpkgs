# Stands in for nofib's mk/boilerplate.mk and the fptools files it includes:
# only the settings that decide how a program is compiled and run
NOFIB_PROG = $(notdir $(CURDIR))
SRC_HC_OPTS += -H32m
SRC_RUNTEST_OPTS += +RTS -H10m -K10m -RTS
PROG_ARGS = $(NORM_OPTS)
RUNTEST_OPTS = $(SRC_RUNTEST_OPTS) $($(NOFIB_PROG)_RUNTEST_OPTS) $(EXTRA_RUNTEST_OPTS)
