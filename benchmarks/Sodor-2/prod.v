module prod
(
  input clock
);

  wire         reset;   

  wire         trgio_debug_port_req_validLeft;
  wire         trgio_debug_port_req_validRight;

  wire  [31:0] trgio_debug_port_req_bits_addrLeft;
  wire  [31:0] trgio_debug_port_req_bits_addrRight;

  wire  [31:0] trgio_debug_port_req_bits_dataLeft;
  wire  [31:0] trgio_debug_port_req_bits_dataRight;

  wire         trgio_debug_port_req_bits_fcnLeft;
  wire         trgio_debug_port_req_bits_fcnRight;

  wire  [2:0]  trgio_debug_port_req_bits_typLeft;
  wire  [2:0]  trgio_debug_port_req_bits_typRight;

  wire         trgio_debug_port_resp_validLeft;
  wire         trgio_debug_port_resp_validRight;

  wire  [31:0] trgio_debug_port_resp_bits_dataLeft;
  wire  [31:0] trgio_debug_port_resp_bits_dataRight;

  wire         trgio_master_port_0_req_validLeft;
  wire         trgio_master_port_0_req_validRight;

  wire  [31:0] trgio_master_port_0_req_bits_addrLeft;
  wire  [31:0] trgio_master_port_0_req_bits_addrRight;

  wire  [31:0] trgio_master_port_0_req_bits_dataLeft;
  wire  [31:0] trgio_master_port_0_req_bits_dataRight;

  wire         trgio_master_port_0_req_bits_fcnLeft;
  wire         trgio_master_port_0_req_bits_fcnRight;

  wire  [2:0]  trgio_master_port_0_req_bits_typLeft;
  wire  [2:0]  trgio_master_port_0_req_bits_typRight;

  wire         trgio_master_port_0_resp_validLeft;
  wire         trgio_master_port_0_resp_validRight;

  wire  [31:0] trgio_master_port_0_resp_bits_dataLeft;
  wire  [31:0] trgio_master_port_0_resp_bits_dataRight;

  wire         trgio_master_port_1_req_validLeft;
  wire         trgio_master_port_1_req_validRight;

  wire  [31:0] trgio_master_port_1_req_bits_addrLeft;
  wire  [31:0] trgio_master_port_1_req_bits_addrRight;

  wire  [31:0] trgio_master_port_1_req_bits_dataLeft;
  wire  [31:0] trgio_master_port_1_req_bits_dataRight;

  wire         trgio_master_port_1_req_bits_fcnLeft;
  wire         trgio_master_port_1_req_bits_fcnRight;

  wire  [2:0]  trgio_master_port_1_req_bits_typLeft;
  wire  [2:0]  trgio_master_port_1_req_bits_typRight;

  wire         trgio_master_port_1_resp_validLeft;
  wire         trgio_master_port_1_resp_validRight;

  wire  [31:0] trgio_master_port_1_resp_bits_dataLeft;
  wire  [31:0] trgio_master_port_1_resp_bits_dataRight;

  wire         trgio_interrupt_debugLeft;
  wire         trgio_interrupt_debugRight;

  wire         trgio_interrupt_mtipLeft;
  wire         trgio_interrupt_mtipRight;

  wire         trgio_interrupt_msipLeft;
  wire         trgio_interrupt_msipRight;

  wire         trgio_interrupt_meipLeft;
  wire         trgio_interrupt_meipRight;

  wire         trgio_hartidLeft;
  wire         trgio_hartidRight;

  wire  [31:0] trgio_reset_vectorLeft;
  wire  [31:0] trgio_reset_vectorRight;



//**Wire declarations**//
//**Init register**//
//**Stuttering Signal**//
//**Self-composed modules**//
//**Initial state**//
//**State invariants**//
//**Verification conditions**//
endmodule