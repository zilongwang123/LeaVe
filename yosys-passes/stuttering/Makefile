CXXFLAGS=$(shell ../../../yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys-config --datdir)

stuttering.so: stuttering.cc
	../../../yosys-config --exec --cxx $(subst $(DATDIR),../../../share,$(CXXFLAGS)) --ldflags -o stuttering.so -shared stuttering.cc --ldlibs



