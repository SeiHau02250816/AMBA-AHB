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
//    v1.4: Updated to handle IDLE and BUSY transactions
// 
// Description:
//    This module represents a subordinate device on the AHB bus. It provides the necessary
//    interfaces for communication with a master device, including address and data transfer,
//    control signals, and response signaling.
//    
//    Key Features:
//    - 2^30 addresses, each storing 8 bits
//    - Direct input signal handling
//    - Internal registers for output signals
//    - HSIZE handling for byte, halfword, and word transfers
//    - Write strobe handling for precise byte-level control
//    - Address alignment checks for read/write operations
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

// Enum type for HBURST signal
typedef enum logic [2:0] {
    SINGLE     = 3'b000, // Single transfer burst
    INCR      = 3'b001, // Incrementing burst of undefined length
    WRAP4     = 3'b010, // 4-beat wrapping burst
    INCR4     = 3'b011, // 4-beat incrementing burst
    WRAP8     = 3'b100, // 8-beat wrapping burst
    INCR8     = 3'b101, // 8-beat incrementing burst
    WRAP16    = 3'b110, // 16-beat wrapping burst
    INCR16    = 3'b111  // 16-beat incrementing burst
} hburst_t;

// Enum type for htrans signal
typedef enum logic [1:0] {
    IDLE          = 2'b00,  // No transfer is occurring
    BUSY          = 2'b01,  // The current transfer is ongoing
    NONSEQUENTIAL  = 2'b10,  // A new transfer is being initiated, but it is not the first in a burst
    SEQUENTIAL     = 2'b11   // A new transfer is being initiated, and it is the first in a burst
} htrans_t;

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
    input  hburst_t     hburst,    // Burst type
    input  logic [3:0]  hprot,     // Protection type (ignored in this example)
    input  htrans_t     htrans,    // Transaction type
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

    // Internal memory array (8-bit values)
    logic [7:0] memory [2**30];  // 2^30 addresses, each storing 8 bits
    
    // Internal registers for output signals
    logic        ready, ready_n;        // Current and next ready
    logic        resp, resp_n;          // Current and next response
    logic [31:0] rdata;       // Current and next read data
    
    // Register updates
    always_ff @(negedge hresetn or posedge hclk) begin
        if (!hresetn) begin
            ready <= 1'b0;
            resp <= 1'b0;
            rdata <= 32'h0;
        end 
        else begin
            ready <= ready_n;
            resp <= resp_n;
            
            if (hselx) begin
                // Handle AHB write logic synchronously
                if (!(htrans == IDLE || htrans == BUSY)) begin // Ignore IDLE and BUSY transactions
                    // Check address alignment
                    if ((haddr[1:0] != 2'b00) && (hsize == WORD)) begin
                    end
                    else if ((haddr[0] != 1'b0) && (hsize == HALFWORD))  begin
                    end
                    else if ((hsize == BYTE && hwstrb > 4'b0001) ||        // BYTE transfer expects one active strobe
                        (hsize == HALFWORD && hwstrb > 4'b0011)) begin     // HALFWORD transfer expects two consecutive strobes
                    end          
                    else begin
                        // Proceed with write operations
                        if (hwrite == WRITE) begin
                            // Write operation based on transfer size and write strobe
                            case(hsize)
                                BYTE: begin
                                    if (hwstrb[0]) memory[haddr[29:0]] = hwdata[7:0]; // Store 8 bits at the address
                                end
                                HALFWORD: begin
                                    if (hwstrb[0]) memory[haddr[29:0]] = hwdata[7:0]; // Store lower half
                                    if (hwstrb[1]) memory[haddr[29:0] + 1] = hwdata[15:8]; // Store upper half
                                end
                                WORD: begin
                                    if (hwstrb[0]) memory[haddr[29:0]] = hwdata[7:0];   // Store byte 0
                                    if (hwstrb[1]) memory[haddr[29:0] + 1] = hwdata[15:8]; // Store byte 1
                                    if (hwstrb[2]) memory[haddr[29:0] + 2] = hwdata[23:16]; // Store byte 2
                                    if (hwstrb[3]) memory[haddr[29:0] + 3] = hwdata[31:24]; // Store byte 3
                                end
                                default: ; // Invalid size
                            endcase
                        end
                    end
                end
            end
        end
    end

    // Handle next-state logic updates
    always_comb begin
        // Default assignments
        ready_n = 1'b1;
        resp_n = 1'b0;

        // Check address alignment
        if ((haddr[1:0] != 2'b00) && (hsize == WORD)) begin
            resp_n = 1'b1; // Address not aligned for word transfer
        end 
        else if ((haddr[0] != 1'b0) && (hsize == HALFWORD)) begin
            resp_n = 1'b1; // Address not aligned for halfword transfer
        end 
        else if ((hsize == BYTE && hwstrb > 4'b0001) ||        // BYTE transfer expects one active strobe
            (hsize == HALFWORD && hwstrb > 4'b0011)) begin    // HALFWORD transfer expects two consecutive strobes
            resp_n = 1'b1; // Signal an error response
        end
        else if (hselx) begin
            if (hwrite == READ) begin // Ignore IDLE and BUSY transactions
                // Read operation based on transfer size
                case(hsize)
                    BYTE: begin
                        rdata = {24'b0, memory[haddr[29:0]]}; // Read 8 bits
                    end
                    HALFWORD: begin
                        rdata = {16'b0, memory[haddr[29:0] + 1], memory[haddr[29:0]]}; // Read 16 bits
                    end
                    WORD: begin
                        rdata = {memory[haddr[29:0] + 3], memory[haddr[29:0] + 2], memory[haddr[29:0] + 1], memory[haddr[29:0]]}; // Read 32 bits
                    end
                    default: begin
                        rdata = 32'h0; // Invalid size
                    end
                endcase
                
                // Replace 'x' bits in rdata_n with '0'
                for (int i = 0; i < 32; i++) begin
                    if (rdata[i] === 1'bx) begin
                        rdata[i] = 1'b0;
                    end
                end
            end
        end
    end
    
    // Output assignments
    assign hreadyout = ready;
    assign hrdata = rdata;
    assign hresp = resp;

endmodule