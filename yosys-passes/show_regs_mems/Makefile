


CXXFLAGS=$(shell yosys-root-path/yosys-config --cxxflags)
DATDIR=$(shell yosys-root-path/yosys-config --datdir)


../../show_regs_mems.so: show_regs_mems.cc
	yosys-root-path/yosys-config --exec --cxx $(subst $(DATDIR),yosys-root-path/share,$(CXXFLAGS)) --ldflags -o ../../show_regs_mems.so -shared show_regs_mems.cc --ldlibs
../../show_regs_mems.d: 
	rm -rf ../../show_regs_mems.d



