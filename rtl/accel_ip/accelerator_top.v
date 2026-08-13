module accelerator_top (
    input HCLK, HRESETn,
    input HWRITE, HREADY,
    input [1:0]  HTRANS,
    input [31:0] HADDR, HWDATA,
    
    input [2:0]  HSIZE, HBURST,
    input [3:0]  HPROT,
    
    input HSEL_ACCEL, HSEL_FPADD,
    
    output wire [31:0] HRDATA_ACCEL,
    output wire        HREADYOUT_ACCEL, HRESP_ACCEL,
    
    output wire [31:0] HRDATA_FPADD,
    output wire        HREADYOUT_FPADD, HRESP_FPADD
);

systolic_with_ahb u_systolic (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HSEL(HSEL_ACCEL),
    
    .HADDR(HADDR),
    .HTRANS(HTRANS),
    .HWDATA(HWDATA),
    .HWRITE(HWRITE),
    .HSIZE(HSIZE),
    .HBURST(HBURST),
    .HPROT(HPROT),
    
    .HRDATA(HRDATA_ACCEL),
    .HREADYOUT(HREADYOUT_ACCEL),
    .HRESP(HRESP_ACCEL)
);

tile_add_ahb u_tile_add (    
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HSEL(HSEL_FPADD),
    
    .HADDR(HADDR),
    .HTRANS(HTRANS),
    .HWDATA(HWDATA),
    .HWRITE(HWRITE),
    
    .HRDATA(HRDATA_FPADD),
    .HREADYOUT(HREADYOUT_FPADD),
    .HRESP(HRESP_FPADD),
    
    .HREADY(HREADY)
);

endmodule