module DatPath_1stage(
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
  input         io_ctl_dmiss,
  input  [2:0]  io_ctl_pc_sel,
  input  [1:0]  io_ctl_op1_sel,
  input  [1:0]  io_ctl_op2_sel,
  input  [3:0]  io_ctl_alu_fun,
  input  [1:0]  io_ctl_wb_sel,
  input         io_ctl_rf_wen,
  input  [2:0]  io_ctl_csr_cmd,
  input         io_ctl_exception,
  input  [31:0] io_ctl_exception_cause,
  input  [2:0]  io_ctl_pc_sel_no_xept,
  output [31:0] io_dat_inst,
  output        io_dat_imiss,
  output        io_dat_br_eq,
  output        io_dat_br_lt,
  output        io_dat_br_ltu,
  output        io_dat_csr_eret,
  output        io_dat_csr_interrupt,
  output        io_dat_inst_misaligned,
  output [2:0]  io_dat_mem_address_low,
  input         io_interrupt_debug,
  input         io_interrupt_mtip,
  input         io_interrupt_msip,
  input         io_interrupt_meip,
  input         io_hartid,
  input  [31:0] io_reset_vector
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  reg [31:0] regfile [0:31]; // @[dpath.scala 120:21]
  wire  regfile_io_ddpath_rdata_MPORT_en; // @[dpath.scala 120:21]
  wire [4:0] regfile_io_ddpath_rdata_MPORT_addr; // @[dpath.scala 120:21]
  wire [31:0] regfile_io_ddpath_rdata_MPORT_data; // @[dpath.scala 120:21]
  wire  regfile_rs1_data_MPORT_en; // @[dpath.scala 120:21]
  wire [4:0] regfile_rs1_data_MPORT_addr; // @[dpath.scala 120:21]
  wire [31:0] regfile_rs1_data_MPORT_data; // @[dpath.scala 120:21]
  wire  regfile_rs2_data_MPORT_en; // @[dpath.scala 120:21]
  wire [4:0] regfile_rs2_data_MPORT_addr; // @[dpath.scala 120:21]
  wire [31:0] regfile_rs2_data_MPORT_data; // @[dpath.scala 120:21]
  wire [31:0] regfile_MPORT_data; // @[dpath.scala 120:21]
  wire [4:0] regfile_MPORT_addr; // @[dpath.scala 120:21]
  wire  regfile_MPORT_mask; // @[dpath.scala 120:21]
  wire  regfile_MPORT_en; // @[dpath.scala 120:21]
  wire [31:0] regfile_MPORT_1_data; // @[dpath.scala 120:21]
  wire [4:0] regfile_MPORT_1_addr; // @[dpath.scala 120:21]
  wire  regfile_MPORT_1_mask; // @[dpath.scala 120:21]
  wire  regfile_MPORT_1_en; // @[dpath.scala 120:21]
  wire  csr_clock; // @[dpath.scala 194:20]
  wire  csr_reset; // @[dpath.scala 194:20]
  wire  csr_io_ungated_clock; // @[dpath.scala 194:20]
  wire  csr_io_interrupts_debug; // @[dpath.scala 194:20]
  wire  csr_io_interrupts_mtip; // @[dpath.scala 194:20]
  wire  csr_io_interrupts_msip; // @[dpath.scala 194:20]
  wire  csr_io_interrupts_meip; // @[dpath.scala 194:20]
  wire  csr_io_hartid; // @[dpath.scala 194:20]
  wire [11:0] csr_io_rw_addr; // @[dpath.scala 194:20]
  wire [2:0] csr_io_rw_cmd; // @[dpath.scala 194:20]
  wire [31:0] csr_io_rw_rdata; // @[dpath.scala 194:20]
  wire [31:0] csr_io_rw_wdata; // @[dpath.scala 194:20]
  wire  csr_io_csr_stall; // @[dpath.scala 194:20]
  wire  csr_io_eret; // @[dpath.scala 194:20]
  wire  csr_io_singleStep; // @[dpath.scala 194:20]
  wire  csr_io_status_debug; // @[dpath.scala 194:20]
  wire  csr_io_status_cease; // @[dpath.scala 194:20]
  wire  csr_io_status_wfi; // @[dpath.scala 194:20]
  wire [31:0] csr_io_status_isa; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_dprv; // @[dpath.scala 194:20]
  wire  csr_io_status_dv; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_prv; // @[dpath.scala 194:20]
  wire  csr_io_status_v; // @[dpath.scala 194:20]
  wire  csr_io_status_sd; // @[dpath.scala 194:20]
  wire [22:0] csr_io_status_zero2; // @[dpath.scala 194:20]
  wire  csr_io_status_mpv; // @[dpath.scala 194:20]
  wire  csr_io_status_gva; // @[dpath.scala 194:20]
  wire  csr_io_status_mbe; // @[dpath.scala 194:20]
  wire  csr_io_status_sbe; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_sxl; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_uxl; // @[dpath.scala 194:20]
  wire  csr_io_status_sd_rv32; // @[dpath.scala 194:20]
  wire [7:0] csr_io_status_zero1; // @[dpath.scala 194:20]
  wire  csr_io_status_tsr; // @[dpath.scala 194:20]
  wire  csr_io_status_tw; // @[dpath.scala 194:20]
  wire  csr_io_status_tvm; // @[dpath.scala 194:20]
  wire  csr_io_status_mxr; // @[dpath.scala 194:20]
  wire  csr_io_status_sum; // @[dpath.scala 194:20]
  wire  csr_io_status_mprv; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_xs; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_fs; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_mpp; // @[dpath.scala 194:20]
  wire [1:0] csr_io_status_vs; // @[dpath.scala 194:20]
  wire  csr_io_status_spp; // @[dpath.scala 194:20]
  wire  csr_io_status_mpie; // @[dpath.scala 194:20]
  wire  csr_io_status_ube; // @[dpath.scala 194:20]
  wire  csr_io_status_spie; // @[dpath.scala 194:20]
  wire  csr_io_status_upie; // @[dpath.scala 194:20]
  wire  csr_io_status_mie; // @[dpath.scala 194:20]
  wire  csr_io_status_hie; // @[dpath.scala 194:20]
  wire  csr_io_status_sie; // @[dpath.scala 194:20]
  wire  csr_io_status_uie; // @[dpath.scala 194:20]
  wire [31:0] csr_io_evec; // @[dpath.scala 194:20]
  wire  csr_io_exception; // @[dpath.scala 194:20]
  wire  csr_io_retire; // @[dpath.scala 194:20]
  wire [31:0] csr_io_cause; // @[dpath.scala 194:20]
  wire [31:0] csr_io_pc; // @[dpath.scala 194:20]
  wire [31:0] csr_io_tval; // @[dpath.scala 194:20]
  wire [31:0] csr_io_time; // @[dpath.scala 194:20]
  wire  csr_io_interrupt; // @[dpath.scala 194:20]
  wire [31:0] csr_io_interrupt_cause; // @[dpath.scala 194:20]
  wire  _pc_next_T = io_ctl_pc_sel == 3'h0; // @[dpath.scala 67:34]
  wire  _pc_next_T_1 = io_ctl_pc_sel == 3'h1; // @[dpath.scala 68:34]
  wire  _pc_next_T_2 = io_ctl_pc_sel == 3'h2; // @[dpath.scala 69:34]
  wire  _pc_next_T_3 = io_ctl_pc_sel == 3'h3; // @[dpath.scala 70:34]
  wire  _pc_next_T_4 = io_ctl_pc_sel == 3'h4; // @[dpath.scala 71:34]
  wire [31:0] exception_target = csr_io_evec; // @[dpath.scala 204:21 63:31]
  reg [31:0] pc_reg; // @[dpath.scala 74:24]
  wire [31:0] pc_plus4 = pc_reg + 32'h4; // @[dpath.scala 81:24]
  wire [31:0] _pc_next_T_5 = _pc_next_T_4 ? exception_target : pc_plus4; // @[Mux.scala 101:16]
  reg  reg_dmiss; // @[dpath.scala 86:27]
  reg [31:0] if_inst_buffer; // @[dpath.scala 87:32]
  wire [31:0] inst = reg_dmiss ? if_inst_buffer : io_imem_resp_bits_data; // @[dpath.scala 97:18]
  wire [4:0] rs1_addr = inst[19:15]; // @[dpath.scala 112:23]
  wire [31:0] rs1_data = rs1_addr != 5'h0 ? regfile_rs1_data_MPORT_data : 32'h0; // @[dpath.scala 134:22]
  wire [11:0] imm_i = inst[31:20]; // @[dpath.scala 139:20]
  wire [19:0] _imm_i_sext_T_2 = imm_i[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_i_sext = {_imm_i_sext_T_2,imm_i}; // @[Cat.scala 31:58]
  wire [31:0] _jump_reg_target_T_1 = rs1_data + imm_i_sext; // @[dpath.scala 191:42]
  wire [31:0] jump_reg_target = _jump_reg_target_T_1 & 32'hfffffffe; // @[dpath.scala 191:65]
  wire [31:0] _pc_next_T_6 = _pc_next_T_3 ? jump_reg_target : _pc_next_T_5; // @[Mux.scala 101:16]
  wire [19:0] imm_j = {inst[31],inst[19:12],inst[20],inst[30:21]}; // @[Cat.scala 31:58]
  wire [10:0] _imm_j_sext_T_2 = imm_j[19] ? 11'h7ff : 11'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_j_sext = {_imm_j_sext_T_2,inst[31],inst[19:12],inst[20],inst[30:21],1'h0}; // @[Cat.scala 31:58]
  wire [31:0] jmp_target = pc_reg + imm_j_sext; // @[dpath.scala 190:30]
  wire [31:0] _pc_next_T_7 = _pc_next_T_2 ? jmp_target : _pc_next_T_6; // @[Mux.scala 101:16]
  wire [11:0] imm_b = {inst[31],inst[7],inst[30:25],inst[11:8]}; // @[Cat.scala 31:58]
  wire [18:0] _imm_b_sext_T_2 = imm_b[11] ? 19'h7ffff : 19'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_b_sext = {_imm_b_sext_T_2,inst[31],inst[7],inst[30:25],inst[11:8],1'h0}; // @[Cat.scala 31:58]
  wire [31:0] br_target = pc_reg + imm_b_sext; // @[dpath.scala 189:30]
  wire  _T = ~io_ctl_stall; // @[dpath.scala 76:10]
  wire  _T_3 = ~reset; // @[dpath.scala 89:13]
  wire  _io_dat_inst_misaligned_T_2 = io_ctl_pc_sel_no_xept == 3'h1; // @[dpath.scala 102:83]
  wire  _io_dat_inst_misaligned_T_6 = io_ctl_pc_sel_no_xept == 3'h2; // @[dpath.scala 103:83]
  wire  _io_dat_inst_misaligned_T_7 = |jmp_target[1:0] & io_ctl_pc_sel_no_xept == 3'h2; // @[dpath.scala 103:58]
  wire  _io_dat_inst_misaligned_T_8 = |br_target[1:0] & io_ctl_pc_sel_no_xept == 3'h1 | _io_dat_inst_misaligned_T_7; // @[dpath.scala 102:94]
  wire  _io_dat_inst_misaligned_T_11 = io_ctl_pc_sel_no_xept == 3'h3; // @[dpath.scala 104:83]
  wire  _io_dat_inst_misaligned_T_12 = |jump_reg_target[1:0] & io_ctl_pc_sel_no_xept == 3'h3; // @[dpath.scala 104:58]
  wire [31:0] _tval_inst_ma_T_3 = _io_dat_inst_misaligned_T_11 ? jump_reg_target : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _tval_inst_ma_T_4 = _io_dat_inst_misaligned_T_6 ? jmp_target : _tval_inst_ma_T_3; // @[Mux.scala 101:16]
  wire [31:0] tval_inst_ma = _io_dat_inst_misaligned_T_2 ? br_target : _tval_inst_ma_T_4; // @[Mux.scala 101:16]
  wire [4:0] rs2_addr = inst[24:20]; // @[dpath.scala 113:23]
  wire [4:0] wb_addr = inst[11:7]; // @[dpath.scala 114:23]
  reg  reg_interrupt_edge; // @[dpath.scala 214:36]
  wire  interrupt_edge = csr_io_interrupt & ~reg_interrupt_edge; // @[dpath.scala 218:39]
  wire  wb_wen = io_ctl_rf_wen & ~io_ctl_exception & ~interrupt_edge; // @[dpath.scala 117:52]
  wire  _T_5 = wb_addr != 5'h0; // @[dpath.scala 122:29]
  wire  _wb_data_T = io_ctl_wb_sel == 2'h0; // @[dpath.scala 233:34]
  wire  _alu_out_T = io_ctl_alu_fun == 4'h1; // @[dpath.scala 175:35]
  wire  _alu_op1_T = io_ctl_op1_sel == 2'h0; // @[dpath.scala 155:32]
  wire  _alu_op1_T_1 = io_ctl_op1_sel == 2'h1; // @[dpath.scala 156:32]
  wire [19:0] imm_u = inst[31:12]; // @[dpath.scala 142:20]
  wire [31:0] imm_u_sext = {imm_u,12'h0}; // @[Cat.scala 31:58]
  wire  _alu_op1_T_2 = io_ctl_op1_sel == 2'h2; // @[dpath.scala 157:32]
  wire [31:0] imm_z = {27'h0,rs1_addr}; // @[Cat.scala 31:58]
  wire [31:0] _alu_op1_T_3 = _alu_op1_T_2 ? imm_z : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _alu_op1_T_4 = _alu_op1_T_1 ? imm_u_sext : _alu_op1_T_3; // @[Mux.scala 101:16]
  wire [31:0] alu_op1 = _alu_op1_T ? rs1_data : _alu_op1_T_4; // @[Mux.scala 101:16]
  wire  _alu_op2_T = io_ctl_op2_sel == 2'h0; // @[dpath.scala 161:32]
  wire [31:0] rs2_data = rs2_addr != 5'h0 ? regfile_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 135:22]
  wire  _alu_op2_T_1 = io_ctl_op2_sel == 2'h3; // @[dpath.scala 162:32]
  wire  _alu_op2_T_2 = io_ctl_op2_sel == 2'h1; // @[dpath.scala 163:32]
  wire  _alu_op2_T_3 = io_ctl_op2_sel == 2'h2; // @[dpath.scala 164:32]
  wire [11:0] imm_s = {inst[31:25],wb_addr}; // @[Cat.scala 31:58]
  wire [19:0] _imm_s_sext_T_2 = imm_s[11] ? 20'hfffff : 20'h0; // @[Bitwise.scala 74:12]
  wire [31:0] imm_s_sext = {_imm_s_sext_T_2,inst[31:25],wb_addr}; // @[Cat.scala 31:58]
  wire [31:0] _alu_op2_T_4 = _alu_op2_T_3 ? imm_s_sext : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _alu_op2_T_5 = _alu_op2_T_2 ? imm_i_sext : _alu_op2_T_4; // @[Mux.scala 101:16]
  wire [31:0] _alu_op2_T_6 = _alu_op2_T_1 ? pc_reg : _alu_op2_T_5; // @[Mux.scala 101:16]
  wire [31:0] alu_op2 = _alu_op2_T ? rs2_data : _alu_op2_T_6; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_2 = alu_op1 + alu_op2; // @[dpath.scala 175:61]
  wire  _alu_out_T_3 = io_ctl_alu_fun == 4'h2; // @[dpath.scala 176:35]
  wire [31:0] _alu_out_T_5 = alu_op1 - alu_op2; // @[dpath.scala 176:61]
  wire  _alu_out_T_6 = io_ctl_alu_fun == 4'h6; // @[dpath.scala 177:35]
  wire [31:0] _alu_out_T_7 = alu_op1 & alu_op2; // @[dpath.scala 177:61]
  wire  _alu_out_T_8 = io_ctl_alu_fun == 4'h7; // @[dpath.scala 178:35]
  wire [31:0] _alu_out_T_9 = alu_op1 | alu_op2; // @[dpath.scala 178:61]
  wire  _alu_out_T_10 = io_ctl_alu_fun == 4'h8; // @[dpath.scala 179:35]
  wire [31:0] _alu_out_T_11 = alu_op1 ^ alu_op2; // @[dpath.scala 179:61]
  wire  _alu_out_T_12 = io_ctl_alu_fun == 4'h9; // @[dpath.scala 180:35]
  wire [31:0] _alu_out_T_13 = _alu_op1_T ? rs1_data : _alu_op1_T_4; // @[dpath.scala 180:67]
  wire [31:0] _alu_out_T_14 = _alu_op2_T ? rs2_data : _alu_op2_T_6; // @[dpath.scala 180:86]
  wire  _alu_out_T_15 = $signed(_alu_out_T_13) < $signed(_alu_out_T_14); // @[dpath.scala 180:70]
  wire  _alu_out_T_16 = io_ctl_alu_fun == 4'ha; // @[dpath.scala 181:35]
  wire  _alu_out_T_17 = alu_op1 < alu_op2; // @[dpath.scala 181:61]
  wire  _alu_out_T_18 = io_ctl_alu_fun == 4'h3; // @[dpath.scala 182:35]
  wire [4:0] alu_shamt = alu_op2[4:0]; // @[dpath.scala 172:27]
  wire [62:0] _GEN_2 = {{31'd0}, alu_op1}; // @[dpath.scala 182:62]
  wire [62:0] _alu_out_T_19 = _GEN_2 << alu_shamt; // @[dpath.scala 182:62]
  wire  _alu_out_T_21 = io_ctl_alu_fun == 4'h5; // @[dpath.scala 183:35]
  wire [31:0] _alu_out_T_24 = $signed(_alu_out_T_13) >>> alu_shamt; // @[dpath.scala 183:90]
  wire  _alu_out_T_25 = io_ctl_alu_fun == 4'h4; // @[dpath.scala 184:35]
  wire [31:0] _alu_out_T_26 = alu_op1 >> alu_shamt; // @[dpath.scala 184:61]
  wire  _alu_out_T_27 = io_ctl_alu_fun == 4'hb; // @[dpath.scala 185:35]
  wire [31:0] _alu_out_T_28 = _alu_out_T_27 ? alu_op1 : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_29 = _alu_out_T_25 ? _alu_out_T_26 : _alu_out_T_28; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_30 = _alu_out_T_21 ? _alu_out_T_24 : _alu_out_T_29; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_31 = _alu_out_T_18 ? _alu_out_T_19[31:0] : _alu_out_T_30; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_32 = _alu_out_T_16 ? {{31'd0}, _alu_out_T_17} : _alu_out_T_31; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_33 = _alu_out_T_12 ? {{31'd0}, _alu_out_T_15} : _alu_out_T_32; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_34 = _alu_out_T_10 ? _alu_out_T_11 : _alu_out_T_33; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_35 = _alu_out_T_8 ? _alu_out_T_9 : _alu_out_T_34; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_36 = _alu_out_T_6 ? _alu_out_T_7 : _alu_out_T_35; // @[Mux.scala 101:16]
  wire [31:0] _alu_out_T_37 = _alu_out_T_3 ? _alu_out_T_5 : _alu_out_T_36; // @[Mux.scala 101:16]
  wire [31:0] alu_out = _alu_out_T ? _alu_out_T_2 : _alu_out_T_37; // @[Mux.scala 101:16]
  wire  _wb_data_T_1 = io_ctl_wb_sel == 2'h1; // @[dpath.scala 234:34]
  wire  _wb_data_T_2 = io_ctl_wb_sel == 2'h2; // @[dpath.scala 235:34]
  wire  _wb_data_T_3 = io_ctl_wb_sel == 2'h3; // @[dpath.scala 236:34]
  wire [31:0] _wb_data_T_4 = _wb_data_T_3 ? csr_io_rw_rdata : alu_out; // @[Mux.scala 101:16]
  wire [31:0] _wb_data_T_5 = _wb_data_T_2 ? pc_plus4 : _wb_data_T_4; // @[Mux.scala 101:16]
  wire [31:0] _wb_data_T_6 = _wb_data_T_1 ? io_dmem_resp_bits_data : _wb_data_T_5; // @[Mux.scala 101:16]
  wire [31:0] wb_data = _wb_data_T ? alu_out : _wb_data_T_6; // @[Mux.scala 101:16]
  wire  _csr_io_tval_T = io_ctl_exception_cause == 32'h2; // @[dpath.scala 207:43]
  wire  _csr_io_tval_T_1 = io_ctl_exception_cause == 32'h0; // @[dpath.scala 208:43]
  wire  _csr_io_tval_T_2 = io_ctl_exception_cause == 32'h6; // @[dpath.scala 209:43]
  wire  _csr_io_tval_T_3 = io_ctl_exception_cause == 32'h4; // @[dpath.scala 210:43]
  wire [31:0] _csr_io_tval_T_4 = _csr_io_tval_T_3 ? alu_out : 32'h0; // @[Mux.scala 101:16]
  wire [31:0] _csr_io_tval_T_5 = _csr_io_tval_T_2 ? alu_out : _csr_io_tval_T_4; // @[Mux.scala 101:16]
  wire [31:0] _csr_io_tval_T_6 = _csr_io_tval_T_1 ? tval_inst_ma : _csr_io_tval_T_5; // @[Mux.scala 101:16]
  wire [31:0] _io_dat_br_lt_T = rs1_addr != 5'h0 ? regfile_rs1_data_MPORT_data : 32'h0; // @[dpath.scala 243:37]
  wire [31:0] _io_dat_br_lt_T_1 = rs2_addr != 5'h0 ? regfile_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 243:57]
  wire [31:0] _T_8 = csr_io_time; // @[dpath.scala 258:18]
  wire [7:0] _T_9 = io_ctl_stall ? 8'h53 : 8'h20; // @[dpath.scala 269:10]
  wire [7:0] _T_11 = 3'h1 == io_ctl_pc_sel ? 8'h42 : 8'h3f; // @[Mux.scala 81:58]
  wire [7:0] _T_13 = 3'h2 == io_ctl_pc_sel ? 8'h4a : _T_11; // @[Mux.scala 81:58]
  wire [7:0] _T_15 = 3'h3 == io_ctl_pc_sel ? 8'h52 : _T_13; // @[Mux.scala 81:58]
  wire [7:0] _T_17 = 3'h4 == io_ctl_pc_sel ? 8'h45 : _T_15; // @[Mux.scala 81:58]
  wire [7:0] _T_19 = 3'h0 == io_ctl_pc_sel ? 8'h20 : _T_17; // @[Mux.scala 81:58]
  wire [7:0] _T_20 = csr_io_exception ? 8'h58 : 8'h20; // @[dpath.scala 276:10]
  CSRFile_1stage CSRFile_1stage ( // @[dpath.scala 194:20]
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
  assign regfile_io_ddpath_rdata_MPORT_data = regfile[regfile_io_ddpath_rdata_MPORT_addr]; // @[dpath.scala 120:21]
  assign regfile_rs1_data_MPORT_en = 1'h1;
  assign regfile_rs1_data_MPORT_addr = inst[19:15];
  assign regfile_rs1_data_MPORT_data = regfile[regfile_rs1_data_MPORT_addr]; // @[dpath.scala 120:21]
  assign regfile_rs2_data_MPORT_en = 1'h1;
  assign regfile_rs2_data_MPORT_addr = inst[24:20];
  assign regfile_rs2_data_MPORT_data = regfile[regfile_rs2_data_MPORT_addr]; // @[dpath.scala 120:21]
  assign regfile_MPORT_data = _wb_data_T ? alu_out : _wb_data_T_6;
  assign regfile_MPORT_addr = inst[11:7];
  assign regfile_MPORT_mask = 1'h1;
  assign regfile_MPORT_en = wb_wen & _T_5;
  assign regfile_MPORT_1_data = 32'h0;
  assign regfile_MPORT_1_addr = 5'h0;
  assign regfile_MPORT_1_mask = 1'h1;
  assign regfile_MPORT_1_en = 1'h0;
  assign io_imem_req_valid = ~reg_dmiss; // @[dpath.scala 96:25]
  assign io_imem_req_bits_addr = pc_reg; // @[dpath.scala 95:26]
  assign io_dmem_req_bits_addr = _alu_out_T ? _alu_out_T_2 : _alu_out_T_37; // @[Mux.scala 101:16]
  assign io_dmem_req_bits_data = rs2_addr != 5'h0 ? regfile_rs2_data_MPORT_data : 32'h0; // @[dpath.scala 135:22]
  assign io_dat_inst = reg_dmiss ? if_inst_buffer : io_imem_resp_bits_data; // @[dpath.scala 97:18]
  assign io_dat_imiss = io_imem_req_valid & ~io_imem_resp_valid; // @[dpath.scala 85:39]
  assign io_dat_br_eq = rs1_data == rs2_data; // @[dpath.scala 242:31]
  assign io_dat_br_lt = $signed(_io_dat_br_lt_T) < $signed(_io_dat_br_lt_T_1); // @[dpath.scala 243:40]
  assign io_dat_br_ltu = rs1_data < rs2_data; // @[dpath.scala 244:40]
  assign io_dat_csr_eret = csr_io_eret; // @[dpath.scala 220:20]
  assign io_dat_csr_interrupt = csr_io_interrupt & ~reg_interrupt_edge; // @[dpath.scala 218:39]
  assign io_dat_inst_misaligned = _io_dat_inst_misaligned_T_8 | _io_dat_inst_misaligned_T_12; // @[dpath.scala 103:94]
  assign io_dat_mem_address_low = alu_out[2:0]; // @[dpath.scala 251:37]
  assign csr_clock = clock;
  assign csr_reset = reset;
  assign csr_io_ungated_clock = clock; // @[dpath.scala 226:25]
  assign csr_io_interrupts_debug = io_interrupt_debug; // @[dpath.scala 222:22]
  assign csr_io_interrupts_mtip = io_interrupt_mtip; // @[dpath.scala 222:22]
  assign csr_io_interrupts_msip = io_interrupt_msip; // @[dpath.scala 222:22]
  assign csr_io_interrupts_meip = io_interrupt_meip; // @[dpath.scala 222:22]
  assign csr_io_hartid = io_hartid; // @[dpath.scala 223:18]
  assign csr_io_rw_addr = inst[31:20]; // @[dpath.scala 197:28]
  assign csr_io_rw_cmd = io_ctl_csr_cmd; // @[dpath.scala 198:21]
  assign csr_io_rw_wdata = _alu_out_T ? _alu_out_T_2 : _alu_out_T_37; // @[Mux.scala 101:16]
  assign csr_io_exception = io_ctl_exception; // @[dpath.scala 202:21]
  assign csr_io_retire = ~(io_ctl_stall | io_ctl_exception); // @[dpath.scala 201:24]
  assign csr_io_cause = io_ctl_exception ? io_ctl_exception_cause : csr_io_interrupt_cause; // @[dpath.scala 225:23]
  assign csr_io_pc = pc_reg; // @[dpath.scala 203:21]
  assign csr_io_tval = _csr_io_tval_T ? inst : _csr_io_tval_T_6; // @[Mux.scala 101:16]
  always @(posedge clock) begin
    if (regfile_MPORT_en & regfile_MPORT_mask) begin
      regfile[regfile_MPORT_addr] <= regfile_MPORT_data; // @[dpath.scala 120:21]
    end
    if (regfile_MPORT_1_en & regfile_MPORT_1_mask) begin
      regfile[regfile_MPORT_1_addr] <= regfile_MPORT_1_data; // @[dpath.scala 120:21]
    end
    if (reset) begin // @[dpath.scala 74:24]
      pc_reg <= io_reset_vector; // @[dpath.scala 74:24]
    end else if (_T) begin // @[dpath.scala 77:4]
      if (_pc_next_T) begin // @[Mux.scala 101:16]
        pc_reg <= pc_plus4;
      end else if (_pc_next_T_1) begin // @[Mux.scala 101:16]
        pc_reg <= br_target;
      end else begin
        pc_reg <= _pc_next_T_7;
      end
    end
    if (reset) begin // @[dpath.scala 86:27]
      reg_dmiss <= 1'h0; // @[dpath.scala 86:27]
    end else begin
      reg_dmiss <= io_ctl_dmiss; // @[dpath.scala 86:27]
    end
    if (reset) begin // @[dpath.scala 87:32]
      if_inst_buffer <= 32'h0; // @[dpath.scala 87:32]
    end else if (io_imem_resp_valid) begin // @[dpath.scala 88:30]
      if_inst_buffer <= io_imem_resp_bits_data; // @[dpath.scala 90:22]
    end
    if (reset) begin // @[dpath.scala 214:36]
      reg_interrupt_edge <= 1'h0; // @[dpath.scala 214:36]
    end else if (_T) begin // @[dpath.scala 215:25]
      reg_interrupt_edge <= csr_io_interrupt; // @[dpath.scala 216:26]
    end
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~reg_dmiss) & (io_imem_resp_valid & ~reset)) begin
          $fatal; // @[dpath.scala 89:13]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (io_imem_resp_valid & ~reset & ~(~reg_dmiss)) begin
          $fwrite(32'h80000002,
            "Assertion failed: instruction arrived during data miss\n    at dpath.scala:89 assert(!reg_dmiss, \"instruction arrived during data miss\")\n"
            ); // @[dpath.scala 89:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_3) begin
          $fwrite(32'h80000002,
            "Cyc= %d [%d] pc=[%x] W[r%d=%x][%d] Op1=[r%d][%x] Op2=[r%d][%x] inst=[%x] %c%c%c DASM(%x)\n",_T_8,
            csr_io_retire,pc_reg,wb_addr,wb_data,wb_wen,rs1_addr,alu_op1,rs2_addr,alu_op2,inst,_T_9,_T_19,_T_20,inst); // @[dpath.scala 257:10]
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
  pc_reg = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  reg_dmiss = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  if_inst_buffer = _RAND_3[31:0];
  _RAND_4 = {1{`RANDOM}};
  reg_interrupt_edge = _RAND_4[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
wire [32*(32)-1:0] regfile_flat_src;
assign regfile_flat_src = {regfile[0 + 0],regfile[0 + 1],regfile[0 + 2],regfile[0 + 3],regfile[0 + 4],regfile[0 + 5],regfile[0 + 6],regfile[0 + 7],regfile[0 + 8],regfile[0 + 9],regfile[0 + 10],regfile[0 + 11],regfile[0 + 12],regfile[0 + 13],regfile[0 + 14],regfile[0 + 15],regfile[0 + 16],regfile[0 + 17],regfile[0 + 18],regfile[0 + 19],regfile[0 + 20],regfile[0 + 21],regfile[0 + 22],regfile[0 + 23],regfile[0 + 24],regfile[0 + 25],regfile[0 + 26],regfile[0 + 27],regfile[0 + 28],regfile[0 + 29],regfile[0 + 30],regfile[0 + 32 - 1] };
endmodule
