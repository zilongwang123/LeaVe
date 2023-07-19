`timescale 1ns/1ps
module ibex_dmem #(
    parameter   DEPTH = 1024
) (
    input                   clk,
    input                   sram_req,
    output                  sram_gnt,
    output                  sram_rvalid,
    input                   sram_we,    
    input [3 : 0]           sram_be,
    input [9 : 0]           sram_addr,
    input [31 : 0]          sram_wdata,
    output[31 : 0]          sram_rdata,
    //// for contract
    input [31:0]            lsu_addr_ctr,

);

    reg   [31 : 0]          dmem[0 : DEPTH - 1];

    reg   [31 : 0]          sram_rdata_t;
    reg                     sram_gnt_t;
    reg                     sram_rvalid_t;

    reg   [31 : 0]          cache_data;
    reg   [9  : 0]          cache_addr;
    reg                     cache_valid;
    reg                     delayed; // delay signal for cache miss 

    wire cache_hit;
    assign cache_hit = ( ( !sram_we ) && cache_valid ) ? ( cache_addr == sram_addr ) : 0;

    
    always @(posedge clk) begin
        if (sram_req) begin
            if(sram_we) begin //store
                if (sram_gnt_t == 0) begin
                    sram_gnt_t <= 1;
                end
                else begin
                    sram_gnt_t <= 0;
                end
                if (sram_gnt_t == 1) begin
                    if (sram_be[0]) begin
                        dmem[sram_addr][7:0] <= sram_wdata[7:0];
                    end
                    else begin 
                        dmem[sram_addr][7:0] <= 8'h0;
                    end
                    if (sram_be[1]) begin
                        dmem[sram_addr][15:8] <= sram_wdata[15:8];
                    end
                    else begin 
                        dmem[sram_addr][15:8] <= 8'h0;
                    end
                    if (sram_be[2]) begin
                        dmem[sram_addr][23:16] <= sram_wdata[23:16];
                    end
                    else begin 
                        dmem[sram_addr][23:16] <= 8'h0;
                    end
                    if (sram_be[3]) begin
                        dmem[sram_addr][31:24] <= sram_wdata[31:24];
                    end
                    else begin 
                        dmem[sram_addr][31:24] <= 8'h0;
                    end
                    sram_rvalid_t <= 1;
                    cache_valid <= 0;
                end
            end
            

            else begin //load
                if (cache_hit) begin //cache hit
                    if (sram_gnt_t == 0) begin
                        sram_gnt_t <= 1;
                    end
                    else begin
                        sram_gnt_t <= 0;
                    end


                    if (sram_gnt_t == 1) begin
                        if (sram_be[0]) begin
                            sram_rdata_t[7:0] <= cache_data[7:0];
                        end
                        else begin 
                            sram_rdata_t[7:0] <= 8'h0;
                        end
                        if (sram_be[1]) begin
                            sram_rdata_t[15:8] <= cache_data[15:8];
                        end
                        else begin 
                            sram_rdata_t[15:8] <= 8'h0;
                        end
                        if (sram_be[2]) begin
                            sram_rdata_t[23:16] <= cache_data[23:16];
                        end
                        else begin 
                            sram_rdata_t[23:16] <= 8'h0;
                        end
                        if (sram_be[3]) begin
                            sram_rdata_t[31:24] <= cache_data[31:24];
                        end
                        else begin 
                            sram_rdata_t[31:24] <= 8'h0;
                        end
                        sram_rvalid_t <= 1;
                    end

                end
                else begin //cache miss
                    if (sram_gnt_t == 0) begin
                        sram_gnt_t <= 1;
                    end 
                    else begin
                        sram_gnt_t <= 0;
                    end

                    if (sram_gnt_t) begin
                        delayed <= 1;
                    end
                    else begin
                        delayed <= 0;
                    end
                end
            end
            
        end
        if (sram_rvalid_t == 1) begin
            sram_rvalid_t <= 0;
        end
        if (delayed == 1) begin
            if (sram_be[0]) begin
                sram_rdata_t[7:0] <= dmem[sram_addr][7:0];
            end
            else begin 
                sram_rdata_t[7:0] <= 8'h0;
            end
            if (sram_be[1]) begin
                sram_rdata_t[15:8] <= dmem[sram_addr][15:8];
            end
            else begin 
                sram_rdata_t[15:8] <= 8'h0;
            end
            if (sram_be[2]) begin
                sram_rdata_t[23:16] <= dmem[sram_addr][23:16];
            end
            else begin 
                sram_rdata_t[23:16] <= 8'h0;
            end
            if (sram_be[3]) begin
                sram_rdata_t[31:24] <= dmem[sram_addr][31:24];
            end
            else begin 
                sram_rdata_t[31:24] <= 8'h0;
            end
            sram_rvalid_t <= 1;
            cache_valid <= 1;
            cache_addr <= sram_addr;
            cache_data <= dmem[sram_addr]; // Always word.
            delayed <= 0;
        end

    end
    assign sram_rdata = sram_rdata_t;
    assign sram_gnt = sram_gnt_t;
    assign sram_rvalid = sram_rvalid_t;

    ////for contract
    wire [31:0] load_data_ctr;
    assign load_data_ctr = dmem[lsu_addr_ctr[11:2]];
    wire [31:0] load_data_id;
    assign load_data_id = dmem[sram_addr];

    // for state invariant 
    wire [31:0] cache_coherence_data;
    assign cache_coherence_data = dmem[cache_addr];

endmodule
