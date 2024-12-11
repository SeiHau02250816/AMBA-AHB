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
//    v1.4: Updated scoreboard to handle IDLE and BUSY transfer types
//////////////////////////////////////////////////////////////////////////////////

class ahb_sb;
    mailbox m2s_mb;                 // Mailbox for receiving transactions from monitor
    logic [31:0] mem[logic [31:0]]; // Internal memory model 
    logic [31:0] rdata;             // Reference read data
    logic [31:0] prev_mem_value;    // Previous memory value for IDLE/BUSY checks
    ahb_txn txn_h;                  // Transaction handler 
    
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
        // Store current memory value before any operations
        prev_mem_value = mem[txn_h.haddr];

        // Skip memory operations for IDLE and BUSY transfers
        if (txn_h.htrans inside {2'b00, 2'b01}) begin
            return;
        end

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
        // For IDLE and BUSY transfers
        if (txn_h.htrans inside {2'b00, 2'b01}) begin
            string transfer_type = txn_h.htrans == 2'b00 ? "IDLE" : "BUSY";
            
            // Check response is OKAY
            if (txn_h.hresp !== 1'b0) begin
                $error($time, "[SCB-FAIL] Invalid response for %s transfer. Expected OKAY(0), Got %0b", 
                       transfer_type, txn_h.hresp);
            end
            
            // Check zero wait state
            if (!txn_h.hreadyout) begin
                $error($time, "[SCB-FAIL] Invalid wait state for %s transfer. Expected zero wait state", 
                       transfer_type);
            end
            
            // For write transaction, verify memory wasn't updated
            if (txn_h.hwrite) begin
                if (mem[txn_h.haddr] !== prev_mem_value) begin
                    $error($time, "[SCB-FAIL] Memory was modified during %s transfer. Address: %0h, Previous: %0h, Current: %0h",
                           transfer_type, txn_h.haddr, prev_mem_value, mem[txn_h.haddr]);
                end
            end
            
            // All checks passed
            if (txn_h.hresp === 1'b0 && txn_h.hreadyout && (mem[txn_h.haddr] === prev_mem_value)) begin
                $display($time, "[SCB-PASS] %s transfer completed with correct OKAY response, zero wait state, and no memory modification", 
                        transfer_type);
            end
        end

        // Only compare for read transactions when transfer is complete
        if (!txn_h.hwrite && txn_h.hreadyout) begin
            // Check for data match
            logic [31:0] expected_data;

            // Reset expected_data to 0 if all bits are x
            // if (^rdata === 1'bx) begin
            //     rdata = 32'b0;
            // end

            // Debugging statements to log values before comparison
            if (rdata === txn_h.hrdata) begin
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