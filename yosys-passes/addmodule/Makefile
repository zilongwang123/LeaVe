


CXXFLAGS=$(shell yosys-root-path/yosys-config --cxxflags)
DATDIR=$(shell yosys-root-path/yosys-config --datdir)

../../addmodule.so: addmodule.cc
	yosys-root-path/yosys-config --exec --cxx $(subst $(DATDIR),yosys-root-path/share,$(CXXFLAGS)) --ldflags -o ../../addmodule.so -shared addmodule.cc --ldlibs
../../addmodule.d: 
	rm -rf ../../addmodule.d



