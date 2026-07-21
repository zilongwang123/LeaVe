`define JAL_OP		7'b1101111
`define JALR_OP		7'b1100111
`define BEQ_OP		7'b1100011
`define BNE_OP		7'b1100011
`define BLT_OP		7'b1100011
`define BGE_OP		7'b1100011
`define BLTU_OP		7'b1100011
`define BGEU_OP		7'b1100011

`define BEQ_FUNCT_3		3'b000
`define BNE_FUNCT_3		3'b001
`define BLT_FUNCT_3		3'b100
`define BGE_FUNCT_3		3'b101
`define BLTU_FUNCT_3	3'b110
`define BGEU_FUNCT_3	3'b111

module darkriscv_2stages (
	CLK,
	RES,
	HLT,
	IDATA,
	IADDR,
	DATAI,
	DATAO,
	DADDR,
	BE,
	WR,
	RD,
	IDLE,
	DEBUG,
	PC_retire,
	DADDR_CTR,
	INSTR_CTR,
	DATAI_CTR,
	PC,
	DADDR_PC,
	INSTR_PC,
	DATAI_PC
);
	// Trace: darkriscv_2stages.v:77:5
	input CLK;
	// Trace: darkriscv_2stages.v:78:5
	input RES;
	// Trace: darkriscv_2stages.v:79:5
	input HLT;
	// Trace: darkriscv_2stages.v:85:5
	input [31:0] IDATA;
	// Trace: darkriscv_2stages.v:86:5
	output wire [31:0] IADDR;
	// Trace: darkriscv_2stages.v:88:5
	input [31:0] DATAI;
	// Trace: darkriscv_2stages.v:89:5
	output wire [31:0] DATAO;
	// Trace: darkriscv_2stages.v:90:5
	output wire [31:0] DADDR;
	// Trace: darkriscv_2stages.v:96:5
	output wire [3:0] BE;
	// Trace: darkriscv_2stages.v:97:5
	output wire WR;
	// Trace: darkriscv_2stages.v:98:5
	output wire RD;
	// Trace: darkriscv_2stages.v:101:5
	output wire IDLE;
	// Trace: darkriscv_2stages.v:103:5
	output wire [3:0] DEBUG;
	// Trace: darkriscv_2stages.v:105:5
	output reg [31:0] PC_retire;
	// Trace: darkriscv_2stages.v:106:5
	output wire [31:0] DADDR_CTR;
	// Trace: darkriscv_2stages.v:107:5
	input wire [31:0] INSTR_CTR;
	// Trace: darkriscv_2stages.v:108:5
	input wire [31:0] DATAI_CTR;
	// Trace: darkriscv_2stages.v:110:5
	output reg [31:0] PC;
	// Trace: darkriscv_2stages.v:111:5
	output wire [31:0] DADDR_PC;
	// Trace: darkriscv_2stages.v:112:5
	input wire [31:0] INSTR_PC;
	// Trace: darkriscv_2stages.v:113:5
	input wire [31:0] DATAI_PC;
	// Trace: darkriscv_2stages.v:117:5
	// combined with INSTR_CTR
	// Trace: darkriscv_2stages.v:118:5
	// combined with DATAI_CTR
	// Trace: darkriscv_2stages.v:119:5
	// combined with DADDR_CTR
	// Trace: darkriscv_2stages.v:120:5
	wire [7:0] OPCODE_CTR = INSTR_CTR[6:0];
	wire LCC_CTR = OPCODE_CTR == 7'b0000011;
	// Trace: darkriscv_2stages.v:121:5
	wire SCC_CTR = OPCODE_CTR == 7'b0100011;
	// Trace: darkriscv_2stages.v:123:5
	// Trace: darkriscv_2stages.v:124:5
	reg [1023:0] REG1;
	wire [31:0] U1REG_CTR = REG1[(31 - INSTR_CTR[18:15]) * 32+:32];
	// Trace: darkriscv_2stages.v:125:5
	wire [31:0] ALL0 = 0;
	wire [31:0] ALL1 = -1;
	wire [31:0] SIMM_CTR = (OPCODE_CTR == 7'b0100011 ? {(INSTR_CTR[31] ? ALL1[31:12] : ALL0[31:12]), INSTR_CTR[31:25], INSTR_CTR[11:7]} : (OPCODE_CTR == 7'b1100011 ? {(INSTR_CTR[31] ? ALL1[31:13] : ALL0[31:13]), INSTR_CTR[31], INSTR_CTR[7], INSTR_CTR[30:25], INSTR_CTR[11:8], ALL0[0]} : (OPCODE_CTR == 7'b1101111 ? {(INSTR_CTR[31] ? ALL1[31:21] : ALL0[31:21]), INSTR_CTR[31], INSTR_CTR[19:12], INSTR_CTR[20], INSTR_CTR[30:21], ALL0[0]} : ((OPCODE_CTR == 7'b0110111) || (OPCODE_CTR == 7'b0010111) ? {INSTR_CTR[31:12], ALL0[11:0]} : {(INSTR_CTR[31] ? ALL1[31:12] : ALL0[31:12]), INSTR_CTR[31:20]}))));
	assign DADDR_CTR = ((OPCODE_CTR == 7'b0000011) || (OPCODE_CTR == 7'b0100011) ? U1REG_CTR + SIMM_CTR : 0);
	// Trace: darkriscv_2stages.v:126:5
	// Trace: darkriscv_2stages.v:132:5
	wire [2:0] FCT3_CTR = INSTR_CTR[14:12];
	// Trace: darkriscv_2stages.v:133:5
	wire [31:0] LDATA_CTR = ((FCT3_CTR == 0) || (FCT3_CTR == 4) ? (DADDR_CTR[1:0] == 3 ? {((FCT3_CTR == 0) && DATAI_CTR[31] ? ALL1[31:8] : ALL0[31:8]), DATAI_CTR[31:24]} : (DADDR_CTR[1:0] == 2 ? {((FCT3_CTR == 0) && DATAI_CTR[23] ? ALL1[31:8] : ALL0[31:8]), DATAI_CTR[23:16]} : (DADDR_CTR[1:0] == 1 ? {((FCT3_CTR == 0) && DATAI_CTR[15] ? ALL1[31:8] : ALL0[31:8]), DATAI_CTR[15:8]} : {((FCT3_CTR == 0) && DATAI_CTR[7] ? ALL1[31:8] : ALL0[31:8]), DATAI_CTR[7:0]}))) : ((FCT3_CTR == 1) || (FCT3_CTR == 5) ? (DADDR_CTR[1] == 1 ? {((FCT3_CTR == 1) && DATAI_CTR[31] ? ALL1[31:16] : ALL0[31:16]), DATAI_CTR[31:16]} : {((FCT3_CTR == 1) && DATAI_CTR[15] ? ALL1[31:16] : ALL0[31:16]), DATAI_CTR[15:0]}) : DATAI_CTR));
	// Trace: darkriscv_2stages.v:142:5
	// combined with INSTR_PC
	// Trace: darkriscv_2stages.v:143:5
	// combined with DATAI_PC
	// Trace: darkriscv_2stages.v:144:5
	// combined with DADDR_PC
	// Trace: darkriscv_2stages.v:145:5
	wire [7:0] OPCODE_PC = INSTR_PC[6:0];
	wire LCC_PC = OPCODE_PC == 7'b0000011;
	// Trace: darkriscv_2stages.v:146:5
	wire SCC_PC = OPCODE_PC == 7'b0100011;
	// Trace: darkriscv_2stages.v:147:5
	wire MCC_PC = OPCODE_PC == 7'b0010011;
	// Trace: darkriscv_2stages.v:148:5
	wire RCC_PC = OPCODE_PC == 7'b0110011;
	// Trace: darkriscv_2stages.v:150:5
	// Trace: darkriscv_2stages.v:151:5
	wire [31:0] U1REG_PC = REG1[(31 - INSTR_PC[18:15]) * 32+:32];
	// Trace: darkriscv_2stages.v:152:5
	wire [31:0] SIMM_PC = (OPCODE_PC == 7'b0100011 ? {(INSTR_PC[31] ? ALL1[31:12] : ALL0[31:12]), INSTR_PC[31:25], INSTR_PC[11:7]} : (OPCODE_PC == 7'b1100011 ? {(INSTR_PC[31] ? ALL1[31:13] : ALL0[31:13]), INSTR_PC[31], INSTR_PC[7], INSTR_PC[30:25], INSTR_PC[11:8], ALL0[0]} : (OPCODE_PC == 7'b1101111 ? {(INSTR_PC[31] ? ALL1[31:21] : ALL0[31:21]), INSTR_PC[31], INSTR_PC[19:12], INSTR_PC[20], INSTR_PC[30:21], ALL0[0]} : ((OPCODE_PC == 7'b0110111) || (OPCODE_PC == 7'b0010111) ? {INSTR_PC[31:12], ALL0[11:0]} : {(INSTR_PC[31] ? ALL1[31:12] : ALL0[31:12]), INSTR_PC[31:20]}))));
	assign DADDR_PC = ((OPCODE_PC == 7'b0000011) || (OPCODE_PC == 7'b0100011) ? U1REG_PC + SIMM_PC : 0);
	// Trace: darkriscv_2stages.v:153:5
	// Trace: darkriscv_2stages.v:159:5
	wire [2:0] FCT3_PC = INSTR_PC[14:12];
	// Trace: darkriscv_2stages.v:160:5
	wire [31:0] LDATA_PC = ((FCT3_PC == 0) || (FCT3_PC == 4) ? (DADDR_PC[1:0] == 3 ? {((FCT3_PC == 0) && DATAI_PC[31] ? ALL1[31:8] : ALL0[31:8]), DATAI_PC[31:24]} : (DADDR_PC[1:0] == 2 ? {((FCT3_PC == 0) && DATAI_PC[23] ? ALL1[31:8] : ALL0[31:8]), DATAI_PC[23:16]} : (DADDR_PC[1:0] == 1 ? {((FCT3_PC == 0) && DATAI_PC[15] ? ALL1[31:8] : ALL0[31:8]), DATAI_PC[15:8]} : {((FCT3_PC == 0) && DATAI_PC[7] ? ALL1[31:8] : ALL0[31:8]), DATAI_PC[7:0]}))) : ((FCT3_PC == 1) || (FCT3_PC == 5) ? (DADDR_PC[1] == 1 ? {((FCT3_PC == 1) && DATAI_PC[31] ? ALL1[31:16] : ALL0[31:16]), DATAI_PC[31:16]} : {((FCT3_PC == 1) && DATAI_PC[15] ? ALL1[31:16] : ALL0[31:16]), DATAI_PC[15:0]}) : DATAI_PC));
	// Trace: darkriscv_2stages.v:172:5
	// Trace: darkriscv_2stages.v:173:5
	// Trace: darkriscv_2stages.v:183:5
	reg [31:0] XIDATA;
	// Trace: darkriscv_2stages.v:186:9
	reg XLUI;
	reg XAUIPC;
	reg XJAL;
	reg XJALR;
	reg XBCC;
	reg XLCC;
	reg XSCC;
	reg XMCC;
	reg XRCC;
	reg XMAC;
	reg XRES;
	// Trace: darkriscv_2stages.v:191:5
	reg [31:0] XSIMM;
	// Trace: darkriscv_2stages.v:192:5
	reg [31:0] XUIMM;
	// Trace: darkriscv_2stages.v:211:5
	reg FLUSH;
	wire decode = (XRES ? 0 : (HLT ? 0 : (FLUSH ? 0 : 1)));
	// Trace: darkriscv_2stages.v:212:5
	wire [31:0] XIDATA_wire = (XRES ? 0 : (HLT ? XIDATA : (FLUSH ? 0 : IDATA)));
	// Trace: darkriscv_2stages.v:213:5
	reg decode_reg;
	// Trace: darkriscv_2stages.v:214:5
	always @(posedge CLK) begin
		// Trace: darkriscv_2stages.v:216:9
		decode_reg <= (XRES ? 0 : (HLT ? 0 : (FLUSH ? 0 : 1)));
		// Trace: darkriscv_2stages.v:218:9
		XIDATA <= (XRES ? 0 : (HLT ? XIDATA : (FLUSH ? 0 : IDATA)));
		// Trace: darkriscv_2stages.v:220:9
		XLUI <= (XRES ? 0 : (HLT ? XLUI : (FLUSH ? 0 : IDATA[6:0] == 7'b0110111)));
		// Trace: darkriscv_2stages.v:221:9
		XAUIPC <= (XRES ? 0 : (HLT ? XAUIPC : (FLUSH ? 0 : IDATA[6:0] == 7'b0010111)));
		// Trace: darkriscv_2stages.v:222:9
		XJAL <= (XRES ? 0 : (HLT ? XJAL : (FLUSH ? 0 : IDATA[6:0] == 7'b1101111)));
		// Trace: darkriscv_2stages.v:223:9
		XJALR <= (XRES ? 0 : (HLT ? XJALR : (FLUSH ? 0 : IDATA[6:0] == 7'b1100111)));
		// Trace: darkriscv_2stages.v:225:9
		XBCC <= (XRES ? 0 : (HLT ? XBCC : (FLUSH ? 0 : IDATA[6:0] == 7'b1100011)));
		// Trace: darkriscv_2stages.v:226:9
		XLCC <= (XRES ? 0 : (HLT ? XLCC : (FLUSH ? 0 : IDATA[6:0] == 7'b0000011)));
		// Trace: darkriscv_2stages.v:227:9
		XSCC <= (XRES ? 0 : (HLT ? XSCC : (FLUSH ? 0 : IDATA[6:0] == 7'b0100011)));
		// Trace: darkriscv_2stages.v:228:9
		XMCC <= (XRES ? 0 : (HLT ? XMCC : (FLUSH ? 0 : IDATA[6:0] == 7'b0010011)));
		// Trace: darkriscv_2stages.v:230:9
		XRCC <= (XRES ? 0 : (HLT ? XRCC : (FLUSH ? 0 : IDATA[6:0] == 7'b0110011)));
		// Trace: darkriscv_2stages.v:231:9
		XMAC <= (XRES ? 0 : (HLT ? XMAC : (FLUSH ? 0 : IDATA[6:0] == 7'b1111111)));
		// Trace: darkriscv_2stages.v:237:9
		XSIMM <= (XRES ? 0 : (HLT ? XSIMM : (FLUSH ? 0 : (IDATA[6:0] == 7'b0100011 ? {(IDATA[31] ? ALL1[31:12] : ALL0[31:12]), IDATA[31:25], IDATA[11:7]} : (IDATA[6:0] == 7'b1100011 ? {(IDATA[31] ? ALL1[31:13] : ALL0[31:13]), IDATA[31], IDATA[7], IDATA[30:25], IDATA[11:8], ALL0[0]} : (IDATA[6:0] == 7'b1101111 ? {(IDATA[31] ? ALL1[31:21] : ALL0[31:21]), IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0]} : ((IDATA[6:0] == 7'b0110111) || (IDATA[6:0] == 7'b0010111) ? {IDATA[31:12], ALL0[11:0]} : {(IDATA[31] ? ALL1[31:12] : ALL0[31:12]), IDATA[31:20]})))))));
		// Trace: darkriscv_2stages.v:246:9
		XUIMM <= (XRES ? 0 : (HLT ? XUIMM : (FLUSH ? 0 : (IDATA[6:0] == 7'b0100011 ? {ALL0[31:12], IDATA[31:25], IDATA[11:7]} : (IDATA[6:0] == 7'b1100011 ? {ALL0[31:13], IDATA[31], IDATA[7], IDATA[30:25], IDATA[11:8], ALL0[0]} : (IDATA[6:0] == 7'b1101111 ? {ALL0[31:21], IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0]} : ((IDATA[6:0] == 7'b0110111) || (IDATA[6:0] == 7'b0010111) ? {IDATA[31:12], ALL0[11:0]} : {ALL0[31:12], IDATA[31:20]})))))));
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

	// Trace: darkriscv_2stages.v:259:5
	// Trace: darkriscv_2stages.v:301:13
	reg [4:0] RESMODE;
	// Trace: darkriscv_2stages.v:306:9
	wire [4:0] DPTR = (XRES ? RESMODE : XIDATA[11:7]);
	// Trace: darkriscv_2stages.v:307:9
	wire [4:0] S1PTR = XIDATA[19:15];
	// Trace: darkriscv_2stages.v:308:9
	wire [4:0] S2PTR = XIDATA[24:20];
	// Trace: darkriscv_2stages.v:312:5
	wire [6:0] OPCODE = (FLUSH ? 0 : XIDATA[6:0]);
	// Trace: darkriscv_2stages.v:313:5
	wire [2:0] FCT3 = XIDATA[14:12];
	// Trace: darkriscv_2stages.v:314:5
	wire [6:0] FCT7 = XIDATA[31:25];
	// Trace: darkriscv_2stages.v:316:5
	wire [31:0] SIMM = XSIMM;
	// Trace: darkriscv_2stages.v:317:5
	wire [31:0] UIMM = XUIMM;
	// Trace: darkriscv_2stages.v:321:5
	wire LUI = (FLUSH ? 0 : XLUI);
	// Trace: darkriscv_2stages.v:322:5
	wire AUIPC = (FLUSH ? 0 : XAUIPC);
	// Trace: darkriscv_2stages.v:323:5
	wire JAL = (FLUSH ? 0 : XJAL);
	// Trace: darkriscv_2stages.v:324:5
	wire JALR = (FLUSH ? 0 : XJALR);
	// Trace: darkriscv_2stages.v:326:5
	wire BCC = (FLUSH ? 0 : XBCC);
	// Trace: darkriscv_2stages.v:327:5
	wire LCC = (FLUSH ? 0 : XLCC);
	// Trace: darkriscv_2stages.v:328:5
	wire SCC = (FLUSH ? 0 : XSCC);
	// Trace: darkriscv_2stages.v:329:5
	wire MCC = (FLUSH ? 0 : XMCC);
	// Trace: darkriscv_2stages.v:331:5
	wire RCC = (FLUSH ? 0 : XRCC);
	// Trace: darkriscv_2stages.v:332:5
	wire MAC = (FLUSH ? 0 : XMAC);
	// Trace: darkriscv_2stages.v:373:9
	// Trace: darkriscv_2stages.v:374:9
	// reg [31:0] REG2 [0:31];
	// Trace: darkriscv_2stages.v:387:5
	reg [31:0] NXPC;
	// Trace: darkriscv_2stages.v:388:5
	// combined with PC
	// Trace: darkriscv_2stages.v:399:5
	wire [31:0] U1REG = REG1[(31 - S1PTR) * 32+:32];
	// Trace: darkriscv_2stages.v:400:5
	wire [31:0] U2REG = REG1[(31 - S2PTR) * 32+:32];
	// Trace: darkriscv_2stages.v:402:5
	wire signed [31:0] S1REG = U1REG;
	// Trace: darkriscv_2stages.v:403:5
	wire signed [31:0] S2REG = U2REG;
	// Trace: darkriscv_2stages.v:414:5
	wire [31:0] LDATA = ((FCT3 == 0) || (FCT3 == 4) ? (DADDR[1:0] == 3 ? {((FCT3 == 0) && DATAI[31] ? ALL1[31:8] : ALL0[31:8]), DATAI[31:24]} : (DADDR[1:0] == 2 ? {((FCT3 == 0) && DATAI[23] ? ALL1[31:8] : ALL0[31:8]), DATAI[23:16]} : (DADDR[1:0] == 1 ? {((FCT3 == 0) && DATAI[15] ? ALL1[31:8] : ALL0[31:8]), DATAI[15:8]} : {((FCT3 == 0) && DATAI[7] ? ALL1[31:8] : ALL0[31:8]), DATAI[7:0]}))) : ((FCT3 == 1) || (FCT3 == 5) ? (DADDR[1] == 1 ? {((FCT3 == 1) && DATAI[31] ? ALL1[31:16] : ALL0[31:16]), DATAI[31:16]} : {((FCT3 == 1) && DATAI[15] ? ALL1[31:16] : ALL0[31:16]), DATAI[15:0]}) : DATAI));
	// Trace: darkriscv_2stages.v:431:5
	wire [31:0] SDATA = (FCT3 == 0 ? (DADDR[1:0] == 3 ? {U2REG[7:0], ALL0[23:0]} : (DADDR[1:0] == 2 ? {ALL0[31:24], U2REG[7:0], ALL0[15:0]} : (DADDR[1:0] == 1 ? {ALL0[31:16], U2REG[7:0], ALL0[7:0]} : {ALL0[31:8], U2REG[7:0]}))) : (FCT3 == 1 ? (DADDR[1] == 1 ? {U2REG[15:0], ALL0[15:0]} : {ALL0[31:16], U2REG[15:0]}) : U2REG));
	// Trace: darkriscv_2stages.v:442:5
	wire [31:0] CDATA = 0;
	// Trace: darkriscv_2stages.v:446:5
	wire signed [31:0] S2REGX = (XMCC ? SIMM : S2REG);
	// Trace: darkriscv_2stages.v:447:5
	wire [31:0] U2REGX = (XMCC ? UIMM : U2REG);
	// Trace: darkriscv_2stages.v:449:5
	wire [31:0] RMDATA = (FCT3 == 7 ? U1REG & S2REGX : (FCT3 == 6 ? U1REG | S2REGX : (FCT3 == 4 ? U1REG ^ S2REGX : (FCT3 == 3 ? (U1REG < U2REGX ? 1 : 0) : (FCT3 == 2 ? (S1REG < S2REGX ? 1 : 0) : (FCT3 == 0 ? (XRCC && FCT7[5] ? U1REG - U2REGX : U1REG + S2REGX) : (FCT3 == 1 ? U1REG << U2REGX[4:0] : (!FCT7[5] ? U1REG >> U2REGX[4:0] : $signed(S1REG >>> U2REGX[4:0])))))))));
	// Trace: darkriscv_2stages.v:482:5
	wire BMUX = (BCC == 1) && (FCT3 == 4 ? S1REG < S2REGX : (FCT3 == 5 ? S1REG >= S2REG : (FCT3 == 6 ? U1REG < U2REGX : (FCT3 == 7 ? U1REG >= U2REG : (FCT3 == 0 ? !(U1REG ^ S2REGX) : U1REG ^ S2REGX)))));
	// Trace: darkriscv_2stages.v:491:5
	wire [31:0] PCSIMM = PC + SIMM;
	// Trace: darkriscv_2stages.v:492:5
	wire JREQ = (JAL || JALR) || BMUX;
	// Trace: darkriscv_2stages.v:493:5
	wire [31:0] JVAL = SIMM + (JALR ? U1REG : PC);
	// Trace: darkriscv_2stages.v:497:5
	wire [31:0] XIDATA_next = (FLUSH ? 0 : XIDATA);
	// Trace: darkriscv_2stages.v:498:5
	reg writeback_reg;
	// Trace: darkriscv_2stages.v:499:5
	wire writeback = (XRES ? 0 : (HLT ? 0 : 1));
	// Trace: darkriscv_2stages.v:509:5
	wire filter_pc_reg = decode_reg || !FLUSH;
	// Trace: darkriscv_2stages.v:510:5
	wire FLUSH_wire = (XRES ? 1 : (HLT ? FLUSH : (JAL || JALR) || BMUX));
	wire filter_pc = decode || !FLUSH_wire;
	// Trace: darkriscv_2stages.v:511:5
	// Trace: darkriscv_2stages.v:514:5
	reg [31:0] DelayU1REG;
	// Trace: darkriscv_2stages.v:515:5
	reg DelayBCC;
	// Trace: darkriscv_2stages.v:516:5
	reg [31:0] DelayU2REG;
	// Trace: darkriscv_2stages.v:517:5
	reg DelayJALR;
	// Trace: darkriscv_2stages.v:518:5
	reg [31:0] DelayLDATA;
	// Trace: darkriscv_2stages.v:519:5
	reg DelayLCC;
	// Trace: darkriscv_2stages.v:520:5
	reg [31:0] DelayDADDR;
	// Trace: darkriscv_2stages.v:521:5
	reg DelaySCC;
	// Trace: darkriscv_2stages.v:522:5
	reg [31:0] DelayXIDATA_next;
	// Trace: darkriscv_2stages.v:524:5
	// combined with PC_retire
	// Trace: darkriscv_2stages.v:525:5
	wire [31:0] PC_flush = (FLUSH ? 0 : PC);
	// Trace: darkriscv_2stages.v:531:4
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
	reg flushed ;
	reg [1:0] resetted ;
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
		resetted <= XRES ? -1 : resetted ? resetted - 1 : 0 ;
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
	reg mem_req;
	// Trace: darkriscv_2stages.v:653:5
	reg [31:0] mem_addr1;
	// Trace: darkriscv_2stages.v:654:5
	reg [31:0] mem_rdata ;
	// Trace: darkriscv_2stages.v:655:5
	reg [31:0] mem_wdata ;
	// Trace: darkriscv_2stages.v:656:5
	reg mem_we ;
	// Trace: darkriscv_2stages.v:657:5
	reg [3:0] mem_be ;
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
	RVFI_2stage RVFI_2stage(
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
			branch_taken <= JREQ;
	// Trace: darkriscv_2stages.v:895:2
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
	// Trace: darkriscv_2stages.v:905:5
	always @(posedge CLK) begin
		// Trace: darkriscv_2stages.v:907:9
		PC_retire <= (HLT ? PC_retire : (FLUSH ? PC_retire : PC));
		// Trace: darkriscv_2stages.v:909:9
		DelayLDATA <= (HLT ? DelayLDATA : LDATA);
		// Trace: darkriscv_2stages.v:910:9
		DelayLCC <= (HLT ? DelayLCC : LCC);
		// Trace: darkriscv_2stages.v:911:9
		DelayDADDR <= (HLT ? DelayDADDR : DADDR);
		// Trace: darkriscv_2stages.v:912:9
		DelaySCC <= (HLT ? DelaySCC : SCC);
		// Trace: darkriscv_2stages.v:913:9
		DelayXIDATA_next <= (HLT ? DelayXIDATA_next : XIDATA_next);
		// Trace: darkriscv_2stages.v:914:9
		DelayU1REG <= (HLT ? DelayU1REG : U1REG);
		// Trace: darkriscv_2stages.v:915:9
		DelayBCC <= (HLT ? DelayBCC : BCC);
		// Trace: darkriscv_2stages.v:916:9
		DelayU2REG <= (HLT ? DelayU2REG : U2REG);
		// Trace: darkriscv_2stages.v:917:9
		DelayJALR <= (HLT ? DelayJALR : JALR);
		// Trace: darkriscv_2stages.v:919:9
		writeback_reg <= (XRES ? 0 : (HLT ? 0 : 1));
		// Trace: darkriscv_2stages.v:932:9
		RESMODE <= (RES ? -1 : (RESMODE ? RESMODE - 1 : 0));
		// Trace: darkriscv_2stages.v:934:9
		XRES <= |RESMODE;
		// Trace: darkriscv_2stages.v:942:9
		FLUSH <= (XRES ? 1 : (HLT ? FLUSH : (JAL || JALR) || BMUX));
		// Trace: darkriscv_2stages.v:949:9
		REG1[(31 - DPTR) * 32+:32] <= (XRES ? (RESMODE[4:0] == 2 ? 32'd0 : 0) : (HLT ? REG1[(31 - DPTR) * 32+:32] : (!DPTR ? 0 : (AUIPC ? PCSIMM : (JAL || JALR ? NXPC : (LUI ? SIMM : (LCC ? LDATA : (MCC || RCC ? RMDATA : REG1[(31 - DPTR) * 32+:32]))))))));
		// Trace: darkriscv_2stages.v:967:9
		// REG2[DPTR] <= (XRES ? (RESMODE[4:0] == 2 ? 32'd0 : 0) : (HLT ? REG2[DPTR] : (!DPTR ? 0 : (AUIPC ? PCSIMM : (JAL || JALR ? NXPC : (LUI ? SIMM : (LCC ? LDATA : (MCC || RCC ? RMDATA : REG2[DPTR]))))))));
		// Trace: darkriscv_2stages.v:1008:9
		NXPC <= (XRES ? 32'd0 : (HLT ? NXPC : (JREQ ? JVAL : NXPC + 4)));
		// Trace: darkriscv_2stages.v:1012:9
		PC <= (HLT ? PC : (FLUSH ? PC : NXPC));
	end
	// Trace: darkriscv_2stages.v:1018:5
	assign DATAO = (SCC ? SDATA : 0);
	// Trace: darkriscv_2stages.v:1019:5
	assign DADDR = (SCC || LCC ? U1REG + SIMM : 0);
	// Trace: darkriscv_2stages.v:1029:5
	assign RD = LCC;
	// Trace: darkriscv_2stages.v:1030:5
	assign WR = SCC;
	// Trace: darkriscv_2stages.v:1031:5
	assign BE = ((FCT3 == 0) || (FCT3 == 4) ? (DADDR[1:0] == 3 ? 4'b1000 : (DADDR[1:0] == 2 ? 4'b0100 : (DADDR[1:0] == 1 ? 4'b0010 : 4'b0001))) : ((FCT3 == 1) || (FCT3 == 5) ? (DADDR[1] == 1 ? 4'b1100 : 4'b0011) : 4'b1111));
	// Trace: darkriscv_2stages.v:1047:5
	assign IADDR = NXPC;
	// Trace: darkriscv_2stages.v:1050:5
	assign IDLE = |FLUSH;
	// Trace: darkriscv_2stages.v:1052:5
	assign DEBUG = {XRES, |FLUSH, SCC, LCC};


endmodule
