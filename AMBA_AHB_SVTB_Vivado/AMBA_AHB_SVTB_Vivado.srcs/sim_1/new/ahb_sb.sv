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
//    - Handles different transfer types (NONSEQ, SEQ)
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
    
    // Burst tracking variables
    int burst_count;
    logic [31:0] burst_addr;
    logic [2:0] burst_type;
    
    // Constructor
    function new(mailbox m2s_mb);
        this.m2s_mb = m2s_mb;
        burst_count = 0;
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
        if (txn_h.hwrite && txn_h.htrans == 2'b10) begin  // NONSEQ write
            burst_type = txn_h.hburst;
            burst_addr = txn_h.haddr;
            burst_count = 0;
        end
        
        // Write data for writes during active transfers
        if (txn_h.hwrite && txn_h.hreadyout) begin
            mem[txn_h.haddr] = txn_h.hwdata;
            burst_count++;
        end
        
        // Prepare read data for read transactions
        if (!txn_h.hwrite && txn_h.htrans == 2'b10) begin  // NONSEQ read
            burst_type = txn_h.hburst;
            burst_addr = txn_h.haddr;
            burst_count = 0;
        end
        
        // Capture read data for reads during active transfers
        if (!txn_h.hwrite && txn_h.hreadyout) begin
            rdata = mem[txn_h.haddr];
            burst_count++;
        end
    endtask
    
    // Compare expected and actual data
    task compare();
        // Only compare for read transactions when transfer is complete
        if (!txn_h.hwrite && txn_h.hreadyout) begin
            // Check for data match
            if (rdata === txn_h.hrdata) begin
                $display($time, "[SCB-PASS] addr = %0h, \t expected data = %0h, actual data = %0h", 
                         txn_h.haddr, rdata, txn_h.hrdata);
                
                // Additional checks for transfer response
                if (txn_h.hresp == 0)  // OKAY response
                    $display($time, "[SCB-INFO] Transfer successful, OKAY response");
                else
                    $warning($time, "[SCB-WARN] Transfer with ERROR response");
            end
            else begin
                $error($time, "[SCB-FAIL] addr = %0h, \t expected data = %0h, actual data = %0h", 
                       txn_h.haddr, rdata, txn_h.hrdata);
            end
            
            // Optional: Burst transfer validation
            if (burst_count > 0) begin
                case(burst_type)
                    3'b000: begin  // SINGLE
                        if (burst_count != 1)
                            $error($time, "[SCB-FAIL] SINGLE burst expected 1 transfer, got %0d", burst_count);
                    end
                    3'b001: begin  // INCR
                        // INCR allows variable length, so no strict check
                    end
                    3'b010: begin  // WRAP4
                        if (burst_count != 4)
                            $error($time, "[SCB-FAIL] WRAP4 burst expected 4 transfers, got %0d", burst_count);
                    end
                    // Add checks for other burst types as needed
                endcase
            end
        end
    endtask
endclass