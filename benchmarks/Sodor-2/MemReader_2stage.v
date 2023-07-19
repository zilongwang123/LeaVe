module MemReader_2stage(
  input  [20:0] io_addr,
  input  [1:0]  io_size,
  input         io_signed,
  output [31:0] io_data,
  output [9:0]  io_mem_addr,
  input  [7:0]  io_mem_data_0,
  input  [7:0]  io_mem_data_1,
  input  [7:0]  io_mem_data_2,
  input  [7:0]  io_mem_data_3
);
  wire [1:0] s_offset = io_addr[1:0]; // @[memory.scala 100:46]
  wire [31:0] _shiftedVec_T = {io_mem_data_0,io_mem_data_1,io_mem_data_2,io_mem_data_3}; // @[Cat.scala 31:58]
  wire [4:0] _shiftedVec_T_1 = {s_offset, 3'h0}; // @[memory.scala 107:63]
  wire [31:0] _shiftedVec_T_2 = _shiftedVec_T >> _shiftedVec_T_1; // @[memory.scala 107:50]
  wire [7:0] shiftedVec_0 = {_shiftedVec_T_2[31],_shiftedVec_T_2[30],_shiftedVec_T_2[29],_shiftedVec_T_2[28],
    _shiftedVec_T_2[27],_shiftedVec_T_2[26],_shiftedVec_T_2[25],_shiftedVec_T_2[24]}; // @[Cat.scala 31:58]
  wire [7:0] shiftedVec_1 = {_shiftedVec_T_2[23],_shiftedVec_T_2[22],_shiftedVec_T_2[21],_shiftedVec_T_2[20],
    _shiftedVec_T_2[19],_shiftedVec_T_2[18],_shiftedVec_T_2[17],_shiftedVec_T_2[16]}; // @[Cat.scala 31:58]
  wire [7:0] shiftedVec_2 = {_shiftedVec_T_2[15],_shiftedVec_T_2[14],_shiftedVec_T_2[13],_shiftedVec_T_2[12],
    _shiftedVec_T_2[11],_shiftedVec_T_2[10],_shiftedVec_T_2[9],_shiftedVec_T_2[8]}; // @[Cat.scala 31:58]
  wire [7:0] shiftedVec_3 = {_shiftedVec_T_2[7],_shiftedVec_T_2[6],_shiftedVec_T_2[5],_shiftedVec_T_2[4],_shiftedVec_T_2
    [3],_shiftedVec_T_2[2],_shiftedVec_T_2[1],_shiftedVec_T_2[0]}; // @[Cat.scala 31:58]
  wire [1:0] _bytes_T_1 = 2'h0 == io_size ? 2'h0 : 2'h3; // @[Mux.scala 81:58]
  wire [1:0] _bytes_T_3 = 2'h1 == io_size ? 2'h1 : _bytes_T_1; // @[Mux.scala 81:58]
  wire [1:0] bytes = 2'h2 == io_size ? 2'h3 : _bytes_T_3; // @[Mux.scala 81:58]
  wire [1:0] _sign_T_1 = 2'h3 - bytes; // @[memory.scala 111:36]
  wire [7:0] _GEN_1 = 2'h1 == _sign_T_1 ? shiftedVec_1 : shiftedVec_0; // @[memory.scala 111:{50,50}]
  wire [7:0] _GEN_2 = 2'h2 == _sign_T_1 ? shiftedVec_2 : _GEN_1; // @[memory.scala 111:{50,50}]
  wire [7:0] _GEN_3 = 2'h3 == _sign_T_1 ? shiftedVec_3 : _GEN_2; // @[memory.scala 111:{50,50}]
  wire  sign = _GEN_3[7]; // @[memory.scala 111:50]
  wire [10:0] _masks_mask_T = 11'h1f << bytes; // @[memory.scala 79:38]
  wire [3:0] masks_mask = _masks_mask_T[7:4]; // @[memory.scala 79:53]
  wire [4:0] _masks_maskWithOffset_T = {{1'd0}, masks_mask}; // @[memory.scala 80:34]
  wire [3:0] masks_maskWithOffset = _masks_maskWithOffset_T[3:0]; // @[memory.scala 80:55]
  wire  masks_3 = masks_maskWithOffset[0]; // @[memory.scala 81:22]
  wire  masks_2 = masks_maskWithOffset[1]; // @[memory.scala 81:22]
  wire  masks_1 = masks_maskWithOffset[2]; // @[memory.scala 81:22]
  wire  masks_0 = masks_maskWithOffset[3]; // @[memory.scala 81:22]
  wire [7:0] _maskedVec_T_2 = masks_0 ? 8'hff : 8'h0; // @[Bitwise.scala 74:12]
  wire [7:0] _maskedVec_T_3 = ~_maskedVec_T_2; // @[memory.scala 114:42]
  wire [7:0] _maskedVec_T_4 = shiftedVec_0 | _maskedVec_T_3; // @[memory.scala 114:40]
  wire [7:0] _maskedVec_T_7 = shiftedVec_0 & _maskedVec_T_2; // @[memory.scala 114:63]
  wire [7:0] maskedVec_0 = sign & io_signed ? _maskedVec_T_4 : _maskedVec_T_7; // @[memory.scala 114:16]
  wire [7:0] _maskedVec_T_10 = masks_1 ? 8'hff : 8'h0; // @[Bitwise.scala 74:12]
  wire [7:0] _maskedVec_T_11 = ~_maskedVec_T_10; // @[memory.scala 114:42]
  wire [7:0] _maskedVec_T_12 = shiftedVec_1 | _maskedVec_T_11; // @[memory.scala 114:40]
  wire [7:0] _maskedVec_T_15 = shiftedVec_1 & _maskedVec_T_10; // @[memory.scala 114:63]
  wire [7:0] maskedVec_1 = sign & io_signed ? _maskedVec_T_12 : _maskedVec_T_15; // @[memory.scala 114:16]
  wire [7:0] _maskedVec_T_18 = masks_2 ? 8'hff : 8'h0; // @[Bitwise.scala 74:12]
  wire [7:0] _maskedVec_T_19 = ~_maskedVec_T_18; // @[memory.scala 114:42]
  wire [7:0] _maskedVec_T_20 = shiftedVec_2 | _maskedVec_T_19; // @[memory.scala 114:40]
  wire [7:0] _maskedVec_T_23 = shiftedVec_2 & _maskedVec_T_18; // @[memory.scala 114:63]
  wire [7:0] maskedVec_2 = sign & io_signed ? _maskedVec_T_20 : _maskedVec_T_23; // @[memory.scala 114:16]
  wire [7:0] _maskedVec_T_26 = masks_3 ? 8'hff : 8'h0; // @[Bitwise.scala 74:12]
  wire [7:0] _maskedVec_T_27 = ~_maskedVec_T_26; // @[memory.scala 114:42]
  wire [7:0] _maskedVec_T_28 = shiftedVec_3 | _maskedVec_T_27; // @[memory.scala 114:40]
  wire [7:0] _maskedVec_T_31 = shiftedVec_3 & _maskedVec_T_26; // @[memory.scala 114:63]
  wire [7:0] maskedVec_3 = sign & io_signed ? _maskedVec_T_28 : _maskedVec_T_31; // @[memory.scala 114:16]
  wire [15:0] io_data_lo = {maskedVec_2,maskedVec_3}; // @[Cat.scala 31:58]
  wire [15:0] io_data_hi = {maskedVec_0,maskedVec_1}; // @[Cat.scala 31:58]
  assign io_data = {io_data_hi,io_data_lo}; // @[Cat.scala 31:58]
  assign io_mem_addr = io_addr[11:2]; // @[memory.scala 105:32]
endmodule