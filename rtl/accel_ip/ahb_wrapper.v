`timescale 1ns / 1ps
module ahb_wrapper (
    // --------------------------------------------------------------------------
    // AHB-Lite Global Signals
    // --------------------------------------------------------------------------
    input  wire        HCLK,      // System Clock
    input  wire        HRESETn,   // Active Low Reset

    // --------------------------------------------------------------------------
    // AHB-Lite Subordinate Interface
    // --------------------------------------------------------------------------
    input  wire        HSEL,      // Select signal (Decoder)
    input  wire [31:0] HADDR,     // Address Bus
    input  wire        HWRITE,    // Write Enable (1=Write, 0=Read)
    input  wire [1:0]  HTRANS,    // Transfer Type (00=IDLE, 10=NONSEQ)
    input  wire [2:0]  HSIZE,     // Transfer Size (ignored here, assumes 32-bit)
    input  wire [2:0]  HBURST,    // Burst Type (ignored)
    input  wire [3:0]  HPROT,     // Protection (ignored)
    input  wire [31:0] HWDATA,    // Write Data Bus
    
    output reg  [31:0] HRDATA,    // Read Data Bus
    output wire        HREADYOUT, // Transfer Done (1=Ready)
    output wire        HRESP,     // Response (0=OKAY, 1=ERROR)
    
    output wire commit_top_out,
    output wire commit_left_out,
    
    output wire [31:0] reg_in_left_0, reg_in_left_1, reg_in_left_2, reg_in_left_3,
    output wire [31:0] reg_in_top_0,  reg_in_top_1,  reg_in_top_2,  reg_in_top_3,
    output reg [31:0] reg_load_weights,
    output reg [31:0] reg_in_bias_0, reg_in_bias_1, reg_in_bias_2, reg_in_bias_3,
    
    // INPUTS from AI Core (To read the results back)
    input  wire [31:0] w_out_col_0, w_out_col_1, w_out_col_2, w_out_col_3
);

    // --------------------------------------------------------------------------
    // AHB Protocol Constants
    // --------------------------------------------------------------------------
    localparam RESP_OKAY  = 1'b0;
    localparam RESP_ERROR = 1'b1;
    localparam TRANS_IDLE = 2'b00;

    assign HREADYOUT = 1'b1; 
    assign HRESP     = RESP_OKAY;

    // --------------------------------------------------------------------------
    // Shadow Registers (Internal Staging Area)
    // --------------------------------------------------------------------------
    reg [31:0] shadow_in_left_0, shadow_in_left_1, shadow_in_left_2, shadow_in_left_3;
    reg [31:0] shadow_in_top_0,  shadow_in_top_1,  shadow_in_top_2,  shadow_in_top_3;

    // --------------------------------------------------------------------------
    // AHB Address Phase Sampling
    // --------------------------------------------------------------------------
    reg [31:0] addr_reg;
    reg        write_enable_reg;
    reg        sel_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg         <= 32'h0;
            write_enable_reg <= 1'b0;
            sel_reg          <= 1'b0;
        end else begin
            if (HREADYOUT) begin 
                if (HSEL && (HTRANS == 2'b10)) begin
                    addr_reg         <= HADDR;
                    write_enable_reg <= HWRITE;
                    sel_reg          <= 1'b1;
                end else begin
                    sel_reg          <= 1'b0;
                end
            end
        end
    end

    // --------------------------------------------------------------------------
    // AHB Data Phase (Write Logic & Shadow Loading)
    // --------------------------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            reg_load_weights <= 32'h0;
            shadow_in_left_0 <= 0; shadow_in_left_1 <= 0; shadow_in_left_2 <= 0; shadow_in_left_3 <= 0;
            shadow_in_top_0  <= 0; shadow_in_top_1  <= 0; shadow_in_top_2  <= 0; shadow_in_top_3  <= 0;
            reg_in_bias_0 <= 0; reg_in_bias_1 <= 0; reg_in_bias_2 <= 0; reg_in_bias_3 <= 0;
        end else begin
            if (sel_reg && write_enable_reg) begin
                case (addr_reg[7:0])
                    8'h00: reg_load_weights <= HWDATA;
                    
                    // Write to SHADOW registers instead of direct output pins
                    8'h10: shadow_in_left_0 <= HWDATA;
                    8'h14: shadow_in_left_1 <= HWDATA;
                    8'h18: shadow_in_left_2 <= HWDATA;
                    8'h1C: shadow_in_left_3 <= HWDATA;
                    
                    8'h20: shadow_in_top_0  <= HWDATA;
                    8'h24: shadow_in_top_1  <= HWDATA;
                    8'h28: shadow_in_top_2  <= HWDATA;
                    8'h2C: shadow_in_top_3  <= HWDATA;
                    
                    8'h30: reg_in_bias_0 <= HWDATA;
                    8'h34: reg_in_bias_1 <= HWDATA;
                    8'h38: reg_in_bias_2 <= HWDATA;
                    8'h3C: reg_in_bias_3 <= HWDATA;
                    default: ; 
                endcase
            end
        end
    end

    // --------------------------------------------------------------------------
    // The "Commit" Triggers (Parallel Hardware Push)
    // --------------------------------------------------------------------------
    // Detects when the CPU writes to 0x04 (Top) or 0x08 (Left)
    wire commit_top  = (sel_reg && write_enable_reg && (addr_reg[7:0] == 8'h04));
    wire commit_left = (sel_reg && write_enable_reg && (addr_reg[7:0] == 8'h08));

    assign reg_in_top_0 = shadow_in_top_0;
    assign reg_in_top_1 = shadow_in_top_1;
    assign reg_in_top_2 = shadow_in_top_2;
    assign reg_in_top_3 = shadow_in_top_3;

    assign reg_in_left_0 = shadow_in_left_0;
    assign reg_in_left_1 = shadow_in_left_1;
    assign reg_in_left_2 = shadow_in_left_2;
    assign reg_in_left_3 = shadow_in_left_3;

    // --------------------------------------------------------------------------
    // AHB Data Phase (Read Logic)
    // --------------------------------------------------------------------------
    always @(*) begin
        HRDATA = 32'h0; 
        if (sel_reg && !write_enable_reg) begin
            case (addr_reg[7:0])
                8'h00: HRDATA = reg_load_weights;
                
                // Read from Shadow Registers so CPU sees what it wrote
                8'h10: HRDATA = shadow_in_left_0;
                8'h14: HRDATA = shadow_in_left_1;
                8'h18: HRDATA = shadow_in_left_2;
                8'h1C: HRDATA = shadow_in_left_3;
                
                8'h20: HRDATA = shadow_in_top_0;
                8'h24: HRDATA = shadow_in_top_1;
                8'h28: HRDATA = shadow_in_top_2;
                8'h2C: HRDATA = shadow_in_top_3;
                
                8'h30: HRDATA = reg_in_bias_0;
                8'h34: HRDATA = reg_in_bias_1;
                8'h38: HRDATA = reg_in_bias_2;
                8'h3C: HRDATA = reg_in_bias_3;
                
                // Read-Only Outputs from Accelerator
                8'h40: HRDATA = w_out_col_0;
                8'h44: HRDATA = w_out_col_1;
                8'h48: HRDATA = w_out_col_2;
                8'h4C: HRDATA = w_out_col_3;
                
                default: HRDATA = 32'h0;
            endcase
        end
    end
    
    // Change the internal wires to assign directly to the new outputs
    assign commit_top_out  = (sel_reg && write_enable_reg && (addr_reg[7:0] == 8'h04));
    assign commit_left_out = (sel_reg && write_enable_reg && (addr_reg[7:0] == 8'h08));

endmodule