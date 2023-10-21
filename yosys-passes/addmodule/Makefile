


CXXFLAGS=$(shell ../../../yosys/yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys/yosys-config --datdir)

../../addmodule.so: addmodule.cc
	../../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../../yosys/share,$(CXXFLAGS)) --ldflags -o ../../addmodule.so -shared addmodule.cc --ldlibs
../../addmodule.d: 
	rm -rf ../../addmodule.d



