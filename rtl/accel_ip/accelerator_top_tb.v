`timescale 1ns / 1ps

module accelerator_top_tb();

    // --- 1. Signal Declarations ---
    reg         clk;
    reg         rst_n;
    reg         hwrite;
    reg         hready;
    reg  [1:0]  htrans;
    reg  [31:0] haddr;
    reg  [31:0] hwdata;
    reg  [2:0]  hsize, hburst;
    reg  [3:0]  hprot;
    reg         hsel_accel;
    reg         hsel_fpadd;

    wire [31:0] hrdata_accel, hrdata_fpadd;
    wire        hreadyout_accel, hreadyout_fpadd;
    wire        hresp_accel, hresp_fpadd;

    // --- 2. Instantiate UUT ---
    accelerator_top uut (
        .HCLK(clk), .HRESETn(rst_n),
        .HWRITE(hwrite), .HREADY(hready),
        .HTRANS(htrans), .HADDR(haddr), .HWDATA(hwdata),
        .HSIZE(hsize), .HBURST(hburst), .HPROT(hprot),
        .HSEL_ACCEL(hsel_accel), .HSEL_FPADD(hsel_fpadd),
        .HRDATA_ACCEL(hrdata_accel), .HREADYOUT_ACCEL(hreadyout_accel), .HRESP_ACCEL(hresp_accel),
        .HRDATA_FPADD(hrdata_fpadd), .HREADYOUT_FPADD(hreadyout_fpadd), .HRESP_FPADD(hresp_fpadd)
    );

    // --- 3. Clock Generation (50MHz) ---
    always #10 clk = ~clk;

    // --- 4. AHB Helper Tasks ---

    // Write Task
    task ahb_write(input [31:0] addr, input [31:0] data, input is_accel);
    begin
        @(posedge clk);
        haddr  <= addr;
        htrans <= 2'b10; // NONSEQ
        hwrite <= 1'b1;
        hsel_accel <= is_accel; hsel_fpadd <= !is_accel;
        
        @(posedge clk);
        hwdata <= data;
        htrans <= 2'b00; // IDLE
        hsel_accel <= 0; hsel_fpadd <= 0;
    end
    endtask

    // Read and Check Task
    task ahb_read_check(input [31:0] addr, input [31:0] expected_val, input is_accel);
    reg [31:0] actual_val;
    begin
        @(posedge clk);
        haddr  <= addr;
        htrans <= 2'b10; // NONSEQ
        hwrite <= 1'b0;  // Read mode
        hsel_accel <= is_accel; hsel_fpadd <= !is_accel;

        @(posedge clk);
        // During this cycle, the slave puts data on the bus
        htrans <= 2'b00; // IDLE
        hsel_accel <= 0; hsel_fpadd <= 0;
        
        @(posedge clk);
        // Sample the data now
        actual_val = (is_accel) ? hrdata_accel : hrdata_fpadd;
        
        if (actual_val === expected_val) begin
            $display("[PASS] Addr: 0x%h | Read: 0x%h | Expected: 0x%h", addr, actual_val, expected_val);
        end else begin
            $display("[FAIL] Addr: 0x%h | Read: 0x%h | Expected: 0x%h", addr, actual_val, expected_val);
        end
    end
    endtask

    // --- 5. Test Stimulus ---
    initial begin
        clk = 0; rst_n = 0; hready = 1;
        htrans = 0; haddr = 0; hwdata = 0;
        hsel_accel = 0; hsel_fpadd = 0;

        #100 rst_n = 1;
        $display("--- Starting Value Checks ---");

        // 1. Check Systolic Array (Write then Read back)
        // Offset 0x10 is shadow_in_left_0
        ahb_write(32'h40000010, 32'hAAAA_BBBB, 1); 
        ahb_read_check(32'h40000010, 32'hAAAA_BBBB, 1);

        // 2. Check Tile Adder (Write then Read back results)
        // We write 1 to MatA[0] and 2 to MatB[0]. 
        // Result at 0x80 should be 3 (if your fp_add handles integers/simple floats)
        ahb_write(32'h40002000, 32'h40000000, 0); // MatA[0] = 2.0 (float)
        ahb_write(32'h40002040, 32'h40400000, 0); // MatB[0] = 3.0 (float)
        
        #40; // Wait a few cycles for the combinational adder to settle
        ahb_read_check(32'h40002080, 32'h40A00000, 0); // Expect 5.0 (float)

        #200;
        
        $display("--- Simulation Finish ---");
        $finish;
    end

endmodule