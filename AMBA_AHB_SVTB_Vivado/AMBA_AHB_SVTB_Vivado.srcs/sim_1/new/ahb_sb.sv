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
//    - Combined all the subordinate's memory space into a single memory model
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
//    v1.5: Added Burst handling
//////////////////////////////////////////////////////////////////////////////////

class ahb_sb;
    mailbox m2s_mb;                 // Mailbox for receiving transactions from monitor
    logic [7:0] mem[logic [31:0]]; // Internal memory model 
    logic [31:0] rdata;             // Reference read data
    logic resp;                     // Reference response
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
        resp = 1'b0; // Default to OKAY

        // Skip memory operations for IDLE and BUSY transfers
        if (txn_h.htrans inside {2'b00, 2'b01}) begin
            return;
        end

        // Update resp to report errors, if any.
        if (txn_h.hsize == 3'b000) begin // BYTE
            case (txn_h.haddr[1:0])
                2'b00: resp = (txn_h.hwstrb[3:1] == 3'b000) ? 1'b0 : 1'b1;
                2'b01: resp = (txn_h.hwstrb[3:2] == 2'b00 && txn_h.hwstrb[0] == 1'b0) ? 1'b0 : 1'b1;
                2'b10: resp = (txn_h.hwstrb[3] == 1'b0 && txn_h.hwstrb[1:0] == 2'b00) ? 1'b0 : 1'b1;
                2'b11: resp = (txn_h.hwstrb[2:0] == 3'b000) ? 1'b0 : 1'b1;
                default: resp = 1'b1; // Invalid case
            endcase
        end else if (txn_h.hsize == 3'b001) begin // HALFWORD
            if (txn_h.haddr[1:0] == 2'b00) resp = (txn_h.hwstrb[3:2] == 2'b00) ? 1'b0 : 1'b1;
            else if (txn_h.haddr[1:0] == 2'b10) resp = (txn_h.hwstrb[1:0] == 2'b00) ? 1'b0 : 1'b1;
            else resp = 1'b1; // Invalid address
        end else if (txn_h.htrans == 2'b11 && (txn_h.haddr[29:0] == 30'h0)) begin
            resp = 1'b1; // Invalid burst transfer
        end

        // Proceed with write operations
        if (!resp && txn_h.hwrite) begin
            // Write operation based on transfer size and write strobe
            case (txn_h.hsize)
                3'b000: begin // BYTE
                    case(txn_h.haddr[1:0]) 
                        2'b00: if (txn_h.hwstrb[0]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                        2'b01: if (txn_h.hwstrb[1]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                        2'b10: if (txn_h.hwstrb[2]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                        2'b11: if (txn_h.hwstrb[3]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                    endcase
                end
                3'b001: begin // HALFWORD
                    case(txn_h.haddr[1:0]) 
                        2'b00: begin
                            if (txn_h.hwstrb[0]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                            if (txn_h.hwstrb[1]) mem[txn_h.haddr[31:0] + 1] = txn_h.hwdata[15:8];
                        end
                        2'b10: begin
                            if (txn_h.hwstrb[2]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];
                            if (txn_h.hwstrb[3]) mem[txn_h.haddr[31:0] + 1] = txn_h.hwdata[15:8];
                        end
                    endcase
                end
                3'b010: begin // WORD
                    if (txn_h.hwstrb[0]) mem[txn_h.haddr[31:0]] = txn_h.hwdata[7:0];   // Store byte 0
                    if (txn_h.hwstrb[1]) mem[txn_h.haddr[31:0] + 1] = txn_h.hwdata[15:8]; // Store byte 1
                    if (txn_h.hwstrb[2]) mem[txn_h.haddr[31:0] + 2] = txn_h.hwdata[23:16]; // Store byte 2
                    if (txn_h.hwstrb[3]) mem[txn_h.haddr[31:0] + 3] = txn_h.hwdata[31:24]; // Store byte 3
                end
                default: ; // Invalid size
            endcase
        end

        // Prepare read data for read transactions
        if (!resp && !txn_h.hwrite) begin
            case (txn_h.hsize)
                3'b000: rdata = {24'b0, mem[txn_h.haddr]}; // Read 8 bits
                3'b001: rdata = {16'b0, mem[txn_h.haddr + 1], mem[txn_h.haddr]}; // Read 16 bits
                3'b010: rdata = {mem[txn_h.haddr + 3], mem[txn_h.haddr + 2], mem[txn_h.haddr + 1], mem[txn_h.haddr]}; // Read 32 bits
                default: rdata = 32'h0; // Invalid size
            endcase
        end
    endtask
    
    // Compare expected and actual data
    task compare();
        if (txn_h.hresp || resp) begin
            $error($time, "[SCB-FAIL] Invalid response found! Expected %0b, Actual %0b, If expected == 0 && actual == 1, please check on address validity in subordinate transactions. Else, please check on hsize, haddr and hwstrb", resp, txn_h.hresp);
        end

        // For IDLE and BUSY transfers
        if (txn_h.hreadyout && txn_h.htrans inside {2'b00, 2'b01}) begin
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
        else if (!txn_h.hwrite && txn_h.hreadyout) begin
            // Reset rdata bits to 0 if any bit is 'x'
            for (int i = 0; i < 32; i++) begin
                if (rdata[i] === 1'bx) begin
                    rdata[i] = 1'b0;
                end
            end

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