module SodorInternalTile_1stage(
  input         clock,
  input         reset,
  input         io_debug_port_req_valid,
  input  [31:0] io_debug_port_req_bits_addr,
  input  [31:0] io_debug_port_req_bits_data,
  input         io_debug_port_req_bits_fcn,
  input  [2:0]  io_debug_port_req_bits_typ,
  output        io_debug_port_resp_valid,
  output [31:0] io_debug_port_resp_bits_data,
  output        io_master_port_0_req_valid,
  output [31:0] io_master_port_0_req_bits_addr,
  output [31:0] io_master_port_0_req_bits_data,
  output        io_master_port_0_req_bits_fcn,
  output [2:0]  io_master_port_0_req_bits_typ,
  input         io_master_port_0_resp_valid,
  input  [31:0] io_master_port_0_resp_bits_data,
  output        io_master_port_1_req_valid,
  output [31:0] io_master_port_1_req_bits_addr,
  output [31:0] io_master_port_1_req_bits_data,
  output        io_master_port_1_req_bits_fcn,
  output [2:0]  io_master_port_1_req_bits_typ,
  input         io_master_port_1_resp_valid,
  input  [31:0] io_master_port_1_resp_bits_data,
  input         io_interrupt_debug,
  input         io_interrupt_mtip,
  input         io_interrupt_msip,
  input         io_interrupt_meip,
  input         io_hartid,
  input  [31:0] io_reset_vector
);
  wire  core_clock; // @[sodor_internal_tile.scala 120:22]
  wire  core_reset; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_imem_req_valid; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_imem_req_bits_addr; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_imem_resp_valid; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_imem_resp_bits_data; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_dmem_req_valid; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_dmem_req_bits_addr; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_dmem_req_bits_data; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_dmem_req_bits_fcn; // @[sodor_internal_tile.scala 120:22]
  wire [2:0] core_io_dmem_req_bits_typ; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_dmem_resp_valid; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_dmem_resp_bits_data; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_interrupt_debug; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_interrupt_mtip; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_interrupt_msip; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_interrupt_meip; // @[sodor_internal_tile.scala 120:22]
  wire  core_io_hartid; // @[sodor_internal_tile.scala 120:22]
  wire [31:0] core_io_reset_vector; // @[sodor_internal_tile.scala 120:22]
  wire  memory_clock; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_core_ports_0_req_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_core_ports_0_req_bits_addr; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_core_ports_0_req_bits_data; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_core_ports_0_req_bits_fcn; // @[sodor_internal_tile.scala 122:22]
  wire [2:0] memory_io_core_ports_0_req_bits_typ; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_core_ports_0_resp_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_core_ports_0_resp_bits_data; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_core_ports_1_req_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_core_ports_1_req_bits_addr; // @[sodor_internal_tile.scala 122:22]
  wire [2:0] memory_io_core_ports_1_req_bits_typ; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_core_ports_1_resp_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_core_ports_1_resp_bits_data; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_debug_port_req_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_debug_port_req_bits_addr; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_debug_port_req_bits_data; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_debug_port_req_bits_fcn; // @[sodor_internal_tile.scala 122:22]
  wire [2:0] memory_io_debug_port_req_bits_typ; // @[sodor_internal_tile.scala 122:22]
  wire  memory_io_debug_port_resp_valid; // @[sodor_internal_tile.scala 122:22]
  wire [31:0] memory_io_debug_port_resp_bits_data; // @[sodor_internal_tile.scala 122:22]
  wire  router_io_masterPort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_masterPort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_masterPort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_masterPort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_io_masterPort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_masterPort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_masterPort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_scratchPort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_scratchPort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_scratchPort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_scratchPort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_io_scratchPort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_scratchPort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_scratchPort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_corePort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_corePort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_corePort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_corePort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_io_corePort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_io_corePort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_corePort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_io_respAddress; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_masterPort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_masterPort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_masterPort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_masterPort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_1_io_masterPort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_masterPort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_masterPort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_scratchPort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_scratchPort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_scratchPort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_scratchPort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_1_io_scratchPort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_scratchPort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_scratchPort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_corePort_req_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_corePort_req_bits_addr; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_corePort_req_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_corePort_req_bits_fcn; // @[sodor_internal_tile.scala 126:24]
  wire [2:0] router_1_io_corePort_req_bits_typ; // @[sodor_internal_tile.scala 126:24]
  wire  router_1_io_corePort_resp_valid; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_corePort_resp_bits_data; // @[sodor_internal_tile.scala 126:24]
  wire [31:0] router_1_io_respAddress; // @[sodor_internal_tile.scala 126:24]
  Core_1stage Core_1stage ( // @[sodor_internal_tile.scala 120:22]
    .clock(core_clock),
    .reset(core_reset),
    .io_imem_req_valid(core_io_imem_req_valid),
    .io_imem_req_bits_addr(core_io_imem_req_bits_addr),
    .io_imem_resp_valid(core_io_imem_resp_valid),
    .io_imem_resp_bits_data(core_io_imem_resp_bits_data),
    .io_dmem_req_valid(core_io_dmem_req_valid),
    .io_dmem_req_bits_addr(core_io_dmem_req_bits_addr),
    .io_dmem_req_bits_data(core_io_dmem_req_bits_data),
    .io_dmem_req_bits_fcn(core_io_dmem_req_bits_fcn),
    .io_dmem_req_bits_typ(core_io_dmem_req_bits_typ),
    .io_dmem_resp_valid(core_io_dmem_resp_valid),
    .io_dmem_resp_bits_data(core_io_dmem_resp_bits_data),
    .io_interrupt_debug(core_io_interrupt_debug),
    .io_interrupt_mtip(core_io_interrupt_mtip),
    .io_interrupt_msip(core_io_interrupt_msip),
    .io_interrupt_meip(core_io_interrupt_meip),
    .io_hartid(core_io_hartid),
    .io_reset_vector(core_io_reset_vector)
  );
  AsyncScratchPadMemory_1stage AsyncScratchPadMemory_1stage ( // @[sodor_internal_tile.scala 122:22]
    .clock(memory_clock),
    .io_core_ports_0_req_valid(memory_io_core_ports_0_req_valid),
    .io_core_ports_0_req_bits_addr(memory_io_core_ports_0_req_bits_addr),
    .io_core_ports_0_req_bits_data(memory_io_core_ports_0_req_bits_data),
    .io_core_ports_0_req_bits_fcn(memory_io_core_ports_0_req_bits_fcn),
    .io_core_ports_0_req_bits_typ(memory_io_core_ports_0_req_bits_typ),
    .io_core_ports_0_resp_valid(memory_io_core_ports_0_resp_valid),
    .io_core_ports_0_resp_bits_data(memory_io_core_ports_0_resp_bits_data),
    .io_core_ports_1_req_valid(memory_io_core_ports_1_req_valid),
    .io_core_ports_1_req_bits_addr(memory_io_core_ports_1_req_bits_addr),
    .io_core_ports_1_req_bits_typ(memory_io_core_ports_1_req_bits_typ),
    .io_core_ports_1_resp_valid(memory_io_core_ports_1_resp_valid),
    .io_core_ports_1_resp_bits_data(memory_io_core_ports_1_resp_bits_data),
    .io_debug_port_req_valid(memory_io_debug_port_req_valid),
    .io_debug_port_req_bits_addr(memory_io_debug_port_req_bits_addr),
    .io_debug_port_req_bits_data(memory_io_debug_port_req_bits_data),
    .io_debug_port_req_bits_fcn(memory_io_debug_port_req_bits_fcn),
    .io_debug_port_req_bits_typ(memory_io_debug_port_req_bits_typ),
    .io_debug_port_resp_valid(memory_io_debug_port_resp_valid),
    .io_debug_port_resp_bits_data(memory_io_debug_port_resp_bits_data)
  );
  SodorRequestRouter_1stage SodorRequestRouter_1stage_0 ( // @[sodor_internal_tile.scala 126:24]
    .io_masterPort_req_valid(router_io_masterPort_req_valid),
    .io_masterPort_req_bits_addr(router_io_masterPort_req_bits_addr),
    .io_masterPort_req_bits_data(router_io_masterPort_req_bits_data),
    .io_masterPort_req_bits_fcn(router_io_masterPort_req_bits_fcn),
    .io_masterPort_req_bits_typ(router_io_masterPort_req_bits_typ),
    .io_masterPort_resp_valid(router_io_masterPort_resp_valid),
    .io_masterPort_resp_bits_data(router_io_masterPort_resp_bits_data),
    .io_scratchPort_req_valid(router_io_scratchPort_req_valid),
    .io_scratchPort_req_bits_addr(router_io_scratchPort_req_bits_addr),
    .io_scratchPort_req_bits_data(router_io_scratchPort_req_bits_data),
    .io_scratchPort_req_bits_fcn(router_io_scratchPort_req_bits_fcn),
    .io_scratchPort_req_bits_typ(router_io_scratchPort_req_bits_typ),
    .io_scratchPort_resp_valid(router_io_scratchPort_resp_valid),
    .io_scratchPort_resp_bits_data(router_io_scratchPort_resp_bits_data),
    .io_corePort_req_valid(router_io_corePort_req_valid),
    .io_corePort_req_bits_addr(router_io_corePort_req_bits_addr),
    .io_corePort_req_bits_data(router_io_corePort_req_bits_data),
    .io_corePort_req_bits_fcn(router_io_corePort_req_bits_fcn),
    .io_corePort_req_bits_typ(router_io_corePort_req_bits_typ),
    .io_corePort_resp_valid(router_io_corePort_resp_valid),
    .io_corePort_resp_bits_data(router_io_corePort_resp_bits_data),
    .io_respAddress(router_io_respAddress)
  );
  SodorRequestRouter_1stage SodorRequestRouter_1stage_1 ( // @[sodor_internal_tile.scala 126:24]
    .io_masterPort_req_valid(router_1_io_masterPort_req_valid),
    .io_masterPort_req_bits_addr(router_1_io_masterPort_req_bits_addr),
    .io_masterPort_req_bits_data(router_1_io_masterPort_req_bits_data),
    .io_masterPort_req_bits_fcn(router_1_io_masterPort_req_bits_fcn),
    .io_masterPort_req_bits_typ(router_1_io_masterPort_req_bits_typ),
    .io_masterPort_resp_valid(router_1_io_masterPort_resp_valid),
    .io_masterPort_resp_bits_data(router_1_io_masterPort_resp_bits_data),
    .io_scratchPort_req_valid(router_1_io_scratchPort_req_valid),
    .io_scratchPort_req_bits_addr(router_1_io_scratchPort_req_bits_addr),
    .io_scratchPort_req_bits_data(router_1_io_scratchPort_req_bits_data),
    .io_scratchPort_req_bits_fcn(router_1_io_scratchPort_req_bits_fcn),
    .io_scratchPort_req_bits_typ(router_1_io_scratchPort_req_bits_typ),
    .io_scratchPort_resp_valid(router_1_io_scratchPort_resp_valid),
    .io_scratchPort_resp_bits_data(router_1_io_scratchPort_resp_bits_data),
    .io_corePort_req_valid(router_1_io_corePort_req_valid),
    .io_corePort_req_bits_addr(router_1_io_corePort_req_bits_addr),
    .io_corePort_req_bits_data(router_1_io_corePort_req_bits_data),
    .io_corePort_req_bits_fcn(router_1_io_corePort_req_bits_fcn),
    .io_corePort_req_bits_typ(router_1_io_corePort_req_bits_typ),
    .io_corePort_resp_valid(router_1_io_corePort_resp_valid),
    .io_corePort_resp_bits_data(router_1_io_corePort_resp_bits_data),
    .io_respAddress(router_1_io_respAddress)
  );
  assign io_debug_port_resp_valid = memory_io_debug_port_resp_valid; // @[sodor_internal_tile.scala 134:17]
  assign io_debug_port_resp_bits_data = memory_io_debug_port_resp_bits_data; // @[sodor_internal_tile.scala 134:17]
  assign io_master_port_0_req_valid = router_io_masterPort_req_valid; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_0_req_bits_addr = router_io_masterPort_req_bits_addr; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_0_req_bits_data = router_io_masterPort_req_bits_data; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_0_req_bits_fcn = router_io_masterPort_req_bits_fcn; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_0_req_bits_typ = router_io_masterPort_req_bits_typ; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_1_req_valid = router_1_io_masterPort_req_valid; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_1_req_bits_addr = router_1_io_masterPort_req_bits_addr; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_1_req_bits_data = router_1_io_masterPort_req_bits_data; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_1_req_bits_fcn = router_1_io_masterPort_req_bits_fcn; // @[sodor_internal_tile.scala 129:26]
  assign io_master_port_1_req_bits_typ = router_1_io_masterPort_req_bits_typ; // @[sodor_internal_tile.scala 129:26]
  assign core_clock = clock;
  assign core_reset = reset;
  assign core_io_imem_resp_valid = router_1_io_corePort_resp_valid; // @[sodor_internal_tile.scala 127:24]
  assign core_io_imem_resp_bits_data = router_1_io_corePort_resp_bits_data; // @[sodor_internal_tile.scala 127:24]
  assign core_io_dmem_resp_valid = router_io_corePort_resp_valid; // @[sodor_internal_tile.scala 127:24]
  assign core_io_dmem_resp_bits_data = router_io_corePort_resp_bits_data; // @[sodor_internal_tile.scala 127:24]
  assign core_io_interrupt_debug = io_interrupt_debug; // @[sodor_internal_tile.scala 136:18]
  assign core_io_interrupt_mtip = io_interrupt_mtip; // @[sodor_internal_tile.scala 136:18]
  assign core_io_interrupt_msip = io_interrupt_msip; // @[sodor_internal_tile.scala 136:18]
  assign core_io_interrupt_meip = io_interrupt_meip; // @[sodor_internal_tile.scala 136:18]
  assign core_io_hartid = io_hartid; // @[sodor_internal_tile.scala 137:15]
  assign core_io_reset_vector = io_reset_vector; // @[sodor_internal_tile.scala 138:21]
  assign memory_clock = clock;
  assign memory_io_core_ports_0_req_valid = router_io_scratchPort_req_valid; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_0_req_bits_addr = router_io_scratchPort_req_bits_addr; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_0_req_bits_data = router_io_scratchPort_req_bits_data; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_0_req_bits_fcn = router_io_scratchPort_req_bits_fcn; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_0_req_bits_typ = router_io_scratchPort_req_bits_typ; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_1_req_valid = router_1_io_scratchPort_req_valid; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_1_req_bits_addr = router_1_io_scratchPort_req_bits_addr; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_core_ports_1_req_bits_typ = router_1_io_scratchPort_req_bits_typ; // @[sodor_internal_tile.scala 128:27]
  assign memory_io_debug_port_req_valid = io_debug_port_req_valid; // @[sodor_internal_tile.scala 134:17]
  assign memory_io_debug_port_req_bits_addr = io_debug_port_req_bits_addr; // @[sodor_internal_tile.scala 134:17]
  assign memory_io_debug_port_req_bits_data = io_debug_port_req_bits_data; // @[sodor_internal_tile.scala 134:17]
  assign memory_io_debug_port_req_bits_fcn = io_debug_port_req_bits_fcn; // @[sodor_internal_tile.scala 134:17]
  assign memory_io_debug_port_req_bits_typ = io_debug_port_req_bits_typ; // @[sodor_internal_tile.scala 134:17]
  assign router_io_masterPort_resp_valid = io_master_port_0_resp_valid; // @[sodor_internal_tile.scala 129:26]
  assign router_io_masterPort_resp_bits_data = io_master_port_0_resp_bits_data; // @[sodor_internal_tile.scala 129:26]
  assign router_io_scratchPort_resp_valid = memory_io_core_ports_0_resp_valid; // @[sodor_internal_tile.scala 128:27]
  assign router_io_scratchPort_resp_bits_data = memory_io_core_ports_0_resp_bits_data; // @[sodor_internal_tile.scala 128:27]
  assign router_io_corePort_req_valid = core_io_dmem_req_valid; // @[sodor_internal_tile.scala 127:24]
  assign router_io_corePort_req_bits_addr = core_io_dmem_req_bits_addr; // @[sodor_internal_tile.scala 127:24]
  assign router_io_corePort_req_bits_data = core_io_dmem_req_bits_data; // @[sodor_internal_tile.scala 127:24]
  assign router_io_corePort_req_bits_fcn = core_io_dmem_req_bits_fcn; // @[sodor_internal_tile.scala 127:24]
  assign router_io_corePort_req_bits_typ = core_io_dmem_req_bits_typ; // @[sodor_internal_tile.scala 127:24]
  assign router_io_respAddress = core_io_dmem_req_bits_addr; // @[sodor_internal_tile.scala 131:27]
  assign router_1_io_masterPort_resp_valid = io_master_port_1_resp_valid; // @[sodor_internal_tile.scala 129:26]
  assign router_1_io_masterPort_resp_bits_data = io_master_port_1_resp_bits_data; // @[sodor_internal_tile.scala 129:26]
  assign router_1_io_scratchPort_resp_valid = memory_io_core_ports_1_resp_valid; // @[sodor_internal_tile.scala 128:27]
  assign router_1_io_scratchPort_resp_bits_data = memory_io_core_ports_1_resp_bits_data; // @[sodor_internal_tile.scala 128:27]
  assign router_1_io_corePort_req_valid = core_io_imem_req_valid; // @[sodor_internal_tile.scala 127:24]
  assign router_1_io_corePort_req_bits_addr = core_io_imem_req_bits_addr; // @[sodor_internal_tile.scala 127:24]
  assign router_1_io_corePort_req_bits_data = 32'h0; // @[sodor_internal_tile.scala 127:24]
  assign router_1_io_corePort_req_bits_fcn = 1'h0; // @[sodor_internal_tile.scala 127:24]
  assign router_1_io_corePort_req_bits_typ = 3'h7; // @[sodor_internal_tile.scala 127:24]
  assign router_1_io_respAddress = core_io_imem_req_bits_addr; // @[sodor_internal_tile.scala 131:27]
endmodule