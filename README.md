# LeaVe
A tool for checking the contract satisfaction for hardware designs


## Dependencies
1. Python 3.8.10
2. yices 2.6.4
3. Yosys 0.26+50
4. Icarus Verilog version 12.0


## Compile the yosys passes
Follow the readme in folder "yosys-passes"


## run the test
1. Change the "yosysPath" in configuration file to the right path "yosys-root-path/yosys".

2. Run 'python3 source/cli.py config/Benchmark.yaml', where 'Benchmark' is one of the configuration file in folder "config".

3. The result is in foldertestOut.

4. The file "logfile" contains the information about the invariants set in each loop.

5. The file "logtimefile" contains the time information about LeaVe.


## verify a new hardware design
1. prepare 'prod.v'

2. prepare configuration file

