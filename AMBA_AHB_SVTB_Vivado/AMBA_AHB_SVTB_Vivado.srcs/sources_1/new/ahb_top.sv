//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: ahb_top
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
// 
// Description:
//    This is the top-level RTL design that instantiates and connects all necessary modules.
//
//////////////////////////////////////////////////////////////////////////////////

module ahb_top (
    // Global signals
    input  logic        hclk,
    input  logic        hresetn,
    
    // Testbench (Manager) interface signals
    input  logic [31:0] haddr,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [2:0]  hburst,
    input  logic [3:0]  hprot,
    input  logic [1:0]  htrans,
    input  logic        hmastlock,
    input  logic [31:0] hwdata,
    input  logic [3:0]  hwstrb,
    
    // Response to testbench
    output logic        hreadyout,
    output logic        hresp,
    output logic [31:0] hrdata
);

    // Internal signals
    logic [2:0]  i_hsel;
    logic [1:0]  i_mul_sel;
    logic [31:0] i_hrdata_sub1;
    logic [31:0] i_hrdata_sub2;
    logic [31:0] i_hrdata_sub3;
    logic        i_hready_sub1;
    logic        i_hready_sub2;
    logic        i_hready_sub3;
    logic        i_hresp_sub1;
    logic        i_hresp_sub2;
    logic        i_hresp_sub3;

    // Instantiate address decoder
    ahb_decoder u_decoder (
        // Input ports
        .haddr    (haddr),

        // Output ports
        .hselx    (i_hsel),
        .mul_sel  (i_mul_sel)
    );

    // Instantiate multiplexor
    ahb_mul u_mul (
        // Input ports
        .mul_sel  (i_mul_sel),
        .hrdata1  (i_hrdata_sub1),
        .hrdata2  (i_hrdata_sub2),
        .hrdata3  (i_hrdata_sub3),

        // Output ports
        .hrdata   (hrdata)
    );

    // Instantiate subordinate 1
    subordinate u_subordinate1 (
        // Input ports
        .hclk      (hclk),
        .hresetn   (hresetn),
        .hselx     (i_hsel[0]),
        .haddr     (haddr),
        .hwrite    (hwrite),
        .hsize     (hsize),
        .hburst    (hburst),
        .hprot     (hprot),
        .htrans    (htrans),
        .hmastlock (hmastlock),
        .hwdata    (hwdata),
        .hwstrb    (hwstrb),

        // Output ports
        .hreadyout (i_hready_sub1),
        .hresp     (i_hresp_sub1),
        .hrdata    (i_hrdata_sub1)
    );

    // Instantiate subordinate 2
    subordinate u_subordinate2 (
        // Input ports
        .hclk      (hclk),
        .hresetn   (hresetn),
        .hselx     (i_hsel[1]),
        .haddr     (haddr),
        .hwrite    (hwrite),
        .hsize     (hsize),
        .hburst    (hburst),
        .hprot     (hprot),
        .htrans    (htrans),
        .hmastlock (hmastlock),
        .hwdata    (hwdata),
        .hwstrb    (hwstrb),

        // Output ports
        .hreadyout (i_hready_sub2),
        .hresp     (i_hresp_sub2),
        .hrdata    (i_hrdata_sub2)
    );

    // Instantiate subordinate 3
    subordinate u_subordinate3 (
        // Input ports
        .hclk      (hclk),
        .hresetn   (hresetn),
        .hselx     (i_hsel[2]),
        .haddr     (haddr),
        .hwrite    (hwrite),
        .hsize     (hsize),
        .hburst    (hburst),
        .hprot     (hprot),
        .htrans    (htrans),
        .hmastlock (hmastlock),
        .hwdata    (hwdata),
        .hwstrb    (hwstrb),

        // Output ports
        .hreadyout (i_hready_sub3),
        .hresp     (i_hresp_sub3),
        .hrdata    (i_hrdata_sub3)
    );

    // Combine ready and response signals from all subordinates
    assign hreadyout = i_hready_sub1 | i_hready_sub2 | i_hready_sub3;
    assign hresp     = i_hresp_sub1  | i_hresp_sub2  | i_hresp_sub3;

endmodule