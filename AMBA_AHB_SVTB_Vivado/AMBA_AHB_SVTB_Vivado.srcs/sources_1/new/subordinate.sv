//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: subordinate
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
//    v1.1: Added AHB Basic Transfers feature.
// 
// Description:
//    This module represents a subordinate device on the AHB bus. It provides the necessary
//    interfaces for communication with a master device, including address and data transfer,
//    control signals, and response signaling.
//    
//    Key Features:
//    - 2^30 words memory size
//    - Direct input signal handling
//    - Internal registers for output signals
//
//////////////////////////////////////////////////////////////////////////////////

module subordinate (
    /* Input ports */
    // Global signals
    input  logic        hclk,      // Clock signal
    input  logic        hresetn,   // Reset signal

    // Select signal
    input  logic        hselx,     // Slave select signal

    // Address and control
    input  logic [31:0] haddr,     // Address bus
    input  logic        hwrite,    // Write enable
    input  logic [2:0]  hsize,     // Transfer size (ignored in this example)
    input  logic [2:0]  hburst,    // Burst type (ignored in this example)
    input  logic [3:0]  hprot,     // Protection type (ignored in this example)
    input  logic [1:0]  htrans,    // Transaction type (ignored in this example)
    input  logic        hmastlock, // Master lock signal

    // Data
    input  logic [31:0] hwdata,    // Write data bus

    /* Output ports */
    // Transfer response
    output logic        hreadyout, // Ready to accept more transfers
    output logic        hresp,     // Response signal (single bit)

    // Data
    output logic [31:0] hrdata     // Read data bus
);

    // Internal memory array (32-bit words)
    logic [31:0] memory [2**30];  // 2^30 words of storage
    
    // Internal registers for output signals
    logic        ready, ready_n;        // Current and next ready
    logic        resp, resp_n;          // Current and next response
    logic [31:0] rdata, rdata_n;       // Current and next read data
    
    // Register updates
    always_ff @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            ready <= 1'b0;
            resp <= 1'b0;
            rdata <= 32'h0;
        end
        else begin
            ready <= ready_n;
            resp <= resp_n;
            rdata <= rdata_n;
        end
    end
    
    // Combinational logic for next state
    always_comb begin
        // Default assignments
        ready_n = 1'b1;
        resp_n = 1'b0;
        rdata_n = rdata;
        
        if (hselx) begin
            if (hwrite) begin
                // Write operation
                memory[haddr[31:2]] = hwdata;  // Word-aligned addressing
            end
            else begin
                // Read operation
                rdata_n = memory[haddr[31:2]];  // Word-aligned addressing
            end
        end
    end
    
    // Output assignments
    assign hreadyout = ready;
    assign hresp = resp;
    assign hrdata = rdata;

endmodule