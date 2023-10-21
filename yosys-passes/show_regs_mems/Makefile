


CXXFLAGS=$(shell ../../../yosys/yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys/yosys-config --datdir)


../../show_regs_mems.so: show_regs_mems.cc
	../../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../../yosys/share,$(CXXFLAGS)) --ldflags -o ../../show_regs_mems.so -shared show_regs_mems.cc --ldlibs
../../show_regs_mems.d: 
	rm -rf ../../show_regs_mems.d



