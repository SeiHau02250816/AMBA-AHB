//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: subordinate
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
// 
// Description:
//    This module represents a subordinate device on the AHB bus. It provides the necessary
//    interfaces for communication with a master device, including address and data transfer,
//    control signals, and response signaling.
//
//////////////////////////////////////////////////////////////////////////////////

module subordinate (
    /* Input ports */
    // Global signals
    input  logic hclk,          // Clock signal
    input  logic hresetn,       // Reset signal

    // Select signal
    input  logic [3:0] hselx,   // Slave select signal

    // Address and control
    input  logic [31:0] haddr,  // Address bus
    input  logic        hwrite,  // Write enable
    input  logic [2:0]  hsize,   // Transfer size (ignored in this example)
    input  logic [2:0]  hburst,  // Burst type (ignored in this example)
    input  logic [3:0]  hprot,   // Protection type (ignored in this example)
    input  logic [1:0]  htrans,  // Transaction type (ignored in this example)
    input  logic        hmastlock, // Master lock signal

    // Data
    input  logic [31:0] hwdata,  // Write data bus

    /* Output ports */
    // Transfer response
    output logic hreadyout,   // Ready to accept more transfers
    output logic hresp,       // Response signal (single bit)

    // Data
    output logic [31:0] hrdata  // Read data bus
);
endmodule