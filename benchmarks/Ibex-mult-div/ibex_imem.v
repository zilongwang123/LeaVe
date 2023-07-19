`timescale 1ns/1ps
module ibex_imem #(
    parameter   DEPTH = 1024
) (
    input                   clk,
    input                   sram_req,
    output                  sram_gnt,
    output                  sram_rvalid,
    input [9 : 0]           sram_addr,
    output[31 : 0]          sram_rdata,
    input [31:0]            pc_ctr,
    output [31:0]           instr_ctr,
    input [31:0]            pc_id,
);

    //// for contract
    wire [31:0] pc_ctr;
    wire [31:0] instr_ctr;
    assign instr_ctr = imem[pc_ctr[11:2]];
    wire [31:0] instr_id;
    assign instr_id = imem [pc_id[11:2]];


    reg   [31 : 0]          imem[0 : DEPTH - 1];
    reg   [31 : 0]          sram_rdata_t;
    reg                     sram_gnt_t;
    reg                     sram_rvalid_t;

    always @(posedge clk) begin
        if (sram_req) begin
            if (sram_gnt_t == 0) begin
                sram_gnt_t <= 1;
            end
            else begin
                sram_gnt_t <= 0;
            end
            if (sram_gnt_t == 1) begin
                sram_rdata_t <= imem[sram_addr];
                sram_rvalid_t <= 1;
            end
        end

        if (sram_rvalid_t == 1) begin
            sram_rvalid_t <= 0;
        end

    end
    assign sram_rdata = sram_rdata_t;
    assign sram_gnt = sram_gnt_t;
    assign sram_rvalid = sram_rvalid_t;
 
endmodule
