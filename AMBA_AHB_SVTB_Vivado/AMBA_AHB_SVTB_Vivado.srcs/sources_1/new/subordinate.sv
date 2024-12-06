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
//    v1.2: Added HSIZE handling for different transfer sizes (byte, halfword, word)
//    v1.3: Implemented write strobe handling for byte-level control.
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
//    - HSIZE handling for byte, halfword, and word transfers
//    - Write strobe handling for precise byte-level control
//
//////////////////////////////////////////////////////////////////////////////////

// Enum type for hwrite signal
typedef enum logic {
    READ  = 1'b0,    // Read operation
    WRITE = 1'b1     // Write operation
} hwrite_t;

// Enum type for transfer size
typedef enum logic [2:0] {
    BYTE     = 3'b000,  // 8-bit transfer
    HALFWORD = 3'b001,  // 16-bit transfer
    WORD     = 3'b010   // 32-bit transfer
} hsize_t;

module subordinate (
    /* Input ports */
    // Global signals
    input  logic        hclk,      // Clock signal
    input  logic        hresetn,   // Reset signal

    // Select signal
    input  logic        hselx,     // Slave select signal

    // Address and control
    input  logic [31:0] haddr,     // Address bus
    input  hwrite_t     hwrite,    // Write enable
    input  hsize_t      hsize,     // Transfer size
    input  logic [2:0]  hburst,    // Burst type (ignored in this example)
    input  logic [3:0]  hprot,     // Protection type (ignored in this example)
    input  logic [1:0]  htrans,    // Transaction type (ignored in this example)
    input  logic        hmastlock, // Master lock signal

    // Data
    input  logic [31:0] hwdata,    // Write data bus
    input  logic [3:0]  hwstrb,    // Write strobe

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
            if (hwrite == WRITE) begin
                // Write operation based on write strobe
                for (int i = 0; i < 4; i++) begin
                    if (hwstrb[i]) begin
                        memory[haddr[29:0]][8*i +: 8] = hwdata[8*i +: 8];
                    end
                end
            end
            else begin
                // Read operation based on transfer size
                logic [31:0] mem_data;  // Temporary variable for memory read
                mem_data = memory[haddr[29:0]];  // Read memory first
                
                case(hsize)
                    BYTE: begin
                        rdata_n = {24'b0, mem_data[7:0]};
                    end
                    HALFWORD: begin
                        rdata_n = {16'b0, mem_data[15:0]};
                    end
                    WORD: begin
                        rdata_n = mem_data;
                    end
                    default: rdata_n = 32'h0; // Invalid size
                endcase
            end
        end
    end
    
    // Output assignments
    assign hreadyout = ready;
    assign hresp = resp;
    assign hrdata = rdata;

endmodule