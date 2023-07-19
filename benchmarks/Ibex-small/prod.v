module prod
 (
   input clk_i
 );  
  wire [31:0] hart_id_i;
  wire [31:0] boot_addr_i;
  wire scramble_key_valid_i;
	wire [127:0] scramble_key_i;
	wire [63:0] scramble_nonce_i;
	
  wire scramble_req_oLeft;
  wire scramble_req_oRight;

  wire debug_req_i;
  	
  wire [159:0] crash_dump_oLeft;
  wire [159:0] crash_dump_oRight;

	wire double_fault_seen_oLeft;
  wire double_fault_seen_oRight;
	
  wire alert_minor_oLeft;
  wire alert_minor_oRight;

	wire alert_major_internal_oLeft;
  wire alert_major_internal_oRight;

	wire alert_major_bus_oLeft;
  wire alert_major_bus_oRight;

	wire core_sleep_oLeft;
  wire core_sleep_oRight;





//**Wire declarations**//
//**Init register**//
//**Stuttering Signal**//
//**Self-composed modules**//
//**Initial state**//
//**State invariants**//
//**Verification conditions**//
 endmodule