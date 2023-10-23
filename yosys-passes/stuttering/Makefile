


CXXFLAGS=$(shell yosys-root-path/yosys-config --cxxflags)
DATDIR=$(shell yosys-root-path/yosys-config --datdir)


../../stuttering.so: stuttering.cc
	yosys-root-path/yosys-config --exec --cxx $(subst $(DATDIR),yosys-root-path/share,$(CXXFLAGS)) --ldflags -o ../../stuttering.so -shared stuttering.cc --ldlibs
../../stuttering.d: 
	rm -rf ../../stuttering.d


