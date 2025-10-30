//ALU commands
    `define ALU_ADD     8'h1
    `define ALU_MUL     8'h2
    `define ALU_CLR     8'h3

module pipeline_mul
(
    input           clk // clock
);

    reg mult; 
    wire ready;
    reg [31:0] wb_res;
    reg       wb_we;
      
    //instruction memory
    reg [31:0] Imem [31:0];
    // we only have single register;
    reg [31:0] register;
    // program counter
    reg [31:0] pc_fetch;
    reg [31:0] pc_decode;
    reg [31:0] pc_execute;
    reg [31:0] pc_retire;

    reg [31:0] instr_decode;
    reg [31:0] instr_execute;
    reg [31:0] instr_retire;

    reg decode;
    reg execute;
    reg retire;

    reg [31:0] counter;
    reg [31:0] counter_decode;
    reg [31:0] counter_execute;
    reg [31:0] counter_retire;

    
    
/* 
Fetch
*/
wire [31:0] instr_fetch = Imem[pc_fetch % 32];
//

    /* 
    Decode stage
    */
    reg [7:0] ex_op;
    reg [23:0] ex_imm;

    
    always @ (posedge clk) begin
    if (ready) begin
            ex_op  <= instr_fetch[7:0];
            ex_imm <= instr_fetch[31:8];
            decode <= 1;
            pc_decode <= pc_fetch;
            instr_decode <= instr_fetch;
            counter_decode <= counter;
    end else begin
            ex_op  <= ex_op;  
            ex_imm <= ex_imm;
            decode <= 0;
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
    assign ready = (!mult);   
    
    // stores temporary result from multiplication
    reg [31:0] mul_res;
    reg [31:0] mul_rd;
    reg [24:0] mul_imm;

    
    //ALU
    always @ (posedge clk) begin
        if (ready && ex_op==`ALU_ADD) begin
            pc_execute <= pc_decode;
            instr_execute <= instr_decode;
            counter_execute <= counter_decode;
            execute <= 1;
            wb_we <= 1;
            mult <= 0;
            wb_res <=  rd + ex_imm;
        end

        else if (ready && ex_op==`ALU_MUL ) begin
            // start multiplying
            pc_execute <= pc_decode;
            instr_execute <= instr_decode;
            counter_execute <= counter_decode;
            execute <= 1;
            mult <= 1;
            wb_we <= 0; 
            mul_rd <= rd ;
            mul_imm <= ex_imm;
            mul_res <= 0;
        end
        else if (ready && ex_op==`ALU_CLR ) begin
            // start clr
            pc_execute <= pc_decode;
            instr_execute <= instr_decode;
            counter_execute <= counter_decode;
            execute <= 1;
            mult <= 0;
            wb_we <= 1; 
            wb_res <= 0;
        end
        // Start the multiplication. The number of cycles depends on mul_imm
        else if (mult) begin 
            if (mul_imm == 0 || mul_imm == 1)begin
            // do one round 
                wb_we <= 1;
                mult <= 0;
                wb_res <= mul_res + ( mul_rd & {32 {mul_imm[0]} });
            end
            
            else begin
            // do one round 
                mult <= 1;
                wb_we <= 0; 
                mul_imm <= mul_imm >> 1;
                mul_rd <= mul_rd << 1;
                mul_res <= mul_res + ( mul_rd & {32 {mul_imm[0]} });
            end

            
        end
        // default: illegal instructions.  
        else begin
            wb_we <= 0;
            mult <= 0;
            execute <= 0;
        end
    end

    /* 
    Writeback stage: writing results into the register file.
    */  
    // 

    
    always @ (posedge clk) begin
      if (wb_we) begin
        pc_retire <= pc_execute;
        instr_retire <= instr_execute;
        register <= wb_res;
        counter_retire <= counter_execute;
        retire <= 1;
    end
        else begin 
            retire <= 0;
        end
    end
    
    // update the pc_fetch and counter
    always @ (posedge clk) begin
        if (ready) begin
            pc_fetch <= pc_fetch + 1;
            counter <= counter + 1;
        end
    end

endmodule


