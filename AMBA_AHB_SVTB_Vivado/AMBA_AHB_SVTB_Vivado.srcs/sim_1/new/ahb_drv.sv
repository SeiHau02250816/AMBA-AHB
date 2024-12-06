//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_drv
// Module Name: ahb_drv
// Project Name: AHB SVTB
// 
// Description:
//    AHB Driver for AMBA AHB-Lite Testbench
//    - Responsible for driving AHB bus transactions from generator to interface
//    - Supports various AHB transfer types and configurations
//    - Uses mailbox-based communication with generator
//    - Implements transaction driving logic following AHB-Lite protocol
//
// Key Features:
//    - Drives AHB master signals based on transaction parameters
//    - Handles different transfer types (IDLE, BUSY, NONSEQ, SEQ)
//    - Supports single and burst transfers
//    - Waits for slave readiness (hreadyout)
//
// Dependencies:
//    - Requires ahb_intf interface
//    - Requires ahb_txn transaction class (not shown)
//
// Revision:
//    v1.0 - Initial implementation based on APB driver pattern
//////////////////////////////////////////////////////////////////////////////////

class ahb_drv;
    virtual ahb_intf vintf; // Virtual interface for driving AHB signals
    mailbox g2d_mb; // Mailbox for receiving transactions from generator
    ahb_txn txn_h; // Transaction handle
    
    // Constructor
    function new(virtual ahb_intf vintf, mailbox g2d_mb);
        this.vintf = vintf;
        this.g2d_mb = g2d_mb;
    endfunction
    
    // Main driving task - runs forever receiving and driving transactions
    task drive;
        forever begin
            $display("Task drive :: ahb_drv");
            
            // Wait for clock edge in driver clocking block
            @(vintf.drv_cb);
            
            // Get transaction from mailbox
            g2d_mb.get(txn_h);
            // txn_h.print("driver");
            
            // Drive the AHB transaction
            ahb_drive();
        end
    endtask
    
    // Task to drive AHB transaction signals
    task ahb_drive();
        // Drive address and control signals
        vintf.drv_cb.haddr <= txn_h.haddr;
        vintf.drv_cb.hwrite <= txn_h.hwrite;
        vintf.drv_cb.hsize <= txn_h.hsize;
        vintf.drv_cb.hburst <= txn_h.hburst;
        vintf.drv_cb.hprot <= txn_h.hprot;
        vintf.drv_cb.htrans <= txn_h.htrans;
        vintf.drv_cb.hmastlock <= txn_h.hmastlock;
        vintf.drv_cb.hwdata <= txn_h.hwdata;
        vintf.drv_cb.hwstrb <= txn_h.hwstrb;
        
        // Wait for slave to be ready
        wait(vintf.drv_cb.hreadyout);
    endtask
endclass