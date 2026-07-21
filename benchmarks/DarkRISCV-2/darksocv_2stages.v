module darksocv_2stages (
	XCLK,
	XRES,
	UART_RXD,
	UART_TXD,
	LED,
	DEBUG
);
	// Trace: darksocv_2stages.v:36:5
	input XCLK;
	// Trace: darksocv_2stages.v:37:5
	input XRES;
	// Trace: darksocv_2stages.v:39:5
	input UART_RXD;
	// Trace: darksocv_2stages.v:40:5
	output wire UART_TXD;
	// Trace: darksocv_2stages.v:42:5
	output wire [3:0] LED;
	// Trace: darksocv_2stages.v:43:5
	output wire [3:0] DEBUG;
	// Trace: darksocv_2stages.v:48:9
	reg [7:0] IRES;
	// Trace: darksocv_2stages.v:56:5
	always @(posedge XCLK)
		// Trace: darksocv_2stages.v:56:27
		IRES <= (XRES == 1 ? -1 : (IRES[7] ? IRES - 1 : 0));
	// Trace: darksocv_2stages.v:202:5
	wire CLK = XCLK;
	// Trace: darksocv_2stages.v:203:5
	wire RES = IRES[7];
	// Trace: darksocv_2stages.v:210:5
	reg [31:0] ROM [0:1023];
	// Trace: darksocv_2stages.v:211:5
	reg [31:0] RAM [0:1023];
	// Trace: darksocv_2stages.v:281:5
	wire [31:0] IADDR;
	// Trace: darksocv_2stages.v:282:5
	wire [31:0] DADDR;
	// Trace: darksocv_2stages.v:283:5
	wire [31:0] IDATA;
	// Trace: darksocv_2stages.v:284:5
	wire [31:0] DATAO;
	// Trace: darksocv_2stages.v:285:5
	wire [31:0] DATAI;
	// Trace: darksocv_2stages.v:286:5
	wire WR;
	wire RD;
	// Trace: darksocv_2stages.v:287:5
	wire [3:0] BE;
	// Trace: darksocv_2stages.v:296:5
	wire [31:0] IOMUX [0:3];
	// Trace: darksocv_2stages.v:298:5
	reg [15:0] GPIOFF;
	// Trace: darksocv_2stages.v:299:5
	reg [15:0] LEDFF;
	// Trace: darksocv_2stages.v:301:5
	wire HLT;
	// Trace: darksocv_2stages.v:302:5
	wire IDLE;
	// Trace: darksocv_2stages.v:363:5
	reg [31:0] ROMFF;
	// Trace: darksocv_2stages.v:373:5
	reg IHITACK;
	// Trace: darksocv_2stages.v:375:5
	wire IHIT = IHITACK == 1;
	// Trace: darksocv_2stages.v:377:5
	always @(posedge CLK)
		// Trace: darksocv_2stages.v:379:9
		IHITACK <= (RES ? 1 : (IHITACK ? IHITACK - 1 : 1));
	// Trace: darksocv_2stages.v:404:5
	assign IDATA = ROMFF;
	// Trace: darksocv_2stages.v:407:5
	always @(posedge CLK)
		// Trace: darksocv_2stages.v:410:9
		ROMFF <= ROM[IADDR[11:2]];
	// Trace: darksocv_2stages.v:565:5
	reg [31:0] RAMFF;
	// Trace: darksocv_2stages.v:574:5
	reg DACK;
	// Trace: darksocv_2stages.v:576:5
	wire WHIT = 1;
	// Trace: darksocv_2stages.v:577:5
	wire DHIT = !((WR || RD) && (DACK != 1));
	// Trace: darksocv_2stages.v:579:5
	always @(posedge CLK)
		// Trace: darksocv_2stages.v:581:9
		DACK <= (RES ? 0 : (DACK ? DACK - 1 : (RD || WR ? 1 : 0)));
	// Trace: darksocv_2stages.v:615:5
	always @(posedge CLK)
		// Trace: darksocv_2stages.v:618:9
		RAMFF <= RAM[DADDR[11:2]];
	// Trace: darksocv_2stages.v:627:5
	reg [31:0] IOMUXFF;
	// Trace: darksocv_2stages.v:628:5
	reg [31:0] XADDR;
	// Trace: darksocv_2stages.v:631:5
	always @(posedge CLK) begin
		// Trace: darksocv_2stages.v:656:9
		if (((!HLT && WR) && (DADDR[31] == 0)) && BE[3])
			// Trace: darksocv_2stages.v:657:13
			RAM[DADDR[11:2]][31:24] <= DATAO[31:24];
		else if (((!HLT && WR) && (DADDR[31] == 0)) && BE[2])
			// Trace: darksocv_2stages.v:660:13
			RAM[DADDR[11:2]][23:16] <= DATAO[23:16];
		else if (((!HLT && WR) && (DADDR[31] == 0)) && BE[1])
			// Trace: darksocv_2stages.v:663:13
			RAM[DADDR[11:2]][15:8] <= DATAO[15:8];
		else if (((!HLT && WR) && (DADDR[31] == 0)) && BE[0])
			// Trace: darksocv_2stages.v:666:13
			RAM[DADDR[11:2]][7:0] <= DATAO[7:0];
		// Trace: darksocv_2stages.v:684:9
		XADDR <= DADDR;
		// Trace: darksocv_2stages.v:685:9
		IOMUXFF <= IOMUX[DADDR[3:2]];
	end
	// Trace: darksocv_2stages.v:691:5
	assign DATAI = RAMFF;
	// Trace: darksocv_2stages.v:697:5
	reg [7:0] IREQ;
	// Trace: darksocv_2stages.v:698:5
	reg [7:0] IACK;
	// Trace: darksocv_2stages.v:700:5
	reg [31:0] TIMERFF;
	// Trace: darksocv_2stages.v:708:5
	wire [7:0] BOARD_IRQ;
	// Trace: darksocv_2stages.v:710:5
	wire [7:0] BOARD_ID = 0;
	// Trace: darksocv_2stages.v:711:5
	wire [7:0] BOARD_CM = 100;
	// Trace: darksocv_2stages.v:712:5
	wire [7:0] BOARD_CK = 0;
	// Trace: darksocv_2stages.v:714:5
	assign IOMUX[0] = {BOARD_IRQ, BOARD_CK, BOARD_CM, BOARD_ID};
	// Trace: darksocv_2stages.v:716:5
	assign IOMUX[2] = {GPIOFF, LEDFF};
	// Trace: darksocv_2stages.v:717:5
	assign IOMUX[3] = TIMERFF;
	// Trace: darksocv_2stages.v:719:5
	reg [31:0] TIMER;
	// Trace: darksocv_2stages.v:721:5
	reg XTIMER;
	// Trace: darksocv_2stages.v:723:5
	always @(posedge CLK) begin
		// Trace: darksocv_2stages.v:725:9
		if ((WR && DADDR[31]) && (DADDR[3:0] == 4'b1000))
			// Trace: darksocv_2stages.v:727:13
			LEDFF <= DATAO[15:0];
		if ((WR && DADDR[31]) && (DADDR[3:0] == 4'b1010))
			// Trace: darksocv_2stages.v:732:13
			GPIOFF <= DATAO[31:16];
		if (RES)
			// Trace: darksocv_2stages.v:736:13
			TIMERFF <= 99;
		else if ((WR && DADDR[31]) && (DADDR[3:0] == 4'b1100))
			// Trace: darksocv_2stages.v:740:13
			TIMERFF <= DATAO[31:0];
		if (RES)
			// Trace: darksocv_2stages.v:744:13
			IACK <= 0;
		else if ((WR && DADDR[31]) && (DADDR[3:0] == 4'b0011)) begin
			// Trace: darksocv_2stages.v:750:13
			IACK[7] <= (DATAO[31] ? IREQ[7] : IACK[7]);
			// Trace: darksocv_2stages.v:751:13
			IACK[6] <= (DATAO[30] ? IREQ[6] : IACK[6]);
			// Trace: darksocv_2stages.v:752:13
			IACK[5] <= (DATAO[29] ? IREQ[5] : IACK[5]);
			// Trace: darksocv_2stages.v:753:13
			IACK[4] <= (DATAO[28] ? IREQ[4] : IACK[4]);
			// Trace: darksocv_2stages.v:754:13
			IACK[3] <= (DATAO[27] ? IREQ[3] : IACK[3]);
			// Trace: darksocv_2stages.v:755:13
			IACK[2] <= (DATAO[26] ? IREQ[2] : IACK[2]);
			// Trace: darksocv_2stages.v:756:13
			IACK[1] <= (DATAO[25] ? IREQ[1] : IACK[1]);
			// Trace: darksocv_2stages.v:757:13
			IACK[0] <= (DATAO[24] ? IREQ[0] : IACK[0]);
		end
		if (RES)
			// Trace: darksocv_2stages.v:761:13
			IREQ <= 0;
		else if (TIMERFF) begin
			// Trace: darksocv_2stages.v:765:13
			TIMER <= (TIMER ? TIMER - 1 : TIMERFF);
			// Trace: darksocv_2stages.v:767:13
			if ((TIMER == 0) && (IREQ == IACK))
				// Trace: darksocv_2stages.v:769:17
				IREQ[7] <= !IACK[7];
			// Trace: darksocv_2stages.v:774:13
			XTIMER <= XTIMER + (TIMER == 0);
		end
	end
	// Trace: darksocv_2stages.v:778:5
	assign BOARD_IRQ = IREQ ^ IACK;
	// Trace: darksocv_2stages.v:780:5
	assign HLT = (!IHIT || !DHIT) || !WHIT;
	// assign HLT = 0;
	// Trace: darksocv_2stages.v:784:5
	wire [3:0] UDEBUG;
	// Trace: darksocv_2stages.v:786:5
	darkuart_2stages uart0(
		.CLK(CLK),
		.RES(RES),
		.RD(((!HLT && RD) && DADDR[31]) && (DADDR[3:2] == 1)),
		.WR(((!HLT && WR) && DADDR[31]) && (DADDR[3:2] == 1)),
		.BE(BE),
		.DATAI(DATAO),
		.DATAO(IOMUX[1]),
		.RXD(UART_RXD),
		.TXD(UART_TXD),
		.DEBUG(UDEBUG)
	);
	// Trace: darksocv_2stages.v:810:5
	wire [3:0] KDEBUG;
	// Trace: darksocv_2stages.v:816:5
	wire [31:0] DADDR_CTR;
	wire [31:0] DADDR_PC;
	wire [31:0] DATAI_CTR;
	wire [31:0] DATAI_PC;
	wire [31:0] INSTR_CTR;
	wire [31:0] INSTR_PC;
	wire [31:0] PC;
	wire [31:0] PC_retire;
	darkriscv_2stages core0(
		.CLK(CLK),
		.RES(RES),
		.HLT(HLT),
		.IDATA(IDATA),
		.IADDR(IADDR),
		.DADDR(DADDR),
		.DATAI(DATAI),
		.DATAO(DATAO),
		.BE(BE),
		.WR(WR),
		.RD(RD),
		.IDLE(IDLE),
		.DEBUG(KDEBUG),
		.PC_retire(PC_retire),
		.DADDR_CTR(DADDR_CTR),
		.INSTR_CTR(INSTR_CTR),
		.DATAI_CTR(DATAI_CTR),
		.PC(PC),
		.DADDR_PC(DADDR_PC),
		.INSTR_PC(INSTR_PC),
		.DATAI_PC(DATAI_PC)
	);
	// Trace: darksocv_2stages.v:866:5
	// Trace: darksocv_2stages.v:867:5
	// Trace: darksocv_2stages.v:868:5
	// Trace: darksocv_2stages.v:869:5
	// Trace: darksocv_2stages.v:870:5
	assign INSTR_CTR = ROM[PC_retire[11:2]];
	// Trace: darksocv_2stages.v:871:5
	assign DATAI_CTR = RAM[DADDR_CTR[11:2]];
	// Trace: darksocv_2stages.v:874:5
	// Trace: darksocv_2stages.v:875:5
	// Trace: darksocv_2stages.v:876:5
	// Trace: darksocv_2stages.v:877:5
	// Trace: darksocv_2stages.v:878:5
	assign INSTR_PC = ROM[PC[11:2]];
	// Trace: darksocv_2stages.v:879:5
	assign DATAI_PC = RAM[DADDR_PC[11:2]];
	// Trace: darksocv_2stages.v:885:5
	assign LED = LEDFF[3:0];
	// Trace: darksocv_2stages.v:886:5
	assign DEBUG = {GPIOFF[0], XTIMER, WR, RD};
endmodule
