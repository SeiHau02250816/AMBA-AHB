//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_scoreboard
// Module Name: ahb_sb
// Project Name: AHB SVTB
// 
// Description:
//    AHB Scoreboard for AMBA AHB-Lite Testbench
//    - Implements a reference model for AHB transactions
//    - Maintains an internal memory model
//    - Compares expected and actual read data
//    - Supports single and burst transfer validation
//
// Key Features:
//    - Tracks write and read transactions
//    - Handles different transfer types 
//    - Validates read data against reference model
//    - Provides detailed pass/fail reporting
//
// Dependencies:
//    - Requires ahb_txn transaction class (not shown)
//
// Revision:
//    v1.0 - Initial implementation of AHB scoreboard.
//    v1.1: Added AHB Basic Transfers feature.
//    v1.2: Added HSIZE handling for different transfer sizes (byte, halfword, word)
//    v1.3: Updated ref_model task to handle write transactions using hwstrb signal
//////////////////////////////////////////////////////////////////////////////////

class ahb_sb;
    // Mailbox for receiving transactions from monitor
    mailbox m2s_mb;
    
    // Internal memory model 
    logic [31:0] mem[logic [31:0]];
    
    // Reference read data
    logic [31:0] rdata;
    
    // Current transaction handle
    ahb_txn txn_h;
    
    // Constructor
    function new(mailbox m2s_mb);
        this.m2s_mb = m2s_mb;
    endfunction
    
    // Main checking task
    task check;
        forever begin
            $display($time, ": Task check :: ahb_sb");
            m2s_mb.get(txn_h);
            
            // Process transaction
            ref_model();
            compare();
        end
    endtask
    
    // Reference model for tracking writes and preparing reads
    task ref_model;
        // Handle write transactions with write strobe
        if (txn_h.hwrite) begin
            for (int i = 0; i < 4; i++) begin
                if (txn_h.hwstrb[i]) begin
                    mem[txn_h.haddr][8*i +: 8] = txn_h.hwdata[8*i +: 8];
                end
            end
        end
        
        // Prepare read data for read transactions
        if (!txn_h.hwrite) begin
            case (txn_h.hsize)
                3'b000: rdata = {24'h0, mem[txn_h.haddr][7:0]};   // BYTE
                3'b001: rdata = {16'h0, mem[txn_h.haddr][15:0]};  // HALFWORD
                3'b010: rdata = mem[txn_h.haddr];                 // WORD
                default: rdata = 32'h0; // Invalid size
            endcase
        end
    endtask
    
    // Compare expected and actual data
    task compare();
        // Only compare for read transactions when transfer is complete
        if (!txn_h.hwrite && txn_h.hreadyout) begin
            // Check for data match
            logic [31:0] expected_data;
            case (txn_h.hsize)
                3'b000: expected_data = {24'h0, txn_h.hrdata[7:0]};    // BYTE
                3'b001: expected_data = {16'h0, txn_h.hrdata[15:0]};  // HALFWORD
                3'b010: expected_data = txn_h.hrdata;                 // WORD
                default: expected_data = 32'h0; // Invalid size
            endcase
            
            // Debugging statements to log values before comparison
            if (rdata === expected_data) begin
                $display($time, "[SCB-PASS] addr = %0h, \t expected data = %0h, actual data = %0h", 
                         txn_h.haddr, rdata, txn_h.hrdata);
            end
            else begin
                $display($time, "[SCB-FAIL] addr = %0h, \t expected data = %0h, actual data = %0h", 
                         txn_h.haddr, rdata, txn_h.hrdata);
            end
        end
    endtask
endclass