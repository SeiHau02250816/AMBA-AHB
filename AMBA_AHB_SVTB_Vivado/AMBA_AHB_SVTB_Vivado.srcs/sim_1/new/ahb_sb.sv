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
        // Handle write transactions
        if (txn_h.hwrite) begin
            case (txn_h.hsize)
                3'b000: mem[txn_h.haddr][7:0] = txn_h.hwdata[7:0];    // BYTE
                3'b001: mem[txn_h.haddr][15:0] = txn_h.hwdata[15:0];  // HALFWORD
                3'b010: mem[txn_h.haddr] = txn_h.hwdata;              // WORD
                default: ; // Invalid size, do nothing
            endcase
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
            $display($time, "[DEBUG] addr = %0h, expected_data = %0h, rdata = %0h, txn_h.hrdata = %0h", 
                     txn_h.haddr, expected_data, rdata, txn_h.hrdata);

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