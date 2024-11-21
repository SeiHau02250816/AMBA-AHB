//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 18:30:00
// Design Name: ahb_intf
// Module Name: ahb_intf
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created AHB interface with testbench as master
// 
// Description:
//    SystemVerilog interface for AMBA AHB-Lite bus
//    - Testbench acts as the master
//    - Single driver clocking block
//    - Provides monitor modport for observing bus transactions
//
// Key Features:
//    - Global signals: hclk, hresetn
//    - Master signals: haddr, hwrite, hsize, hburst, hprot, htrans, hmastlock, hwdata
//    - Slave signals: hreadyout, hresp, hrdata
//////////////////////////////////////////////////////////////////////////////////

interface ahb_intf(
    input logic hclk,       // System clock
    input logic hresetn     // Active-low reset
);
    // Master interface signals (from testbench)
    logic [31:0] haddr;     // Address bus
    logic        hwrite;    // Transfer direction (1: write, 0: read)
    logic [2:0]  hsize;     // Transfer size (byte, halfword, word)
    logic [2:0]  hburst;    // Burst type
    logic [3:0]  hprot;     // Protection control
    logic [1:0]  htrans;    // Transfer type
    logic        hmastlock; // Locked transfer
    logic [31:0] hwdata;    // Write data bus

    // Slave response signals
    logic        hreadyout; // Transfer complete
    logic        hresp;     // Transfer response
    logic [31:0] hrdata;    // Read data bus

    // Testbench driver clocking block (single driver)
    clocking drv_cb @(posedge hclk);
        default input #1 output #1;
        
        // Outputs from testbench (master)
        output haddr;
        output hwrite;
        output hsize;
        output hburst;
        output hprot;
        output htrans;
        output hmastlock;
        output hwdata;
        
        // Inputs to testbench
        input  hreadyout;
        input  hresp;
        input  hrdata;
    endclocking
    
    // Monitor clocking block (captures all signals)
    clocking mon_cb @(posedge hclk);
        default input #2 output #1;  // Longer input delay for stability
        
        // All monitored signals
        input hclk;
        input hresetn;
        input haddr;
        input hwrite;
        input hsize;
        input hburst;
        input hprot;
        input htrans;
        input hmastlock;
        input hwdata;
        input hreadyout;
        input hresp;
        input hrdata;
    endclocking
    
    // Modports for testbench components
    modport drv_mp(
        input  hclk, 
        input  hresetn, 
        clocking drv_cb
    );
    
    modport mon_mp(
        input  hclk, 
        input  hresetn, 
        clocking mon_cb
    );

endinterface