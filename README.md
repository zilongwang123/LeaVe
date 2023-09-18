# LeaVe
A tool for checking the contract satisfaction for hardware designs


## Compile the yosys passes
follow the readme in folder "yosys-passes"



## run the test
### run 'python3 source/cli.py config/Benchmark.yaml', where 'Benchmark' is one of the configuration file in folder "config".

### The result is in foldertestOut.

### "logfile" contains the information about the invariants set in each loop.

### "logtimefile" contains the time information about LeaVe.



## verify a new hardware design
### prepare 'prod.v'

### prepare configuration file

