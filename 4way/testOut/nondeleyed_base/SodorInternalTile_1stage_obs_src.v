module SodorInternalTile_1stage_obs_src ( input [31:0] \Core_1stage.DatPath_1stage.io_imem_resp_bits_data , input [31:0] \Core_1stage.DatPath_1stage.pc_reg , input [20:0] \AsyncScratchPadMemory_1stage.io_core_ports_0_resp_bits_data_module_io_addr , input [20:0] \AsyncScratchPadMemory_1stage.module__io_addr , input \AsyncScratchPadMemory_1stage.module__io_en , input [31:0] \AsyncScratchPadMemory_1stage.module__io_data , input \Core_1stage.DatPath_1stage._wb_data_T_1 , input \Core_1stage.DatPath_1stage._wb_data_T , input [31:0] \AsyncScratchPadMemory_1stage.io_core_ports_0_resp_bits_data_module_io_data , output RDATA_obs_src_cond , output RADDR_obs_src_cond , output [31:0] INSTR_obs_src_arg0 , output [31:0] WDATA_obs_src_arg0 , output INSTR_obs_src_cond , output WADDR_obs_src_cond , output [31:0] PC_obs_src_arg0 , output PC_obs_src_cond , output [31:0] RDATA_obs_src_arg0 , output [20:0] WADDR_obs_src_arg0 , output [20:0] RADDR_obs_src_arg0 , output WDATA_obs_src_cond );
	assign PC_obs_src_cond = 1 ;
	assign PC_obs_src_arg0 = \Core_1stage.DatPath_1stage.pc_reg ;
	assign INSTR_obs_src_cond = 1 ;
	assign INSTR_obs_src_arg0 = \Core_1stage.DatPath_1stage.io_imem_resp_bits_data ;
	assign WADDR_obs_src_cond = \AsyncScratchPadMemory_1stage.module__io_en ;
	assign WADDR_obs_src_arg0 = \AsyncScratchPadMemory_1stage.module__io_addr ;
	assign WDATA_obs_src_cond = \AsyncScratchPadMemory_1stage.module__io_en ;
	assign WDATA_obs_src_arg0 = \AsyncScratchPadMemory_1stage.module__io_data ;
	assign RADDR_obs_src_cond = ( \Core_1stage.DatPath_1stage._wb_data_T_1 ) && ( ! ( \Core_1stage.DatPath_1stage._wb_data_T ) ) ;
	assign RADDR_obs_src_arg0 = \AsyncScratchPadMemory_1stage.io_core_ports_0_resp_bits_data_module_io_addr ;
	assign RDATA_obs_src_cond = ( \Core_1stage.DatPath_1stage._wb_data_T_1 ) && ( ! ( \Core_1stage.DatPath_1stage._wb_data_T ) ) ;
	assign RDATA_obs_src_arg0 = \AsyncScratchPadMemory_1stage.io_core_ports_0_resp_bits_data_module_io_data ;
endmodule