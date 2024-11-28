This folder contains three Yosys custom passes for LeaVe.

To build them with Yosys installed system wide, run `make`.

To build with a custom Yosys installation, run `make YOSYS_CONFIG=<path-to-yosys-config>`
with the path of `yosys-config` in the Yosys installation directory.

The three yosys passes ("addmodule.so", "show_regs_mems.so", "stuttering.so") are
installed into the main folder of LeaVe.
