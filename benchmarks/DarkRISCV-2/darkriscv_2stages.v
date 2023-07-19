/*
 * Copyright (c) 2018, Marcelo Samsoniuk
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

`timescale 1ns / 1ps

// implemented opcodes:

`define LUI     7'b01101_11      // lui   rd,imm[31:12]
`define AUIPC   7'b00101_11      // auipc rd,imm[31:12]
`define JAL     7'b11011_11      // jal   rd,imm[xxxxx]
`define JALR    7'b11001_11      // jalr  rd,rs1,imm[11:0] 
`define BCC     7'b11000_11      // bcc   rs1,rs2,imm[12:1]
`define LCC     7'b00000_11      // lxx   rd,rs1,imm[11:0]
`define SCC     7'b01000_11      // sxx   rs1,rs2,imm[11:0]
`define MCC     7'b00100_11      // xxxi  rd,rs1,imm[11:0]
`define RCC     7'b01100_11      // xxx   rd,rs1,rs2 
`define MAC     7'b11111_11      // mac   rd,rs1,rs2

// not implemented opcodes:

`define FCC     7'b00011_11      // fencex
`define CCC     7'b11100_11      // exx, csrxx

// configuration file

`include "config_2stages.vh"

module darkriscv_2stages
//#(
//    parameter [31:0] RESET_PC = 0,
//    parameter [31:0] RESET_SP = 4096
//) 
(
    input             CLK,   // clock
    input             RES,   // reset
    input             HLT,   // halt
    
`ifdef __THREADS__    
    output [`__THREADS__-1:0] TPTR,  // thread pointer
`endif    

    input      [31:0] IDATA, // instruction data bus
    output     [31:0] IADDR, // instruction addr bus
    
    input      [31:0] DATAI, // data bus (input)
    output     [31:0] DATAO, // data bus (output)
    output     [31:0] DADDR, // addr bus

`ifdef __FLEXBUZZ__
    output     [ 2:0] DLEN, // data length
    output            RW,   // data read/write
`else    
    output     [ 3:0] BE,   // byte enable
    output            WR,    // write enable
    output            RD,    // read enable 
`endif    

    output            IDLE,   // idle output
    
    output [3:0]  DEBUG,       // old-school osciloscope based debug! :)
// for contracts 
    output [31:0]    PC_retire,
    output [31:0]    DADDR_CTR,
    input  [31:0]    INSTR_CTR,
    input  [31:0]    DATAI_CTR, 
// state invariant
    output [31:0]    PC,
    output [31:0]    DADDR_PC,
    input  [31:0]    INSTR_PC,
    input  [31:0]    DATAI_PC,

);
    // for contracts
    wire [31:0] INSTR_CTR;
    wire [31:0] DATAI_CTR;
    wire [31:0] DADDR_CTR;
    wire LCC_CTR = OPCODE_CTR == `LCC;
    wire SCC_CTR = OPCODE_CTR == `SCC;

    wire [7:0]  OPCODE_CTR = INSTR_CTR[6:0];
    wire [31:0] U1REG_CTR = REG1[INSTR_CTR[18:15]];
    wire [31:0] DADDR_CTR = (OPCODE_CTR == `LCC || OPCODE_CTR == `SCC) ? U1REG_CTR + SIMM_CTR : 0;
    wire [31:0] SIMM_CTR  = OPCODE_CTR==`SCC ? { INSTR_CTR[31] ? ALL1[31:12]:ALL0[31:12], INSTR_CTR[31:25],INSTR_CTR[11:7] } : // s-type
                            OPCODE_CTR==`BCC ? { INSTR_CTR[31] ? ALL1[31:13]:ALL0[31:13], INSTR_CTR[31],INSTR_CTR[7],INSTR_CTR[30:25],INSTR_CTR[11:8],ALL0[0] } : // b-type
                            OPCODE_CTR==`JAL ? { INSTR_CTR[31] ? ALL1[31:21]:ALL0[31:21], INSTR_CTR[31], INSTR_CTR[19:12], INSTR_CTR[20], INSTR_CTR[30:21], ALL0[0] } : // j-type
                            OPCODE_CTR==`LUI||
                            OPCODE_CTR==`AUIPC ? { INSTR_CTR[31:12], ALL0[11:0] } : // u-type
                                                { INSTR_CTR[31] ? ALL1[31:12]:ALL0[31:12],  INSTR_CTR[31:20] };
    wire [2:0]  FCT3_CTR = INSTR_CTR[14:12];
    wire [31:0] LDATA_CTR = FCT3_CTR==0||FCT3_CTR==4 ? ( DADDR_CTR[1:0]==3 ? { FCT3_CTR==0&&DATAI_CTR[31] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_CTR[31:24] } :
                                             DADDR_CTR[1:0]==2 ? { FCT3_CTR==0&&DATAI_CTR[23] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_CTR[23:16] } :
                                             DADDR_CTR[1:0]==1 ? { FCT3_CTR==0&&DATAI_CTR[15] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_CTR[15: 8] } :
                                                             { FCT3_CTR==0&&DATAI_CTR[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_CTR[ 7: 0] } ):
                            FCT3_CTR==1||FCT3_CTR==5 ? ( DADDR_CTR[1]==1   ? { FCT3_CTR==1&&DATAI_CTR[31] ? ALL1[31:16]:ALL0[31:16] , DATAI_CTR[31:16] } :
                                                             { FCT3_CTR==1&&DATAI_CTR[15] ? ALL1[31:16]:ALL0[31:16] , DATAI_CTR[15: 0] } ) :
                                 DATAI_CTR;
     
    // state invariant
    wire [31:0] INSTR_PC;
    wire [31:0] DATAI_PC;
    wire [31:0] DADDR_PC;
    wire LCC_PC = OPCODE_PC == `LCC;
    wire SCC_PC = OPCODE_PC == `SCC;
    wire MCC_PC = OPCODE_PC == `MCC;
    wire RCC_PC = OPCODE_PC == `RCC;

    wire [7:0]  OPCODE_PC = INSTR_PC[6:0];
    wire [31:0] U1REG_PC = REG1[INSTR_PC[18:15]];
    wire [31:0] DADDR_PC = (OPCODE_PC == `LCC || OPCODE_PC == `SCC) ? U1REG_PC + SIMM_PC : 0;
    wire [31:0] SIMM_PC  = OPCODE_PC==`SCC ? { INSTR_PC[31] ? ALL1[31:12]:ALL0[31:12], INSTR_PC[31:25],INSTR_PC[11:7] } : // s-type
                            OPCODE_PC==`BCC ? { INSTR_PC[31] ? ALL1[31:13]:ALL0[31:13], INSTR_PC[31],INSTR_PC[7],INSTR_PC[30:25],INSTR_PC[11:8],ALL0[0] } : // b-type
                            OPCODE_PC==`JAL ? { INSTR_PC[31] ? ALL1[31:21]:ALL0[31:21], INSTR_PC[31], INSTR_PC[19:12], INSTR_PC[20], INSTR_PC[30:21], ALL0[0] } : // j-type
                            OPCODE_PC==`LUI||
                            OPCODE_PC==`AUIPC ? { INSTR_PC[31:12], ALL0[11:0] } : // u-type
                                                { INSTR_PC[31] ? ALL1[31:12]:ALL0[31:12],  INSTR_PC[31:20] };
    wire [2:0]  FCT3_PC = INSTR_PC[14:12];
    wire [31:0] LDATA_PC = FCT3_PC==0||FCT3_PC==4 ? ( DADDR_PC[1:0]==3 ? { FCT3_PC==0&&DATAI_PC[31] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[31:24] } :
                                             DADDR_PC[1:0]==2 ? { FCT3_PC==0&&DATAI_PC[23] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[23:16] } :
                                             DADDR_PC[1:0]==1 ? { FCT3_PC==0&&DATAI_PC[15] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[15: 8] } :
                                                             { FCT3_PC==0&&DATAI_PC[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[ 7: 0] } ):
                            FCT3_PC==1||FCT3_PC==5 ? ( DADDR_PC[1]==1   ? { FCT3_PC==1&&DATAI_PC[31] ? ALL1[31:16]:ALL0[31:16] , DATAI_PC[31:16] } :
                                                             { FCT3_PC==1&&DATAI_PC[15] ? ALL1[31:16]:ALL0[31:16] , DATAI_PC[15: 0] } ) :
                                 DATAI_PC;    




    // dummy 32-bit words w/ all-0s and all-1s: 
    wire [31:0] ALL0  = 0;
    wire [31:0] ALL1  = -1;

`ifdef __THREADS__
    reg [`__THREADS__-1:0] XMODE = 0;     // thread ptr
    
    assign TPTR = XMODE;
`endif
    
    // pre-decode: IDATA is break apart as described in the RV32I specification

    reg [31:0] XIDATA;

    `ifdef VERIFICATION
        reg XLUI, XAUIPC, XJAL, XJALR, XBCC, XLCC, XSCC, XMCC, XRCC, XMAC, XRES; //, XFCC, XCCC;
    `else
        reg XLUI, XAUIPC, XJAL, XJALR, XBCC, XLCC, XSCC, XMCC, XRCC, XMAC, XRES; //, XFCC, XCCC;
    `endif

    reg [31:0] XSIMM;
    reg [31:0] XUIMM;

    // `ifdef VERIFICATION
    //     initial begin
    //         XIDATA = 0;
    //         XLUI = 0; 
    //         XAUIPC = 0; 
    //         XJAL = 0;
    //         XJALR = 0;
    //         XBCC = 0;
    //         XLCC = 0;
    //         XSCC = 0;
    //         XMCC = 0;
    //         XRCC = 0;
    //         XMAC = 0;
    //         XSIMM = 0;
    //         XUIMM = 0;
    //     end
    // `endif
    wire decode = XRES ? 0 : HLT ? 0 : FLUSH ? 0  : 1;
    wire [31:0] XIDATA_wire = XRES ? 0 : HLT ? XIDATA : FLUSH ? 0  : IDATA;
    reg decode_reg;
    always@(posedge CLK)
    begin
        decode_reg <= XRES ? 0 : HLT ? 0 : FLUSH ? 0  : 1;

        XIDATA <= XRES ? 0 : HLT ? XIDATA : FLUSH ? 0  : IDATA;
        
        XLUI   <= XRES ? 0 : HLT ? XLUI : FLUSH ? 0    : IDATA[6:0]==`LUI;
        XAUIPC <= XRES ? 0 : HLT ? XAUIPC : FLUSH ? 0  : IDATA[6:0]==`AUIPC;
        XJAL   <= XRES ? 0 : HLT ? XJAL : FLUSH ? 0    : IDATA[6:0]==`JAL;
        XJALR  <= XRES ? 0 : HLT ? XJALR : FLUSH ? 0   : IDATA[6:0]==`JALR;        

        XBCC   <= XRES ? 0 : HLT ? XBCC : FLUSH ? 0    : IDATA[6:0]==`BCC;
        XLCC   <= XRES ? 0 : HLT ? XLCC : FLUSH ? 0    : IDATA[6:0]==`LCC;
        XSCC   <= XRES ? 0 : HLT ? XSCC : FLUSH ? 0    : IDATA[6:0]==`SCC;
        XMCC   <= XRES ? 0 : HLT ? XMCC : FLUSH ? 0    : IDATA[6:0]==`MCC;

        XRCC   <= XRES ? 0 : HLT ? XRCC : FLUSH ? 0    : IDATA[6:0]==`RCC;
        XMAC   <= XRES ? 0 : HLT ? XMAC : FLUSH ? 0    : IDATA[6:0]==`MAC;
        //XFCC   <= XRES ? 0 : HLT ? XFCC   : IDATA[6:0]==`FCC;
        //XCCC   <= XRES ? 0 : HLT ? XCCC   : IDATA[6:0]==`CCC;

        // signal extended immediate, according to the instruction type:
        
        XSIMM  <= XRES ? 0 : HLT ? XSIMM : FLUSH ? 0 :
                 IDATA[6:0]==`SCC ? { IDATA[31] ? ALL1[31:12]:ALL0[31:12], IDATA[31:25],IDATA[11:7] } : // s-type
                 IDATA[6:0]==`BCC ? { IDATA[31] ? ALL1[31:13]:ALL0[31:13], IDATA[31],IDATA[7],IDATA[30:25],IDATA[11:8],ALL0[0] } : // b-type
                 IDATA[6:0]==`JAL ? { IDATA[31] ? ALL1[31:21]:ALL0[31:21], IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0] } : // j-type
                 IDATA[6:0]==`LUI||
                 IDATA[6:0]==`AUIPC ? { IDATA[31:12], ALL0[11:0] } : // u-type
                                      { IDATA[31] ? ALL1[31:12]:ALL0[31:12], IDATA[31:20] }; // i-type
        // non-signal extended immediate, according to the instruction type:

        XUIMM  <= XRES ? 0: HLT ? XUIMM : FLUSH ? 0 :
                 IDATA[6:0]==`SCC ? { ALL0[31:12], IDATA[31:25],IDATA[11:7] } : // s-type
                 IDATA[6:0]==`BCC ? { ALL0[31:13], IDATA[31],IDATA[7],IDATA[30:25],IDATA[11:8],ALL0[0] } : // b-type
                 IDATA[6:0]==`JAL ? { ALL0[31:21], IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0] } : // j-type
                 IDATA[6:0]==`LUI||
                 IDATA[6:0]==`AUIPC ? { IDATA[31:12], ALL0[11:0] } : // u-type
                                      { ALL0[31:12], IDATA[31:20] }; // i-type
    end

    // decode: after XIDATA
`ifdef __3stages__3STAGE__
    reg [1:0] FLUSH ;  // flush instruction pipeline
`else
    reg FLUSH ;  // flush instruction pipeline
`endif

`ifdef __THREADS__    
    `ifdef __RV32E__
    
        `ifdef VERIFICATION
            reg [`__THREADS__+3:0] RESMODE = -1;
        `else
            reg [`__THREADS__+3:0] RESMODE = 0;
        `endif

        wire [`__THREADS__+3:0] DPTR   = XRES ? RESMODE : { XMODE, XIDATA[10: 7] }; // set SP_RESET when RES==1
        wire [`__THREADS__+3:0] S1PTR  = { XMODE, XIDATA[18:15] };
        wire [`__THREADS__+3:0] S2PTR  = { XMODE, XIDATA[23:20] };
    `else
    
        `ifdef VERIFICATION
            reg [`__THREADS__+4:0] RESMODE = 0;
        `else
            reg [`__THREADS__+4:0] RESMODE = -1;
        `endif

        wire [`__THREADS__+4:0] DPTR   = XRES ? RESMODE : { XMODE, XIDATA[11: 7] }; // set SP_RESET when RES==1
        wire [`__THREADS__+4:0] S1PTR  = { XMODE, XIDATA[19:15] };
        wire [`__THREADS__+4:0] S2PTR  = { XMODE, XIDATA[24:20] };
    `endif
`else
    `ifdef __RV32E__    
    
        `ifdef VERIFICATIONS1PTR
            reg [3:0] RESMODE ;
        `else
            reg [3:0] RESMODE ;
        `endif
    
        wire [3:0] DPTR   = XRES ? RESMODE : XIDATA[10: 7]; // set SP_RESET when RES==1
        wire [3:0] S1PTR  = XIDATA[18:15];
        wire [3:0] S2PTR  = XIDATA[23:20];
    `else

        `ifdef VERIFICATION
            reg [4:0] RESMODE;
        `else
            reg [4:0] RESMODE;
        `endif
    
        wire [4:0] DPTR   = XRES ? RESMODE : XIDATA[11: 7]; // set SP_RESET when RES==1
        wire [4:0] S1PTR  = XIDATA[19:15];
        wire [4:0] S2PTR  = XIDATA[24:20];    
    `endif
`endif

    wire [6:0] OPCODE = FLUSH ? 0 : XIDATA[6:0];
    wire [2:0] FCT3   = XIDATA[14:12];
    wire [6:0] FCT7   = XIDATA[31:25];

    wire [31:0] SIMM  = XSIMM;
    wire [31:0] UIMM  = XUIMM;
    
    // main opcode decoder:
                                
    wire    LUI = FLUSH ? 0 : XLUI;   // OPCODE==7'b0110111;
    wire  AUIPC = FLUSH ? 0 : XAUIPC; // OPCODE==7'b0010111;
    wire    JAL = FLUSH ? 0 : XJAL;   // OPCODE==7'b1101111;
    wire   JALR = FLUSH ? 0 : XJALR;  // OPCODE==7'b1100111;
    
    wire    BCC = FLUSH ? 0 : XBCC; // OPCODE==7'b1100011; //FCT3
    wire    LCC = FLUSH ? 0 : XLCC; // OPCODE==7'b0000011; //FCT3
    wire    SCC = FLUSH ? 0 : XSCC; // OPCODE==7'b0100011; //FCT3
    wire    MCC = FLUSH ? 0 : XMCC; // OPCODE==7'b0010011; //FCT3
    
    wire    RCC = FLUSH ? 0 : XRCC; // OPCODE==7'b0110011; //FCT3
    wire    MAC = FLUSH ? 0 : XMAC; // OPCODE==7'b0110011; //FCT3
    //wire    FCC = FLUSH ? 0 : XFCC; // OPCODE==7'b0001111; //FCT3
    //wire    CCC = FLUSH ? 0 : XCCC; // OPCODE==7'b1110011; //FCT3

`ifdef __THREADS__
    `ifdef __3stages__3STAGE__
        reg [31:0] NXPC2 [0:(2**`__THREADS__)-1];       // 32-bit program counter t+2
    `endif

    `ifdef __RV32E__
        reg [31:0] REG1 [0:16*(2**`__THREADS__)-1];	// general-purpose 16x32-bit registers (s1)
        reg [31:0] REG2 [0:16*(2**`__THREADS__)-1];	// general-purpose 16x32-bit registers (s2)
    `else
        reg [31:0] REG1 [0:32*(2**`__THREADS__)-1];	// general-purpose 32x32-bit registers (s1)
        reg [31:0] REG2 [0:32*(2**`__THREADS__)-1];	// general-purpose 32x32-bit registers (s2)    
    `endif
`else
    `ifdef __3stages__3STAGE__
        reg [31:0] NXPC2;       // 32-bit program counter t+2

        // `ifdef VERIFICATION
        //     initial begin
        //         NXPC2 = `__RESETPC__;
        //     end
        // `endif
    `endif

    `ifdef __RV32E__
        reg [31:0] REG1 [0:15];	// general-purpose 16x32-bit registers (s1)
        reg [31:0] REG2 [0:15];	// general-purpose 16x32-bit registers (s2)

        // `ifdef VERIFICATION
        //     integer i_REGS;
        //     initial
        //         for(i_REGS=0;i_REGS<16;i_REGS=i_REGS+1) begin
        //             REG1[i_REGS] = 32'b00000000000000000000000000000000;
        //             REG2[i_REGS] = 32'b00000000000000000000000000000000;
        //         end
        // `endif

    `else
        reg [31:0] REG1 [0:31];	// general-purpose 32x32-bit registers (s1)
        reg [31:0] REG2 [0:31];	// general-purpose 32x32-bit registers (s2)

        // `ifdef VERIFICATION
        //     integer i_REGS;
        //     initial
        //         for(i_REGS=0;i_REGS<32;i_REGS=i_REGS+1) begin
        //             REG1[i_REGS] = 32'b00000000000000000000000000000000;
        //             REG2[i_REGS] = 32'b00000000000000000000000000000000;
        //         end
        // `endif
    `endif
`endif

    reg [31:0] NXPC;        // 32-bit program counter t+1
    reg [31:0] PC;		    // 32-bit program counter t+0

    // `ifdef VERIFICATION
    //         initial begin
    //             PC = `__RESETPC__;
    //             NXPC = `__RESETPC__;
    //         end
    // `endif

    // source-1 and source-1 register selection

    wire          [31:0] U1REG = REG1[S1PTR];
    wire          [31:0] U2REG = REG2[S2PTR];

    wire signed   [31:0] S1REG = U1REG;
    wire signed   [31:0] S2REG = U2REG;
    

    // L-group of instructions (OPCODE==7'b0000011)

`ifdef __FLEXBUZZ__

    wire [31:0] LDATA = FCT3[1:0]==0 ? { FCT3[2]==0&&DATAI[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[ 7: 0] } :
                        FCT3[1:0]==1 ? { FCT3[2]==0&&DATAI[15] ? ALL1[31:16]:ALL0[31:16] , DATAI[15: 0] } :
                                        DATAI;
`else
    wire [31:0] LDATA = FCT3==0||FCT3==4 ? ( DADDR[1:0]==3 ? { FCT3==0&&DATAI[31] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[31:24] } :
                                             DADDR[1:0]==2 ? { FCT3==0&&DATAI[23] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[23:16] } :
                                             DADDR[1:0]==1 ? { FCT3==0&&DATAI[15] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[15: 8] } :
                                                             { FCT3==0&&DATAI[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[ 7: 0] } ):
                        FCT3==1||FCT3==5 ? ( DADDR[1]==1   ? { FCT3==1&&DATAI[31] ? ALL1[31:16]:ALL0[31:16] , DATAI[31:16] } :
                                                             { FCT3==1&&DATAI[15] ? ALL1[31:16]:ALL0[31:16] , DATAI[15: 0] } ) :
                                             DATAI;
`endif

    // S-group of instructions (OPCODE==7'b0100011)

`ifdef __FLEXBUZZ__

    wire [31:0] SDATA = U2REG; /* FCT3==0 ? { ALL0 [31: 8], U2REG[ 7:0] } :
                        FCT3==1 ? { ALL0 [31:16], U2REG[15:0] } :
                                    U2REG;*/
`else
    wire [31:0] SDATA = FCT3==0 ? ( DADDR[1:0]==3 ? { U2REG[ 7: 0], ALL0 [23:0] } : 
                                    DADDR[1:0]==2 ? { ALL0 [31:24], U2REG[ 7:0], ALL0[15:0] } : 
                                    DADDR[1:0]==1 ? { ALL0 [31:16], U2REG[ 7:0], ALL0[7:0] } :
                                                    { ALL0 [31: 8], U2REG[ 7:0] } ) :
                        FCT3==1 ? ( DADDR[1]==1   ? { U2REG[15: 0], ALL0 [15:0] } :
                                                    { ALL0 [31:16], U2REG[15:0] } ) :
                                    U2REG;
`endif

    // C-group not implemented yet!
    
    wire [31:0] CDATA = 0;	// status register istructions not implemented yet

    // RM-group of instructions (OPCODEs==7'b0010011/7'b0110011), merged! src=immediate(M)/register(R)

    wire signed [31:0] S2REGX = XMCC ? SIMM : S2REG;
    wire        [31:0] U2REGX = XMCC ? UIMM : U2REG;

    wire [31:0] RMDATA = FCT3==7 ? U1REG&S2REGX :
                         FCT3==6 ? U1REG|S2REGX :
                         FCT3==4 ? U1REG^S2REGX :
                         FCT3==3 ? U1REG<U2REGX?1:0 : // unsigned
                         FCT3==2 ? S1REG<S2REGX?1:0 : // signed
                         FCT3==0 ? (XRCC&&FCT7[5] ? U1REG-U2REGX : U1REG+S2REGX) :
                         FCT3==1 ? U1REG<<U2REGX[4:0] :                         
                         //FCT3==5 ? 
                         !FCT7[5] ? U1REG>>U2REGX[4:0] :
`ifdef MODEL_TECH        
                         FCT7[5] ? -((-U1REG)>>U2REGX[4:0]; // workaround for modelsim
`else
                                   $signed(S1REG>>>U2REGX[4:0]);  // (FCT7[5] ? U1REG>>>U2REG[4:0] : 
`endif                        

`ifdef __MAC16X16__

    // MAC instruction rd += s1*s2 (OPCODE==7'b1111111)
    // 
    // 0000000 01100 01011 100 01100 0110011 xor a2,a1,a2
    // 0000000 01010 01100 000 01010 0110011 add a0,a2,a0
    // 0000000 01100 01011 000 01010 1111111 mac a0,a1,a2
    // 
    // 0000 0000 1100 0101 1000 0101 0111 1111 = 00c5857F

    wire signed [15:0] K1TMP = S1REG[15:0];
    wire signed [15:0] K2TMP = S2REG[15:0];
    wire signed [31:0] KDATA = K1TMP*K2TMP;

`endif

    // J/B-group of instructions (OPCODE==7'b1100011)
    
    wire BMUX       = BCC==1 && (
                          FCT3==4 ? S1REG< S2REGX : // blt
                          FCT3==5 ? S1REG>=S2REG : // bge
                          FCT3==6 ? U1REG< U2REGX : // bltu
                          FCT3==7 ? U1REG>=U2REG : // bgeu
                          FCT3==0 ? !(U1REG^S2REGX) : //U1REG==U2REG : // beq
                          /*FCT3==1 ? */ U1REG^S2REGX); //U1REG!=U2REG); // bne
                                    //0);

    wire [31:0] PCSIMM = PC+SIMM;
    wire        JREQ = (JAL||JALR||BMUX);
    wire [31:0] JVAL = SIMM + (JALR ? U1REG : PC);//JALR ? DADDR : PCSIMM; // SIMM + (JALR ? U1REG : PC);


    // for pipeline invariants
    wire [31:0] XIDATA_next = FLUSH ? 0 : XIDATA;
    reg writeback_reg;
    wire writeback =  XRES ? 0 :           
                       HLT ? 0 : 1;       // halt
                //      !DPTR ? 0 :                // x0 = 0, always!
                //      AUIPC ? 0 :
                //       JAL||
                //       JALR ? 0 :
                //        LUI ? 0 :
                //        LCC ? 1 :
                //   MCC||RCC ? 0:
                //              0;
    reg         retire;   
    wire filter_pc_reg = decode_reg || (! FLUSH );
    wire filter_pc = decode || (! FLUSH_wire);
    wire FLUSH_wire = XRES ? 1 : HLT ? FLUSH :        // reset and halt
                       (JAL||JALR||BMUX); 

    reg [31:0] DelayU1REG;
    reg DelayBCC;
    reg [31:0] DelayU2REG;
    reg DelayJALR;
    reg [31:0] DelayLDATA;
    reg DelayLCC;
    reg [31:0] DelayDADDR;
    reg DelaySCC;
    reg [31:0] DelayXIDATA_next;

    reg [31:0] PC_retire;
    wire [31:0] PC_flush = FLUSH ? 0 : PC;
    
    always@(posedge CLK) begin

        PC_retire <= HLT ? PC_retire : FLUSH ? PC_retire : PC;
        
        DelayLDATA <= HLT? DelayLDATA : LDATA;
        DelayLCC <= HLT? DelayLCC : LCC;
        DelayDADDR <= HLT? DelayDADDR : DADDR;
        DelaySCC <= HLT? DelaySCC : SCC;
        DelayXIDATA_next <= HLT? DelayXIDATA_next : XIDATA_next;
        DelayU1REG <= HLT? DelayU1REG : U1REG;
        DelayBCC <= HLT? DelayBCC : BCC;
        DelayU2REG <= HLT? DelayU2REG : U2REG;
        DelayJALR <= HLT? DelayJALR : JALR;

        writeback_reg <=  XRES ? 0 :           
                       HLT ? 0 : 1;      // halt
                //      !DPTR ? 0 :                // x0 = 0, always!
                //      AUIPC ? 0 :
                //       JAL||
                //       JALR ? 0 :
                //        LUI ? 0 :
                //        LCC ? 1 :
                //   MCC||RCC ? 0:
                //              0;

        retire   <= /*XRES ? `__RESETPC__ :*/ HLT ? 0 : 1; 

        RESMODE <= RES ? -1 : RESMODE ? RESMODE-1 : 0;
        
        XRES <= |RESMODE;


`ifdef __3stages__3STAGE__
	    FLUSH <= XRES ? 2 : HLT ? FLUSH :        // reset and halt                              
	                       FLUSH ? FLUSH-1 :                           
	                       (JAL||JALR||BMUX) ? 2 : 0;  // flush the pipeline!
`else
        FLUSH <= XRES ? 1 : HLT ? FLUSH :        // reset and halt
                       (JAL||JALR||BMUX);  // flush the pipeline!
`endif

`ifdef __RV32E__
        REG1[DPTR] <=   XRES ? (RESMODE[3:0]==2 ? `__RESETSP__ : 0)  :        // reset sp
`else
        REG1[DPTR] <=   XRES ? (RESMODE[4:0]==2 ? `__RESETSP__ : 0)  :        // reset sp
`endif
                       HLT ? REG1[DPTR] :        // halt
                     !DPTR ? 0 :                // x0 = 0, always!
                     AUIPC ? PCSIMM :
                      JAL||
                      JALR ? NXPC :
                       LUI ? SIMM :
                       LCC ? LDATA :
                  MCC||RCC ? RMDATA:
`ifdef __MAC16X16__                  
                       MAC ? REG2[DPTR]+KDATA :
`endif
                       //CCC ? CDATA : 
                             REG1[DPTR];
`ifdef __RV32E__
        REG2[DPTR] <=   XRES ? (RESMODE[3:0]==2 ? `__RESETSP__ : 0) :        // reset sp
`else        
        REG2[DPTR] <=   XRES ? (RESMODE[4:0]==2 ? `__RESETSP__ : 0) :        // reset sp
