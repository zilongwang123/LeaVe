module MemWriter_2stage(
  input  [20:0] io_addr,
  input  [31:0] io_data,
  input  [1:0]  io_size,
  input         io_en,
  output [9:0] io_mem_addr,
  output [7:0]  io_mem_data_0,
  output [7:0]  io_mem_data_1,
  output [7:0]  io_mem_data_2,
  output [7:0]  io_mem_data_3,
  output        io_mem_masks_0,
  output        io_mem_masks_1,
  output        io_mem_masks_2,
  output        io_mem_masks_3
);
  wire [1:0] offset = io_addr[1:0]; // @[memory.scala 146:30]
  wire [4:0] _shiftedVec_T = {offset, 3'h0}; // @[memory.scala 147:56]
  wire [62:0] _GEN_0 = {{31'd0}, io_data}; // @[memory.scala 147:45]
  wire [62:0] _shiftedVec_T_1 = _GEN_0 << _shiftedVec_T; // @[memory.scala 147:45]
  wire [3:0] shiftedVec_lo = {_shiftedVec_T_1[27],_shiftedVec_T_1[26],_shiftedVec_T_1[25],_shiftedVec_T_1[24]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_hi = {_shiftedVec_T_1[31],_shiftedVec_T_1[30],_shiftedVec_T_1[29],_shiftedVec_T_1[28]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_lo_1 = {_shiftedVec_T_1[19],_shiftedVec_T_1[18],_shiftedVec_T_1[17],_shiftedVec_T_1[16]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_hi_1 = {_shiftedVec_T_1[23],_shiftedVec_T_1[22],_shiftedVec_T_1[21],_shiftedVec_T_1[20]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_lo_2 = {_shiftedVec_T_1[11],_shiftedVec_T_1[10],_shiftedVec_T_1[9],_shiftedVec_T_1[8]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_hi_2 = {_shiftedVec_T_1[15],_shiftedVec_T_1[14],_shiftedVec_T_1[13],_shiftedVec_T_1[12]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_lo_3 = {_shiftedVec_T_1[3],_shiftedVec_T_1[2],_shiftedVec_T_1[1],_shiftedVec_T_1[0]}; // @[Cat.scala 31:58]
  wire [3:0] shiftedVec_hi_3 = {_shiftedVec_T_1[7],_shiftedVec_T_1[6],_shiftedVec_T_1[5],_shiftedVec_T_1[4]}; // @[Cat.scala 31:58]
  wire [1:0] _masks_T_1 = 2'h0 == io_size ? 2'h0 : 2'h3; // @[Mux.scala 81:58]
  wire [1:0] _masks_T_3 = 2'h1 == io_size ? 2'h1 : _masks_T_1; // @[Mux.scala 81:58]
  wire [1:0] _masks_T_5 = 2'h2 == io_size ? 2'h3 : _masks_T_3; // @[Mux.scala 81:58]
  wire [10:0] _masks_mask_T = 11'h1f << _masks_T_5; // @[memory.scala 79:38]
  wire [3:0] masks_mask = _masks_mask_T[7:4]; // @[memory.scala 79:53]
  wire [6:0] _GEN_1 = {{3'd0}, masks_mask}; // @[memory.scala 80:34]
  wire [6:0] _masks_maskWithOffset_T = _GEN_1 << offset; // @[memory.scala 80:34]
  wire [3:0] masks_maskWithOffset = _masks_maskWithOffset_T[3:0]; // @[memory.scala 80:55]
  wire  masks_3 = masks_maskWithOffset[0]; // @[memory.scala 81:22]
  wire  masks_2 = masks_maskWithOffset[1]; // @[memory.scala 81:22]
  wire  masks_1 = masks_maskWithOffset[2]; // @[memory.scala 81:22]
  wire  masks_0 = masks_maskWithOffset[3]; // @[memory.scala 81:22]
  assign io_mem_addr = io_addr[11:2]; // @[memory.scala 151:32]
  assign io_mem_data_0 = {shiftedVec_hi,shiftedVec_lo}; // @[Cat.scala 31:58]
  assign io_mem_data_1 = {shiftedVec_hi_1,shiftedVec_lo_1}; // @[Cat.scala 31:58]
  assign io_mem_data_2 = {shiftedVec_hi_2,shiftedVec_lo_2}; // @[Cat.scala 31:58]
  assign io_mem_data_3 = {shiftedVec_hi_3,shiftedVec_lo_3}; // @[Cat.scala 31:58]
  assign io_mem_masks_0 = masks_0 & io_en; // @[memory.scala 153:58]
  assign io_mem_masks_1 = masks_1 & io_en; // @[memory.scala 153:58]
  assign io_mem_masks_2 = masks_2 & io_en; // @[memory.scala 153:58]
  assign io_mem_masks_3 = masks_3 & io_en; // @[memory.scala 153:58]
endmodule