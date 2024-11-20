//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: ahb_decoder
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
// 
// Description:
//    This module decodes the address bus from the master to determine which subordinate device(s) should be selected and what secondary select signals to use.
//
//////////////////////////////////////////////////////////////////////////////////

module ahb_decoder (
    /* Input ports */
    // Address from manager
    input  logic [31:0] haddr,

    /* Output ports */
    // Slave select signals
    output logic [2:0] hselx,
    
    // Secondary select signals for subordinates
    output logic [1:0] mul_sel
);

endmodule