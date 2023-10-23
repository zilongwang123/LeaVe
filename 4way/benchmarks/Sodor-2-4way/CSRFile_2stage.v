module CSRFile_2stage(
  input         clock,
  input         reset,
  input         io_ungated_clock,
  input         io_interrupts_debug,
  input         io_interrupts_mtip,
  input         io_interrupts_msip,
  input         io_interrupts_meip,
  input         io_hartid,
  input  [11:0] io_rw_addr,
  input  [2:0]  io_rw_cmd,
  output [31:0] io_rw_rdata,
  input  [31:0] io_rw_wdata,
  output        io_csr_stall,
  output        io_eret,
  output        io_singleStep,
  output        io_status_debug,
  output        io_status_cease,
  output        io_status_wfi,
  output [31:0] io_status_isa,
  output [1:0]  io_status_dprv,
  output        io_status_dv,
  output [1:0]  io_status_prv,
  output        io_status_v,
  output        io_status_sd,
  output [22:0] io_status_zero2,
  output        io_status_mpv,
  output        io_status_gva,
  output        io_status_mbe,
  output        io_status_sbe,
  output [1:0]  io_status_sxl,
  output [1:0]  io_status_uxl,
  output        io_status_sd_rv32,
  output [7:0]  io_status_zero1,
  output        io_status_tsr,
  output        io_status_tw,
  output        io_status_tvm,
  output        io_status_mxr,
  output        io_status_sum,
  output        io_status_mprv,
  output [1:0]  io_status_xs,
  output [1:0]  io_status_fs,
  output [1:0]  io_status_mpp,
  output [1:0]  io_status_vs,
  output        io_status_spp,
  output        io_status_mpie,
  output        io_status_ube,
  output        io_status_spie,
  output        io_status_upie,
  output        io_status_mie,
  output        io_status_hie,
  output        io_status_sie,
  output        io_status_uie,
  output [31:0] io_evec,
  input         io_exception,
  input         io_retire,
  input  [31:0] io_cause,
  input  [31:0] io_pc,
  input  [31:0] io_tval,
  output [31:0] io_time,
  output        io_interrupt,
  output [31:0] io_interrupt_cause
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
  reg [63:0] _RAND_19;
  reg [31:0] _RAND_20;
  reg [63:0] _RAND_21;
  reg [31:0] _RAND_22;
`endif // RANDOMIZE_REG_INIT
  reg  reg_mstatus_spp; // @[CSR.scala 369:24]
  reg  reg_mstatus_mpie; // @[CSR.scala 369:24]
  reg  reg_mstatus_mie; // @[CSR.scala 369:24]
  reg  reg_dcsr_ebreakm; // @[CSR.scala 377:21]
  reg [2:0] reg_dcsr_cause; // @[CSR.scala 377:21]
  reg  reg_dcsr_step; // @[CSR.scala 377:21]
  reg  reg_debug; // @[CSR.scala 449:22]
  reg [31:0] reg_dpc; // @[CSR.scala 450:20]
  reg [31:0] reg_dscratch; // @[CSR.scala 451:25]
  reg  reg_singleStepped; // @[CSR.scala 453:30]
  reg [31:0] reg_mie; // @[CSR.scala 462:20]
  reg [31:0] reg_mepc; // @[CSR.scala 472:21]
  reg [31:0] reg_mcause; // @[CSR.scala 473:27]
  reg [31:0] reg_mtval; // @[CSR.scala 474:22]
  reg [31:0] reg_mscratch; // @[CSR.scala 476:25]
  reg [31:0] reg_mtvec; // @[CSR.scala 479:27]
  reg  reg_wfi; // @[CSR.scala 538:50]
  reg [2:0] reg_mcountinhibit; // @[CSR.scala 547:34]
  wire  x79 = reg_mcountinhibit[2]; // @[CSR.scala 549:75]
  reg [5:0] small_; // @[Counters.scala 45:37]
  wire [5:0] _GEN_34 = {{5'd0}, io_retire}; // @[Counters.scala 46:33]
  wire [6:0] nextSmall = small_ + _GEN_34; // @[Counters.scala 46:33]
  wire  _T_14 = ~x79; // @[Counters.scala 47:9]
  wire [6:0] _GEN_0 = ~x79 ? nextSmall : {{1'd0}, small_}; // @[Counters.scala 47:{19,27} 45:37]
  reg [57:0] large_; // @[Counters.scala 50:27]
  wire [57:0] _large_r_T_1 = large_ + 58'h1; // @[Counters.scala 51:55]
  wire [57:0] _GEN_1 = nextSmall[6] & _T_14 ? _large_r_T_1 : large_; // @[Counters.scala 50:27 51:{46,50}]
  wire [63:0] value = {large_,small_}; // @[Cat.scala 31:58]
  wire  x86 = ~io_csr_stall; // @[CSR.scala 551:56]
  reg [5:0] small_1; // @[Counters.scala 45:37]
  wire [5:0] _GEN_35 = {{5'd0}, x86}; // @[Counters.scala 46:33]
  wire [6:0] nextSmall_1 = small_1 + _GEN_35; // @[Counters.scala 46:33]
  wire  _T_15 = ~reg_mcountinhibit[0]; // @[Counters.scala 47:9]
  wire [6:0] _GEN_2 = ~reg_mcountinhibit[0] ? nextSmall_1 : {{1'd0}, small_1}; // @[Counters.scala 47:{19,27} 45:37]
  reg [57:0] large_1; // @[Counters.scala 50:27]
  wire [57:0] _large_r_T_3 = large_1 + 58'h1; // @[Counters.scala 51:55]
  wire [57:0] _GEN_3 = nextSmall_1[6] & _T_15 ? _large_r_T_3 : large_1; // @[Counters.scala 50:27 51:{46,50}]
  wire [63:0] value_1 = {large_1,small_1}; // @[Cat.scala 31:58]
  wire [15:0] _read_mip_T = {4'h0,io_interrupts_meip,1'h0,2'h0,io_interrupts_mtip,1'h0,2'h0,io_interrupts_msip,1'h0,2'h0
    }; // @[CSR.scala 567:22]
  wire [15:0] read_mip = _read_mip_T & 16'h888; // @[CSR.scala 567:29]
  wire [31:0] _GEN_40 = {{16'd0}, read_mip}; // @[CSR.scala 571:56]
  wire [31:0] pending_interrupts = _GEN_40 & reg_mie; // @[CSR.scala 571:56]
  wire [14:0] d_interrupts = {io_interrupts_debug, 14'h0}; // @[CSR.scala 572:42]
  wire [31:0] _m_interrupts_T_3 = ~pending_interrupts; // @[CSR.scala 577:83]
  wire [31:0] _m_interrupts_T_5 = ~_m_interrupts_T_3; // @[CSR.scala 577:81]
  wire [31:0] m_interrupts = reg_mstatus_mie ? _m_interrupts_T_5 : 32'h0; // @[CSR.scala 577:25]
  wire  _any_T_78 = d_interrupts[14] | d_interrupts[13] | d_interrupts[12] | d_interrupts[11] | d_interrupts[3] |
    d_interrupts[7] | d_interrupts[9] | d_interrupts[1] | d_interrupts[5] | d_interrupts[10] | d_interrupts[2] |
    d_interrupts[6] | d_interrupts[8] | d_interrupts[0] | d_interrupts[4] | m_interrupts[15]; // @[CSR.scala 1534:90]
  wire  anyInterrupt = _any_T_78 | m_interrupts[14] | m_interrupts[13] | m_interrupts[12] | m_interrupts[11] |
    m_interrupts[3] | m_interrupts[7] | m_interrupts[9] | m_interrupts[1] | m_interrupts[5] | m_interrupts[10] |
    m_interrupts[2] | m_interrupts[6] | m_interrupts[8] | m_interrupts[0] | m_interrupts[4]; // @[CSR.scala 1534:90]
  wire [3:0] _which_T_95 = m_interrupts[0] ? 4'h0 : 4'h4; // @[Mux.scala 47:70]
  wire [3:0] _which_T_96 = m_interrupts[8] ? 4'h8 : _which_T_95; // @[Mux.scala 47:70]
  wire [3:0] _which_T_97 = m_interrupts[6] ? 4'h6 : _which_T_96; // @[Mux.scala 47:70]
  wire [3:0] _which_T_98 = m_interrupts[2] ? 4'h2 : _which_T_97; // @[Mux.scala 47:70]
  wire [3:0] _which_T_99 = m_interrupts[10] ? 4'ha : _which_T_98; // @[Mux.scala 47:70]
  wire [3:0] _which_T_100 = m_interrupts[5] ? 4'h5 : _which_T_99; // @[Mux.scala 47:70]
  wire [3:0] _which_T_101 = m_interrupts[1] ? 4'h1 : _which_T_100; // @[Mux.scala 47:70]
  wire [3:0] _which_T_102 = m_interrupts[9] ? 4'h9 : _which_T_101; // @[Mux.scala 47:70]
  wire [3:0] _which_T_103 = m_interrupts[7] ? 4'h7 : _which_T_102; // @[Mux.scala 47:70]
  wire [3:0] _which_T_104 = m_interrupts[3] ? 4'h3 : _which_T_103; // @[Mux.scala 47:70]
  wire [3:0] _which_T_105 = m_interrupts[11] ? 4'hb : _which_T_104; // @[Mux.scala 47:70]
  wire [3:0] _which_T_106 = m_interrupts[12] ? 4'hc : _which_T_105; // @[Mux.scala 47:70]
  wire [3:0] _which_T_107 = m_interrupts[13] ? 4'hd : _which_T_106; // @[Mux.scala 47:70]
  wire [3:0] _which_T_108 = m_interrupts[14] ? 4'he : _which_T_107; // @[Mux.scala 47:70]
  wire [3:0] _which_T_109 = m_interrupts[15] ? 4'hf : _which_T_108; // @[Mux.scala 47:70]
  wire [3:0] _which_T_111 = d_interrupts[4] ? 4'h4 : _which_T_109; // @[Mux.scala 47:70]
  wire [3:0] _which_T_112 = d_interrupts[0] ? 4'h0 : _which_T_111; // @[Mux.scala 47:70]
  wire [3:0] _which_T_113 = d_interrupts[8] ? 4'h8 : _which_T_112; // @[Mux.scala 47:70]
  wire [3:0] _which_T_114 = d_interrupts[6] ? 4'h6 : _which_T_113; // @[Mux.scala 47:70]
  wire [3:0] _which_T_115 = d_interrupts[2] ? 4'h2 : _which_T_114; // @[Mux.scala 47:70]
  wire [3:0] _which_T_116 = d_interrupts[10] ? 4'ha : _which_T_115; // @[Mux.scala 47:70]
  wire [3:0] _which_T_117 = d_interrupts[5] ? 4'h5 : _which_T_116; // @[Mux.scala 47:70]
  wire [3:0] _which_T_118 = d_interrupts[1] ? 4'h1 : _which_T_117; // @[Mux.scala 47:70]
  wire [3:0] _which_T_119 = d_interrupts[9] ? 4'h9 : _which_T_118; // @[Mux.scala 47:70]
  wire [3:0] _which_T_120 = d_interrupts[7] ? 4'h7 : _which_T_119; // @[Mux.scala 47:70]
  wire [3:0] _which_T_121 = d_interrupts[3] ? 4'h3 : _which_T_120; // @[Mux.scala 47:70]
  wire [3:0] _which_T_122 = d_interrupts[11] ? 4'hb : _which_T_121; // @[Mux.scala 47:70]
  wire [3:0] _which_T_123 = d_interrupts[12] ? 4'hc : _which_T_122; // @[Mux.scala 47:70]
  wire [3:0] _which_T_124 = d_interrupts[13] ? 4'hd : _which_T_123; // @[Mux.scala 47:70]
  wire [3:0] whichInterrupt = d_interrupts[14] ? 4'he : _which_T_124; // @[Mux.scala 47:70]
  wire [31:0] _GEN_41 = {{28'd0}, whichInterrupt}; // @[CSR.scala 582:67]
  wire  _io_interrupt_T = ~io_singleStep; // @[CSR.scala 583:36]
  wire [8:0] read_mstatus_lo_lo = {io_status_spp,io_status_mpie,io_status_ube,io_status_spie,io_status_upie,
    io_status_mie,io_status_hie,io_status_sie,io_status_uie}; // @[CSR.scala 606:38]
  wire [21:0] read_mstatus_lo = {io_status_tw,io_status_tvm,io_status_mxr,io_status_sum,io_status_mprv,io_status_xs,
    io_status_fs,io_status_mpp,io_status_vs,read_mstatus_lo_lo}; // @[CSR.scala 606:38]
  wire [64:0] read_mstatus_hi_hi = {io_status_debug,io_status_cease,io_status_wfi,io_status_isa,io_status_dprv,
    io_status_dv,io_status_prv,io_status_v,io_status_sd,io_status_zero2}; // @[CSR.scala 606:38]
  wire [82:0] read_mstatus_hi = {read_mstatus_hi_hi,io_status_mpv,io_status_gva,io_status_mbe,io_status_sbe,
    io_status_sxl,io_status_uxl,io_status_sd_rv32,io_status_zero1,io_status_tsr}; // @[CSR.scala 606:38]
  wire [104:0] _read_mstatus_T = {read_mstatus_hi,read_mstatus_lo}; // @[CSR.scala 606:38]
  wire [31:0] read_mstatus = _read_mstatus_T[31:0]; // @[CSR.scala 606:40]
  wire [6:0] _read_mtvec_T_1 = reg_mtvec[0] ? 7'h7e : 7'h2; // @[CSR.scala 1563:39]
  wire [31:0] _read_mtvec_T_3 = {{25'd0}, _read_mtvec_T_1}; // @[package.scala 165:41]
  wire [31:0] _read_mtvec_T_4 = ~_read_mtvec_T_3; // @[package.scala 165:37]
  wire [31:0] read_mtvec = reg_mtvec & _read_mtvec_T_4; // @[package.scala 165:35]
  wire [31:0] _T_18 = ~reg_mepc; // @[CSR.scala 1562:28]
  wire [31:0] _T_21 = _T_18 | 32'h3; // @[CSR.scala 1562:31]
  wire [31:0] _T_22 = ~_T_21; // @[CSR.scala 1562:26]
  wire [31:0] _T_23 = {4'h4,12'h0,reg_dcsr_ebreakm,4'h0,2'h0,reg_dcsr_cause,1'h0,2'h0,reg_dcsr_step,2'h3}; // @[CSR.scala 627:27]
  wire [31:0] _T_24 = ~reg_dpc; // @[CSR.scala 1562:28]
  wire [31:0] _T_27 = _T_24 | 32'h3; // @[CSR.scala 1562:31]
  wire [31:0] _T_28 = ~_T_27; // @[CSR.scala 1562:26]
  wire [12:0] addr = {io_status_v,io_rw_addr}; // @[Cat.scala 31:58]
  wire [12:0] _decoded_T_8 = addr & 13'h865; // @[Decode.scala 14:65]
  wire  decoded_4 = _decoded_T_8 == 13'h1; // @[Decode.scala 14:121]
  wire  decoded_5 = _decoded_T_8 == 13'h0; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_12 = addr & 13'h825; // @[Decode.scala 14:65]
  wire  decoded_6 = _decoded_T_12 == 13'h5; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_14 = addr & 13'h44; // @[Decode.scala 14:65]
  wire  decoded_7 = _decoded_T_14 == 13'h44; // @[Decode.scala 14:121]
  wire  decoded_8 = _decoded_T_8 == 13'h4; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_18 = addr & 13'h47; // @[Decode.scala 14:65]
  wire  decoded_9 = _decoded_T_18 == 13'h40; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_20 = addr & 13'h43; // @[Decode.scala 14:65]
  wire  decoded_10 = _decoded_T_20 == 13'h41; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_22 = addr & 13'h823; // @[Decode.scala 14:65]
  wire  decoded_11 = _decoded_T_22 == 13'h3; // @[Decode.scala 14:121]
  wire  decoded_12 = _decoded_T_22 == 13'h2; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_26 = addr & 13'h483; // @[Decode.scala 14:65]
  wire  decoded_13 = _decoded_T_26 == 13'h400; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_28 = addr & 13'hc13; // @[Decode.scala 14:65]
  wire  decoded_14 = _decoded_T_28 == 13'h410; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_30 = addr & 13'hc11; // @[Decode.scala 14:65]
  wire  decoded_15 = _decoded_T_30 == 13'h411; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_32 = addr & 13'hc12; // @[Decode.scala 14:65]
  wire  decoded_16 = _decoded_T_32 == 13'h412; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_34 = addr & 13'h43e; // @[Decode.scala 14:65]
  wire  decoded_17 = _decoded_T_34 == 13'h20; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_36 = addr & 13'h89e; // @[Decode.scala 14:65]
  wire  decoded_18 = _decoded_T_36 == 13'h800; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_38 = addr & 13'hdf; // @[Decode.scala 14:65]
  wire  decoded_19 = _decoded_T_38 == 13'h2; // @[Decode.scala 14:121]
  wire [12:0] _decoded_T_122 = addr & 13'h49f; // @[Decode.scala 14:65]
  wire [12:0] _decoded_T_214 = addr & 13'h49e; // @[Decode.scala 14:65]
  wire  decoded_107 = _decoded_T_214 == 13'h80; // @[Decode.scala 14:121]
  wire  decoded_108 = _decoded_T_122 == 13'h82; // @[Decode.scala 14:121]
  wire [31:0] _wdata_T_1 = io_rw_cmd[1] ? io_rw_rdata : 32'h0; // @[CSR.scala 1540:9]
  wire [31:0] _wdata_T_2 = _wdata_T_1 | io_rw_wdata; // @[CSR.scala 1540:34]
  wire [31:0] _wdata_T_5 = &io_rw_cmd[1:0] ? io_rw_wdata : 32'h0; // @[CSR.scala 1540:49]
  wire [31:0] _wdata_T_6 = ~_wdata_T_5; // @[CSR.scala 1540:45]
  wire [31:0] wdata = _wdata_T_2 & _wdata_T_6; // @[CSR.scala 1540:43]
  wire  system_insn = io_rw_cmd == 3'h4; // @[CSR.scala 813:31]
  wire [31:0] _T_172 = {io_rw_addr, 20'h0}; // @[CSR.scala 829:28]
  wire [31:0] _T_173 = _T_172 & 32'h20100000; // @[Decode.scala 14:65]
  wire  _T_174 = _T_173 == 32'h0; // @[Decode.scala 14:121]
  wire [31:0] _T_176 = _T_172 & 32'h10100000; // @[Decode.scala 14:65]
  wire  _T_177 = _T_176 == 32'h100000; // @[Decode.scala 14:121]
  wire [31:0] _T_179 = _T_172 & 32'h20400000; // @[Decode.scala 14:65]
  wire  _T_180 = _T_179 == 32'h20000000; // @[Decode.scala 14:121]
  wire [31:0] _T_182 = _T_172 & 32'h20200000; // @[Decode.scala 14:65]
  wire  _T_183 = _T_182 == 32'h20000000; // @[Decode.scala 14:121]
  wire [31:0] _T_185 = _T_172 & 32'h30000000; // @[Decode.scala 14:65]
  wire  _T_186 = _T_185 == 32'h10000000; // @[Decode.scala 14:121]
  wire  insn_call = system_insn & _T_174; // @[CSR.scala 829:95]
  wire  insn_break = system_insn & _T_177; // @[CSR.scala 829:95]
  wire  insn_ret = system_insn & _T_180; // @[CSR.scala 829:95]
  wire  insn_cease = system_insn & _T_183; // @[CSR.scala 829:95]
  wire  insn_wfi = system_insn & _T_186; // @[CSR.scala 829:95]
  wire  _io_decode_0_read_illegal_T_16 = ~reg_debug; // @[CSR.scala 861:45]
  wire [31:0] _cause_T_5 = insn_break ? 32'h3 : io_cause; // @[CSR.scala 894:14]
  wire [31:0] cause = insn_call ? 32'hb : _cause_T_5; // @[CSR.scala 893:8]
  wire [7:0] cause_lsbs = cause[7:0]; // @[CSR.scala 895:25]
  wire  _causeIsDebugInt_T_1 = cause_lsbs == 8'he; // @[CSR.scala 896:53]
  wire  causeIsDebugInt = cause[31] & cause_lsbs == 8'he; // @[CSR.scala 896:39]
  wire  _causeIsDebugTrigger_T_1 = ~cause[31]; // @[CSR.scala 897:29]
  wire  causeIsDebugTrigger = ~cause[31] & _causeIsDebugInt_T_1; // @[CSR.scala 897:44]
  wire [3:0] _causeIsDebugBreak_T_3 = {reg_dcsr_ebreakm,1'h0,2'h0}; // @[Cat.scala 31:58]
  wire [3:0] _causeIsDebugBreak_T_4 = {{3'd0}, _causeIsDebugBreak_T_3[3]}; // @[CSR.scala 898:134]
  wire  causeIsDebugBreak = _causeIsDebugTrigger_T_1 & insn_break & _causeIsDebugBreak_T_4[0]; // @[CSR.scala 898:56]
  wire  trapToDebug = reg_singleStepped | causeIsDebugInt | causeIsDebugTrigger | causeIsDebugBreak | reg_debug; // @[CSR.scala 899:123]
  wire [11:0] _debugTVec_T = insn_break ? 12'h800 : 12'h808; // @[CSR.scala 902:37]
  wire [11:0] debugTVec = reg_debug ? _debugTVec_T : 12'h800; // @[CSR.scala 902:22]
  wire [6:0] notDebugTVec_interruptOffset = {cause[4:0], 2'h0}; // @[CSR.scala 912:59]
  wire [31:0] notDebugTVec_interruptVec = {read_mtvec[31:7],notDebugTVec_interruptOffset}; // @[Cat.scala 31:58]
  wire  notDebugTVec_doVector = read_mtvec[0] & cause[31] & cause_lsbs[7:5] == 3'h0; // @[CSR.scala 914:55]
  wire [31:0] _notDebugTVec_T_1 = {read_mtvec[31:2], 2'h0}; // @[CSR.scala 915:56]
  wire [31:0] notDebugTVec = notDebugTVec_doVector ? notDebugTVec_interruptVec : _notDebugTVec_T_1; // @[CSR.scala 915:8]
  wire [31:0] tvec = trapToDebug ? {{20'd0}, debugTVec} : notDebugTVec; // @[CSR.scala 928:17]
  wire  _io_eret_T = insn_call | insn_break; // @[CSR.scala 933:24]
  wire  exception = _io_eret_T | io_exception; // @[CSR.scala 953:43]
  wire [1:0] _T_214 = insn_ret + insn_call; // @[Bitwise.scala 48:55]
  wire [1:0] _T_216 = insn_break + io_exception; // @[Bitwise.scala 48:55]
  wire [2:0] _T_218 = _T_214 + _T_216; // @[Bitwise.scala 48:55]
  wire  _T_222 = ~reset; // @[CSR.scala 954:9]
  wire  _GEN_46 = insn_wfi & _io_interrupt_T & _io_decode_0_read_illegal_T_16 | reg_wfi; // @[CSR.scala 538:50 956:{51,61}]
  wire  _GEN_48 = io_retire | exception | reg_singleStepped; // @[CSR.scala 453:30 960:{36,56}]
  wire [31:0] _epc_T = ~io_pc; // @[CSR.scala 1561:28]
  wire [31:0] _epc_T_1 = _epc_T | 32'h3; // @[CSR.scala 1561:31]
  wire [31:0] epc = ~_epc_T_1; // @[CSR.scala 1561:26]
  wire [1:0] _reg_dcsr_cause_T = causeIsDebugTrigger ? 2'h2 : 2'h1; // @[CSR.scala 973:86]
  wire [1:0] _reg_dcsr_cause_T_1 = causeIsDebugInt ? 2'h3 : _reg_dcsr_cause_T; // @[CSR.scala 973:56]
  wire [2:0] _reg_dcsr_cause_T_2 = reg_singleStepped ? 3'h4 : {{1'd0}, _reg_dcsr_cause_T_1}; // @[CSR.scala 973:30]
  wire  _GEN_51 = _io_decode_0_read_illegal_T_16 | reg_debug; // @[CSR.scala 969:25 971:19 449:22]
  wire [31:0] _GEN_52 = _io_decode_0_read_illegal_T_16 ? epc : reg_dpc; // @[CSR.scala 969:25 972:17 450:20]
  wire [1:0] _GEN_73 = {{1'd0}, reg_mstatus_spp}; // @[CSR.scala 1007:23 369:24 997:35]
  wire  _GEN_145 = trapToDebug ? _GEN_51 : reg_debug; // @[CSR.scala 449:22 968:24]
  wire [31:0] _GEN_146 = trapToDebug ? _GEN_52 : reg_dpc; // @[CSR.scala 450:20 968:24]
  wire [1:0] _GEN_170 = trapToDebug ? {{1'd0}, reg_mstatus_spp} : _GEN_73; // @[CSR.scala 369:24 968:24]
  wire [31:0] _GEN_174 = trapToDebug ? reg_mepc : epc; // @[CSR.scala 472:21 968:24]
  wire [31:0] _GEN_175 = trapToDebug ? reg_mcause : cause; // @[CSR.scala 968:24 473:27]
  wire [31:0] _GEN_176 = trapToDebug ? reg_mtval : io_tval; // @[CSR.scala 474:22 968:24]
  wire  _GEN_178 = trapToDebug ? reg_mstatus_mpie : reg_mstatus_mie; // @[CSR.scala 369:24 968:24]
  wire  _GEN_180 = trapToDebug & reg_mstatus_mie; // @[CSR.scala 369:24 968:24]
  wire  _GEN_182 = exception ? _GEN_145 : reg_debug; // @[CSR.scala 967:20 449:22]
  wire [31:0] _GEN_183 = exception ? _GEN_146 : reg_dpc; // @[CSR.scala 450:20 967:20]
  wire [1:0] _GEN_207 = exception ? _GEN_170 : {{1'd0}, reg_mstatus_spp}; // @[CSR.scala 967:20 369:24]
  wire [31:0] _GEN_211 = exception ? _GEN_174 : reg_mepc; // @[CSR.scala 967:20 472:21]
  wire [31:0] _GEN_212 = exception ? _GEN_175 : reg_mcause; // @[CSR.scala 967:20 473:27]
  wire [31:0] _GEN_213 = exception ? _GEN_176 : reg_mtval; // @[CSR.scala 967:20 474:22]
  wire  _GEN_215 = exception ? _GEN_178 : reg_mstatus_mpie; // @[CSR.scala 967:20 369:24]
  wire  _GEN_217 = exception ? _GEN_180 : reg_mstatus_mie; // @[CSR.scala 967:20 369:24]
  wire [31:0] _GEN_239 = io_rw_addr[10] & io_rw_addr[7] ? _T_28 : _T_22; // @[CSR.scala 1064:70 1068:15]
  wire  _GEN_241 = io_rw_addr[10] & io_rw_addr[7] ? _GEN_217 : reg_mstatus_mpie; // @[CSR.scala 1064:70]
  wire  _GEN_242 = io_rw_addr[10] & io_rw_addr[7] ? _GEN_215 : 1'h1; // @[CSR.scala 1064:70]
  wire  _GEN_273 = insn_ret ? _GEN_241 : _GEN_217; // @[CSR.scala 1045:19]
  wire  _GEN_274 = insn_ret ? _GEN_242 : _GEN_215; // @[CSR.scala 1045:19]
  reg  io_status_cease_r; // @[Reg.scala 28:20]
  wire  _GEN_279 = insn_cease | io_status_cease_r; // @[Reg.scala 29:18 28:20 29:22]
  wire [30:0] _io_rw_rdata_T_4 = decoded_4 ? 31'h40800100 : 31'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_5 = decoded_5 ? read_mstatus : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_6 = decoded_6 ? read_mtvec : 32'h0; // @[Mux.scala 27:73]
  wire [15:0] _io_rw_rdata_T_7 = decoded_7 ? read_mip : 16'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_8 = decoded_8 ? reg_mie : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_9 = decoded_9 ? reg_mscratch : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_10 = decoded_10 ? _T_22 : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_11 = decoded_11 ? reg_mtval : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_12 = decoded_12 ? reg_mcause : 32'h0; // @[Mux.scala 27:73]
  wire  _io_rw_rdata_T_13 = decoded_13 & io_hartid; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_14 = decoded_14 ? _T_23 : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_15 = decoded_15 ? _T_28 : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_16 = decoded_16 ? reg_dscratch : 32'h0; // @[Mux.scala 27:73]
  wire [2:0] _io_rw_rdata_T_17 = decoded_17 ? reg_mcountinhibit : 3'h0; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_18 = decoded_18 ? value_1 : 64'h0; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_19 = decoded_19 ? value : 64'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_107 = decoded_107 ? value_1[63:32] : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_108 = decoded_108 ? value[63:32] : 32'h0; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_115 = {{1'd0}, _io_rw_rdata_T_4}; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_116 = _io_rw_rdata_T_115 | _io_rw_rdata_T_5; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_117 = _io_rw_rdata_T_116 | _io_rw_rdata_T_6; // @[Mux.scala 27:73]
  wire [31:0] _GEN_341 = {{16'd0}, _io_rw_rdata_T_7}; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_118 = _io_rw_rdata_T_117 | _GEN_341; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_119 = _io_rw_rdata_T_118 | _io_rw_rdata_T_8; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_120 = _io_rw_rdata_T_119 | _io_rw_rdata_T_9; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_121 = _io_rw_rdata_T_120 | _io_rw_rdata_T_10; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_122 = _io_rw_rdata_T_121 | _io_rw_rdata_T_11; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_123 = _io_rw_rdata_T_122 | _io_rw_rdata_T_12; // @[Mux.scala 27:73]
  wire [31:0] _GEN_342 = {{31'd0}, _io_rw_rdata_T_13}; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_124 = _io_rw_rdata_T_123 | _GEN_342; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_125 = _io_rw_rdata_T_124 | _io_rw_rdata_T_14; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_126 = _io_rw_rdata_T_125 | _io_rw_rdata_T_15; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_127 = _io_rw_rdata_T_126 | _io_rw_rdata_T_16; // @[Mux.scala 27:73]
  wire [31:0] _GEN_343 = {{29'd0}, _io_rw_rdata_T_17}; // @[Mux.scala 27:73]
  wire [31:0] _io_rw_rdata_T_128 = _io_rw_rdata_T_127 | _GEN_343; // @[Mux.scala 27:73]
  wire [63:0] _GEN_344 = {{32'd0}, _io_rw_rdata_T_128}; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_129 = _GEN_344 | _io_rw_rdata_T_18; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_130 = _io_rw_rdata_T_129 | _io_rw_rdata_T_19; // @[Mux.scala 27:73]
  wire [63:0] _GEN_345 = {{32'd0}, _io_rw_rdata_T_107}; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_218 = _io_rw_rdata_T_130 | _GEN_345; // @[Mux.scala 27:73]
  wire [63:0] _GEN_346 = {{32'd0}, _io_rw_rdata_T_108}; // @[Mux.scala 27:73]
  wire [63:0] _io_rw_rdata_T_219 = _io_rw_rdata_T_218 | _GEN_346; // @[Mux.scala 27:73]
  wire  _T_366 = io_rw_cmd == 3'h5; // @[package.scala 15:47]
  wire  _T_367 = io_rw_cmd == 3'h6; // @[package.scala 15:47]
  wire  _T_368 = io_rw_cmd == 3'h7; // @[package.scala 15:47]
  wire  csr_wen = _T_367 | _T_368 | _T_366; // @[package.scala 72:59]
  wire [104:0] _new_mstatus_WIRE = {{73'd0}, wdata};
  wire  new_mstatus_mie = _new_mstatus_WIRE[3]; // @[CSR.scala 1153:47]
  wire  new_mstatus_mpie = _new_mstatus_WIRE[7]; // @[CSR.scala 1153:47]
  wire [31:0] _reg_mie_T = wdata & 32'h888; // @[CSR.scala 1205:59]
  wire [31:0] _reg_mepc_T = ~wdata; // @[CSR.scala 1561:28]
  wire [31:0] _reg_mepc_T_1 = _reg_mepc_T | 32'h3; // @[CSR.scala 1561:31]
  wire [31:0] _reg_mepc_T_2 = ~_reg_mepc_T_1; // @[CSR.scala 1561:26]
  wire [31:0] _reg_mcause_T = wdata & 32'h8000000f; // @[CSR.scala 1210:62]
  wire [31:0] _reg_mcountinhibit_T_1 = wdata & 32'hfffffffd; // @[CSR.scala 1230:76]
  wire [31:0] _GEN_293 = decoded_17 ? _reg_mcountinhibit_T_1 : {{29'd0}, reg_mcountinhibit}; // @[CSR.scala 1230:{47,67} 547:34]
  wire [63:0] _T_1714 = {value_1[63:32],wdata}; // @[Cat.scala 31:58]
  wire [63:0] _GEN_294 = decoded_18 ? _T_1714 : {{57'd0}, _GEN_2}; // @[CSR.scala 1555:31 Counters.scala 65:11]
  wire [63:0] _T_1717 = {wdata,value_1[31:0]}; // @[Cat.scala 31:58]
  wire [63:0] _GEN_296 = decoded_107 ? _T_1717 : _GEN_294; // @[CSR.scala 1556:31 Counters.scala 65:11]
  wire [63:0] _T_1719 = {value[63:32],wdata}; // @[Cat.scala 31:58]
  wire [63:0] _GEN_298 = decoded_19 ? _T_1719 : {{57'd0}, _GEN_0}; // @[CSR.scala 1555:31 Counters.scala 65:11]
  wire [63:0] _T_1722 = {wdata,value[31:0]}; // @[Cat.scala 31:58]
  wire [63:0] _GEN_300 = decoded_108 ? _T_1722 : _GEN_298; // @[CSR.scala 1556:31 Counters.scala 65:11]
  wire  new_dcsr_ebreakm = wdata[15]; // @[CSR.scala 1246:43]
  wire [31:0] _GEN_315 = csr_wen ? _GEN_293 : {{29'd0}, reg_mcountinhibit}; // @[CSR.scala 1148:18 547:34]
  wire [63:0] _GEN_316 = csr_wen ? _GEN_296 : {{57'd0}, _GEN_2}; // @[CSR.scala 1148:18]
  wire [63:0] _GEN_318 = csr_wen ? _GEN_300 : {{57'd0}, _GEN_0}; // @[CSR.scala 1148:18]
  assign io_rw_rdata = _io_rw_rdata_T_219[31:0]; // @[CSR.scala 1101:15]
  assign io_csr_stall = reg_wfi | io_status_cease; // @[CSR.scala 1091:27]
  assign io_eret = insn_call | insn_break | insn_ret; // @[CSR.scala 933:38]
  assign io_singleStep = reg_dcsr_step & _io_decode_0_read_illegal_T_16; // @[CSR.scala 934:34]
  assign io_status_debug = reg_debug; // @[CSR.scala 937:19]
  assign io_status_cease = io_status_cease_r; // @[CSR.scala 1092:19]
  assign io_status_wfi = reg_wfi; // @[CSR.scala 1093:17]
  assign io_status_isa = 32'h40800100; // @[CSR.scala 938:17]
  assign io_status_dprv = 2'h3; // @[CSR.scala 941:24]
  assign io_status_dv = 1'h0; // @[CSR.scala 942:33]
  assign io_status_prv = 2'h3; // @[CSR.scala 935:13]
  assign io_status_v = 1'h0; // @[CSR.scala 935:13]
  assign io_status_sd = &io_status_fs | &io_status_xs | &io_status_vs; // @[CSR.scala 936:58]
  assign io_status_zero2 = 23'h0; // @[CSR.scala 935:13]
  assign io_status_mpv = 1'h0; // @[CSR.scala 944:17]
  assign io_status_gva = 1'h0; // @[CSR.scala 945:17]
  assign io_status_mbe = 1'h0; // @[CSR.scala 935:13]
  assign io_status_sbe = 1'h0; // @[CSR.scala 935:13]
  assign io_status_sxl = 2'h0; // @[CSR.scala 940:17]
  assign io_status_uxl = 2'h0; // @[CSR.scala 939:17]
  assign io_status_sd_rv32 = io_status_sd; // @[CSR.scala 943:35]
  assign io_status_zero1 = 8'h0; // @[CSR.scala 935:13]
  assign io_status_tsr = 1'h0; // @[CSR.scala 935:13]
  assign io_status_tw = 1'h0; // @[CSR.scala 935:13]
  assign io_status_tvm = 1'h0; // @[CSR.scala 935:13]
  assign io_status_mxr = 1'h0; // @[CSR.scala 935:13]
  assign io_status_sum = 1'h0; // @[CSR.scala 935:13]
  assign io_status_mprv = 1'h0; // @[CSR.scala 935:13]
  assign io_status_xs = 2'h0; // @[CSR.scala 935:13]
  assign io_status_fs = 2'h0; // @[CSR.scala 935:13]
  assign io_status_mpp = 2'h3; // @[CSR.scala 935:13]
  assign io_status_vs = 2'h0; // @[CSR.scala 935:13]
  assign io_status_spp = reg_mstatus_spp; // @[CSR.scala 935:13]
  assign io_status_mpie = reg_mstatus_mpie; // @[CSR.scala 935:13]
  assign io_status_ube = 1'h0; // @[CSR.scala 935:13]
  assign io_status_spie = 1'h0; // @[CSR.scala 935:13]
  assign io_status_upie = 1'h0; // @[CSR.scala 935:13]
  assign io_status_mie = reg_mstatus_mie; // @[CSR.scala 935:13]
  assign io_status_hie = 1'h0; // @[CSR.scala 935:13]
  assign io_status_sie = 1'h0; // @[CSR.scala 935:13]
  assign io_status_uie = 1'h0; // @[CSR.scala 935:13]
  assign io_evec = insn_ret ? _GEN_239 : tvec; // @[CSR.scala 1045:19 929:11]
  assign io_time = value_1[31:0]; // @[CSR.scala 1090:11]
  assign io_interrupt = (anyInterrupt & ~io_singleStep | reg_singleStepped) & ~(reg_debug | io_status_cease); // @[CSR.scala 583:73]
  assign io_interrupt_cause = 32'h80000000 + _GEN_41; // @[CSR.scala 582:67]
  always @(posedge clock) begin
    if (reset) begin // @[CSR.scala 369:24]
      reg_mstatus_spp <= 1'h0; // @[CSR.scala 369:24]
    end else begin
      reg_mstatus_spp <= _GEN_207[0];
    end
    if (reset) begin // @[CSR.scala 369:24]
      reg_mstatus_mpie <= 1'h0; // @[CSR.scala 369:24]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_5) begin // @[CSR.scala 1152:39]
        reg_mstatus_mpie <= new_mstatus_mpie; // @[CSR.scala 1155:24]
      end else begin
        reg_mstatus_mpie <= _GEN_274;
      end
    end else begin
      reg_mstatus_mpie <= _GEN_274;
    end
    if (reset) begin // @[CSR.scala 369:24]
      reg_mstatus_mie <= 1'h0; // @[CSR.scala 369:24]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_5) begin // @[CSR.scala 1152:39]
        reg_mstatus_mie <= new_mstatus_mie; // @[CSR.scala 1154:23]
      end else begin
        reg_mstatus_mie <= _GEN_273;
      end
    end else begin
      reg_mstatus_mie <= _GEN_273;
    end
    if (reset) begin // @[CSR.scala 377:21]
      reg_dcsr_ebreakm <= 1'h0; // @[CSR.scala 377:21]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_14) begin // @[CSR.scala 1245:38]
        reg_dcsr_ebreakm <= new_dcsr_ebreakm; // @[CSR.scala 1248:26]
      end
    end
    if (reset) begin // @[CSR.scala 377:21]
      reg_dcsr_cause <= 3'h0; // @[CSR.scala 377:21]
    end else if (exception) begin // @[CSR.scala 967:20]
      if (trapToDebug) begin // @[CSR.scala 968:24]
        if (_io_decode_0_read_illegal_T_16) begin // @[CSR.scala 969:25]
          reg_dcsr_cause <= _reg_dcsr_cause_T_2; // @[CSR.scala 973:24]
        end
      end
    end
    if (reset) begin // @[CSR.scala 377:21]
      reg_dcsr_step <= 1'h0; // @[CSR.scala 377:21]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_14) begin // @[CSR.scala 1245:38]
        reg_dcsr_step <= wdata[2]; // @[CSR.scala 1247:23]
      end
    end
    if (reset) begin // @[CSR.scala 449:22]
      reg_debug <= 1'h0; // @[CSR.scala 449:22]
    end else if (insn_ret) begin // @[CSR.scala 1045:19]
      if (io_rw_addr[10] & io_rw_addr[7]) begin // @[CSR.scala 1064:70]
        reg_debug <= 1'h0; // @[CSR.scala 1067:17]
      end else begin
        reg_debug <= _GEN_182;
      end
    end else begin
      reg_debug <= _GEN_182;
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_15) begin // @[CSR.scala 1254:42]
        reg_dpc <= _reg_mepc_T_2; // @[CSR.scala 1254:52]
      end else begin
        reg_dpc <= _GEN_183;
      end
    end else begin
      reg_dpc <= _GEN_183;
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_16) begin // @[CSR.scala 1255:42]
        reg_dscratch <= wdata; // @[CSR.scala 1255:57]
      end
    end
    if (_io_interrupt_T) begin // @[CSR.scala 961:25]
      reg_singleStepped <= 1'h0; // @[CSR.scala 961:45]
    end else begin
      reg_singleStepped <= _GEN_48;
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_8) begin // @[CSR.scala 1205:40]
        reg_mie <= _reg_mie_T; // @[CSR.scala 1205:50]
      end
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_10) begin // @[CSR.scala 1206:40]
        reg_mepc <= _reg_mepc_T_2; // @[CSR.scala 1206:51]
      end else begin
        reg_mepc <= _GEN_211;
      end
    end else begin
      reg_mepc <= _GEN_211;
    end
    if (reset) begin // @[CSR.scala 473:27]
      reg_mcause <= 32'h0; // @[CSR.scala 473:27]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_12) begin // @[CSR.scala 1210:40]
        reg_mcause <= _reg_mcause_T; // @[CSR.scala 1210:53]
      end else begin
        reg_mcause <= _GEN_212;
      end
    end else begin
      reg_mcause <= _GEN_212;
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_11) begin // @[CSR.scala 1211:40]
        reg_mtval <= wdata; // @[CSR.scala 1211:52]
      end else begin
        reg_mtval <= _GEN_213;
      end
    end else begin
      reg_mtval <= _GEN_213;
    end
    if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_9) begin // @[CSR.scala 1207:40]
        reg_mscratch <= wdata; // @[CSR.scala 1207:55]
      end
    end
    if (reset) begin // @[CSR.scala 479:27]
      reg_mtvec <= 32'h0; // @[CSR.scala 479:27]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_6) begin // @[CSR.scala 1209:40]
        reg_mtvec <= wdata; // @[CSR.scala 1209:52]
      end
    end
    if (reset) begin // @[CSR.scala 547:34]
      reg_mcountinhibit <= 3'h0; // @[CSR.scala 547:34]
    end else begin
      reg_mcountinhibit <= _GEN_315[2:0];
    end
    if (reset) begin // @[Counters.scala 45:37]
      small_ <= 6'h0; // @[Counters.scala 45:37]
    end else begin
      small_ <= _GEN_318[5:0];
    end
    if (reset) begin // @[Counters.scala 50:27]
      large_ <= 58'h0; // @[Counters.scala 50:27]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_108) begin // @[CSR.scala 1556:31]
        large_ <= _T_1722[63:6]; // @[Counters.scala 66:23]
      end else if (decoded_19) begin // @[CSR.scala 1555:31]
        large_ <= _T_1719[63:6]; // @[Counters.scala 66:23]
      end else begin
        large_ <= _GEN_1;
      end
    end else begin
      large_ <= _GEN_1;
    end
    if (reset) begin // @[Reg.scala 28:20]
      io_status_cease_r <= 1'h0; // @[Reg.scala 28:20]
    end else begin
      io_status_cease_r <= _GEN_279;
    end
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_218 <= 3'h1) & ~reset) begin
          $fatal; // @[CSR.scala 954:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~reset & ~(_T_218 <= 3'h1)) begin
          $fwrite(32'h80000002,
            "Assertion failed: these conditions must be mutually exclusive\n    at CSR.scala:954 assert(PopCount(insn_ret :: insn_call :: insn_break :: io.exception :: Nil) <= 1, \"these conditions must be mutually exclusive\")\n"
            ); // @[CSR.scala 954:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~reg_singleStepped | ~io_retire) & _T_222) begin
          $fatal; // @[CSR.scala 963:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_222 & ~(~reg_singleStepped | ~io_retire)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at CSR.scala:963 assert(!reg_singleStepped || io.retire === UInt(0))\n"); // @[CSR.scala 963:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
  end
  always @(posedge io_ungated_clock) begin
    if (reset) begin // @[CSR.scala 538:50]
      reg_wfi <= 1'h0; // @[CSR.scala 538:50]
    end else if (|pending_interrupts | io_interrupts_debug | exception) begin // @[CSR.scala 957:69]
      reg_wfi <= 1'h0; // @[CSR.scala 957:79]
    end else begin
      reg_wfi <= _GEN_46;
    end
    if (reset) begin // @[Counters.scala 45:37]
      small_1 <= 6'h0; // @[Counters.scala 45:37]
    end else begin
      small_1 <= _GEN_316[5:0];
    end
    if (reset) begin // @[Counters.scala 50:27]
      large_1 <= 58'h0; // @[Counters.scala 50:27]
    end else if (csr_wen) begin // @[CSR.scala 1148:18]
      if (decoded_107) begin // @[CSR.scala 1556:31]
        large_1 <= _T_1717[63:6]; // @[Counters.scala 66:23]
      end else if (decoded_18) begin // @[CSR.scala 1555:31]
        large_1 <= _T_1714[63:6]; // @[Counters.scala 66:23]
      end else begin
        large_1 <= _GEN_3;
      end
    end else begin
      large_1 <= _GEN_3;
    end
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
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  reg_mstatus_spp = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  reg_mstatus_mpie = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  reg_mstatus_mie = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  reg_dcsr_ebreakm = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  reg_dcsr_cause = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  reg_dcsr_step = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  reg_debug = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  reg_dpc = _RAND_7[31:0];
  _RAND_8 = {1{`RANDOM}};
  reg_dscratch = _RAND_8[31:0];
  _RAND_9 = {1{`RANDOM}};
  reg_singleStepped = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  reg_mie = _RAND_10[31:0];
  _RAND_11 = {1{`RANDOM}};
  reg_mepc = _RAND_11[31:0];
  _RAND_12 = {1{`RANDOM}};
  reg_mcause = _RAND_12[31:0];
  _RAND_13 = {1{`RANDOM}};
  reg_mtval = _RAND_13[31:0];
  _RAND_14 = {1{`RANDOM}};
  reg_mscratch = _RAND_14[31:0];
  _RAND_15 = {1{`RANDOM}};
  reg_mtvec = _RAND_15[31:0];
  _RAND_16 = {1{`RANDOM}};
  reg_wfi = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  reg_mcountinhibit = _RAND_17[2:0];
  _RAND_18 = {1{`RANDOM}};
  small_ = _RAND_18[5:0];
  _RAND_19 = {2{`RANDOM}};
  large_ = _RAND_19[57:0];
  _RAND_20 = {1{`RANDOM}};
  small_1 = _RAND_20[5:0];
  _RAND_21 = {2{`RANDOM}};
  large_1 = _RAND_21[57:0];
  _RAND_22 = {1{`RANDOM}};
  io_status_cease_r = _RAND_22[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule