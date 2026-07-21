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

`include "config_3stages.vh"

module darkriscv_3stages
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
    wire [31:0] U1REG_CTR = REG1[(31 - INSTR_CTR[18:15]) * 32+:32];
    wire [31:0] DADDR_CTR = (OPCODE_CTR == `LCC || OPCODE_CTR == `SCC) ? U1REG_CTR + SIMM_CTR : 0;
    wire [31:0] SIMM_CTR  = OPCODE_CTR==`SCC ? { INSTR_CTR[31] ? ALL1[31:12]:ALL0[31:12], INSTR_CTR[31:25],INSTR_CTR[11:7] } : // s-type
                            OPCODE_CTR==`BCC ? { INSTR_CTR[31] ? ALL1[31:13]:ALL0[31:13], INSTR_CTR[31],INSTR_CTR[7],INSTR_CTR[30:25],INSTR_CTR[11:8],ALL0[0] } : // b-type
                            OPCODE_CTR==`JAL ? { INSTR_CTR[31] ? ALL1[31:21]:ALL0[31:21], INSTR_CTR[31], INSTR_CTR[19:12], INSTR_CTR[20], INSTR_CTR[30:21], ALL0[0] } : // j-type
                            OPCODE_CTR==`LUI||
                            OPCODE_CTR==`AUIPC ? { INSTR_CTR[31:12], ALL0[11:0] } : // u-type
                                                { INSTR_CTR[31] ? ALL1[31:12]:ALL0[31:12],  INSTR_CTR[31:20] };
    wire [2:0] FCT3_CTR = INSTR_CTR[14:12];
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
    wire MCC_PC = OPCODE_PC == `MCC; // OPCODE==7'b0010011; //FCT3
    wire RCC_PC = OPCODE_PC == `RCC; // OPCODE==7'b0110011; //FCT3

    wire [7:0]  OPCODE_PC = INSTR_PC[6:0];
    wire [31:0] U1REG_PC = REG1[(31 - INSTR_PC[18:15]) * 32+:32];
    wire [31:0] DADDR_PC = (OPCODE_PC == `LCC || OPCODE_PC == `SCC) ? U1REG_PC + SIMM_PC : 0;
    wire [31:0] SIMM_PC  = OPCODE_PC==`SCC ? { INSTR_PC[31] ? ALL1[31:12]:ALL0[31:12], INSTR_PC[31:25],INSTR_PC[11:7] } : // s-type
                            OPCODE_PC==`BCC ? { INSTR_PC[31] ? ALL1[31:13]:ALL0[31:13], INSTR_PC[31],INSTR_PC[7],INSTR_PC[30:25],INSTR_PC[11:8],ALL0[0] } : // b-type
                            OPCODE_PC==`JAL ? { INSTR_PC[31] ? ALL1[31:21]:ALL0[31:21], INSTR_PC[31], INSTR_PC[19:12], INSTR_PC[20], INSTR_PC[30:21], ALL0[0] } : // j-type
                            OPCODE_PC==`LUI||
                            OPCODE_PC==`AUIPC ? { INSTR_PC[31:12], ALL0[11:0] } : // u-type
                                                { INSTR_PC[31] ? ALL1[31:12]:ALL0[31:12],  INSTR_PC[31:20] };
    wire [2:0] FCT3_PC = INSTR_PC[14:12];
    wire [31:0] LDATA_PC = FCT3_PC==0||FCT3_PC==4 ? ( DADDR_PC[1:0]==3 ? { FCT3_PC==0&&DATAI_PC[31] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[31:24] } :
                                             DADDR_PC[1:0]==2 ? { FCT3_PC==0&&DATAI_PC[23] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[23:16] } :
                                             DADDR_PC[1:0]==1 ? { FCT3_PC==0&&DATAI_PC[15] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[15: 8] } :
                                                             { FCT3_PC==0&&DATAI_PC[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI_PC[ 7: 0] } ):
                            FCT3_PC==1||FCT3_PC==5 ? ( DADDR_PC[1]==1   ? { FCT3_PC==1&&DATAI_PC[31] ? ALL1[31:16]:ALL0[31:16] , DATAI_PC[31:16] } :
                                                             { FCT3_PC==1&&DATAI_PC[15] ? ALL1[31:16]:ALL0[31:16] , DATAI_PC[15: 0] } ) :
                                 DATAI_PC;    



////////////////////////////////////////
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
    //         //XIDATA = 0;
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
    wire [31:0] XIDATA_wire = XRES ? 0 : HLT ? XIDATA : FLUSH ? 0  : IDATA;
    wire decode = XRES ? 0 : HLT ? 0 : FLUSH ? 0  : 1;
    reg decode_reg;
    always@(posedge CLK)
    begin
        decode_reg <= (XRES ? 0 : (HLT ? decode_reg : (FLUSH ? 0 : 1)));
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


	wire legal;
	assign legal = ! decode_reg || ( XLUI 
									|| XAUIPC 
									|| XJAL 
									|| (XJALR && XIDATA[14:12] == 3'b000)
								 	|| XBCC && ( XIDATA[14:12] == 3'b000 || XIDATA[14:12] == 3'b001 || XIDATA[14:12] == 3'b100 || XIDATA[14:12] == 3'b101 || XIDATA[14:12] == 3'b110 || XIDATA[14:12] == 3'b111 )
									|| XLCC && ( XIDATA[14:12] == 3'b000 || XIDATA[14:12] == 3'b001 || XIDATA[14:12] == 3'b100 || XIDATA[14:12] == 3'b010 || XIDATA[14:12] == 3'b101 )
									|| XSCC && ( XIDATA[14:12] == 3'b000 || XIDATA[14:12] == 3'b001 || XIDATA[14:12] == 3'b010 )
									|| XRCC && ( ( XIDATA[14:12] == 3'b000 && XIDATA[31:25] == 7'b0000000 ) || ( XIDATA[14:12] == 3'b000 && XIDATA[31:25] == 7'b0100000 ) ||  ( XIDATA[14:12] == 3'b101 && XIDATA[31:25] == 7'b0100000 ) || ( XIDATA[14:12] == 3'b101 && XIDATA[31:25] == 7'b0100000 ) )
									|| XMCC && ( ( XIDATA[14:12] == 3'b001 && XIDATA[31:25] == 7'b0000000 ) || ( XIDATA[14:12] == 3'b101 && XIDATA[31:25] == 7'b0100000 ) ||  ( XIDATA[14:12] == 3'b101 && XIDATA[31:25] == 7'b0000000 ) )
								 ) ; 
								 
	wire decode_BCC;
	assign decode_BCC =  BCC && ( XIDATA[14:12] == 3'b000 || XIDATA[14:12] == 3'b001 || XIDATA[14:12] == 3'b100 || XIDATA[14:12] == 3'b101 || XIDATA[14:12] == 3'b110 || XIDATA[14:12] == 3'b111 );
	wire decode_JAL;
	assign decode_JAL =  JAL;
	wire decode_JALR;
	assign decode_JALR = (JALR && XIDATA[14:12] == 3'b000);
	wire decode_branch_taken;
	assign decode_branch_taken = JREQ;

	
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
    
        `ifdef VERIFICATION
            reg [3:0] RESMODE ;
        `else
            reg [3:0] RESMODE ;
        `endif
    
        wire [3:0] DPTR   = XRES ? RESMODE : XIDATA[10: 7]; // set SP_RESET when RES==1
        //wire [3:0] DPTR   = XRES ? RESMODE : FLUSH ? 0 : XIDATA[10: 7]; // set SP_RESET when RES==1
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
        reg [1023:0] REG1;	// general-purpose 32x32-bit registers (s1)
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
        reg [1023:0] REG1;	// general-purpose 32x32-bit registers (s1)
        // reg [31:0] REG2 [0:31];	// general-purpose 32x32-bit registers (s2)

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

    wire          [31:0] U1REG = REG1[(31 - S1PTR) * 32+:32];
    wire          [31:0] U2REG = REG1[(31 - S2PTR) * 32+:32];

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

                        
    wire filter_pc_reg = decode_reg || (! FLUSH );
    wire filter_pc = decode || (! FLUSH_wire);
    wire [1:0] FLUSH_wire = XRES ? 2 : HLT ? FLUSH :        // reset and halt                              
	                       FLUSH ? FLUSH-1 :                           
	                       (JAL||JALR||BMUX) ? 2 : 0;
    // for contracts
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
    // reg [31:0] PC_filtered_reg;
    // wire [31:0] PC_filtered = FLUSH ? PC_filtered_reg : PC;
    // wire [31:0] PC_filtered = FLUSH ? PC_retire : PC;
    wire [31:0] PC_flush = FLUSH ? 0 : PC;


    always@(posedge CLK) begin
        // PC_filtered_reg <= PC_filtered;

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

REG1[(31 - DPTR) * 32+:32] <= (XRES ? (RESMODE[4:0] == 2 ? 32'd0 : 0) : (HLT ? REG1[(31 - DPTR) * 32+:32] : (!DPTR ? 0 : (AUIPC ? PCSIMM : (JAL || JALR ? NXPC : (LUI ? SIMM : (LCC ? LDATA : (MCC || RCC ? RMDATA : REG1[(31 - DPTR) * 32+:32]))))))));

// REG2[DPTR] <= (XRES ? (RESMODE[4:0] == 2 ? 32'd0 : 0) : (HLT ? REG2[DPTR] : (!DPTR ? 0 : (AUIPC ? PCSIMM : (JAL || JALR ? NXPC : (LUI ? SIMM : (LCC ? LDATA : (MCC || RCC ? RMDATA : REG2[DPTR]))))))));

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


///////////////////////////////// RVFI ////////////////////////////
	wire rvfi_valid;
	// Trace: darkriscv_2stages.v:532:5
	wire [63:0] rvfi_order;
	// Trace: darkriscv_2stages.v:533:5
	wire [31:0] rvfi_insn;
	// Trace: darkriscv_2stages.v:534:5
	wire rvfi_trap;
	// Trace: darkriscv_2stages.v:535:5
	wire rvfi_halt;
	// Trace: darkriscv_2stages.v:536:5
	wire rvfi_intr;
	// Trace: darkriscv_2stages.v:537:5
	wire [1:0] rvfi_mode;
	// Trace: darkriscv_2stages.v:538:5
	wire [1:0] rvfi_ixl;
	// Trace: darkriscv_2stages.v:539:5
	wire [4:0] rvfi_rs1_addr;
	// Trace: darkriscv_2stages.v:540:5
	wire [4:0] rvfi_rs2_addr;
	// Trace: darkriscv_2stages.v:541:5
	wire [4:0] rvfi_rs3_addr;
	// Trace: darkriscv_2stages.v:542:5
	wire [31:0] rvfi_rs1_rdata;
	// Trace: darkriscv_2stages.v:543:5
	wire [31:0] rvfi_rs2_rdata;
	// Trace: darkriscv_2stages.v:544:5
	wire [31:0] rvfi_rs3_rdata;
	// Trace: darkriscv_2stages.v:545:5
	wire [4:0] rvfi_rd_addr;
	// Trace: darkriscv_2stages.v:546:5
	wire [31:0] rvfi_rd_wdata;
	// Trace: darkriscv_2stages.v:547:5
	wire [31:0] rvfi_pc_rdata;
	// Trace: darkriscv_2stages.v:548:5
	wire [31:0] rvfi_pc_wdata;
	// Trace: darkriscv_2stages.v:549:5
	wire [31:0] rvfi_mem_addr;
	// Trace: darkriscv_2stages.v:550:5
	wire [3:0] rvfi_mem_rmask;
	// Trace: darkriscv_2stages.v:551:5
	wire [3:0] rvfi_mem_wmask;
	// Trace: darkriscv_2stages.v:552:5
	wire [31:0] rvfi_mem_rdata;
	// Trace: darkriscv_2stages.v:553:5
	wire [31:0] rvfi_mem_wdata;
	// Trace: darkriscv_2stages.v:557:5
	reg [1023:0] rvfi_regfile;
	// Trace: darkriscv_2stages.v:559:5
	always @(*)
		if (retire_wire || XRES) begin
			rvfi_regfile = REG1;
			rvfi_regfile[(31 - DPTR) * 32+:32] = (XRES ? (RESMODE[4:0] == 2 ? 32'd0 : 0) : (HLT ? REG1[(31 - DPTR) * 32+:32] : (!DPTR ? 0 : (AUIPC ? PCSIMM : (JAL || JALR ? NXPC : (LUI ? SIMM : (LCC ? LDATA : (MCC || RCC ? RMDATA : REG1[(31 - DPTR) * 32+:32]))))))));
		end
	wire retire_wire;
	// Trace: darkriscv_2stages.v:583:5
	reg flushed;
	reg [2:0] resetted;
	assign retire_wire = ((HLT | flushed) | FLUSH ? 0 : (XRES || |resetted ? 0 : 1));
	// Trace: darkriscv_2stages.v:584:5
	wire retire;
	// Trace: darkriscv_2stages.v:585:5
	assign retire = rvfi_valid;
	// Trace: darkriscv_2stages.v:589:5
	// Trace: darkriscv_2stages.v:590:5
	always @(posedge CLK)
		// Trace: darkriscv_2stages.v:591:9
		if (FLUSH)
			// Trace: darkriscv_2stages.v:592:13
			flushed <= 1;
		else
			// Trace: darkriscv_2stages.v:594:13
			flushed <= 0;
	// Trace: darkriscv_2stages.v:598:5
	// Trace: darkriscv_2stages.v:599:5
	always @(posedge CLK)
		// // Trace: darkriscv_2stages.v:600:9
		// if (XRES)
		// 	// Trace: darkriscv_2stages.v:601:13
		// 	resetted <= 2'b11;
		// else
		// 	// Trace: darkriscv_2stages.v:603:13
		// 	if (resetted == 2'b11)
		// 		// Trace: darkriscv_2stages.v:604:17
		// 		resetted <= 2'b01;
		// 	else if (resetted == 2'b01)
		// 		// Trace: darkriscv_2stages.v:606:17
		// 		resetted <= 2'b00;
		resetted <= XRES ? 5 : resetted ? resetted - 1 : 0 ;
	// Trace: darkriscv_2stages.v:611:5
	reg [31:0] stalled_instruction ;
	// Trace: darkriscv_2stages.v:612:5
	always @(posedge CLK)
		// Trace: darkriscv_2stages.v:613:9
		if (RES)
			// Trace: darkriscv_2stages.v:614:13
			stalled_instruction <= 32'b00000000000000000000000000000000;
		else
			// Trace: darkriscv_2stages.v:616:13
			stalled_instruction <= (!retire_wire ? stalled_instruction : XIDATA);
	// Trace: darkriscv_2stages.v:619:5
	wire [31:0] instruction;
	// Trace: darkriscv_2stages.v:621:5
	assign instruction = (!retire_wire ? stalled_instruction : XIDATA);
	// Trace: darkriscv_2stages.v:624:5
	reg [1023:0] old_regfile;
	// Trace: darkriscv_2stages.v:625:5
	always @(posedge CLK)
		// Trace: darkriscv_2stages.v:626:9
		if (RES)
			// Trace: darkriscv_2stages.v:627:13
			old_regfile <= 0;
		else
			// Trace: darkriscv_2stages.v:629:13
			if (retire_wire || XRES)
				// Trace: darkriscv_2stages.v:630:17
				old_regfile <= rvfi_regfile;
	// Trace: darkriscv_2stages.v:634:5
	reg [31:0] old_pc;
	// Trace: darkriscv_2stages.v:635:5
	reg [31:0] next_pc;
	// wire [31:0] pc_wdata = (FLUSH ? NXPC + 4 : next_pc);
	wire [31:0] pc_wdata = (FLUSH ? JVAL : NXPC);
	always @(posedge CLK)
		// Trace: darkriscv_2stages.v:636:9
		if (RES)
			// Trace: darkriscv_2stages.v:637:13
			old_pc <= 4;
		else
			// Trace: darkriscv_2stages.v:639:13
			if (retire_wire)
				// Trace: darkriscv_2stages.v:640:17
				old_pc <= pc_wdata;
	// Trace: darkriscv_2stages.v:645:5
	// Trace: darkriscv_2stages.v:647:5
	always @(posedge CLK)
		// Trace: darkriscv_2stages.v:648:9
		next_pc <= NXPC;
	// Trace: darkriscv_2stages.v:650:5
	// Trace: darkriscv_2stages.v:652:5
	reg mem_req ;
	// Trace: darkriscv_2stages.v:653:5
	reg [31:0] mem_addr1;
	// Trace: darkriscv_2stages.v:654:5
	reg [31:0] mem_rdata;
	// Trace: darkriscv_2stages.v:655:5
	reg [31:0] mem_wdata;
	// Trace: darkriscv_2stages.v:656:5
	reg mem_we;
	// Trace: darkriscv_2stages.v:657:5
	reg [3:0] mem_be;
	// Trace: darkriscv_2stages.v:658:5
	always @(*)
		// Trace: darkriscv_2stages.v:659:9
		if (RES) begin
			// Trace: darkriscv_2stages.v:660:13
			mem_req = 0;
			// Trace: darkriscv_2stages.v:661:13
			mem_addr1 = 32'b00000000000000000000000000000000;
			// Trace: darkriscv_2stages.v:662:13
			mem_rdata = 32'b00000000000000000000000000000000;
			// Trace: darkriscv_2stages.v:663:13
			mem_wdata = 32'b00000000000000000000000000000000;
			// Trace: darkriscv_2stages.v:664:13
			mem_we = 0;
			// Trace: darkriscv_2stages.v:665:13
			mem_be = 4'b0000;
		end
		else begin
			// Trace: darkriscv_2stages.v:667:13
			mem_req = WR || RD;
			// Trace: darkriscv_2stages.v:668:13
			mem_addr1 = DADDR;
			// Trace: darkriscv_2stages.v:669:13
			mem_rdata = DATAI;
			// Trace: darkriscv_2stages.v:670:13
			mem_wdata = DATAO;
			// Trace: darkriscv_2stages.v:671:13
			mem_we = WR;
			// Trace: darkriscv_2stages.v:672:13
			mem_be = BE;
		end
	// Trace: darkriscv_2stages.v:676:5
	RVFI_3stage RVFI_3stage(
		.clock(CLK),
		.retire(retire_wire),
		.instruction(instruction),
		.old_regfile(old_regfile),
		.new_regfile(rvfi_regfile),
		.old_pc(old_pc),
		.new_pc(pc_wdata),
		.mem_req(mem_req),
		.mem_addr(mem_addr1),
		.mem_rdata(mem_rdata),
		.mem_wdata(mem_wdata),
		.mem_we(mem_we),
		.mem_be(mem_be),
		.rvfi_valid(rvfi_valid),
		.rvfi_order(rvfi_order),
		.rvfi_insn(rvfi_insn),
		.rvfi_trap(rvfi_trap),
		.rvfi_halt(rvfi_halt),
		.rvfi_intr(rvfi_intr),
		.rvfi_mode(rvfi_mode),
		.rvfi_ixl(rvfi_ixl),
		.rvfi_rs1_addr(rvfi_rs1_addr),
		.rvfi_rs2_addr(rvfi_rs2_addr),
		.rvfi_rs3_addr(rvfi_rs3_addr),
		.rvfi_rs1_rdata(rvfi_rs1_rdata),
		.rvfi_rs2_rdata(rvfi_rs2_rdata),
		.rvfi_rs3_rdata(rvfi_rs3_rdata),
		.rvfi_rd_addr(rvfi_rd_addr),
		.rvfi_rd_wdata(rvfi_rd_wdata),
		.rvfi_pc_rdata(rvfi_pc_rdata),
		.rvfi_pc_wdata(rvfi_pc_wdata),
		.rvfi_mem_addr(rvfi_mem_addr),
		.rvfi_mem_rmask(rvfi_mem_rmask),
		.rvfi_mem_wmask(rvfi_mem_wmask),
		.rvfi_mem_rdata(rvfi_mem_rdata),
		.rvfi_mem_wdata(rvfi_mem_wdata)
	);
	// Trace: darkriscv_2stages.v:718:2
	wire rvfi_lui_ctr;
	// Trace: darkriscv_2stages.v:719:2
	assign rvfi_lui_ctr = rvfi_insn[6:0] == 7'h37;
	// Trace: darkriscv_2stages.v:720:2
	wire rvfi_auipc_ctr;
	// Trace: darkriscv_2stages.v:721:2
	assign rvfi_auipc_ctr = rvfi_insn[6:0] == 7'h17;
	// Trace: darkriscv_2stages.v:723:2
	wire rvfi_jal_ctr;
	// Trace: darkriscv_2stages.v:724:2
	assign rvfi_jal_ctr = rvfi_insn[6:0] == 7'h6f;
	// Trace: darkriscv_2stages.v:725:2
	wire rvfi_jalr_ctr;
	// Trace: darkriscv_2stages.v:726:2
	assign rvfi_jalr_ctr = (rvfi_insn[6:0] == 7'h67) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:728:2
	wire rvfi_beq_ctr;
	// Trace: darkriscv_2stages.v:729:2
	assign rvfi_beq_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:730:2
	wire rvfi_bge_ctr;
	// Trace: darkriscv_2stages.v:731:2
	assign rvfi_bge_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b101);
	// Trace: darkriscv_2stages.v:732:2
	wire rvfi_bgeu_ctr;
	// Trace: darkriscv_2stages.v:733:2
	assign rvfi_bgeu_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b111);
	// Trace: darkriscv_2stages.v:734:2
	wire rvfi_bltu_ctr;
	// Trace: darkriscv_2stages.v:735:2
	assign rvfi_bltu_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b110);
	// Trace: darkriscv_2stages.v:736:2
	wire rvfi_blt_ctr;
	// Trace: darkriscv_2stages.v:737:2
	assign rvfi_blt_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b100);
	// Trace: darkriscv_2stages.v:738:2
	wire rvfi_bne_ctr;
	// Trace: darkriscv_2stages.v:739:2
	assign rvfi_bne_ctr = (rvfi_insn[6:0] == 7'h63) && (rvfi_insn[14:12] == 3'b001);
	// Trace: darkriscv_2stages.v:742:2
	wire rvfi_lb_ctr;
	// Trace: darkriscv_2stages.v:743:2
	assign rvfi_lb_ctr = (rvfi_insn[6:0] == 7'h03) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:744:2
	wire rvfi_lh_ctr;
	// Trace: darkriscv_2stages.v:745:2
	assign rvfi_lh_ctr = (rvfi_insn[6:0] == 7'h03) && (rvfi_insn[14:12] == 3'b001);
	// Trace: darkriscv_2stages.v:746:2
	wire rvfi_lhu_ctr;
	// Trace: darkriscv_2stages.v:747:2
	assign rvfi_lhu_ctr = (rvfi_insn[6:0] == 7'h03) && (rvfi_insn[14:12] == 3'b101);
	// Trace: darkriscv_2stages.v:748:2
	wire rvfi_lbu_ctr;
	// Trace: darkriscv_2stages.v:749:2
	assign rvfi_lbu_ctr = (rvfi_insn[6:0] == 7'h03) && (rvfi_insn[14:12] == 3'b100);
	// Trace: darkriscv_2stages.v:750:2
	wire rvfi_lw_ctr;
	// Trace: darkriscv_2stages.v:751:2
	assign rvfi_lw_ctr = (rvfi_insn[6:0] == 7'h03) && (rvfi_insn[14:12] == 3'b010);
	// Trace: darkriscv_2stages.v:753:2
	wire rvfi_sb_ctr;
	// Trace: darkriscv_2stages.v:754:2
	assign rvfi_sb_ctr = (rvfi_insn[6:0] == 7'h23) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:755:2
	wire rvfi_sw_ctr;
	// Trace: darkriscv_2stages.v:756:2
	assign rvfi_sw_ctr = (rvfi_insn[6:0] == 7'h23) && (rvfi_insn[14:12] == 3'b010);
	// Trace: darkriscv_2stages.v:757:2
	wire rvfi_sh_ctr;
	// Trace: darkriscv_2stages.v:758:2
	assign rvfi_sh_ctr = (rvfi_insn[6:0] == 7'h23) && (rvfi_insn[14:12] == 3'b001);
	// Trace: darkriscv_2stages.v:760:2
	wire rvfi_addi_ctr;
	// Trace: darkriscv_2stages.v:761:2
	assign rvfi_addi_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:762:2
	wire rvfi_slti_ctr;
	// Trace: darkriscv_2stages.v:763:2
	assign rvfi_slti_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b010);
	// Trace: darkriscv_2stages.v:764:2
	wire rvfi_sltiu_ctr;
	// Trace: darkriscv_2stages.v:765:2
	assign rvfi_sltiu_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b011);
	// Trace: darkriscv_2stages.v:766:2
	wire rvfi_xori_ctr;
	// Trace: darkriscv_2stages.v:767:2
	assign rvfi_xori_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b100);
	// Trace: darkriscv_2stages.v:768:2
	wire rvfi_ori_ctr;
	// Trace: darkriscv_2stages.v:769:2
	assign rvfi_ori_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b110);
	// Trace: darkriscv_2stages.v:770:2
	wire rvfi_andi_ctr;
	// Trace: darkriscv_2stages.v:771:2
	assign rvfi_andi_ctr = (rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b111);
	// Trace: darkriscv_2stages.v:772:2
	wire rvfi_slli_ctr;
	// Trace: darkriscv_2stages.v:773:2
	assign rvfi_slli_ctr = ((rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b001)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:774:2
	wire rvfi_srli_ctr;
	// Trace: darkriscv_2stages.v:775:2
	assign rvfi_srli_ctr = ((rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b101)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:776:2
	wire rvfi_srai_ctr;
	// Trace: darkriscv_2stages.v:777:2
	assign rvfi_srai_ctr = ((rvfi_insn[6:0] == 7'h13) && (rvfi_insn[14:12] == 3'b101)) && (rvfi_insn[31:25] == 7'b0100000);
	// Trace: darkriscv_2stages.v:779:2
	wire rvfi_add_ctr;
	// Trace: darkriscv_2stages.v:780:2
	assign rvfi_add_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b000)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:781:2
	wire rvfi_sub_ctr;
	// Trace: darkriscv_2stages.v:782:2
	assign rvfi_sub_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b000)) && (rvfi_insn[31:25] == 7'b0100000);
	// Trace: darkriscv_2stages.v:783:2
	wire rvfi_sll_ctr;
	// Trace: darkriscv_2stages.v:784:2
	assign rvfi_sll_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b001)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:785:2
	wire rvfi_slt_ctr;
	// Trace: darkriscv_2stages.v:786:2
	assign rvfi_slt_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b010)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:787:2
	wire rvfi_sltu_ctr;
	// Trace: darkriscv_2stages.v:788:2
	assign rvfi_sltu_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b011)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:789:2
	wire rvfi_xor_ctr;
	// Trace: darkriscv_2stages.v:790:2
	assign rvfi_xor_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b100)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:791:2
	wire rvfi_srl_ctr;
	// Trace: darkriscv_2stages.v:792:2
	assign rvfi_srl_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b101)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:793:2
	wire rvfi_sra_ctr;
	// Trace: darkriscv_2stages.v:794:2
	assign rvfi_sra_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b101)) && (rvfi_insn[31:25] == 7'b0100000);
	// Trace: darkriscv_2stages.v:795:2
	wire rvfi_or_ctr;
	// Trace: darkriscv_2stages.v:796:2
	assign rvfi_or_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b110)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:797:2
	wire rvfi_and_ctr;
	// Trace: darkriscv_2stages.v:798:2
	assign rvfi_and_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[14:12] == 3'b111)) && (rvfi_insn[31:25] == 7'b0000000);
	// Trace: darkriscv_2stages.v:800:2
	wire rvfi_mul_ctr;
	// Trace: darkriscv_2stages.v:801:2
	assign rvfi_mul_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b000);
	// Trace: darkriscv_2stages.v:802:2
	wire rvfi_mulh_ctr;
	// Trace: darkriscv_2stages.v:803:2
	assign rvfi_mulh_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b001);
	// Trace: darkriscv_2stages.v:804:2
	wire rvfi_mulhsu_ctr;
	// Trace: darkriscv_2stages.v:805:2
	assign rvfi_mulhsu_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b010);
	// Trace: darkriscv_2stages.v:806:2
	wire rvfi_mulhu_ctr;
	// Trace: darkriscv_2stages.v:807:2
	assign rvfi_mulhu_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b011);
	// Trace: darkriscv_2stages.v:808:2
	wire rvfi_div_ctr;
	// Trace: darkriscv_2stages.v:809:2
	assign rvfi_div_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b100);
	// Trace: darkriscv_2stages.v:810:2
	wire rvfi_divu_ctr;
	// Trace: darkriscv_2stages.v:811:2
	assign rvfi_divu_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b101);
	// Trace: darkriscv_2stages.v:812:2
	wire rvfi_rem_ctr;
	// Trace: darkriscv_2stages.v:813:2
	assign rvfi_rem_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b110);
	// Trace: darkriscv_2stages.v:814:2
	wire rvfi_remu_ctr;
	// Trace: darkriscv_2stages.v:815:2
	assign rvfi_remu_ctr = ((rvfi_insn[6:0] == 7'h33) && (rvfi_insn[31:25] == 7'b0000001)) && (rvfi_insn[14:12] == 3'b111);
	// Trace: darkriscv_2stages.v:819:2
	wire [4:0] rs1;
	// Trace: darkriscv_2stages.v:820:2
	wire [4:0] rs2;
	// Trace: darkriscv_2stages.v:821:2
	wire [4:0] rd;
	// Trace: darkriscv_2stages.v:822:2
	wire [6:0] opcode;
	// Trace: darkriscv_2stages.v:823:2
	wire [31:0] imm;
	// Trace: darkriscv_2stages.v:824:2
	wire [2:0] format;
	// Trace: darkriscv_2stages.v:825:2
	wire [2:0] funct3;
	// Trace: darkriscv_2stages.v:826:2
	wire [6:0] funct7;
	// Trace: darkriscv_2stages.v:828:5
	RISCV_Decoder ctr_decode(
		.instr_i(rvfi_insn),
		.format_o(format),
		.op_o(opcode),
		.funct_3_o(funct3),
		.funct_7_o(funct7),
		.rd_o(rd),
		.rs1_o(rs1),
		.rs2_o(rs2),
		.imm_o(imm)
	);
	// Trace: darkriscv_2stages.v:840:2
	wire [31:0] new_pc;
	// Trace: darkriscv_2stages.v:841:2
	assign new_pc = rvfi_pc_wdata;
	// Trace: darkriscv_2stages.v:842:2
	wire is_branch;
	// Trace: darkriscv_2stages.v:843:2
	assign is_branch = ((((((rvfi_beq_ctr || rvfi_bge_ctr) || rvfi_bgeu_ctr) || rvfi_bltu_ctr) || rvfi_blt_ctr) || rvfi_bne_ctr) || rvfi_jal_ctr) || rvfi_jalr_ctr;
	// Trace: darkriscv_2stages.v:846:2
	wire [31:0] reg_rd;
	// Trace: darkriscv_2stages.v:847:2
	assign reg_rd = rvfi_rd_wdata;
	// Trace: darkriscv_2stages.v:848:2
	wire [31:0] reg_rs1;
	// Trace: darkriscv_2stages.v:849:2
	assign reg_rs1 = rvfi_rs1_rdata;
	// Trace: darkriscv_2stages.v:850:2
	wire [31:0] reg_rs2;
	// Trace: darkriscv_2stages.v:851:2
	assign reg_rs2 = rvfi_rs2_rdata;
	// Trace: darkriscv_2stages.v:853:2
	wire reg_rs1_zero;
	// Trace: darkriscv_2stages.v:854:2
	assign reg_rs1_zero = rvfi_rs1_rdata == 0;
	// Trace: darkriscv_2stages.v:855:2
	wire reg_rs2_zero;
	// Trace: darkriscv_2stages.v:856:2
	assign reg_rs2_zero = rvfi_rs2_rdata == 0;
	// Trace: darkriscv_2stages.v:857:2
	wire [31:0] reg_rs1_log2;
	// Trace: darkriscv_2stages.v:858:2
	function integer clogb2;
		// Trace: darkriscv_2stages.v:863:3
		input [31:0] value;
		// Trace: darkriscv_2stages.v:864:3
		integer i;
		// Trace: darkriscv_2stages.v:865:3
		begin
			// Trace: darkriscv_2stages.v:866:4
			clogb2 = 0;
			// Trace: darkriscv_2stages.v:867:4
			for (i = 0; i < 32; i = i + 1)
				begin
					// Trace: darkriscv_2stages.v:868:5
					if (value > 0) begin
						// Trace: darkriscv_2stages.v:869:6
						clogb2 = i + 1;
						// Trace: darkriscv_2stages.v:870:6
						value = value >> 1;
					end
				end
		end
	endfunction
	assign reg_rs1_log2 = clogb2(rvfi_rs1_rdata);
	// Trace: darkriscv_2stages.v:859:2
	wire [31:0] reg_rs2_log2;
	// Trace: darkriscv_2stages.v:860:2
	assign reg_rs2_log2 = clogb2(rvfi_rs2_rdata);
	wire reg_rd_zero;
	assign reg_rd_zero = ( rvfi_rd_wdata == 0 );
	wire [31:0] reg_rd_log2;
	assign reg_rd_log2 = clogb2( rvfi_rd_wdata );
	
	// Trace: darkriscv_2stages.v:862:2
	// Trace: darkriscv_2stages.v:879:2
	wire is_aligned;
	// Trace: darkriscv_2stages.v:880:2
	assign is_aligned = rvfi_mem_addr[1:0] == 2'b00;
	// Trace: darkriscv_2stages.v:881:2
	wire is_half_aligned;
	// Trace: darkriscv_2stages.v:882:5
	assign is_half_aligned = rvfi_mem_addr[1:0] != 2'b11;
	// Trace: darkriscv_2stages.v:884:2
	// wire branch_taken;
	// // Trace: darkriscv_2stages.v:885:5
	// assign branch_taken = (((((((opcode == 7'b1101111) || (opcode == 7'b1100111)) || (((opcode == 7'b1100011) && (funct3 == 3'b000)) && (reg_rs1 == reg_rs2))) || (((opcode == 7'b1100011) && (funct3 == 3'b001)) && (reg_rs1 != reg_rs2))) || (((opcode == 7'b1100011) && (funct3 == 3'b100)) && ($signed(reg_rs1) < $signed(reg_rs2)))) || (((opcode == 7'b1100011) && (funct3 == 3'b101)) && ($signed(reg_rs1) >= $signed(reg_rs2)))) || (((opcode == 7'b1100011) && (funct3 == 3'b110)) && (reg_rs1 < reg_rs2))) || (((opcode == 7'b1100011) && (funct3 == 3'b111)) && (reg_rs1 >= reg_rs2));
	reg branch_taken;
	always @(posedge CLK) 
		if (retire_wire) 
			branch_taken <= JREQ;// Trace: darkriscv_2stages.v:895:2
	// Trace: darkriscv_2stages.v:896:2
	// Trace: darkriscv_2stages.v:897:2
	wire [31:0] mem_addr;
	assign mem_addr = rvfi_mem_addr;

	wire [31:0] mem_r_data;
	// Trace: darkriscv_2stages.v:898:2
	assign mem_r_data = rvfi_mem_rdata;
	// Trace: darkriscv_2stages.v:899:2
	wire [31:0] mem_w_data;
	// Trace: darkriscv_2stages.v:900:2
	assign mem_w_data = rvfi_mem_wdata;

endmodule