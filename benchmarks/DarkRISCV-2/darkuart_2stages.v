module darkuart_2stages (
	CLK,
	RES,
	RD,
	WR,
	BE,
	DATAI,
	DATAO,
	IRQ,
	RXD,
	TXD,
	DEBUG
);
	// Trace: darkuart_2stages.v:79:5
	input CLK;
	// Trace: darkuart_2stages.v:80:5
	input RES;
	// Trace: darkuart_2stages.v:82:5
	input RD;
	// Trace: darkuart_2stages.v:83:5
	input WR;
	// Trace: darkuart_2stages.v:84:5
	input [3:0] BE;
	// Trace: darkuart_2stages.v:85:5
	input [31:0] DATAI;
	// Trace: darkuart_2stages.v:86:5
	output wire [31:0] DATAO;
	// Trace: darkuart_2stages.v:87:5
	output wire IRQ;
	// Trace: darkuart_2stages.v:89:5
	input RXD;
	// Trace: darkuart_2stages.v:90:5
	output wire TXD;
	// Trace: darkuart_2stages.v:96:5
	output wire [3:0] DEBUG;
	// Trace: darkuart_2stages.v:99:5
	reg [15:0] UART_TIMER;
	// Trace: darkuart_2stages.v:100:5
	reg UART_IREQ;
	// Trace: darkuart_2stages.v:101:5
	reg UART_IACK;
	// Trace: darkuart_2stages.v:109:5
	reg [7:0] UART_XFIFO;
	// Trace: darkuart_2stages.v:110:5
	reg UART_XREQ;
	// Trace: darkuart_2stages.v:111:5
	reg UART_XACK;
	// Trace: darkuart_2stages.v:113:5
	reg [15:0] UART_XBAUD;
	// Trace: darkuart_2stages.v:114:5
	reg [3:0] UART_XSTATE;
	// Trace: darkuart_2stages.v:122:5
	reg [7:0] UART_RFIFO;
	// Trace: darkuart_2stages.v:123:5
	reg UART_RREQ;
	// Trace: darkuart_2stages.v:124:5
	reg UART_RACK;
	// Trace: darkuart_2stages.v:126:5
	reg [15:0] UART_RBAUD;
	// Trace: darkuart_2stages.v:127:5
	reg [3:0] UART_RSTATE;
	// Trace: darkuart_2stages.v:129:5
	reg [2:0] UART_RXDFF;
	// Trace: darkuart_2stages.v:143:5
	wire [7:0] UART_STATE = {6'd0, UART_RREQ != UART_RACK, UART_XREQ != UART_XACK};
	// Trace: darkuart_2stages.v:145:5
	reg [7:0] UART_STATEFF;
	// Trace: darkuart_2stages.v:149:5
	reg [31:0] DATAOFF;
	// Trace: darkuart_2stages.v:151:5
	always @(posedge CLK) begin
		// Trace: darkuart_2stages.v:153:9
		if (WR) begin
			begin
				// Trace: darkuart_2stages.v:155:13
				if (BE[1]) begin
					// Trace: darkuart_2stages.v:184:17
					UART_XFIFO <= DATAI[15:8];
					// Trace: darkuart_2stages.v:185:17
					UART_XREQ <= !UART_XACK;
				end
			end
		end
		if (RES) begin
			// Trace: darkuart_2stages.v:195:13
			UART_RACK <= UART_RREQ;
			// Trace: darkuart_2stages.v:196:13
			UART_STATEFF <= UART_STATE;
		end
		else if (RD) begin
			// Trace: darkuart_2stages.v:204:13
			if (BE[1])
				// Trace: darkuart_2stages.v:204:23
				UART_RACK <= UART_RREQ;
			if (BE[0])
				// Trace: darkuart_2stages.v:206:23
				UART_STATEFF <= UART_STATE;
		end
	end
	// Trace: darkuart_2stages.v:210:5
	assign IRQ = |(UART_STATE ^ UART_STATEFF);
	// Trace: darkuart_2stages.v:214:5
	assign DATAO = {UART_TIMER, UART_RFIFO, UART_STATE};
	// Trace: darkuart_2stages.v:219:5
	always @(posedge CLK) begin
		// Trace: darkuart_2stages.v:221:9
		UART_XBAUD <= (UART_XSTATE == 6 ? UART_TIMER : (UART_XBAUD ? UART_XBAUD - 1 : UART_TIMER));
		// Trace: darkuart_2stages.v:224:9
		UART_XSTATE <= (RES || (UART_XSTATE == 1) ? 6 : (UART_XSTATE == 6 ? UART_XSTATE + (UART_XREQ != UART_XACK) : UART_XSTATE + (UART_XBAUD == 0)));
		// Trace: darkuart_2stages.v:230:9
		UART_XACK <= (RES || (UART_XSTATE == 1) ? UART_XREQ : UART_XACK);
	end
	// Trace: darkuart_2stages.v:239:5
	assign TXD = (UART_XSTATE[3] ? UART_XFIFO[UART_XSTATE[2:0]] : (UART_XSTATE == 7 ? 0 : 1));
	// Trace: darkuart_2stages.v:244:5
	always @(posedge CLK) begin
		// Trace: darkuart_2stages.v:246:9
		UART_RXDFF <= (UART_RXDFF << 1) | RXD;
		// Trace: darkuart_2stages.v:248:9
		UART_RBAUD <= (UART_RSTATE == 6 ? {1'b0, UART_TIMER[15:1]} : (UART_RBAUD ? UART_RBAUD - 1 : UART_TIMER));
		// Trace: darkuart_2stages.v:252:9
		UART_RSTATE <= (RES || (UART_RSTATE == 1) ? 6 : (UART_RSTATE == 6 ? UART_RSTATE + (UART_RXDFF[2:1] == 2'b10) : UART_RSTATE + (UART_RBAUD == 0)));
		// Trace: darkuart_2stages.v:263:9
		UART_RREQ <= (UART_RSTATE == 1 ? !UART_RACK : UART_RREQ);
		// Trace: darkuart_2stages.v:265:9
		if (UART_RSTATE[3])
			// Trace: darkuart_2stages.v:270:13
			UART_RFIFO[UART_RSTATE[2:0]] <= UART_RXDFF[2];
	end
	// Trace: darkuart_2stages.v:277:5
	assign DEBUG = {RXD, TXD, UART_XSTATE != 6, UART_RSTATE != 6};
endmodule
