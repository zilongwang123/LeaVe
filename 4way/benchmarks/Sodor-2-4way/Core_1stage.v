module Core_1stage(
  input         clock,
  input         reset,
  output        io_imem_req_valid,
  output [31:0] io_imem_req_bits_addr,
  input         io_imem_resp_valid,
  input  [31:0] io_imem_resp_bits_data,
  output        io_dmem_req_valid,
  output [31:0] io_dmem_req_bits_addr,
  output [31:0] io_dmem_req_bits_data,
  output        io_dmem_req_bits_fcn,
  output [2:0]  io_dmem_req_bits_typ,
  input         io_dmem_resp_valid,
  input  [31:0] io_dmem_resp_bits_data,
  input         io_interrupt_debug,
  input         io_interrupt_mtip,
  input         io_interrupt_msip,
  input         io_interrupt_meip,
  input         io_hartid,
  input  [31:0] io_reset_vector
);
  wire  c_clock; // @[core.scala 41:18]
  wire  c_reset; // @[core.scala 41:18]
  wire  c_io_imem_resp_valid; // @[core.scala 41:18]
  wire  c_io_dmem_req_valid; // @[core.scala 41:18]
  wire  c_io_dmem_req_bits_fcn; // @[core.scala 41:18]
  wire [2:0] c_io_dmem_req_bits_typ; // @[core.scala 41:18]
  wire  c_io_dmem_resp_valid; // @[core.scala 41:18]
  wire [31:0] c_io_dat_inst; // @[core.scala 41:18]
  wire  c_io_dat_imiss; // @[core.scala 41:18]
  wire  c_io_dat_br_eq; // @[core.scala 41:18]
  wire  c_io_dat_br_lt; // @[core.scala 41:18]
  wire  c_io_dat_br_ltu; // @[core.scala 41:18]
  wire  c_io_dat_csr_eret; // @[core.scala 41:18]
  wire  c_io_dat_csr_interrupt; // @[core.scala 41:18]
  wire  c_io_dat_inst_misaligned; // @[core.scala 41:18]
  wire [2:0] c_io_dat_mem_address_low; // @[core.scala 41:18]
  wire  c_io_ctl_stall; // @[core.scala 41:18]
  wire  c_io_ctl_dmiss; // @[core.scala 41:18]
  wire [2:0] c_io_ctl_pc_sel; // @[core.scala 41:18]
  wire [1:0] c_io_ctl_op1_sel; // @[core.scala 41:18]
  wire [1:0] c_io_ctl_op2_sel; // @[core.scala 41:18]
  wire [3:0] c_io_ctl_alu_fun; // @[core.scala 41:18]
  wire [1:0] c_io_ctl_wb_sel; // @[core.scala 41:18]
  wire  c_io_ctl_rf_wen; // @[core.scala 41:18]
  wire [2:0] c_io_ctl_csr_cmd; // @[core.scala 41:18]
  wire  c_io_ctl_exception; // @[core.scala 41:18]
  wire [31:0] c_io_ctl_exception_cause; // @[core.scala 41:18]
  wire [2:0] c_io_ctl_pc_sel_no_xept; // @[core.scala 41:18]
  wire  d_clock; // @[core.scala 42:18]
  wire  d_reset; // @[core.scala 42:18]
  wire  d_io_imem_req_valid; // @[core.scala 42:18]
  wire [31:0] d_io_imem_req_bits_addr; // @[core.scala 42:18]
  wire  d_io_imem_resp_valid; // @[core.scala 42:18]
  wire [31:0] d_io_imem_resp_bits_data; // @[core.scala 42:18]
  wire [31:0] d_io_dmem_req_bits_addr; // @[core.scala 42:18]
  wire [31:0] d_io_dmem_req_bits_data; // @[core.scala 42:18]
  wire [31:0] d_io_dmem_resp_bits_data; // @[core.scala 42:18]
  wire  d_io_ctl_stall; // @[core.scala 42:18]
  wire  d_io_ctl_dmiss; // @[core.scala 42:18]
  wire [2:0] d_io_ctl_pc_sel; // @[core.scala 42:18]
  wire [1:0] d_io_ctl_op1_sel; // @[core.scala 42:18]
  wire [1:0] d_io_ctl_op2_sel; // @[core.scala 42:18]
  wire [3:0] d_io_ctl_alu_fun; // @[core.scala 42:18]
  wire [1:0] d_io_ctl_wb_sel; // @[core.scala 42:18]
  wire  d_io_ctl_rf_wen; // @[core.scala 42:18]
  wire [2:0] d_io_ctl_csr_cmd; // @[core.scala 42:18]
  wire  d_io_ctl_exception; // @[core.scala 42:18]
  wire [31:0] d_io_ctl_exception_cause; // @[core.scala 42:18]
  wire [2:0] d_io_ctl_pc_sel_no_xept; // @[core.scala 42:18]
  wire [31:0] d_io_dat_inst; // @[core.scala 42:18]
  wire  d_io_dat_imiss; // @[core.scala 42:18]
  wire  d_io_dat_br_eq; // @[core.scala 42:18]
  wire  d_io_dat_br_lt; // @[core.scala 42:18]
  wire  d_io_dat_br_ltu; // @[core.scala 42:18]
  wire  d_io_dat_csr_eret; // @[core.scala 42:18]
  wire  d_io_dat_csr_interrupt; // @[core.scala 42:18]
  wire  d_io_dat_inst_misaligned; // @[core.scala 42:18]
  wire [2:0] d_io_dat_mem_address_low; // @[core.scala 42:18]
  wire  d_io_interrupt_debug; // @[core.scala 42:18]
  wire  d_io_interrupt_mtip; // @[core.scala 42:18]
  wire  d_io_interrupt_msip; // @[core.scala 42:18]
  wire  d_io_interrupt_meip; // @[core.scala 42:18]
  wire  d_io_hartid; // @[core.scala 42:18]
  wire [31:0] d_io_reset_vector; // @[core.scala 42:18]
  CtlPath_1stage CtlPath_1stage ( // @[core.scala 41:18]
    .clock(c_clock),
    .reset(c_reset),
    .io_imem_resp_valid(c_io_imem_resp_valid),
    .io_dmem_req_valid(c_io_dmem_req_valid),
    .io_dmem_req_bits_fcn(c_io_dmem_req_bits_fcn),
    .io_dmem_req_bits_typ(c_io_dmem_req_bits_typ),
    .io_dmem_resp_valid(c_io_dmem_resp_valid),
    .io_dat_inst(c_io_dat_inst),
    .io_dat_imiss(c_io_dat_imiss),
    .io_dat_br_eq(c_io_dat_br_eq),
    .io_dat_br_lt(c_io_dat_br_lt),
    .io_dat_br_ltu(c_io_dat_br_ltu),
    .io_dat_csr_eret(c_io_dat_csr_eret),
    .io_dat_csr_interrupt(c_io_dat_csr_interrupt),
    .io_dat_inst_misaligned(c_io_dat_inst_misaligned),
    .io_dat_mem_address_low(c_io_dat_mem_address_low),
    .io_ctl_stall(c_io_ctl_stall),
    .io_ctl_dmiss(c_io_ctl_dmiss),
    .io_ctl_pc_sel(c_io_ctl_pc_sel),
    .io_ctl_op1_sel(c_io_ctl_op1_sel),
    .io_ctl_op2_sel(c_io_ctl_op2_sel),
    .io_ctl_alu_fun(c_io_ctl_alu_fun),
    .io_ctl_wb_sel(c_io_ctl_wb_sel),
    .io_ctl_rf_wen(c_io_ctl_rf_wen),
    .io_ctl_csr_cmd(c_io_ctl_csr_cmd),
    .io_ctl_exception(c_io_ctl_exception),
    .io_ctl_exception_cause(c_io_ctl_exception_cause),
    .io_ctl_pc_sel_no_xept(c_io_ctl_pc_sel_no_xept)
  );
  DatPath_1stage DatPath_1stage ( // @[core.scala 42:18]
    .clock(d_clock),
    .reset(d_reset),
    .io_imem_req_valid(d_io_imem_req_valid),
    .io_imem_req_bits_addr(d_io_imem_req_bits_addr),
    .io_imem_resp_valid(d_io_imem_resp_valid),
    .io_imem_resp_bits_data(d_io_imem_resp_bits_data),
    .io_dmem_req_bits_addr(d_io_dmem_req_bits_addr),
    .io_dmem_req_bits_data(d_io_dmem_req_bits_data),
    .io_dmem_resp_bits_data(d_io_dmem_resp_bits_data),
    .io_ctl_stall(d_io_ctl_stall),
    .io_ctl_dmiss(d_io_ctl_dmiss),
    .io_ctl_pc_sel(d_io_ctl_pc_sel),
    .io_ctl_op1_sel(d_io_ctl_op1_sel),
    .io_ctl_op2_sel(d_io_ctl_op2_sel),
    .io_ctl_alu_fun(d_io_ctl_alu_fun),
    .io_ctl_wb_sel(d_io_ctl_wb_sel),
    .io_ctl_rf_wen(d_io_ctl_rf_wen),
    .io_ctl_csr_cmd(d_io_ctl_csr_cmd),
    .io_ctl_exception(d_io_ctl_exception),
    .io_ctl_exception_cause(d_io_ctl_exception_cause),
    .io_ctl_pc_sel_no_xept(d_io_ctl_pc_sel_no_xept),
    .io_dat_inst(d_io_dat_inst),
    .io_dat_imiss(d_io_dat_imiss),
    .io_dat_br_eq(d_io_dat_br_eq),
    .io_dat_br_lt(d_io_dat_br_lt),
    .io_dat_br_ltu(d_io_dat_br_ltu),
    .io_dat_csr_eret(d_io_dat_csr_eret),
    .io_dat_csr_interrupt(d_io_dat_csr_interrupt),
    .io_dat_inst_misaligned(d_io_dat_inst_misaligned),
    .io_dat_mem_address_low(d_io_dat_mem_address_low),
    .io_interrupt_debug(d_io_interrupt_debug),
    .io_interrupt_mtip(d_io_interrupt_mtip),
    .io_interrupt_msip(d_io_interrupt_msip),
    .io_interrupt_meip(d_io_interrupt_meip),
    .io_hartid(d_io_hartid),
    .io_reset_vector(d_io_reset_vector)
  );
  assign io_imem_req_valid = d_io_imem_req_valid; // @[core.scala 47:11]
  assign io_imem_req_bits_addr = d_io_imem_req_bits_addr; // @[core.scala 47:11]
  assign io_dmem_req_valid = c_io_dmem_req_valid; // @[core.scala 51:21]
  assign io_dmem_req_bits_addr = d_io_dmem_req_bits_addr; // @[core.scala 50:11]
  assign io_dmem_req_bits_data = d_io_dmem_req_bits_data; // @[core.scala 50:11]
  assign io_dmem_req_bits_fcn = c_io_dmem_req_bits_fcn; // @[core.scala 53:24]
  assign io_dmem_req_bits_typ = c_io_dmem_req_bits_typ; // @[core.scala 52:24]
  assign c_clock = clock;
  assign c_reset = reset;
  assign c_io_imem_resp_valid = io_imem_resp_valid; // @[core.scala 46:11]
  assign c_io_dmem_resp_valid = io_dmem_resp_valid; // @[core.scala 49:11]
  assign c_io_dat_inst = d_io_dat_inst; // @[core.scala 44:13]
  assign c_io_dat_imiss = d_io_dat_imiss; // @[core.scala 44:13]
  assign c_io_dat_br_eq = d_io_dat_br_eq; // @[core.scala 44:13]
  assign c_io_dat_br_lt = d_io_dat_br_lt; // @[core.scala 44:13]
  assign c_io_dat_br_ltu = d_io_dat_br_ltu; // @[core.scala 44:13]
  assign c_io_dat_csr_eret = d_io_dat_csr_eret; // @[core.scala 44:13]
  assign c_io_dat_csr_interrupt = d_io_dat_csr_interrupt; // @[core.scala 44:13]
  assign c_io_dat_inst_misaligned = d_io_dat_inst_misaligned; // @[core.scala 44:13]
  assign c_io_dat_mem_address_low = d_io_dat_mem_address_low; // @[core.scala 44:13]
  assign d_clock = clock;
  assign d_reset = reset;
  assign d_io_imem_resp_valid = io_imem_resp_valid; // @[core.scala 47:11]
  assign d_io_imem_resp_bits_data = io_imem_resp_bits_data; // @[core.scala 47:11]
  assign d_io_dmem_resp_bits_data = io_dmem_resp_bits_data; // @[core.scala 50:11]
  assign d_io_ctl_stall = c_io_ctl_stall; // @[core.scala 43:13]
  assign d_io_ctl_dmiss = c_io_ctl_dmiss; // @[core.scala 43:13]
  assign d_io_ctl_pc_sel = c_io_ctl_pc_sel; // @[core.scala 43:13]
  assign d_io_ctl_op1_sel = c_io_ctl_op1_sel; // @[core.scala 43:13]
  assign d_io_ctl_op2_sel = c_io_ctl_op2_sel; // @[core.scala 43:13]
  assign d_io_ctl_alu_fun = c_io_ctl_alu_fun; // @[core.scala 43:13]
  assign d_io_ctl_wb_sel = c_io_ctl_wb_sel; // @[core.scala 43:13]
  assign d_io_ctl_rf_wen = c_io_ctl_rf_wen; // @[core.scala 43:13]
  assign d_io_ctl_csr_cmd = c_io_ctl_csr_cmd; // @[core.scala 43:13]
  assign d_io_ctl_exception = c_io_ctl_exception; // @[core.scala 43:13]
  assign d_io_ctl_exception_cause = c_io_ctl_exception_cause; // @[core.scala 43:13]
  assign d_io_ctl_pc_sel_no_xept = c_io_ctl_pc_sel_no_xept; // @[core.scala 43:13]
  assign d_io_interrupt_debug = io_interrupt_debug; // @[core.scala 58:18]
  assign d_io_interrupt_mtip = io_interrupt_mtip; // @[core.scala 58:18]
  assign d_io_interrupt_msip = io_interrupt_msip; // @[core.scala 58:18]
  assign d_io_interrupt_meip = io_interrupt_meip; // @[core.scala 58:18]
  assign d_io_hartid = io_hartid; // @[core.scala 59:15]
  assign d_io_reset_vector = io_reset_vector; // @[core.scala 60:21]
endmodule
