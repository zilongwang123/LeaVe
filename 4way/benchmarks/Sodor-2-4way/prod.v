module prod
(
  input clock
);

  wire         reset;   

  wire         srcio_debug_port_req_validLeft;
  wire         srcio_debug_port_req_validRight;
  wire         trgio_debug_port_req_validLeft;
  wire         trgio_debug_port_req_validRight;

  wire  [31:0] srcio_debug_port_req_bits_addrLeft;
  wire  [31:0] srcio_debug_port_req_bits_addrRight;
  wire  [31:0] trgio_debug_port_req_bits_addrLeft;
  wire  [31:0] trgio_debug_port_req_bits_addrRight;
  
  wire  [31:0] srcio_debug_port_req_bits_dataLeft;
  wire  [31:0] srcio_debug_port_req_bits_dataRight;
  wire  [31:0] trgio_debug_port_req_bits_dataLeft;
  wire  [31:0] trgio_debug_port_req_bits_dataRight;

  wire         srcio_debug_port_req_bits_fcnLeft;
  wire         srcio_debug_port_req_bits_fcnRight;
  wire         trgio_debug_port_req_bits_fcnLeft;
  wire         trgio_debug_port_req_bits_fcnRight;

  wire  [2:0]  srcio_debug_port_req_bits_typLeft;
  wire  [2:0]  srcio_debug_port_req_bits_typRight;
  wire  [2:0]  trgio_debug_port_req_bits_typLeft;
  wire  [2:0]  trgio_debug_port_req_bits_typRight;

  wire         srcio_debug_port_resp_validLeft;
  wire         srcio_debug_port_resp_validRight;
  wire         trgio_debug_port_resp_validLeft;
  wire         trgio_debug_port_resp_validRight;

  wire  [31:0] srcio_debug_port_resp_bits_dataLeft;
  wire  [31:0] srcio_debug_port_resp_bits_dataRight;
  wire  [31:0] trgio_debug_port_resp_bits_dataLeft;
  wire  [31:0] trgio_debug_port_resp_bits_dataRight;

  wire         srcio_master_port_0_req_validLeft;
  wire         srcio_master_port_0_req_validRight;
  wire         trgio_master_port_0_req_validLeft;
  wire         trgio_master_port_0_req_validRight;

  wire  [31:0] srcio_master_port_0_req_bits_addrLeft;
  wire  [31:0] srcio_master_port_0_req_bits_addrRight;
  wire  [31:0] trgio_master_port_0_req_bits_addrLeft;
  wire  [31:0] trgio_master_port_0_req_bits_addrRight;

  wire  [31:0] srcio_master_port_0_req_bits_dataLeft;
  wire  [31:0] srcio_master_port_0_req_bits_dataRight;
  wire  [31:0] trgio_master_port_0_req_bits_dataLeft;
  wire  [31:0] trgio_master_port_0_req_bits_dataRight;

  wire         srcio_master_port_0_req_bits_fcnLeft;
  wire         srcio_master_port_0_req_bits_fcnRight;
  wire         trgio_master_port_0_req_bits_fcnLeft;
  wire         trgio_master_port_0_req_bits_fcnRight;

  wire  [2:0]  srcio_master_port_0_req_bits_typLeft;
  wire  [2:0]  srcio_master_port_0_req_bits_typRight;
  wire  [2:0]  trgio_master_port_0_req_bits_typLeft;
  wire  [2:0]  trgio_master_port_0_req_bits_typRight;

  wire         srcio_master_port_0_resp_validLeft;
  wire         srcio_master_port_0_resp_validRight;
  wire         trgio_master_port_0_resp_validLeft;
  wire         trgio_master_port_0_resp_validRight;

  wire  [31:0] srcio_master_port_0_resp_bits_dataLeft;
  wire  [31:0] srcio_master_port_0_resp_bits_dataRight;
  wire  [31:0] trgio_master_port_0_resp_bits_dataLeft;
  wire  [31:0] trgio_master_port_0_resp_bits_dataRight;

  wire         srcio_master_port_1_req_validLeft;
  wire         srcio_master_port_1_req_validRight;
  wire         trgio_master_port_1_req_validLeft;
  wire         trgio_master_port_1_req_validRight;

  wire  [31:0] srcio_master_port_1_req_bits_addrLeft;
  wire  [31:0] srcio_master_port_1_req_bits_addrRight;
  wire  [31:0] trgio_master_port_1_req_bits_addrLeft;
  wire  [31:0] trgio_master_port_1_req_bits_addrRight;

  wire  [31:0] srcio_master_port_1_req_bits_dataLeft;
  wire  [31:0] srcio_master_port_1_req_bits_dataRight;
  wire  [31:0] trgio_master_port_1_req_bits_dataLeft;
  wire  [31:0] trgio_master_port_1_req_bits_dataRight;

  wire         srcio_master_port_1_req_bits_fcnLeft;
  wire         srcio_master_port_1_req_bits_fcnRight;
  wire         trgio_master_port_1_req_bits_fcnLeft;
  wire         trgio_master_port_1_req_bits_fcnRight;

  wire  [2:0]  srcio_master_port_1_req_bits_typLeft;
  wire  [2:0]  srcio_master_port_1_req_bits_typRight;
  wire  [2:0]  trgio_master_port_1_req_bits_typLeft;
  wire  [2:0]  trgio_master_port_1_req_bits_typRight;

  wire         srcio_master_port_1_resp_validLeft;
  wire         srcio_master_port_1_resp_validRight;
  wire         trgio_master_port_1_resp_validLeft;
  wire         trgio_master_port_1_resp_validRight;

  wire  [31:0] srcio_master_port_1_resp_bits_dataLeft;
  wire  [31:0] srcio_master_port_1_resp_bits_dataRight;
  wire  [31:0] trgio_master_port_1_resp_bits_dataLeft;
  wire  [31:0] trgio_master_port_1_resp_bits_dataRight;

  wire         srcio_interrupt_debugLeft;
  wire         srcio_interrupt_debugRight;
  wire         trgio_interrupt_debugLeft;
  wire         trgio_interrupt_debugRight;

  wire         srcio_interrupt_mtipLeft;
  wire         srcio_interrupt_mtipRight;
  wire         trgio_interrupt_mtipLeft;
  wire         trgio_interrupt_mtipRight;
  
  wire         srcio_interrupt_msipLeft;
  wire         srcio_interrupt_msipRight;
  wire         trgio_interrupt_msipLeft;
  wire         trgio_interrupt_msipRight;

  wire         srcio_interrupt_meipLeft;
  wire         srcio_interrupt_meipRight;
  wire         trgio_interrupt_meipLeft;
  wire         trgio_interrupt_meipRight;

  wire         srcio_hartidLeft;
  wire         srcio_hartidRight;
  wire         trgio_hartidLeft;
  wire         trgio_hartidRight;

  wire  [31:0] srcio_reset_vectorLeft;
  wire  [31:0] srcio_reset_vectorRight;
  wire  [31:0] trgio_reset_vectorLeft;
  wire  [31:0] trgio_reset_vectorRight;


//**Wire declarations**//
//**Init register**//
//**Self-composed modules**//
//**Initial state**//
//**State invariants**//
//**Source to target mapping**//
//**Verification conditions**//
endmodule