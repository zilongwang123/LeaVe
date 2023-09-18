# LeaVe
A tool for checking the contract satisfaction for hardware designs


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

