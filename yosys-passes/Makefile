


CXXFLAGS=$(shell ../../yosys/yosys-config --cxxflags)
DATDIR=$(shell ../../yosys/yosys-config --datdir)

../addmodule.so: addmodule/addmodule.cc
	../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../yosys/share,$(CXXFLAGS)) --ldflags -o ../addmodule.so -shared addmodule/addmodule.cc --ldlibs
../addmodule.d: 
	rm -rf ../addmodule.d
../show_regs_mems.so: show_regs_mems/show_regs_mems.cc
	../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../yosys/share,$(CXXFLAGS)) --ldflags -o ../show_regs_mems.so -shared show_regs_mems/show_regs_mems.cc --ldlibs
../show_regs_mems.d: 
	rm -rf ../show_regs_mems.d
../stuttering.so: stuttering/stuttering.cc
	../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../yosys/share,$(CXXFLAGS)) --ldflags -o ../stuttering.so -shared stuttering/stuttering.cc --ldlibs
../stuttering.d: 
	rm -rf ../stuttering.d


