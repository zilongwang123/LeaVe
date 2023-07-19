


CXXFLAGS=$(shell ../../../yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys-config --datdir)

addobs.so: addmodule.cc
	../../../yosys-config --exec --cxx $(subst $(DATDIR),../../../share,$(CXXFLAGS)) --ldflags -o addmodule.so -shared addmodule.cc --ldlibs



