module SodorRequestRouter_2stage(
  output        io_masterPort_req_valid,
  output [31:0] io_masterPort_req_bits_addr,
  output [31:0] io_masterPort_req_bits_data,
  output        io_masterPort_req_bits_fcn,
  output [2:0]  io_masterPort_req_bits_typ,
  input         io_masterPort_resp_valid,
  input  [31:0] io_masterPort_resp_bits_data,
  output        io_scratchPort_req_valid,
  output [31:0] io_scratchPort_req_bits_addr,
  output [31:0] io_scratchPort_req_bits_data,
  output        io_scratchPort_req_bits_fcn,
  output [2:0]  io_scratchPort_req_bits_typ,
  input         io_scratchPort_resp_valid,
  input  [31:0] io_scratchPort_resp_bits_data,
  input         io_corePort_req_valid,
  input  [31:0] io_corePort_req_bits_addr,
  input  [31:0] io_corePort_req_bits_data,
  input         io_corePort_req_bits_fcn,
  input  [2:0]  io_corePort_req_bits_typ,
  output        io_corePort_resp_valid,
  output [31:0] io_corePort_resp_bits_data,
  input  [31:0] io_respAddress
);
  wire [31:0] _in_range_T = io_corePort_req_bits_addr ^ 32'h80000000; // @[Parameters.scala 137:31]
  wire [32:0] _in_range_T_1 = {1'b0,$signed(_in_range_T)}; // @[Parameters.scala 137:49]
  wire [32:0] _in_range_T_3 = $signed(_in_range_T_1) & -33'sh40000; // @[Parameters.scala 137:52]
  wire  in_range = $signed(_in_range_T_3) == 33'sh0; // @[Parameters.scala 137:67]
  wire [31:0] _resp_in_range_T = io_respAddress ^ 32'h80000000; // @[Parameters.scala 137:31]
  wire [32:0] _resp_in_range_T_1 = {1'b0,$signed(_resp_in_range_T)}; // @[Parameters.scala 137:49]
  wire [32:0] _resp_in_range_T_3 = $signed(_resp_in_range_T_1) & -33'sh40000; // @[Parameters.scala 137:52]
  wire  resp_in_range = $signed(_resp_in_range_T_3) == 33'sh0; // @[Parameters.scala 137:67]
  assign io_masterPort_req_valid = io_corePort_req_valid & 0; // @[scratchpad_adapter.scala 90:52]
  assign io_masterPort_req_bits_addr = io_corePort_req_bits_addr; // @[scratchpad_adapter.scala 86:26]
  assign io_masterPort_req_bits_data = io_corePort_req_bits_data; // @[scratchpad_adapter.scala 86:26]
  assign io_masterPort_req_bits_fcn = io_corePort_req_bits_fcn; // @[scratchpad_adapter.scala 86:26]
  assign io_masterPort_req_bits_typ = io_corePort_req_bits_typ; // @[scratchpad_adapter.scala 86:26]
  assign io_scratchPort_req_valid = io_corePort_req_valid;// & in_range; // @[scratchpad_adapter.scala 91:53]
  assign io_scratchPort_req_bits_addr = io_corePort_req_bits_addr; // @[scratchpad_adapter.scala 87:27]
  assign io_scratchPort_req_bits_data = io_corePort_req_bits_data; // @[scratchpad_adapter.scala 87:27]
  assign io_scratchPort_req_bits_fcn = io_corePort_req_bits_fcn; // @[scratchpad_adapter.scala 87:27]
  assign io_scratchPort_req_bits_typ = io_corePort_req_bits_typ; // @[scratchpad_adapter.scala 87:27]
  assign io_corePort_resp_valid = io_scratchPort_resp_valid; //resp_in_range ? io_scratchPort_resp_valid : io_masterPort_resp_valid; // @[scratchpad_adapter.scala 98:32]
  assign io_corePort_resp_bits_data = io_scratchPort_resp_bits_data; //  resp_in_range ? io_scratchPort_resp_bits_data : io_masterPort_resp_bits_data; // @[scratchpad_adapter.scala 97:31]
endmodule