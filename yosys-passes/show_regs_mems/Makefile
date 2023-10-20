CXXFLAGS=$(shell ../../../yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys-config --datdir)

show_regs_mems.so: show_regs_mems.cc
	../../../yosys-config --exec --cxx $(subst $(DATDIR),../../../share,$(CXXFLAGS)) --ldflags -o show_regs_mems.so -shared show_regs_mems.cc --ldlibs



