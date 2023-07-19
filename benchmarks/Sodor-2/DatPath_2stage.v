module DatPath_2stage(
  input         clock,
  input         reset,
  output        io_imem_req_valid,
  output [31:0] io_imem_req_bits_addr,
  input         io_imem_resp_valid,
  input  [31:0] io_imem_resp_bits_data,
  output [31:0] io_dmem_req_bits_addr,
  output [31:0] io_dmem_req_bits_data,
  input  [31:0] io_dmem_resp_bits_data,
  input         io_ctl_stall,
  input         io_ctl_if_kill,
  input  [2:0]  io_ctl_pc_sel,
  input  [1:0]  io_ctl_op1_sel,
  input  [2:0]  io_ctl_op2_sel,
  input  [4:0]  io_ctl_alu_fun,
  input  [1:0]  io_ctl_wb_sel,
  input         io_ctl_rf_wen,
  input  [2:0]  io_ctl_csr_cmd,
  input         io_ctl_mem_val,
  input  [1:0]  io_ctl_mem_fcn,
  input  [2:0]  io_ctl_mem_typ,
  input         io_ctl_exception,
  input  [31:0] io_ctl_exception_cause,
  input  [2:0]  io_ctl_pc_sel_no_xept,
  output        io_dat_if_valid_resp,
  output [31:0] io_dat_inst,
  output        io_dat_br_eq,
  output        io_dat_br_lt,
  output        io_dat_br_ltu,
  output        io_dat_inst_misaligned,
  output        io_dat_data_misaligned,
  output        io_dat_mem_store,
  output        io_dat_csr_eret,
  output        io_dat_csr_interrupt,
  input         io_interrupt_debug,
  input         io_interrupt_mtip,
  input         io_interrupt_msip,
  input         io_interrupt_meip,
  input         io_hartid,
  input  [31:0] io_reset_vector,
//// for contract
  //instruction
  output [31:0] pc_retire,
  input  [31:0] instr_ctr,
  output [31:0] io_dat_inst_ctr,
  // memory address
  input  [4:0]  io_ctl_alu_fun_ctr,
  input  [1:0]  io_ctl_op1_sel_ctr,
  input  [2:0]  io_ctl_op2_sel_ctr,
  // data load from memory
  output [31:0] io_dmem_req_bits_addr_ctr,
  // for branch instruction
  output        io_dat_br_eq_ctr,
  output        io_dat_br_lt_ctr,
  output        io_dat_br_ltu_ctr,
//// for state invariant
  output [31:0] exe_reg_pc,


);

