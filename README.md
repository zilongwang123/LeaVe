# LeaVe
A tool for checking the contract satisfaction for hardware designs


## Dependencies
1. Python 3.8.10
2. yices 2.6.4
3. Yosys 0.26+50
4. Icarus Verilog version 12.0


## Compile the yosys passes
Follow the instructions in folder "yosys-passes" to build the yosys passes.


## Run the test
1. Change the "yosysPath" in configuration file to the executable yosys "yosys-root-path/yosys".

2. Run 'python3 source/cli.py config/Benchmark.yaml', where 'Benchmark' is in ["RE","DarkRISCV-2","DarkRISCV-3","Sodor-2","ibex-small","ibex-mult-div","ibex_cache"].

3. The result is in folder "testOut/benchmark". The output file "logfile" contains the information about the invariants set in each loop. The output file "logtimefile" contains the time information about LeaVe.

## A running example
1. Change the "yosysPath" in "config/RE.yaml" to the executable yosys "yosys-root-path/yosys".

2. Run the tool with command "python3 source/cli.py config/RE.yaml".

3. The output file should contain "Verification passed"

4. Remove one of the contract observations "MUL" from "srcObservations" in "config/RE.yaml" (srcObservations:[]).

5. Rerun the tool as in step 3.

6. The output file should contain "Verification failed"


## verify a new hardware design
1. prepare 'prod.v'
    See the "benchmarks/prod_example.v"

2. prepare configuration file
    See the "benchmarks/config_example.v"