`endif        
                       HLT ? REG2[DPTR] :        // halt
                     !DPTR ? 0 :                // x0 = 0, always!
                     AUIPC ? PCSIMM :
                      JAL||
                      JALR ? NXPC :
                       LUI ? SIMM :
                       LCC ? LDATA :
                  MCC||RCC ? RMDATA:
`ifdef __MAC16X16__
                       MAC ? REG2[DPTR]+KDATA :
`endif                       
                       //CCC ? CDATA : 
                             REG2[DPTR];

`ifdef __3stages__3STAGE__

    `ifdef __THREADS__

        NXPC <= /*XRES ? `__RESETPC__ :*/ HLT ? NXPC : NXPC2[XMODE];

        NXPC2[XRES ? RESMODE[`__THREADS__-1:0] : XMODE] <=  XRES ? `__RESETPC__ : HLT ? NXPC2[XMODE] :   // reset and halt
                                      JREQ ? JVAL :                            // jmp/bra
	                                         NXPC2[XMODE]+4;                   // normal flow

        XMODE <= XRES ? 0 : HLT ? XMODE :        // reset and halt
                            JAL ? XMODE+1 : XMODE;
	             //XMODE==0/*&& IREQ*/&&(JAL||JALR||BMUX) ? 1 :         // wait pipeflush to switch to irq
                 //XMODE==1/*&&!IREQ*/&&(JAL||JALR||BMUX) ? 0 : XMODE;  // wait pipeflush to return from irq

    `else
        NXPC <= /*XRES ? `__RESETPC__ :*/ HLT ? NXPC : FLUSH ? NXPC : NXPC2;
	
	    NXPC2 <=  XRES ? `__RESETPC__ : HLT ? NXPC2 :   // reset and halt
	                 JREQ ? JVAL :                    // jmp/bra
	                        NXPC2+4;                   // normal flow

    `endif

`else
        NXPC <= XRES ? `__RESETPC__ : HLT ? NXPC :   // reset and halt
              JREQ ? JVAL :                   // jmp/bra
                     NXPC+4;                   // normal flow
`endif
        PC   <= /*XRES ? `__RESETPC__ :*/ HLT ? PC : FLUSH ? PC : NXPC; // current program counter

    end

    // IO and memory interface

    assign DATAO = SCC ? SDATA : 0; //SDATA;
    assign DADDR =  (SCC||LCC) ? U1REG + SIMM : 0;//U1REG + SIMM;

    // based in the Scc and Lcc   

`ifdef __FLEXBUZZ__
    assign RW      = !SCC;
    assign DLEN[0] = (SCC||LCC)&&FCT3[1:0]==0;
    assign DLEN[1] = (SCC||LCC)&&FCT3[1:0]==1;
    assign DLEN[2] = (SCC||LCC)&&FCT3[1:0]==2;
`else
    assign RD = LCC;
    assign WR = SCC;
    assign BE = FCT3==0||FCT3==4 ? ( DADDR[1:0]==3 ? 4'b1000 : // sb/lb
                                     DADDR[1:0]==2 ? 4'b0100 : 
                                     DADDR[1:0]==1 ? 4'b0010 :
                                                     4'b0001 ) :
                FCT3==1||FCT3==5 ? ( DADDR[1]==1   ? 4'b1100 : // sh/lh
                                                     4'b0011 ) :
                                                     4'b1111; // sw/lw
`endif

`ifdef __3stages__3STAGE__
    `ifdef __THREADS__
        assign IADDR = NXPC2[XMODE];
    `else
        assign IADDR = NXPC2;
    `endif    
`else
    assign IADDR = NXPC;
`endif

    assign IDLE = |FLUSH;

    assign DEBUG = { XRES, |FLUSH, SCC, LCC };

endmodule
