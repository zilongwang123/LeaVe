


CXXFLAGS=$(shell ../../../yosys/yosys-config --cxxflags)
DATDIR=$(shell ../../../yosys/yosys-config --datdir)


../../stuttering.so: stuttering.cc
	../../../yosys/yosys-config --exec --cxx $(subst $(DATDIR),../../../yosys/share,$(CXXFLAGS)) --ldflags -o ../../stuttering.so -shared stuttering.cc --ldlibs
../../stuttering.d: 
	rm -rf ../../stuttering.d


