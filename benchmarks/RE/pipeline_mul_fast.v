//ALU commands
    `define ALU_ADD     8'h1
    `define ALU_MUL     8'h2
    `define ALU_CLR     8'h3

module pipeline_mul_fast
(
    input           clk // clock
);

  
    //instruction memory
    reg [31:0] Imem [31:0];
    // we only have single register;
    reg [31:0] register;
    // program counter
    reg [31:0] pc;
    reg [31:0] nxpc;
    reg [31:0] nxpc2;
    reg [31:0] nxpc3;
    wire [31:0] instr_r = Imem[pc % 32];
    wire [7:0] op_ctr = instr_r[7:0];
    wire [23:0] imm_ctr = instr_r[31:8];
    wire [31:0] instr = Imem[nxpc3 % 32];

    wire [31:0] instr_exe = Imem[nxpc % 32];
    wire [7:0] op_exe = instr_exe[7:0];
    wire [23:0] imm_exe = instr_exe[31:8];

    wire [31:0] instr_decode = Imem[nxpc2 % 32];
    wire [7:0] op_decode = instr_decode[7:0];
    wire [23:0] imm_decode = instr_decode[31:8];
    /* 
    Decode stage
    */
    reg [7:0] ex_op;
    reg [23:0] ex_imm;
    wire decode = ready;
    reg decode_reg;
    always @ (posedge clk) begin
    if (ready) begin
            ex_op  <= instr[7:0];
            ex_imm <= instr[31:8];
            decode_reg <= 1;
    end else begin
            ex_op  <= ex_op;  
            ex_imm <= ex_imm;
            decode_reg <= 0;
    end
    end

/* 
Execute stage: compute results.
*/
    wire [31:0] rd;
    //read from register file, or forward the result of the previous instruction
    assign rd = wb_we ? wb_res : register;

    // are we ready for the next instruction?
    // whenever we're not multiplying
    reg mult; 
    wire ready;
    assign ready = (!mult);   
    
    // stores temporary result from multiplication
    reg [31:0] mul_res;
    reg [31:0] mul_rd;
    reg [23:0] mul_imm;

    reg [31:0] rd_old;
    
    //ALU
    always @ (posedge clk) begin
        if (ready && ex_op==`ALU_ADD) begin
                wb_we <= 1;
                mult <= 0;
                wb_res <=  rd + ex_imm;
        end

        else if (ready && ex_op==`ALU_MUL ) begin
            // start multiplying
            mult <= 1;
            wb_we <= 0;	
            mul_rd <= rd ;
            mul_imm <= ex_imm;
            mul_res <= 0;
            rd_old <= rd;
        end
        else if (ready && ex_op==`ALU_CLR ) begin
            // start multiplying
            mult <= 0;
            wb_we <= 1;	
            mul_res <= 0;
        end

        else if (mult) begin
            if (mul_imm == 0 || mul_imm == 1)begin
            // do one round 
                wb_we <= 1;
                mult <= 0;
                wb_res <= ( mul_rd & {32 {mul_imm[0]} });
            end
            else if (mul_rd == 0 || mul_rd == 1)begin
            // do one round 
                wb_we <= 1;
                mult <= 0;
                wb_res <= mul_res + ( mul_imm & {32 {mul_rd[0]} });
            end
            
            else begin
            // do one round 
                mult <= 1;
                wb_we <= 0;	
                mul_imm <= mul_imm << 1;
                mul_rd <= mul_rd >> 1;
                mul_res <= mul_res + ( mul_imm & {32 {mul_rd[0]} });
            end

            
        end
        // default: write old value.  
        else begin
            wb_we <= 1;
            mult <= 0;
            wb_res <=  register;
        end
    end

    /* 
    Writeback stage: writing results into the register file.
    */  
    reg [31:0] wb_res;
    reg       wb_we;
    //Writeback
    reg retire;
    reg [31:0] register_old;
    wire retire_wire;
    assign retire_wire = wb_we;
    always @ (posedge clk) begin
      if (wb_we) begin
        register_old <= rd_old;
        register <= wb_res;
        retire <= 1;
    end
        else begin 
            retire <= 0;
        end
    end
    
    always @ (posedge clk) begin
        if (ready) begin
            nxpc3 <= nxpc3 + 1;
            nxpc2 <= nxpc3;
            nxpc <= nxpc2;
        end
        if (wb_we) begin
            pc <= nxpc;
        end
    end


endmodule

