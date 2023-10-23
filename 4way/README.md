
## Reproducing the results from the CCS 2023 paper

These are the instructions for reproducing the results for Q3 in Section 6 of our CCS 2023 paper. Follow the following step to apply 4way-LeaVe to verify Sodor-2 based on Soder-1.

1. In the configuration file `config/Sodor-2-4way.yaml`, change the value of the `yosysPath` option to point to the Yosys's executable in your machine, e.g., `yosys-root-path/yosys`.

2. Run 4way-LeaVe by executing `python3 source/cli.py config/Sodor-2-4way..yaml`.

3. The output file `logfile` contains the information about the invariants discovered in each iteration of the invariant synthesis loop. The output file `logtimefile` reports timing statistics about the verification process.

Note that the verificatrion required more than 1 day in our experiments.


