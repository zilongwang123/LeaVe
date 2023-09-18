# LeaVe
A tool for checking the contract satisfaction for hardware designs

## Dependencies
Python 3.8.10
yices 2.6.4
Yosys 0.26+50
Icarus Verilog version 12.0



## Compile the yosys passes
Follow the readme in folder "yosys-passes"



## run the test
### Change the "yosysPath" in configuration file to the right path "yosys-root-path/yosys".

### Run 'python3 source/cli.py config/Benchmark.yaml', where 'Benchmark' is one of the configuration file in folder "config".

### The result is in foldertestOut.

### The file "logfile" contains the information about the invariants set in each loop.

### The file "logtimefile" contains the time information about LeaVe.



## verify a new hardware design
### prepare 'prod.v'

### prepare configuration file

