module tile_add_ahb (
    input  wire        HCLK, HRESETn,
    input  wire [31:0] HADDR, HWDATA,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE, HSEL, HREADY,
    output wire [31:0] HRDATA,
    output wire        HREADYOUT, HRESP,

    // Outputs to Iris Classifier (Top 3 scores)
    output wire [31:0] score0_out, score1_out, score2_out,
    output wire        program_finished_out
);

    // 16 Registers for Matrix A and 16 for Matrix B
    reg [31:0] matA [0:15];
    reg [31:0] matB [0:15];
    wire [31:0] results [0:15];

    reg [7:0] addr_phase; 
    reg write_phase, sel_phase;
    
    reg reg_finish; // Internal register for the finish flag

    // Address Phase
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_phase <= 8'h0; 
            write_phase <= 1'b0; 
            sel_phase <= 1'b0;
            // reg_finish removed from here to avoid multi-driver error
        end else if (HSEL && HREADY && HTRANS[1]) begin
            addr_phase <= HADDR[7:0];
            write_phase <= HWRITE;
            sel_phase <= 1'b1;
        end else begin
            sel_phase <= 1'b0;
        end
    end

    // Data Phase: Execute Read/Write
    integer k;
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            reg_finish <= 1'b0; // Reset condition
            for (k=0; k<16; k=k+1) begin 
                matA[k] <= 32'h0; 
                matB[k] <= 32'h0; 
            end
        end else if (sel_phase && write_phase) begin
            // Matrix A: 0x00 to 0x3C
            if (addr_phase <= 8'h3C) 
                matA[addr_phase >> 2] <= HWDATA;
            
            // Matrix B: 0x40 to 0x7C
            else if (addr_phase >= 8'h40 && addr_phase <= 8'h7C) 
                matB[(addr_phase - 8'h40) >> 2] <= HWDATA;

            // --- ADDED: Program Finish Trigger ---
            // Address 0xC0 with Magic Number 0xDEADBEEF
            else if (addr_phase == 8'hC0) begin
                if (HWDATA == 32'hDEADBEEF)
                    reg_finish <= 1'b1;
            end
        end
    end

    // Results Readback: 0x80 to 0xBC
    wire [3:0] read_index = (addr_phase - 8'h80) >> 2;
    
    assign HRDATA = (sel_phase && !write_phase && addr_phase >= 8'h80 && addr_phase <= 8'hBC) 
                    ? results[read_index] 
                    : 32'h0;

    // 3. Parallel Adder Instantiation
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_adders
            fp_add u_adder (
                .a(matA[i]),
                .b(matB[i]),
                .out(results[i])
            );
        end
    endgenerate

    // 4. Output Logic
    assign score0_out = results[0];
    assign score1_out = results[1];
    assign score2_out = results[2];
    
    assign HREADYOUT = 1'b1;
    assign HRESP = 1'b0;

    // Indication for program finish
    assign program_finished_out = reg_finish;

endmodule