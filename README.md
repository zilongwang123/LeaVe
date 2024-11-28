# LeaVe
LeaVe is a tool for verifying that processor designs formalized in Verilog satisfy an ISA-level leakage contract capturing security guarantees in terms of timing leaks. 

For more details on LeaVe's verification approach, see our paper "Specification and Verification of Side-channel Security for Open-source Processors via Leakage Contracts" at ACM CCS 2023  (open access [here](https://arxiv.org/abs/2305.06979)).

For more details on leakage contracts, see our paper "Hardware-Software Contracts for Secure Speculation" at IEEE S&P 2021 (open access [here](https://arxiv.org/abs/2006.03841)).

## Dependencies

To run LeaVe, you need the following dependencies:

1. Python, version 3.8.10 or higher
2. yices 2.6.4
3. Yosys, version 0.26+50 or higher
4. Icarus Verilog version 12.0


## Compile the Yosys passes

LeaVe relies on three Yosys custom passes to prepare the processor design for verification. These passes need to be compiled before using LeaVe. Run `make -C yosys-passes` or follow the instructions in folder `yosys-passes` for more detailed instructions.

## Baseline example

As a baseline example, we will use the running example from our CCS 2023 paper (see section 2 for a description of processor, ISA, and leakage contract). To run this baseline example and check that everything works correctly follow these steps:

1. In the configuration file `config/RE.yaml`, change the value of the `yosysPath` option to point to the Yosys's executable in your machine. 
 The leakage contract is encoded in the `srcObservations` option in the configuration file, whereas the attacker monitor is encoded in the `trgObservations` option.

2. Run LeaVe with the command `python3 source/cli.py config/RE.yaml`. If everything is set-up properly, the output file `testout/logfile` should contain the `Verification passed` message. This indicates that LeaVe successfully verified that the contract in `srcObservations` is satisfied for the processor under verification and the attacker in `trgObservations`.

4. Now, remove the contract observations `MUL` from  `srcObservations`, so that the  `srcObservations` is `[]`. Run again LeaVe with the command `python3 source/cli.py config/RE.yaml`. This time the output file `testout/logfile` should contain the message `Verification failed`, indicating that LeaVe cannot prove contract satisfaction.

## Reproducing the results from the CCS 2023 paper

These are the instructions for reproducing the results in Table 1 from our CCS 2023 paper. For each target, the instructions below describe how to verify that the processor satisfies the strongest contract in Table 1.

Below, `$TARGET` is one of  [`DarkRISCV-2`,`DarkRISCV-3`,`Sodor-2`,`ibex-small`,`ibex-mult-div`,`ibex-cache`]. To use LeaVe to verify `$TARGET`, follow these steps:

1. In the configuration file `config/$TARGET.yaml`, change the value of the `yosysPath` option to point to the Yosys's executable in your machine, e.g., `yosys-root-path/yosys`.

2. Run LeaVe by executing `python3 source/cli.py config/$TARGET.yaml`.

3. Inspect the results in the folder `testOut`. The output file `logfile` contains the information about the invariants discovered in each iteration of the invariant synthesis loop. The output file `logtimefile` reports timing statistics about the verification process.

Note that while the verification of `DarkRISCV-2`,`DarkRISCV-3`, and `Sodor-2` is rather quick, verifying `ibex-small`,`ibex-mult-div`, and `ibex-cache` required roughly 1 day in our experiments.

To run the 4way-LeaVe, follow the instruction in folder `4way`.

## Verify a new processor design

To verify a new processor design using LeaVe, you first need to prepare the following files:

1. A template of the product circuit. For an example of such template, see  the file at `benchmarks/prod_example.v`. It should be placed in the same folder of the source code.

2. A configuration file. For an example of such file, see `config/config_example.yaml`. It should be placed in the folder "config".

3. Once both files, you can start the verification by executing the following command:  `python3 source/cli.py config/config_example.yaml`
