module RISCV_Decoder (
	instr_i,
	format_o,
	op_o,
	funct_3_o,
	funct_7_o,
	rd_o,
	rs1_o,
	rs2_o,
	imm_o
);
	// Trace: RISCV_Decoder.v.v:48:5
	input wire [31:0] instr_i;
	// Trace: RISCV_Decoder.v.v:49:5
	output wire [2:0] format_o;
	// Trace: RISCV_Decoder.v.v:50:5
	output wire [6:0] op_o;
	// Trace: RISCV_Decoder.v.v:51:5
	output wire [2:0] funct_3_o;
	// Trace: RISCV_Decoder.v.v:52:5
	output wire [6:0] funct_7_o;
	// Trace: RISCV_Decoder.v.v:53:5
	output wire [4:0] rd_o;
	// Trace: RISCV_Decoder.v.v:54:5
	output wire [4:0] rs1_o;
	// Trace: RISCV_Decoder.v.v:55:5
	output wire [4:0] rs2_o;
	// Trace: RISCV_Decoder.v.v:56:5
	output wire [31:0] imm_o;
	// Trace: RISCV_Decoder.v.v:59:5
	assign op_o = instr_i[6:0];
	// Trace: RISCV_Decoder.v.v:60:5
	assign funct_3_o = instr_i[14:12];
	// Trace: RISCV_Decoder.v.v:61:5
	assign funct_7_o = instr_i[31:25];
	// Trace: RISCV_Decoder.v.v:62:5
	assign format_o = (op_o == 7'b0110011 ? 3'd0 : (((op_o == 7'b0010011) || (op_o == 7'b1100111)) || (op_o == 7'b0000011) ? 3'd1 : (op_o == 7'b0100011 ? 3'd2 : (op_o == 7'b1100011 ? 3'd3 : ((op_o == 7'b0110111) || (op_o == 7'b0010111) ? 3'd4 : (op_o == 7'b1101111 ? 3'd5 : 3'd6))))));
	// Trace: RISCV_Decoder.v.v:91:5
	assign rd_o = ((format_o == 3'd2) || (format_o == 3'd3) ? 5'b00000 : instr_i[11:7]);
	// Trace: RISCV_Decoder.v.v:92:5
	assign rs1_o = ((format_o == 3'd4) || (format_o == 3'd5) ? 5'b00000 : instr_i[19:15]);
	// Trace: RISCV_Decoder.v.v:93:5
	assign rs2_o = (((format_o == 3'd1) || (format_o == 3'd4)) || (format_o == 3'd5) ? 5'b00000 : instr_i[24:20]);
	// Trace: RISCV_Decoder.v.v:94:5
	assign imm_o = (format_o == 3'd0 ? 32'b00000000000000000000000000000000 : (format_o == 3'd1 ? {20'b00000000000000000000, instr_i[31:20]} : (format_o == 3'd2 ? {20'b00000000000000000000, instr_i[31:25], instr_i[11:7]} : (format_o == 3'd3 ? {19'b0000000000000000000, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:6], 1'b0} : (format_o == 3'd4 ? {instr_i[31:12], 12'b000000000000} : (format_o == 3'd5 ? {12'b000000000000, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0} : 32'b00000000000000000000000000000000))))));
endmodule
