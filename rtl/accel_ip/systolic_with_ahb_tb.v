`timescale 1ns / 1ps

module systolic_with_ahb_tb;

    // --------------------------------------------------------------------------
    // 1. Signals & Setup
    // --------------------------------------------------------------------------
    reg HCLK, HRESETn;
    
    // AHB Signals
    reg         HSEL;
    reg  [31:0] HADDR;
    reg         HWRITE;
    reg  [1:0]  HTRANS;
    reg  [31:0] HWDATA;
    wire [31:0] HRDATA;
    wire        HREADYOUT;
    wire        HRESP;

    localparam TRANS_IDLE   = 2'b00;
    localparam TRANS_NONSEQ = 2'b10;

    // Memory Map
    localparam ADDR_CTRL   = 32'h00;
    localparam ADDR_LEFT_0 = 32'h10; 
    localparam ADDR_TOP_0  = 32'h20; 
    localparam ADDR_BIAS_0 = 32'h30;
    localparam ADDR_OUT_0  = 32'h40;

    // --------------------------------------------------------------------------
    // 2. IEEE 754 Constants (Floating Point Hex)
    // --------------------------------------------------------------------------
    // Use an online converter to verify these if needed
    localparam FP_1_0   = 32'h3F800000; // 1.0
    localparam FP_5_0   = 32'h40A00000; // 5.0
    localparam FP_10_0  = 32'h41200000; // 10.0
    localparam FP_20_0  = 32'h41A00000; // 20.0
    localparam FP_30_0  = 32'h41F00000; // 30.0
    localparam FP_40_0  = 32'h42200000; // 40.0
    localparam FP_105_0 = 32'h42D20000; // 105.0 (Expected Result)

    // --------------------------------------------------------------------------
    // 3. DUT Instantiation
    // --------------------------------------------------------------------------
    systolic_with_ahb u_dut (
        .HCLK(HCLK), .HRESETn(HRESETn), .HSEL(HSEL), .HADDR(HADDR),
        .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(3'b010), .HBURST(3'b0),
        .HPROT(4'b0), .HWDATA(HWDATA), .HRDATA(HRDATA),
        .HREADYOUT(HREADYOUT), .HRESP(HRESP)
    );

    // Clock Gen
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    // --------------------------------------------------------------------------
    // 4. Tasks
    // --------------------------------------------------------------------------
    task ahb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge HCLK);
            HSEL <= 1; HADDR <= addr; HWRITE <= 1; HTRANS <= TRANS_NONSEQ;
            @(posedge HCLK);
            HSEL <= 0; HADDR <= 0; HWRITE <= 0; HTRANS <= TRANS_IDLE; HWDATA <= data;
            @(posedge HCLK);
            HWDATA <= 0;
        end
    endtask

    task ahb_read(input [31:0] addr, output [31:0] data_out);
        begin
            @(posedge HCLK);
            HSEL <= 1; HADDR <= addr; HWRITE <= 0; HTRANS <= TRANS_NONSEQ;
            @(posedge HCLK);
            HSEL <= 0; HADDR <= 0; HTRANS <= TRANS_IDLE;
            @(negedge HCLK); 
            data_out = HRDATA;
            @(posedge HCLK);
        end
    endtask

    // --------------------------------------------------------------------------
    // 5. Main Test: Floating Point Accumulation
    // --------------------------------------------------------------------------
    reg [31:0] read_val_0, read_val_1, read_val_2, read_val_3;

    initial begin
        // Reset
        HRESETn = 0; HSEL = 0; HADDR = 0; HWRITE = 0; HTRANS = TRANS_IDLE; HWDATA = 0;
        #20 HRESETn = 1;
        $display("\n=== Simulation Start: IEEE 754 Floating Point Test ===");

        // [1] Set Bias = 5.0
        $display("[1] Setting Bias = 5.0 (Hex: %h)", FP_5_0);
        ahb_write(ADDR_BIAS_0 + 0, FP_5_0);
        ahb_write(ADDR_BIAS_0 + 4, FP_5_0);
        ahb_write(ADDR_BIAS_0 + 8, FP_5_0);
        ahb_write(ADDR_BIAS_0 + 12, FP_5_0);

        // [2] Set Weights = 1.0
        $display("[2] Setting Weights = 1.0 (Hex: %h)", FP_1_0);
        ahb_write(ADDR_TOP_0 + 0, FP_1_0);
        ahb_write(ADDR_TOP_0 + 4, FP_1_0);
        ahb_write(ADDR_TOP_0 + 8, FP_1_0);
        ahb_write(ADDR_TOP_0 + 12, FP_1_0);

        // [3] Set Inputs = 10.0, 20.0, 30.0, 40.0
        $display("[3] Setting Inputs [10.0, 20.0, 30.0, 40.0]");
        ahb_write(ADDR_LEFT_0 + 0, FP_10_0);
        ahb_write(ADDR_LEFT_0 + 4, FP_20_0);
        ahb_write(ADDR_LEFT_0 + 8, FP_30_0);
        ahb_write(ADDR_LEFT_0 + 12, FP_40_0);

        // [4] LOAD WEIGHTS (Critical Step)
        $display("[4] Triggering Load Weights (Must be > 4 cycles for 4x4 array)");
        
        // A. Set Control Bit HIGH (Load Mode)
        ahb_write(ADDR_CTRL, 32'd1); 
        
        // B. WAIT here! 
        // In the hardware, the weight flows: Top -> Row0 -> Row1 -> Row2 -> Row3
        // We need to keep 'load_weights' high long enough for 1.0 to reach Row3.
        repeat(10) @(posedge HCLK); 
        
        // C. Set Control Bit LOW (Compute Mode)
        ahb_write(ADDR_CTRL, 32'd0);

        // [5] Wait for Compute Latency
        // Pipeline: Row0(1 cyc) -> Row1(1 cyc) -> Row2(1 cyc) -> Row3(1 cyc)
        // Also FP adders might have internal latency. 30 cycles is safe.
        $display("[5] Waiting for Systolic Computation...");
        repeat(30) @(posedge HCLK);

        // [6] Verify
        $display("[6] Reading Results...");
        ahb_read(ADDR_OUT_0 + 0, read_val_0);
        ahb_read(ADDR_OUT_0 + 4, read_val_1);
        ahb_read(ADDR_OUT_0 + 8, read_val_2);
        ahb_read(ADDR_OUT_0 + 12, read_val_3);

        $display("--------------------------------------------------");
        $display(" Result Check: 5.0 + (10*1) + (20*1) + (30*1) + (40*1) = 105.0");
        $display(" Expected Hex: %h", FP_105_0);
        $display("--------------------------------------------------");
        $display(" Col 0 Actual: %h", read_val_0);
        $display(" Col 1 Actual: %h", read_val_1);
        $display(" Col 2 Actual: %h", read_val_2);
        $display(" Col 3 Actual: %h", read_val_3);

        if (read_val_0 == FP_105_0 && read_val_1 == FP_105_0)
            $display("SUCCESS: Floating point calc matches 105.0!");
        else
            $display("FAILURE: Check FP IP core latency or Weight Loading duration.");

        $finish;
    end
endmodule