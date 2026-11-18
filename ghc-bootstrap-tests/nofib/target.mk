# Stands in for nofib's mk/target.mk: prints the settings that the real one
# hands to the compiler and to runstdtest
ifeq "$(STDIN_FILE)" ""
STDIN_FILE = $(wildcard $(NOFIB_PROG).stdin)
endif

nofib-vars:
	$(info subdirs=$(SUBDIRS))
	$(info prog=$(NOFIB_PROG))
	$(info hc_opts=$(SRC_HC_OPTS) $(EXTRA_HC_OPTS))
	$(info srcs=$(SRCS) $(HS_SRCS))
	$(info stdin=$(STDIN_FILE))
	$(info stdout=$(wildcard $(NOFIB_PROG).stdout*))
	$(info stderr=$(wildcard $(NOFIB_PROG).stderr*))
	$(info runtest_opts=$(RUNTEST_OPTS))
	$(info args=$(PROG_ARGS))
	@:
