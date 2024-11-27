YOSYS_CONFIG ?= yosys-config

PASSES := addmodule stuttering show_regs_mems
OBJS := $(patsubst %,../%.so,${PASSES})

.PHONY: all clean
all: ${OBJS}

clean:
	rm -f ${OBJS}

../%.so: %.cc
	${YOSYS_CONFIG} --build $@ $^
	rm -f $(@:.so=.d)