//// for contract
  //instruction
  wire [31:0] instr_ctr;
  wire instr_ctr_resp_valid;
  assign instr_ctr_resp_valid = retire;
  wire [31:0] io_dat_inst_ctr;
  assign io_dat_inst_ctr = instr_ctr;
  
  // memory address
  wire [31:0] io_dmem_req_bits_addr_ctr;
  assign io_dmem_req_bits_addr_ctr = _exe_alu_out_T_ctr ? _exe_alu_out_T_2_ctr : _exe_alu_out_T_37_ctr;
  wire  _exe_alu_out_T_ctr = io_ctl_alu_fun_ctr == 5'h1;

  wire [31:0] _exe_alu_out_T_2_ctr = exe_alu_op1_ctr + exe_alu_op2_ctr;
  wire  _exe_alu_op1_T_ctr = io_ctl_op1_sel_ctr == 2'h0; // @[dpath.scala 178:32]
  wire  _exe_alu_op1_T_1_ctr = io_ctl_op1_sel_ctr == 2'h1; // @[dpath.scala 179:32]
  wire [19:0] imm_u_ctr = instr_ctr[31:12]; // @[dpath.scala 165:28]
  wire [31:0] imm_u_sext_ctr = {imm_u_ctr,12'h0}; // @[Cat.scala 31:58]
  wire  _exe_alu_op1_T_2_ctr = io_ctl_op1_sel_ctr == 2'h2; // @[dpath.scala 180:32]
  wire [31:0] imm_z_ctr = {27'h0,exe_rs1_addr_ctr}; // @[Cat.scala 31:58]
  wire [31:0] _exe_alu_op1_T_3_ctr = _exe_alu_op1_T_2_ctr ? imm_z_ctr : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op1_T_4_ctr = _exe_alu_op1_T_1_ctr ? imm_u_sext_ctr : _exe_alu_op1_T_3_ctr; // @[Mux.scala 101:16]
  wire [31:0] exe_alu_op1_ctr = _exe_alu_op1_T_ctr ? exe_rs1_data_ctr : _exe_alu_op1_T_4_ctr;
  wire  _exe_alu_op2_T_ctr = io_ctl_op2_sel_ctr == 3'h0; // @[dpath.scala 184:32]
  wire [31:0] exe_rs2_data_ctr = exe_rs2_addr_ctr != 5'h0 ? regfile_exe_rs2_data_MPORT_data_ctr : 32'h0; // @[dpath.scala 158:26]
  wire  _exe_alu_op2_T_1_ctr = io_ctl_op2_sel_ctr == 3'h1; // @[dpath.scala 185:32]
  wire  _exe_alu_op2_T_2_ctr = io_ctl_op2_sel_ctr == 3'h2; // @[dpath.scala 186:32]
  wire  _exe_alu_op2_T_3_ctr = io_ctl_op2_sel_ctr == 3'h3; // @[dpath.scala 187:32]
  wire [11:0] imm_s_ctr = {instr_ctr[31:25],exe_wbaddr_ctr}; // @[Cat.scala 31:58]
  wire [19:0] _imm_s_sext_T_2_ctr = imm_s_ctr[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_s_sext_ctr = {_imm_s_sext_T_2_ctr,instr_ctr[31:25],exe_wbaddr_ctr}; // @[Cat.scala 31:58]
  wire [31:0] _exe_alu_op2_T_4_ctr = _exe_alu_op2_T_3_ctr ? imm_s_sext_ctr : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op2_T_5_ctr = _exe_alu_op2_T_2_ctr ? imm_i_sext_ctr : _exe_alu_op2_T_4_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op2_T_6_ctr = _exe_alu_op2_T_1_ctr ? pc_retire : _exe_alu_op2_T_5_ctr; // @[Mux.scala 101:16]
  wire [31:0] exe_alu_op2_ctr = _exe_alu_op2_T_ctr ? exe_rs2_data_ctr : _exe_alu_op2_T_6_ctr;

  wire  _exe_alu_out_T_3_ctr = io_ctl_alu_fun_ctr == 5'h2; // @[dpath.scala 198:35]
  wire [31:0] _exe_alu_out_T_5_ctr = exe_alu_op1_ctr - exe_alu_op2_ctr; // @[dpath.scala 198:65]
  wire  _exe_alu_out_T_6_ctr = io_ctl_alu_fun_ctr == 5'h6; // @[dpath.scala 199:35]
  wire [31:0] _exe_alu_out_T_7_ctr = exe_alu_op1_ctr & exe_alu_op2_ctr; // @[dpath.scala 199:65]
  wire  _exe_alu_out_T_8_ctr = io_ctl_alu_fun_ctr == 5'h7; // @[dpath.scala 200:35]
  wire [31:0] _exe_alu_out_T_9_ctr = exe_alu_op1_ctr | exe_alu_op2_ctr; // @[dpath.scala 200:65]
  wire  _exe_alu_out_T_10_ctr = io_ctl_alu_fun_ctr == 5'h8; // @[dpath.scala 201:35]
  wire [31:0] _exe_alu_out_T_11_ctr = exe_alu_op1_ctr ^ exe_alu_op2_ctr; // @[dpath.scala 201:65]
  wire  _exe_alu_out_T_12_ctr = io_ctl_alu_fun_ctr == 5'h9; // @[dpath.scala 202:35]
  wire [31:0] _exe_alu_out_T_13_ctr = _exe_alu_op1_T_ctr ? exe_rs1_data_ctr : _exe_alu_op1_T_4_ctr; // @[dpath.scala 202:71]
  wire [31:0] _exe_alu_out_T_14_ctr = _exe_alu_op2_T_ctr ? exe_rs2_data_ctr : _exe_alu_op2_T_6_ctr; // @[dpath.scala 202:94]
  wire  _exe_alu_out_T_15_ctr = $signed(_exe_alu_out_T_13_ctr) < $signed(_exe_alu_out_T_14_ctr); // @[dpath.scala 202:74]
  wire  _exe_alu_out_T_16_ctr = io_ctl_alu_fun_ctr == 5'ha; // @[dpath.scala 203:35]
  wire  _exe_alu_out_T_17_ctr = exe_alu_op1_ctr < exe_alu_op2_ctr; // @[dpath.scala 203:65]
  wire  _exe_alu_out_T_18_ctr = io_ctl_alu_fun_ctr == 5'h3; // @[dpath.scala 204:35]
  wire [4:0] alu_shamt_ctr = exe_alu_op2_ctr[4:0]; // @[dpath.scala 194:31]
  wire [62:0] _GEN_11_ctr = {{31'd0}, exe_alu_op1_ctr}; // @[dpath.scala 204:66]
  wire [62:0] _exe_alu_out_T_19_ctr = _GEN_11_ctr << alu_shamt_ctr; // @[dpath.scala 204:66]
  wire  _exe_alu_out_T_21_ctr = io_ctl_alu_fun_ctr == 5'h5; // @[dpath.scala 205:35]
  wire [31:0] _exe_alu_out_T_24_ctr = $signed(_exe_alu_out_T_13_ctr) >>> alu_shamt_ctr; // @[dpath.scala 205:94]
  wire  _exe_alu_out_T_25_ctr = io_ctl_alu_fun_ctr == 5'h4; // @[dpath.scala 206:35]
  wire [31:0] _exe_alu_out_T_26_ctr = exe_alu_op1_ctr >> alu_shamt_ctr; // @[dpath.scala 206:65]
  wire  _exe_alu_out_T_27_ctr = io_ctl_alu_fun_ctr == 5'hb; // @[dpath.scala 207:35]
  wire [31:0] _exe_alu_out_T_28_ctr = _exe_alu_out_T_27_ctr ? exe_alu_op1_ctr : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_29_ctr = _exe_alu_out_T_25_ctr ? _exe_alu_out_T_26_ctr : _exe_alu_out_T_28_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_30_ctr = _exe_alu_out_T_21_ctr ? _exe_alu_out_T_24_ctr : _exe_alu_out_T_29_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_31_ctr = _exe_alu_out_T_18_ctr ? _exe_alu_out_T_19_ctr[31:0] : _exe_alu_out_T_30_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_32_ctr = _exe_alu_out_T_16_ctr ? {{31'd0}, _exe_alu_out_T_17_ctr} : _exe_alu_out_T_31_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_33_ctr = _exe_alu_out_T_12_ctr ? {{31'd0}, _exe_alu_out_T_15_ctr} : _exe_alu_out_T_32_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_34_ctr = _exe_alu_out_T_10_ctr ? _exe_alu_out_T_11_ctr : _exe_alu_out_T_33_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_35_ctr = _exe_alu_out_T_8_ctr ? _exe_alu_out_T_9_ctr : _exe_alu_out_T_34_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_36_ctr = _exe_alu_out_T_6_ctr ? _exe_alu_out_T_7_ctr : _exe_alu_out_T_35_ctr; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_37_ctr = _exe_alu_out_T_3_ctr ? _exe_alu_out_T_5_ctr : _exe_alu_out_T_36_ctr; // @[Mux.scala 101:16]

  wire [4:0] exe_rs1_addr_ctr = instr_ctr[19:15]; // @[dpath.scala 134:35]
  wire [31:0] exe_rs1_data_ctr = exe_rs1_addr_ctr != 5'h0 ? regfile_exe_rs1_data_MPORT_data_ctr : 32'h0; 
  wire [4:0] exe_rs2_addr_ctr = instr_ctr[24:20]; // @[dpath.scala 135:35]
  wire [4:0] exe_wbaddr_ctr = instr_ctr[11:7]; // @[dpath.scala 136:35]
  wire [31:0] exe_rs2_data_ctr = exe_rs2_addr_ctr != 5'h0 ? regfile_exe_rs2_data_MPORT_data_ctr : 32'h0; // @[dpath.scala 158:26]
  wire [31:0] regfile_exe_rs1_data_MPORT_data_ctr;
  wire [31:0] regfile_exe_rs2_data_MPORT_data_ctr;
  assign regfile_exe_rs1_data_MPORT_data_ctr = regfile[exe_rs1_addr_ctr]; // @[dpath.scala 142:21]
  assign regfile_exe_rs2_data_MPORT_data_ctr = regfile[exe_rs2_addr_ctr]; // @[dpath.scala 142:21]

  wire [11:0] imm_i_ctr = instr_ctr[31:20]; // @[dpath.scala 162:28]
  wire [19:0] _imm_i_sext_T_2_ctr = imm_i_ctr[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_i_sext_ctr = {_imm_i_sext_T_2_ctr,imm_i_ctr}; // @[Cat.scala 31:58]

// for branch instruction
  assign io_dat_br_eq_ctr = exe_rs1_data_ctr == exe_rs2_data_ctr; // @[dpath.scala 278:35]
  assign io_dat_br_lt_ctr = $signed(exe_rs1_data_ctr) < $signed(exe_rs2_data_ctr); // @[dpath.scala 279:44]
  assign io_dat_br_ltu_ctr = exe_rs1_data_ctr < exe_rs2_data_ctr; // @[dpath.scala 280:44]





`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
`endif // RANDOMIZE_REG_INIT
  reg [31:0] regfile [0:31]; // @[dpath.scala 142:21]
  wire  regfile_io_ddpath_rdata_MPORT_en; // @[dpath.scala 142:21]
  wire [4:0] regfile_io_ddpath_rdata_MPORT_addr; // @[dpath.scala 142:21]
  wire [31:0] regfile_io_ddpath_rdata_MPORT_data; // @[dpath.scala 142:21]
  wire  regfile_exe_rs1_data_MPORT_en; // @[dpath.scala 142:21]
  wire [4:0] regfile_exe_rs1_data_MPORT_addr; // @[dpath.scala 142:21]
  wire [31:0] regfile_exe_rs1_data_MPORT_data; // @[dpath.scala 142:21]
  wire  regfile_exe_rs2_data_MPORT_en; // @[dpath.scala 142:21]
  wire [4:0] regfile_exe_rs2_data_MPORT_addr; // @[dpath.scala 142:21]
  wire [31:0] regfile_exe_rs2_data_MPORT_data; // @[dpath.scala 142:21]
  wire [31:0] regfile_MPORT_data; // @[dpath.scala 142:21]
  wire [4:0] regfile_MPORT_addr; // @[dpath.scala 142:21]
  wire  regfile_MPORT_mask; // @[dpath.scala 142:21]
  wire  regfile_MPORT_en; // @[dpath.scala 142:21]
  wire [31:0] regfile_MPORT_1_data; // @[dpath.scala 142:21]
  wire [4:0] regfile_MPORT_1_addr; // @[dpath.scala 142:21]
  wire  regfile_MPORT_1_mask; // @[dpath.scala 142:21]
  wire  regfile_MPORT_1_en; // @[dpath.scala 142:21]
  wire  csr_clock; // @[dpath.scala 228:20]
  wire  csr_reset; // @[dpath.scala 228:20]
  wire  csr_io_ungated_clock; // @[dpath.scala 228:20]
  wire  csr_io_interrupts_debug; // @[dpath.scala 228:20]
  wire  csr_io_interrupts_mtip; // @[dpath.scala 228:20]
  wire  csr_io_interrupts_msip; // @[dpath.scala 228:20]
  wire  csr_io_interrupts_meip; // @[dpath.scala 228:20]
  wire  csr_io_hartid; // @[dpath.scala 228:20]
  wire [11:0] csr_io_rw_addr; // @[dpath.scala 228:20]
  wire [2:0] csr_io_rw_cmd; // @[dpath.scala 228:20]
  wire [31:0] csr_io_rw_rdata; // @[dpath.scala 228:20]
  wire [31:0] csr_io_rw_wdata; // @[dpath.scala 228:20]
  wire  csr_io_csr_stall; // @[dpath.scala 228:20]
  wire  csr_io_eret; // @[dpath.scala 228:20]
  wire  csr_io_singleStep; // @[dpath.scala 228:20]
  wire  csr_io_status_debug; // @[dpath.scala 228:20]
  wire  csr_io_status_cease; // @[dpath.scala 228:20]
  wire  csr_io_status_wfi; // @[dpath.scala 228:20]
  wire [31:0] csr_io_status_isa; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_dprv; // @[dpath.scala 228:20]
  wire  csr_io_status_dv; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_prv; // @[dpath.scala 228:20]
  wire  csr_io_status_v; // @[dpath.scala 228:20]
  wire  csr_io_status_sd; // @[dpath.scala 228:20]
  wire [22:0] csr_io_status_zero2; // @[dpath.scala 228:20]
  wire  csr_io_status_mpv; // @[dpath.scala 228:20]
  wire  csr_io_status_gva; // @[dpath.scala 228:20]
  wire  csr_io_status_mbe; // @[dpath.scala 228:20]
  wire  csr_io_status_sbe; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_sxl; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_uxl; // @[dpath.scala 228:20]
  wire  csr_io_status_sd_rv32; // @[dpath.scala 228:20]
  wire [7:0] csr_io_status_zero1; // @[dpath.scala 228:20]
  wire  csr_io_status_tsr; // @[dpath.scala 228:20]
  wire  csr_io_status_tw; // @[dpath.scala 228:20]
  wire  csr_io_status_tvm; // @[dpath.scala 228:20]
  wire  csr_io_status_mxr; // @[dpath.scala 228:20]
  wire  csr_io_status_sum; // @[dpath.scala 228:20]
  wire  csr_io_status_mprv; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_xs; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_fs; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_mpp; // @[dpath.scala 228:20]
  wire [1:0] csr_io_status_vs; // @[dpath.scala 228:20]
  wire  csr_io_status_spp; // @[dpath.scala 228:20]
  wire  csr_io_status_mpie; // @[dpath.scala 228:20]
  wire  csr_io_status_ube; // @[dpath.scala 228:20]
  wire  csr_io_status_spie; // @[dpath.scala 228:20]
  wire  csr_io_status_upie; // @[dpath.scala 228:20]
  wire  csr_io_status_mie; // @[dpath.scala 228:20]
  wire  csr_io_status_hie; // @[dpath.scala 228:20]
  wire  csr_io_status_sie; // @[dpath.scala 228:20]
  wire  csr_io_status_uie; // @[dpath.scala 228:20]
  wire [31:0] csr_io_evec; // @[dpath.scala 228:20]
  wire  csr_io_exception; // @[dpath.scala 228:20]
  wire  csr_io_retire; // @[dpath.scala 228:20]
  wire [31:0] csr_io_cause; // @[dpath.scala 228:20]
  wire [31:0] csr_io_pc; // @[dpath.scala 228:20]
  wire [31:0] csr_io_tval; // @[dpath.scala 228:20]
  wire [31:0] csr_io_time; // @[dpath.scala 228:20]
  wire  csr_io_interrupt; // @[dpath.scala 228:20]
  wire [31:0] csr_io_interrupt_cause; // @[dpath.scala 228:20]
  reg [31:0] if_reg_pc; // @[dpath.scala 57:27]
  reg [31:0] exe_reg_pc; // @[dpath.scala 59:34]
  reg [31:0] exe_reg_pc_plus4; // @[dpath.scala 60:34]
  reg [31:0] exe_reg_inst; // @[dpath.scala 61:34]
  reg  exe_reg_valid; // @[dpath.scala 62:34]
  wire  _T = ~io_ctl_stall; // @[dpath.scala 72:10]
  wire  _if_pc_next_T = io_ctl_pc_sel == 3'h0; // @[dpath.scala 80:34]
  wire [31:0] if_pc_plus4 = if_reg_pc + 32'h4; // @[dpath.scala 77:33]
  wire  _if_pc_next_T_1 = io_ctl_pc_sel == 3'h1; // @[dpath.scala 81:34]
  wire [11:0] imm_b = {exe_reg_inst[31],exe_reg_inst[7],exe_reg_inst[30:25],exe_reg_inst[11:8]}; // @[Cat.scala 31:58]
  wire [18:0] _imm_b_sext_T_2 = imm_b[11] ? 19'h7ffff : 19'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_b_sext = {_imm_b_sext_T_2,exe_reg_inst[31],exe_reg_inst[7],exe_reg_inst[30:25],exe_reg_inst[11:8],1'h0
    }; // @[Cat.scala 31:58]
  wire [31:0] exe_br_target = exe_reg_pc + imm_b_sext; // @[dpath.scala 211:38]
  wire  _if_pc_next_T_2 = io_ctl_pc_sel == 3'h2; // @[dpath.scala 82:34]
  wire [19:0] imm_j = {exe_reg_inst[31],exe_reg_inst[19:12],exe_reg_inst[20],exe_reg_inst[30:21]}; // @[Cat.scala 31:58]
  wire [10:0] _imm_j_sext_T_2 = imm_j[19] ? 11'h7ff : 11'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_j_sext = {_imm_j_sext_T_2,exe_reg_inst[31],exe_reg_inst[19:12],exe_reg_inst[20],exe_reg_inst[30:21],1'h0
    }; // @[Cat.scala 31:58]
  wire [31:0] exe_jmp_target = exe_reg_pc + imm_j_sext; // @[dpath.scala 212:38]
  wire  _if_pc_next_T_3 = io_ctl_pc_sel == 3'h3; // @[dpath.scala 83:34]
  wire [4:0] exe_rs1_addr = exe_reg_inst[19:15]; // @[dpath.scala 134:35]
  wire [31:0] exe_rs1_data = exe_rs1_addr != 5'h0 ? regfile_exe_rs1_data_MPORT_data : 32'h0; // @[dpath.scala 157:26]
  wire [11:0] imm_i = exe_reg_inst[31:20]; // @[dpath.scala 162:28]
  wire [19:0] _imm_i_sext_T_2 = imm_i[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_i_sext = {_imm_i_sext_T_2,imm_i}; // @[Cat.scala 31:58]
  wire [31:0] _exe_jump_reg_target_T_1 = exe_rs1_data + imm_i_sext; // @[dpath.scala 213:50]
  wire [31:0] exe_jump_reg_target = _exe_jump_reg_target_T_1 & 32'hfffffffe; // @[dpath.scala 213:73]
  wire  _if_pc_next_T_4 = io_ctl_pc_sel == 3'h4; // @[dpath.scala 84:34]
  wire [31:0] exception_target = csr_io_evec; // @[dpath.scala 239:21 70:34]
  wire [31:0] _if_pc_next_T_5 = _if_pc_next_T_4 ? exception_target : if_pc_plus4; // @[Mux.scala 101:16]
  wire [31:0] _if_pc_next_T_6 = _if_pc_next_T_3 ? exe_jump_reg_target : _if_pc_next_T_5; // @[Mux.scala 101:16]
  wire [31:0] _if_pc_next_T_7 = _if_pc_next_T_2 ? exe_jmp_target : _if_pc_next_T_6; // @[Mux.scala 101:16]
  reg [31:0] if_inst_buffer; // @[dpath.scala 89:32]
  reg  if_inst_buffer_valid; // @[dpath.scala 90:38]
  wire  _GEN_1 = io_imem_resp_valid | if_inst_buffer_valid; // @[dpath.scala 92:33 93:31 90:38]
  wire  _GEN_3 = io_ctl_stall & _GEN_1; // @[dpath.scala 91:24 99:28]
  wire [4:0] exe_rs2_addr = exe_reg_inst[24:20]; // @[dpath.scala 135:35]
  wire [4:0] exe_wbaddr = exe_reg_inst[11:7]; // @[dpath.scala 136:35]
  wire  exe_wben = io_ctl_rf_wen & ~io_ctl_exception; // @[dpath.scala 139:33]
  wire  _T_1 = exe_wbaddr != 5'h0; // @[dpath.scala 152:34]
  wire  _exe_wbdata_T = io_ctl_wb_sel == 2'h0; // @[dpath.scala 269:34]
  wire  _exe_alu_out_T = io_ctl_alu_fun == 5'h1; // @[dpath.scala 197:35]
  wire  _exe_alu_op1_T = io_ctl_op1_sel == 2'h0; // @[dpath.scala 178:32]
  wire  _exe_alu_op1_T_1 = io_ctl_op1_sel == 2'h1; // @[dpath.scala 179:32]
  wire [19:0] imm_u = exe_reg_inst[31:12]; // @[dpath.scala 165:28]
  wire [31:0] imm_u_sext = {imm_u,12'h0}; // @[Cat.scala 31:58]
  wire  _exe_alu_op1_T_2 = io_ctl_op1_sel == 2'h2; // @[dpath.scala 180:32]
  wire [31:0] imm_z = {27'h0,exe_rs1_addr}; // @[Cat.scala 31:58]
  wire [31:0] _exe_alu_op1_T_3 = _exe_alu_op1_T_2 ? imm_z : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op1_T_4 = _exe_alu_op1_T_1 ? imm_u_sext : _exe_alu_op1_T_3; // @[Mux.scala 101:16]
  wire [31:0] exe_alu_op1 = _exe_alu_op1_T ? exe_rs1_data : _exe_alu_op1_T_4; // @[Mux.scala 101:16]
  wire  _exe_alu_op2_T = io_ctl_op2_sel == 3'h0; // @[dpath.scala 184:32]
  wire [31:0] exe_rs2_data = exe_rs2_addr != 5'h0 ? regfile_exe_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 158:26]
  wire  _exe_alu_op2_T_1 = io_ctl_op2_sel == 3'h1; // @[dpath.scala 185:32]
  wire  _exe_alu_op2_T_2 = io_ctl_op2_sel == 3'h2; // @[dpath.scala 186:32]
  wire  _exe_alu_op2_T_3 = io_ctl_op2_sel == 3'h3; // @[dpath.scala 187:32]
  wire [11:0] imm_s = {exe_reg_inst[31:25],exe_wbaddr}; // @[Cat.scala 31:58]
  wire [19:0] _imm_s_sext_T_2 = imm_s[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_s_sext = {_imm_s_sext_T_2,exe_reg_inst[31:25],exe_wbaddr}; // @[Cat.scala 31:58]
  wire [31:0] _exe_alu_op2_T_4 = _exe_alu_op2_T_3 ? imm_s_sext : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op2_T_5 = _exe_alu_op2_T_2 ? imm_i_sext : _exe_alu_op2_T_4; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_op2_T_6 = _exe_alu_op2_T_1 ? exe_reg_pc : _exe_alu_op2_T_5; // @[Mux.scala 101:16]
  wire [31:0] exe_alu_op2 = _exe_alu_op2_T ? exe_rs2_data : _exe_alu_op2_T_6; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_2 = exe_alu_op1 + exe_alu_op2; // @[dpath.scala 197:65]
  wire  _exe_alu_out_T_3 = io_ctl_alu_fun == 5'h2; // @[dpath.scala 198:35]
  wire [31:0] _exe_alu_out_T_5 = exe_alu_op1 - exe_alu_op2; // @[dpath.scala 198:65]
  wire  _exe_alu_out_T_6 = io_ctl_alu_fun == 5'h6; // @[dpath.scala 199:35]
  wire [31:0] _exe_alu_out_T_7 = exe_alu_op1 & exe_alu_op2; // @[dpath.scala 199:65]
  wire  _exe_alu_out_T_8 = io_ctl_alu_fun == 5'h7; // @[dpath.scala 200:35]
  wire [31:0] _exe_alu_out_T_9 = exe_alu_op1 | exe_alu_op2; // @[dpath.scala 200:65]
  wire  _exe_alu_out_T_10 = io_ctl_alu_fun == 5'h8; // @[dpath.scala 201:35]
  wire [31:0] _exe_alu_out_T_11 = exe_alu_op1 ^ exe_alu_op2; // @[dpath.scala 201:65]
  wire  _exe_alu_out_T_12 = io_ctl_alu_fun == 5'h9; // @[dpath.scala 202:35]
  wire [31:0] _exe_alu_out_T_13 = _exe_alu_op1_T ? exe_rs1_data : _exe_alu_op1_T_4; // @[dpath.scala 202:71]
  wire [31:0] _exe_alu_out_T_14 = _exe_alu_op2_T ? exe_rs2_data : _exe_alu_op2_T_6; // @[dpath.scala 202:94]
  wire  _exe_alu_out_T_15 = $signed(_exe_alu_out_T_13) < $signed(_exe_alu_out_T_14); // @[dpath.scala 202:74]
  wire  _exe_alu_out_T_16 = io_ctl_alu_fun == 5'ha; // @[dpath.scala 203:35]
  wire  _exe_alu_out_T_17 = exe_alu_op1 < exe_alu_op2; // @[dpath.scala 203:65]
  wire  _exe_alu_out_T_18 = io_ctl_alu_fun == 5'h3; // @[dpath.scala 204:35]
  wire [4:0] alu_shamt = exe_alu_op2[4:0]; // @[dpath.scala 194:31]
  wire [62:0] _GEN_11 = {{31'd0}, exe_alu_op1}; // @[dpath.scala 204:66]
  wire [62:0] _exe_alu_out_T_19 = _GEN_11 << alu_shamt; // @[dpath.scala 204:66]
  wire  _exe_alu_out_T_21 = io_ctl_alu_fun == 5'h5; // @[dpath.scala 205:35]
  wire [31:0] _exe_alu_out_T_24 = $signed(_exe_alu_out_T_13) >>> alu_shamt; // @[dpath.scala 205:94]
  wire  _exe_alu_out_T_25 = io_ctl_alu_fun == 5'h4; // @[dpath.scala 206:35]
  wire [31:0] _exe_alu_out_T_26 = exe_alu_op1 >> alu_shamt; // @[dpath.scala 206:65]
  wire  _exe_alu_out_T_27 = io_ctl_alu_fun == 5'hb; // @[dpath.scala 207:35]
  wire [31:0] _exe_alu_out_T_28 = _exe_alu_out_T_27 ? exe_alu_op1 : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_29 = _exe_alu_out_T_25 ? _exe_alu_out_T_26 : _exe_alu_out_T_28; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_30 = _exe_alu_out_T_21 ? _exe_alu_out_T_24 : _exe_alu_out_T_29; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_31 = _exe_alu_out_T_18 ? _exe_alu_out_T_19[31:0] : _exe_alu_out_T_30; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_32 = _exe_alu_out_T_16 ? {{31'd0}, _exe_alu_out_T_17} : _exe_alu_out_T_31; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_33 = _exe_alu_out_T_12 ? {{31'd0}, _exe_alu_out_T_15} : _exe_alu_out_T_32; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_34 = _exe_alu_out_T_10 ? _exe_alu_out_T_11 : _exe_alu_out_T_33; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_35 = _exe_alu_out_T_8 ? _exe_alu_out_T_9 : _exe_alu_out_T_34; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_36 = _exe_alu_out_T_6 ? _exe_alu_out_T_7 : _exe_alu_out_T_35; // @[Mux.scala 101:16]
  wire [31:0] _exe_alu_out_T_37 = _exe_alu_out_T_3 ? _exe_alu_out_T_5 : _exe_alu_out_T_36; // @[Mux.scala 101:16]
  wire [31:0] exe_alu_out = _exe_alu_out_T ? _exe_alu_out_T_2 : _exe_alu_out_T_37; // @[Mux.scala 101:16]
  wire  _exe_wbdata_T_1 = io_ctl_wb_sel == 2'h1; // @[dpath.scala 270:34]
  wire  _exe_wbdata_T_2 = io_ctl_wb_sel == 2'h2; // @[dpath.scala 271:34]
  wire  _exe_wbdata_T_3 = io_ctl_wb_sel == 2'h3; // @[dpath.scala 272:34]
  wire [31:0] _exe_wbdata_T_4 = _exe_wbdata_T_3 ? csr_io_rw_rdata : exe_alu_out; // @[Mux.scala 101:16]
  wire [31:0] _exe_wbdata_T_5 = _exe_wbdata_T_2 ? exe_reg_pc_plus4 : _exe_wbdata_T_4; // @[Mux.scala 101:16]
  wire [31:0] _exe_wbdata_T_6 = _exe_wbdata_T_1 ? io_dmem_resp_bits_data : _exe_wbdata_T_5; // @[Mux.scala 101:16]
  wire [31:0] exe_wbdata = _exe_wbdata_T ? exe_alu_out : _exe_wbdata_T_6; // @[Mux.scala 101:16]
  wire  _io_dat_inst_misaligned_T_2 = io_ctl_pc_sel_no_xept == 3'h1; // @[dpath.scala 218:87]
  wire  _io_dat_inst_misaligned_T_6 = io_ctl_pc_sel_no_xept == 3'h2; // @[dpath.scala 219:87]
  wire  _io_dat_inst_misaligned_T_7 = |exe_jmp_target[1:0] & io_ctl_pc_sel_no_xept == 3'h2; // @[dpath.scala 219:62]
  wire  _io_dat_inst_misaligned_T_8 = |exe_br_target[1:0] & io_ctl_pc_sel_no_xept == 3'h1 | _io_dat_inst_misaligned_T_7; // @[dpath.scala 218:98]
  wire  _io_dat_inst_misaligned_T_11 = io_ctl_pc_sel_no_xept == 3'h3; // @[dpath.scala 220:87]
  wire  _io_dat_inst_misaligned_T_12 = |exe_jump_reg_target[1:0] & io_ctl_pc_sel_no_xept == 3'h3; // @[dpath.scala 220:62]
  wire [31:0] _tval_inst_ma_T_3 = _io_dat_inst_misaligned_T_11 ? exe_jump_reg_target : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _tval_inst_ma_T_4 = _io_dat_inst_misaligned_T_6 ? exe_jmp_target : _tval_inst_ma_T_3; // @[Mux.scala 101:16]
  wire [31:0] tval_inst_ma = _io_dat_inst_misaligned_T_2 ? exe_br_target : _tval_inst_ma_T_4; // @[Mux.scala 101:16]
  wire  _csr_io_tval_T = io_ctl_exception_cause == 32'h2; // @[dpath.scala 242:43]
  wire  _csr_io_tval_T_1 = io_ctl_exception_cause == 32'h0; // @[dpath.scala 243:43]
  wire  _csr_io_tval_T_2 = io_ctl_exception_cause == 32'h6; // @[dpath.scala 244:43]
  wire  _csr_io_tval_T_3 = io_ctl_exception_cause == 32'h4; // @[dpath.scala 245:43]
  wire [31:0] _csr_io_tval_T_4 = _csr_io_tval_T_3 ? exe_alu_out : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _csr_io_tval_T_5 = _csr_io_tval_T_2 ? exe_alu_out : _csr_io_tval_T_4; // @[Mux.scala 101:16]
  wire [31:0] _csr_io_tval_T_6 = _csr_io_tval_T_1 ? tval_inst_ma : _csr_io_tval_T_5; // @[Mux.scala 101:16]
  reg  reg_interrupt_handled; // @[dpath.scala 249:39]
  wire [31:0] _io_dat_br_lt_T = exe_rs1_addr != 5'h0 ? regfile_exe_rs1_data_MPORT_data : 32'h0; // @[dpath.scala 279:41]
  wire [31:0] _io_dat_br_lt_T_1 = exe_rs2_addr != 5'h0 ? regfile_exe_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 279:65]
  wire [2:0] _misaligned_mask_T_1 = io_ctl_mem_typ - 3'h1; // @[dpath.scala 285:53]
  wire [5:0] _misaligned_mask_T_3 = 6'h7 << _misaligned_mask_T_1[1:0]; // @[dpath.scala 285:34]
  wire [5:0] _misaligned_mask_T_4 = ~_misaligned_mask_T_3; // @[dpath.scala 285:23]
  wire [2:0] misaligned_mask = _misaligned_mask_T_4[2:0]; // @[dpath.scala 284:30 285:20]
  wire [2:0] _io_dat_data_misaligned_T_1 = misaligned_mask & exe_alu_out[2:0]; // @[dpath.scala 286:47]
  wire [31:0] _T_4 = csr_io_time; // @[dpath.scala 297:18]
  wire [7:0] _T_5 = io_ctl_if_kill ? 8'h4b : 8'h20; // @[Mux.scala 101:16]
  wire [7:0] _T_6 = io_ctl_stall ? 8'h53 : _T_5; // @[Mux.scala 101:16]
  wire [7:0] _T_8 = 3'h1 == io_ctl_pc_sel ? 8'h42 : 8'h3f; // @[Mux.scala 81:58]
  wire [7:0] _T_10 = 3'h2 == io_ctl_pc_sel ? 8'h4a : _T_8; // @[Mux.scala 81:58]
  wire [7:0] _T_12 = 3'h3 == io_ctl_pc_sel ? 8'h52 : _T_10; // @[Mux.scala 81:58]
  wire [7:0] _T_14 = 3'h4 == io_ctl_pc_sel ? 8'h45 : _T_12; // @[Mux.scala 81:58]
  wire [7:0] _T_16 = 3'h0 == io_ctl_pc_sel ? 8'h20 : _T_14; // @[Mux.scala 81:58]
  wire [7:0] _T_17 = csr_io_exception ? 8'h58 : 8'h20; // @[dpath.scala 317:10]
  CSRFile_2stage CSRFile_2stage ( // @[dpath.scala 228:20]
    .clock(csr_clock),
    .reset(csr_reset),
    .io_ungated_clock(csr_io_ungated_clock),
    .io_interrupts_debug(csr_io_interrupts_debug),
    .io_interrupts_mtip(csr_io_interrupts_mtip),
    .io_interrupts_msip(csr_io_interrupts_msip),
    .io_interrupts_meip(csr_io_interrupts_meip),
    .io_hartid(csr_io_hartid),
    .io_rw_addr(csr_io_rw_addr),
    .io_rw_cmd(csr_io_rw_cmd),
    .io_rw_rdata(csr_io_rw_rdata),
    .io_rw_wdata(csr_io_rw_wdata),
    .io_csr_stall(csr_io_csr_stall),
    .io_eret(csr_io_eret),
    .io_singleStep(csr_io_singleStep),
    .io_status_debug(csr_io_status_debug),
    .io_status_cease(csr_io_status_cease),
    .io_status_wfi(csr_io_status_wfi),
    .io_status_isa(csr_io_status_isa),
    .io_status_dprv(csr_io_status_dprv),
    .io_status_dv(csr_io_status_dv),
    .io_status_prv(csr_io_status_prv),
    .io_status_v(csr_io_status_v),
    .io_status_sd(csr_io_status_sd),
    .io_status_zero2(csr_io_status_zero2),
    .io_status_mpv(csr_io_status_mpv),
    .io_status_gva(csr_io_status_gva),
    .io_status_mbe(csr_io_status_mbe),
    .io_status_sbe(csr_io_status_sbe),
    .io_status_sxl(csr_io_status_sxl),
    .io_status_uxl(csr_io_status_uxl),
    .io_status_sd_rv32(csr_io_status_sd_rv32),
    .io_status_zero1(csr_io_status_zero1),
    .io_status_tsr(csr_io_status_tsr),
    .io_status_tw(csr_io_status_tw),
    .io_status_tvm(csr_io_status_tvm),
    .io_status_mxr(csr_io_status_mxr),
    .io_status_sum(csr_io_status_sum),
    .io_status_mprv(csr_io_status_mprv),
    .io_status_xs(csr_io_status_xs),
    .io_status_fs(csr_io_status_fs),
    .io_status_mpp(csr_io_status_mpp),
    .io_status_vs(csr_io_status_vs),
    .io_status_spp(csr_io_status_spp),
    .io_status_mpie(csr_io_status_mpie),
    .io_status_ube(csr_io_status_ube),
    .io_status_spie(csr_io_status_spie),
    .io_status_upie(csr_io_status_upie),
    .io_status_mie(csr_io_status_mie),
    .io_status_hie(csr_io_status_hie),
    .io_status_sie(csr_io_status_sie),
    .io_status_uie(csr_io_status_uie),
    .io_evec(csr_io_evec),
    .io_exception(csr_io_exception),
    .io_retire(csr_io_retire),
    .io_cause(csr_io_cause),
    .io_pc(csr_io_pc),
    .io_tval(csr_io_tval),
    .io_time(csr_io_time),
    .io_interrupt(csr_io_interrupt),
    .io_interrupt_cause(csr_io_interrupt_cause)
  );
  assign regfile_io_ddpath_rdata_MPORT_en = 1'h1;
  assign regfile_io_ddpath_rdata_MPORT_addr = 5'h0;
  assign regfile_io_ddpath_rdata_MPORT_data = regfile[regfile_io_ddpath_rdata_MPORT_addr]; // @[dpath.scala 142:21]
  assign regfile_exe_rs1_data_MPORT_en = 1'h1;
  assign regfile_exe_rs1_data_MPORT_addr = exe_reg_inst[19:15];
  assign regfile_exe_rs1_data_MPORT_data = regfile[regfile_exe_rs1_data_MPORT_addr]; // @[dpath.scala 142:21]
  assign regfile_exe_rs2_data_MPORT_en = 1'h1;
  assign regfile_exe_rs2_data_MPORT_addr = exe_reg_inst[24:20];
  assign regfile_exe_rs2_data_MPORT_data = regfile[regfile_exe_rs2_data_MPORT_addr]; // @[dpath.scala 142:21]
  assign regfile_MPORT_data = 32'h0;
  assign regfile_MPORT_addr = 5'h0;
  assign regfile_MPORT_mask = 1'h1;
  assign regfile_MPORT_en = 1'h0;
  assign regfile_MPORT_1_data = _exe_wbdata_T ? exe_alu_out : _exe_wbdata_T_6;
  assign regfile_MPORT_1_addr = exe_reg_inst[11:7];
  assign regfile_MPORT_1_mask = 1'h1;
  assign regfile_MPORT_1_en = exe_wben & _T_1;
  assign io_imem_req_valid = ~if_inst_buffer_valid; // @[dpath.scala 106:28]
  assign io_imem_req_bits_addr = if_reg_pc; // @[dpath.scala 109:26]
  assign io_dmem_req_bits_addr = _exe_alu_out_T ? _exe_alu_out_T_2 : _exe_alu_out_T_37; // @[Mux.scala 101:16]
  assign io_dmem_req_bits_data = exe_rs2_addr != 5'h0 ? regfile_exe_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 158:26]
  assign io_dat_if_valid_resp = if_inst_buffer_valid | io_imem_resp_valid; // @[dpath.scala 103:49]
  assign io_dat_inst = exe_reg_inst; // @[dpath.scala 277:18]
  assign io_dat_br_eq = exe_rs1_data == exe_rs2_data; // @[dpath.scala 278:35]
  assign io_dat_br_lt = $signed(_io_dat_br_lt_T) < $signed(_io_dat_br_lt_T_1); // @[dpath.scala 279:44]
  assign io_dat_br_ltu = exe_rs1_data < exe_rs2_data; // @[dpath.scala 280:44]
  assign io_dat_inst_misaligned = _io_dat_inst_misaligned_T_8 | _io_dat_inst_misaligned_T_12; // @[dpath.scala 219:98]
  assign io_dat_data_misaligned = |_io_dat_data_misaligned_T_1 & io_ctl_mem_val; // @[dpath.scala 286:85]
  assign io_dat_mem_store = io_ctl_mem_fcn == 2'h1; // @[dpath.scala 287:39]
  assign io_dat_csr_eret = csr_io_eret; // @[dpath.scala 261:20]
  assign io_dat_csr_interrupt = csr_io_interrupt & ~reg_interrupt_handled; // @[dpath.scala 253:42]
  assign csr_clock = clock;
  assign csr_reset = reset;
  assign csr_io_ungated_clock = clock; // @[dpath.scala 259:25]
  assign csr_io_interrupts_debug = io_interrupt_debug; // @[dpath.scala 255:22]
  assign csr_io_interrupts_mtip = io_interrupt_mtip; // @[dpath.scala 255:22]
  assign csr_io_interrupts_msip = io_interrupt_msip; // @[dpath.scala 255:22]
  assign csr_io_interrupts_meip = io_interrupt_meip; // @[dpath.scala 255:22]
  assign csr_io_hartid = io_hartid; // @[dpath.scala 256:18]
  assign csr_io_rw_addr = exe_reg_inst[31:20]; // @[dpath.scala 231:35]
  assign csr_io_rw_cmd = io_ctl_csr_cmd; // @[dpath.scala 232:20]
  assign csr_io_rw_wdata = _exe_alu_out_T ? _exe_alu_out_T_2 : _exe_alu_out_T_37; // @[Mux.scala 101:16]
  assign csr_io_exception = io_ctl_exception; // @[dpath.scala 237:21]
  assign csr_io_retire = exe_reg_valid & ~(io_ctl_stall | io_ctl_exception); // @[dpath.scala 236:38]
  assign csr_io_cause = io_ctl_exception ? io_ctl_exception_cause : csr_io_interrupt_cause; // @[dpath.scala 258:23]
  assign csr_io_pc = exe_reg_pc; // @[dpath.scala 238:21]
  assign csr_io_tval = _csr_io_tval_T ? exe_reg_inst : _csr_io_tval_T_6; // @[Mux.scala 101:16]



  wire io_ctl_if_kill_r = (exe_reg_inst == 32'h4033);
  // wire [31:0] pc_x;
  // assign pc_x = io_ctl_if_kill_r ? if_reg_pc : exe_reg_pc;
  reg fetch_reg;
  reg execute_reg;
  wire filtered_fetch_reg = fetch_reg && io_ctl_if_kill;

  // For contract
  reg _exe_wbdata_T_1_delay;
  reg _exe_wbdata_T_delay;
  reg [31:0] exe_reg_inst_delay;
  reg [31:0] pc_retire;
  reg retire;

  always @(posedge clock) begin
    retire <= execute_reg;
    pc_retire <= io_ctl_if_kill_r ? pc_retire : exe_reg_pc;
    exe_reg_inst_delay <= exe_reg_inst;
    _exe_wbdata_T_delay <= _exe_wbdata_T;
    _exe_wbdata_T_1_delay <= _exe_wbdata_T_1;
  end
  // for delayed check
  wire execute = reset ? 0 : (!(io_ctl_stall)) ? (io_ctl_if_kill ? 0 : 1) : 0;
 
  wire fetch = reset ? 0 : _T? 1  : 0;
  // wire filtered_fetch = fetch && io_ctl_if_kill_prev;

  wire [31:0] filtered_if_reg_pc = io_ctl_if_kill ? if_reg_pc_delay : if_reg_pc;
  reg [31:0]  if_reg_pc_delay;
  always @(posedge clock) begin

    if (regfile_MPORT_en & regfile_MPORT_mask) begin
      regfile[regfile_MPORT_addr] <= regfile_MPORT_data; // @[dpath.scala 142:21]
    end
    if (regfile_MPORT_1_en & regfile_MPORT_1_mask) begin
      regfile[regfile_MPORT_1_addr] <= regfile_MPORT_1_data; // @[dpath.scala 142:21]
    end
    if (reset) begin // @[dpath.scala 57:27]
      if_reg_pc <= io_reset_vector; // @[dpath.scala 57:27]
      fetch_reg <= 0;
    end else if (_T) begin // @[dpath.scala 73:4]
      fetch_reg <= 1;
      if_reg_pc_delay <= if_reg_pc;
      if (_if_pc_next_T) begin // @[Mux.scala 101:16]
        if_reg_pc <= if_pc_plus4;
      end else if (_if_pc_next_T_1) begin // @[Mux.scala 101:16]
        if_reg_pc <= exe_br_target;
      end else begin
        if_reg_pc <= _if_pc_next_T_7;
      end
    end
    if (reset) begin // @[dpath.scala 59:34]
      exe_reg_pc <= 32'h0; // @[dpath.scala 59:34]
      execute_reg <= 0;
    end else if (!(io_ctl_stall)) begin // @[dpath.scala 113:4]
      if (io_ctl_if_kill) begin // @[dpath.scala 118:4]
        exe_reg_pc <= 32'h0; // @[dpath.scala 120:20]
        execute_reg <= 0;
      end else begin
        exe_reg_pc <= if_reg_pc; // @[dpath.scala 126:20]
        execute_reg <= 1;
      end
    end
    if (reset) begin // @[dpath.scala 60:34]
      exe_reg_pc_plus4 <= 32'h0; // @[dpath.scala 60:34]
    end else begin
      exe_reg_pc_plus4 <= if_pc_plus4; // @[dpath.scala 130:21]
    end
    if (reset) begin // @[dpath.scala 61:34]
      exe_reg_inst <= 32'h4033; // @[dpath.scala 61:34]
    end else if (!(io_ctl_stall)) begin // @[dpath.scala 113:4]
      if (io_ctl_if_kill) begin // @[dpath.scala 118:4]
        exe_reg_inst <= 32'h4033; // @[dpath.scala 119:20]
      end else if (if_inst_buffer_valid) begin // @[dpath.scala 110:21]
        exe_reg_inst <= if_inst_buffer;
      end else begin
        exe_reg_inst <= io_imem_resp_bits_data;
      end
    end
    if (reset) begin // @[dpath.scala 62:34]
      exe_reg_valid <= 1'h0; // @[dpath.scala 62:34]
    end else if (!(io_ctl_stall)) begin // @[dpath.scala 113:4]
      if (io_ctl_if_kill) begin // @[dpath.scala 118:4]
        exe_reg_valid <= 1'h0; // @[dpath.scala 121:21]
      end else begin
        exe_reg_valid <= 1'h1; // @[dpath.scala 127:21]
      end
    end
    if (reset) begin // @[dpath.scala 89:32]
      if_inst_buffer <= 32'h0; // @[dpath.scala 89:32]
    end else if (io_ctl_stall) begin // @[dpath.scala 91:24]
      if (io_imem_resp_valid) begin // @[dpath.scala 92:33]
        if_inst_buffer <= io_imem_resp_bits_data; // @[dpath.scala 94:25]
      end
    end else begin
      if_inst_buffer <= 32'h0; // @[dpath.scala 98:22]
    end
    if (reset) begin // @[dpath.scala 90:38]
      if_inst_buffer_valid <= 1'h0; // @[dpath.scala 90:38]
    end else begin
      if_inst_buffer_valid <= _GEN_3;
    end
    if (reset) begin // @[dpath.scala 249:39]
      reg_interrupt_handled <= 1'h0; // @[dpath.scala 249:39]
    end else if (_T) begin // @[dpath.scala 250:25]
      reg_interrupt_handled <= csr_io_interrupt; // @[dpath.scala 251:29]
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~reset) begin
          $fwrite(32'h80000002,
            "Cyc= %d [%d] pc=[%x] W[r%d=%x][%d] Op1=[r%d][%x] Op2=[r%d][%x] inst=[%x] %c%c%c DASM(%x)\n",_T_4,
            csr_io_retire,exe_reg_pc,exe_wbaddr,exe_wbdata,exe_wben,exe_rs1_addr,exe_alu_op1,exe_rs2_addr,exe_alu_op2,
            exe_reg_inst,_T_6,_T_16,_T_17,exe_reg_inst); // @[dpath.scala 296:10]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 32; initvar = initvar+1)
    regfile[initvar] = _RAND_0[31:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  if_reg_pc = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  exe_reg_pc = _RAND_2[31:0];
  _RAND_3 = {1{`RANDOM}};
  exe_reg_pc_plus4 = _RAND_3[31:0];
  _RAND_4 = {1{`RANDOM}};
  exe_reg_inst = _RAND_4[31:0];
  _RAND_5 = {1{`RANDOM}};
  exe_reg_valid = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  if_inst_buffer = _RAND_6[31:0];
  _RAND_7 = {1{`RANDOM}};
  if_inst_buffer_valid = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  reg_interrupt_handled = _RAND_8[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule