module RVFI_3stage (
	clock,
	retire,
	instruction,
	old_regfile,
	new_regfile,
	old_pc,
	new_pc,
	mem_req,
	mem_addr,
	mem_rdata,
	mem_wdata,
	mem_we,
	mem_be,
	rvfi_valid,
	rvfi_order,
	rvfi_insn,
	rvfi_trap,
	rvfi_halt,
	rvfi_intr,
	rvfi_mode,
	rvfi_ixl,
	rvfi_rs1_addr,
	rvfi_rs2_addr,
	rvfi_rs3_addr,
	rvfi_rs1_rdata,
	rvfi_rs2_rdata,
	rvfi_rs3_rdata,
	rvfi_rd_addr,
	rvfi_rd_wdata,
	rvfi_pc_rdata,
	rvfi_pc_wdata,
	rvfi_mem_addr,
	rvfi_mem_rmask,
	rvfi_mem_wmask,
	rvfi_mem_rdata,
	rvfi_mem_wdata
);
	// Trace: RVFI_2stage.v:2:2
	input clock;
	// Trace: RVFI_2stage.v:3:2
	input retire;
	// Trace: RVFI_2stage.v:4:2
	input [31:0] instruction;
	// Trace: RVFI_2stage.v:5:2
	input [1023:0] old_regfile;
	// Trace: RVFI_2stage.v:6:2
	input [1023:0] new_regfile;
	// Trace: RVFI_2stage.v:7:2
	input [31:0] old_pc;
	// Trace: RVFI_2stage.v:8:2
	input [31:0] new_pc;
	// Trace: RVFI_2stage.v:9:2
	input mem_req;
	// Trace: RVFI_2stage.v:10:2
	input [31:0] mem_addr;
	// Trace: RVFI_2stage.v:11:2
	input [31:0] mem_rdata;
	// Trace: RVFI_2stage.v:12:2
	input [31:0] mem_wdata;
	// Trace: RVFI_2stage.v:13:2
	input mem_we;
	// Trace: RVFI_2stage.v:14:2
	input [3:0] mem_be;
	// Trace: RVFI_2stage.v:16:2
	output reg rvfi_valid;
	// Trace: RVFI_2stage.v:17:5
	output reg [63:0] rvfi_order;
	// Trace: RVFI_2stage.v:18:5
	output reg [31:0] rvfi_insn;
	// Trace: RVFI_2stage.v:19:5
	output reg rvfi_trap;
	// Trace: RVFI_2stage.v:20:5
	output reg rvfi_halt;
	// Trace: RVFI_2stage.v:21:5
	output reg rvfi_intr;
	// Trace: RVFI_2stage.v:22:5
	output reg [1:0] rvfi_mode;
	// Trace: RVFI_2stage.v:23:5
	output reg [1:0] rvfi_ixl;
	// Trace: RVFI_2stage.v:24:5
	output reg [4:0] rvfi_rs1_addr;
	// Trace: RVFI_2stage.v:25:5
	output reg [4:0] rvfi_rs2_addr;
	// Trace: RVFI_2stage.v:26:5
	output reg [4:0] rvfi_rs3_addr;
	// Trace: RVFI_2stage.v:27:5
	output reg [31:0] rvfi_rs1_rdata;
	// Trace: RVFI_2stage.v:28:5
	output reg [31:0] rvfi_rs2_rdata;
	// Trace: RVFI_2stage.v:29:5
	output reg [31:0] rvfi_rs3_rdata;
	// Trace: RVFI_2stage.v:30:5
	output reg [4:0] rvfi_rd_addr;
	// Trace: RVFI_2stage.v:31:5
	output reg [31:0] rvfi_rd_wdata;
	// Trace: RVFI_2stage.v:32:5
	output reg [31:0] rvfi_pc_rdata;
	// Trace: RVFI_2stage.v:33:5
	output reg [31:0] rvfi_pc_wdata;
	// Trace: RVFI_2stage.v:34:5
	output reg [31:0] rvfi_mem_addr;
	// Trace: RVFI_2stage.v:35:5
	output reg [3:0] rvfi_mem_rmask;
	// Trace: RVFI_2stage.v:36:5
	output reg [3:0] rvfi_mem_wmask;
	// Trace: RVFI_2stage.v:37:5
	output reg [31:0] rvfi_mem_rdata;
	// Trace: RVFI_2stage.v:38:5
	output reg [31:0] rvfi_mem_wdata;
	// Trace: RVFI_2stage.v:41:2
	wire [6:0] op;
	// Trace: RVFI_2stage.v:42:5
	wire [2:0] funct_3;
	// Trace: RVFI_2stage.v:43:5
	wire [6:0] funct_7;
	// Trace: RVFI_2stage.v:44:5
	wire [2:0] format;
	// Trace: RVFI_2stage.v:45:5
	wire [31:0] imm;
	// Trace: RVFI_2stage.v:46:5
	wire [4:0] rs1;
	// Trace: RVFI_2stage.v:47:5
	wire [4:0] rs2;
	// Trace: RVFI_2stage.v:48:5
	wire [4:0] rd;
	// Trace: RVFI_2stage.v:50:2
	RISCV_Decoder RISCV_Decoder(
		.instr_i(instruction),
		.format_o(format),
		.op_o(op),
		.funct_3_o(funct_3),
		.funct_7_o(funct_7),
		.rd_o(rd),
		.rs1_o(rs1),
		.rs2_o(rs2),
		.imm_o(imm)
	);
	// Trace: RVFI_2stage.v:62:2
	initial begin
		// Trace: RVFI_2stage.v:63:3
		rvfi_valid <= 0;
		// Trace: RVFI_2stage.v:64:3
		rvfi_order <= 0;
		// Trace: RVFI_2stage.v:65:3
		rvfi_insn <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:66:3
		rvfi_trap <= 0;
		// Trace: RVFI_2stage.v:67:3
		rvfi_halt <= 0;
		// Trace: RVFI_2stage.v:68:3
		rvfi_intr <= 0;
		// Trace: RVFI_2stage.v:69:3
		rvfi_mode <= 2'b00;
		// Trace: RVFI_2stage.v:70:3
		rvfi_ixl <= 2'b00;
		// Trace: RVFI_2stage.v:71:3
		rvfi_rs1_addr <= 5'b00000;
		// Trace: RVFI_2stage.v:72:3
		rvfi_rs2_addr <= 5'b00000;
		// Trace: RVFI_2stage.v:73:3
		rvfi_rs3_addr <= 5'b00000;
		// Trace: RVFI_2stage.v:74:3
		rvfi_rs1_rdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:75:3
		rvfi_rs2_rdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:76:3
		rvfi_rs3_rdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:77:3
		rvfi_rd_addr <= 5'b00000;
		// Trace: RVFI_2stage.v:78:3
		rvfi_rd_wdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:79:3
		rvfi_pc_rdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:80:3
		rvfi_pc_wdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:81:3
		rvfi_mem_addr <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:82:3
		rvfi_mem_rdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:83:3
		rvfi_mem_rmask <= 4'b0000;
		// Trace: RVFI_2stage.v:84:3
		rvfi_mem_wdata <= 32'b00000000000000000000000000000000;
		// Trace: RVFI_2stage.v:85:3
		rvfi_mem_wmask <= 4'b0000;
	end
	// Trace: RVFI_2stage.v:87:5
	wire [31:0] mem_mask;
	// Trace: RVFI_2stage.v:88:5
	assign mem_mask[0] = mem_be[0];
	// Trace: RVFI_2stage.v:89:5
	assign mem_mask[1] = mem_be[0];
	// Trace: RVFI_2stage.v:90:5
	assign mem_mask[2] = mem_be[0];
	// Trace: RVFI_2stage.v:91:5
	assign mem_mask[3] = mem_be[0];
	// Trace: RVFI_2stage.v:92:5
	assign mem_mask[4] = mem_be[0];
	// Trace: RVFI_2stage.v:93:5
	assign mem_mask[5] = mem_be[0];
	// Trace: RVFI_2stage.v:94:5
	assign mem_mask[6] = mem_be[0];
	// Trace: RVFI_2stage.v:95:5
	assign mem_mask[7] = mem_be[0];
	// Trace: RVFI_2stage.v:96:5
	assign mem_mask[8] = mem_be[1];
	// Trace: RVFI_2stage.v:97:5
	assign mem_mask[9] = mem_be[1];
	// Trace: RVFI_2stage.v:98:5
	assign mem_mask[10] = mem_be[1];
	// Trace: RVFI_2stage.v:99:5
	assign mem_mask[11] = mem_be[1];
	// Trace: RVFI_2stage.v:100:5
	assign mem_mask[12] = mem_be[1];
	// Trace: RVFI_2stage.v:101:5
	assign mem_mask[13] = mem_be[1];
	// Trace: RVFI_2stage.v:102:5
	assign mem_mask[14] = mem_be[1];
	// Trace: RVFI_2stage.v:103:5
	assign mem_mask[15] = mem_be[1];
	// Trace: RVFI_2stage.v:104:5
	assign mem_mask[16] = mem_be[2];
	// Trace: RVFI_2stage.v:105:5
	assign mem_mask[17] = mem_be[2];
	// Trace: RVFI_2stage.v:106:5
	assign mem_mask[18] = mem_be[2];
	// Trace: RVFI_2stage.v:107:5
	assign mem_mask[19] = mem_be[2];
	// Trace: RVFI_2stage.v:108:5
	assign mem_mask[20] = mem_be[2];
	// Trace: RVFI_2stage.v:109:5
	assign mem_mask[21] = mem_be[2];
	// Trace: RVFI_2stage.v:110:5
	assign mem_mask[22] = mem_be[2];
	// Trace: RVFI_2stage.v:111:5
	assign mem_mask[23] = mem_be[2];
	// Trace: RVFI_2stage.v:112:5
	assign mem_mask[24] = mem_be[3];
	// Trace: RVFI_2stage.v:113:5
	assign mem_mask[25] = mem_be[3];
	// Trace: RVFI_2stage.v:114:5
	assign mem_mask[26] = mem_be[3];
	// Trace: RVFI_2stage.v:115:5
	assign mem_mask[27] = mem_be[3];
	// Trace: RVFI_2stage.v:116:5
	assign mem_mask[28] = mem_be[3];
	// Trace: RVFI_2stage.v:117:5
	assign mem_mask[29] = mem_be[3];
	// Trace: RVFI_2stage.v:118:5
	assign mem_mask[30] = mem_be[3];
	// Trace: RVFI_2stage.v:119:5
	assign mem_mask[31] = mem_be[3];
	// Trace: RVFI_2stage.v:121:2
	always @(posedge clock)
		// Trace: RVFI_2stage.v:122:3
		if (retire == 1'b1) begin
			// Trace: RVFI_2stage.v:123:4
			rvfi_valid <= 1;
			// Trace: RVFI_2stage.v:124:4
			rvfi_order <= rvfi_order + 1;
			// Trace: RVFI_2stage.v:125:4
			rvfi_insn <= instruction;
			// Trace: RVFI_2stage.v:126:4
			rvfi_trap <= 0;
			// Trace: RVFI_2stage.v:127:4
			rvfi_halt <= 0;
			// Trace: RVFI_2stage.v:128:4
			rvfi_intr <= 0;
			// Trace: RVFI_2stage.v:129:4
			rvfi_mode <= 2'b00;
			// Trace: RVFI_2stage.v:130:4
			rvfi_ixl <= 2'b00;
			// Trace: RVFI_2stage.v:131:4
			rvfi_rs1_addr <= rs1;
			// Trace: RVFI_2stage.v:132:4
			rvfi_rs2_addr <= rs2;
			// Trace: RVFI_2stage.v:133:4
			rvfi_rs3_addr <= 5'b00000;
			// Trace: RVFI_2stage.v:134:4
			rvfi_rs1_rdata <= (rs1 == 0 ? 32'b00000000000000000000000000000000 : old_regfile[(31 - rs1) * 32+:32]);
			// Trace: RVFI_2stage.v:135:4
			rvfi_rs2_rdata <= (rs2 == 0 ? 32'b00000000000000000000000000000000 : old_regfile[(31 - rs2) * 32+:32]);
			// Trace: RVFI_2stage.v:136:4
			rvfi_rs3_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:137:4
			rvfi_rd_addr <= rd;
			// Trace: RVFI_2stage.v:138:4
			rvfi_rd_wdata <= (rd == 0 ? 32'b00000000000000000000000000000000 : new_regfile[(31 - rd) * 32+:32]);
			// Trace: RVFI_2stage.v:139:4
			rvfi_pc_rdata <= old_pc;
			// Trace: RVFI_2stage.v:140:4
			rvfi_pc_wdata <= new_pc;
			// Trace: RVFI_2stage.v:141:4
			rvfi_mem_addr <= (mem_req == 0 ? 32'b00000000000000000000000000000000 : mem_addr);
			// Trace: RVFI_2stage.v:142:4
			rvfi_mem_rdata <= (mem_req == 0 ? 32'b00000000000000000000000000000000 : (mem_we == 1 ? 32'b00000000000000000000000000000000 : mem_rdata & mem_mask));
			// Trace: RVFI_2stage.v:152:4
			rvfi_mem_rmask <= (mem_req == 0 ? 4'b0000 : (mem_we == 1 ? 4'b0000 : mem_be));
			// Trace: RVFI_2stage.v:161:4
			rvfi_mem_wdata <= (mem_req == 0 ? 32'b00000000000000000000000000000000 : (mem_we == 0 ? 32'b00000000000000000000000000000000 : mem_wdata & mem_mask));
			// Trace: RVFI_2stage.v:171:4
			rvfi_mem_wmask <= (mem_req == 0 ? 4'b0000 : (mem_we == 0 ? 4'b0000 : mem_be));
		end
		else begin
			// Trace: RVFI_2stage.v:181:3
			rvfi_valid <= 0;
			// Trace: RVFI_2stage.v:182:3
			rvfi_order <= rvfi_order;
			// Trace: RVFI_2stage.v:183:3
			rvfi_insn <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:184:3
			rvfi_trap <= 0;
			// Trace: RVFI_2stage.v:185:3
			rvfi_halt <= 0;
			// Trace: RVFI_2stage.v:186:3
			rvfi_intr <= 0;
			// Trace: RVFI_2stage.v:187:3
			rvfi_mode <= 2'b00;
			// Trace: RVFI_2stage.v:188:3
			rvfi_ixl <= 2'b00;
			// Trace: RVFI_2stage.v:189:3
			rvfi_rs1_addr <= 5'b00000;
			// Trace: RVFI_2stage.v:190:3
			rvfi_rs2_addr <= 5'b00000;
			// Trace: RVFI_2stage.v:191:3
			rvfi_rs3_addr <= 5'b00000;
			// Trace: RVFI_2stage.v:192:3
			rvfi_rs1_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:193:3
			rvfi_rs2_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:194:3
			rvfi_rs3_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:195:3
			rvfi_rd_addr <= 5'b00000;
			// Trace: RVFI_2stage.v:196:3
			rvfi_rd_wdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:197:3
			rvfi_pc_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:198:3
			rvfi_pc_wdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:199:3
			rvfi_mem_addr <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:200:3
			rvfi_mem_rdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:201:3
			rvfi_mem_rmask <= 4'b0000;
			// Trace: RVFI_2stage.v:202:3
			rvfi_mem_wdata <= 32'b00000000000000000000000000000000;
			// Trace: RVFI_2stage.v:203:3
			rvfi_mem_wmask <= 4'b0000;
		end
endmodule
