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
//    v1.5: Added Burst handling
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
    int          cnt, cnt_n;            // Current and next counter to count on number of txns for a burst.
    logic [31:0] rdata;       // Current and next read data
    
    // Register updates
    always_ff @(negedge hresetn or posedge hclk) begin
        if (!hresetn) begin
            ready <= 1'b0;
            resp <= 1'b0;
            rdata <= 32'h0;
            cnt <= 0;
        end 
        else begin
            ready <= ready_n;
            resp <= resp_n;
            cnt <= cnt_n;
            
            if (hselx) begin
                // Handle AHB write logic synchronously
                if (!(htrans == IDLE || htrans == BUSY)) begin // Ignore IDLE and BUSY transactions
                    if (!resp_n) begin
                        // Proceed with write operations
                        if (hwrite == WRITE) begin
                            // Write operation based on transfer size and write strobe
                            case(hsize)
                                BYTE: begin
                                    case(haddr[1:0]) 
                                        2'b00: if (hwstrb[0]) memory[haddr[29:0]] = hwdata[7:0];
                                        2'b01: if (hwstrb[1]) memory[haddr[29:0]] = hwdata[7:0];
                                        2'b10: if (hwstrb[2]) memory[haddr[29:0]] = hwdata[7:0];
                                        2'b11: if (hwstrb[3]) memory[haddr[29:0]] = hwdata[7:0];
                                    endcase
                                end
                                HALFWORD: begin
                                    case(haddr[1:0]) 
                                        2'b00: begin
                                            if (hwstrb[0]) memory[haddr[29:0]] = hwdata[7:0];
                                            if (hwstrb[1]) memory[haddr[29:0] + 1] = hwdata[15:8];
                                        end
                                        2'b10: begin
                                            if (hwstrb[2]) memory[haddr[29:0]] = hwdata[7:0];
                                            if (hwstrb[3]) memory[haddr[29:0] + 1] = hwdata[15:8];
                                        end
                                    endcase
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

        if (hselx) begin
            // Update cnt_n 
            if (htrans == IDLE) begin
                cnt_n = 0; // Reset counter
            end 
            else if ((htrans == NONSEQUENTIAL && (cnt == 5 && (hburst == INCR4 || hburst == WRAP4) || cnt == 9 && (hburst == INCR8 || hburst == WRAP8) || cnt == 17 && (hburst == INCR16 || hburst == WRAP16)))) begin
                cnt_n = 1;
            end
            else if (htrans == SEQUENTIAL || htrans == NONSEQUENTIAL) begin
                cnt_n = cnt + 1; // Increment counter
            end

            if (!(htrans == IDLE || htrans == BUSY)) begin // Ignore IDLE and BUSY transactions
                // Update resp_n to report errors, if any.
                if (hsize == 3'b000) begin // BYTE
                    case (haddr[1:0])
                        2'b00: resp_n = (hwstrb[3:1] == 3'b000) ? 1'b0 : 1'b1;
                        2'b01: resp_n = (hwstrb[3:2] == 2'b00 && hwstrb[0] == 1'b0) ? 1'b0 : 1'b1;
                        2'b10: resp_n = (hwstrb[3] == 1'b0 && hwstrb[1:0] == 2'b00) ? 1'b0 : 1'b1;
                        2'b11: resp_n = (hwstrb[2:0] == 3'b000) ? 1'b0 : 1'b1;
                        default: resp_n = 1'b1; // Invalid case
                    endcase
                end 
                else if (hsize == 3'b001) begin // HALFWORD
                    if (haddr[1:0] == 2'b00) resp_n = (hwstrb[3:2] == 2'b00) ? 1'b0 : 1'b1;
                    else if (haddr[1:0] == 2'b10) resp_n = (hwstrb[1:0] == 2'b00) ? 1'b0 : 1'b1;
                    else resp_n = 1'b1; // Invalid address
                end
                else if (htrans == SEQUENTIAL && (haddr[29:0] == 30'h0)) begin
                    resp_n = 1'b1; // Invalid burst transfer
                end
                else if ((hburst == INCR4 || hburst == WRAP4) && cnt > 4 && htrans == SEQUENTIAL) begin
                    resp_n = 1'b1; // Invalid burst transfer
                end
                else if ((hburst == INCR8 || hburst == WRAP8) && cnt > 8 && htrans == SEQUENTIAL) begin
                    resp_n = 1'b1; // Invalid burst transfer
                end
                else if ((hburst == INCR16 || hburst == WRAP16) && cnt > 16 && htrans == SEQUENTIAL) begin
                    resp_n = 1'b1; // Invalid burst transfer
                end
                
                if (!resp_n && hselx) begin
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
        end
    end
    
    // Output assignments
    assign hreadyout = ready;
    assign hrdata = rdata;
    assign hresp = resp;

endmodule