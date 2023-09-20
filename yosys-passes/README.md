1. Cope the Yosys source code from the repository "https://github.com/YosysHQ/yosys", and install it follow the instruction

2. Move the folder "yosys-passes" to "Yosys-root-path/manual"， where "Yosys-root-path" is the main folder of the Yosys

3. Run "make" to compile the 'my_cmd.cc' in each folder, which will generate "my_cmd.so" in the same folder, where "my_cmd" is in ["addmodule","show_regs_mems","stuttering"]

4. Move the "my_cmd.so" to the main folder of LeaVe