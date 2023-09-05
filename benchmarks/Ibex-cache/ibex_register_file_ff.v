module ibex_register_file_ff (
	clk_i,
	rst_ni,
	test_en_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	err_o,
	rf_raddr_a_o_ctr,
	rf_raddr_b_o_ctr,
	rf_raddr_b_o_ctr_id,
	rf_rdata_a_fwd_ctr,
	rf_rdata_b_fwd_ctr,
	rf_rdata_b_fwd_ctr_id,
);
	parameter [0:0] RV32E = 0;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] DummyInstructions = 0;
	parameter [0:0] WrenCheck = 0;
	parameter [DataWidth - 1:0] WordZeroVal = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	input wire [4:0] raddr_a_i;
	output wire [DataWidth - 1:0] rdata_a_o;
	input wire [4:0] raddr_b_i;
	output wire [DataWidth - 1:0] rdata_b_o;
	input wire [4:0] waddr_a_i;
	input wire [DataWidth - 1:0] wdata_a_i;
	input wire we_a_i;
	output wire err_o;
	localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
	localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
	wire [DataWidth - 1:0] rf_reg [0:NUM_WORDS - 1];
	reg [NUM_WORDS - 1:0] we_a_dec;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin : we_a_decoder
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				we_a_dec[i] = (waddr_a_i == sv2v_cast_5(i) ? we_a_i : 1'b0);
		end
	end
	// generate
	// 	if (WrenCheck) begin : gen_wren_check
	// 		wire [NUM_WORDS - 1:0] we_a_dec_buf;
	// 		prim_generic_buf #(.Width(NUM_WORDS)) u_prim_generic_buf(
	// 			.in_i(we_a_dec),
	// 			.out_o(we_a_dec_buf)
	// 		);
	// 		prim_onehot_check #(
	// 			.AddrWidth(ADDR_WIDTH),
	// 			.AddrCheck(1),
	// 			.EnableCheck(1)
	// 		) u_prim_onehot_check(
	// 			.clk_i(clk_i),
	// 			.rst_ni(rst_ni),
	// 			.oh_i(we_a_dec_buf),
	// 			.addr_i(waddr_a_i),
	// 			.en_i(we_a_i),
	// 			.err_o(err_o)
	// 		);
	// 	end
	// 	else begin : gen_no_wren_check
			wire unused_strobe;
			assign unused_strobe = we_a_dec[0];
			assign err_o = 1'b0;
	// 	end
	// endgenerate
	
	generate
	genvar i;
		for (i = 1; i < NUM_WORDS; i = i + 1) begin : g_rf_flops
			reg [DataWidth - 1:0] rf_reg_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rf_reg_q <= WordZeroVal;
				else if (we_a_dec[i])
					rf_reg_q <= wdata_a_i;
			assign rf_reg[i] = rf_reg_q;
		end
		// if (DummyInstructions) begin : g_dummy_r0
		// 	wire we_r0_dummy;
		// 	reg [DataWidth - 1:0] rf_r0_q;
		// 	assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
		// 	always @(posedge clk_i or negedge rst_ni)
		// 		if (!rst_ni)
		// 			rf_r0_q <= WordZeroVal;
		// 		else if (we_r0_dummy)
		// 			rf_r0_q <= wdata_a_i;
		// 	assign rf_reg[0] = (dummy_instr_id_i ? rf_r0_q : WordZeroVal);
		// end
		// else begin : g_normal_r0
			wire unused_dummy_instr;
			assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
			assign rf_reg[0] = WordZeroVal;
		// end
	endgenerate
	assign rdata_a_o = rf_reg[raddr_a_i];
	assign rdata_b_o = rf_reg[raddr_b_i];
	wire unused_test_en;
	assign unused_test_en = test_en_i;

	input wire [4:0]  rf_raddr_a_o_ctr;
	output wire [31:0]	rf_rdata_a_fwd_ctr;
	assign rf_rdata_a_fwd_ctr = rf_reg[rf_raddr_a_o_ctr];
	input wire [4:0]  rf_raddr_b_o_ctr;
	output wire [31:0]	rf_rdata_b_fwd_ctr;
	assign rf_rdata_b_fwd_ctr = rf_reg[rf_raddr_b_o_ctr];
	input wire [4:0]  rf_raddr_b_o_ctr_id;
	output wire [31:0]	rf_rdata_b_fwd_ctr_id;
	assign rf_rdata_b_fwd_ctr_id = rf_reg[rf_raddr_b_o_ctr_id];
endmodule
