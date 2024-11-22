//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: ahb_decoder
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
//    v1.1: Added address decoding logic for subordinate selection
// 
// Description:
//    This module decodes the address bus from the master to determine which subordinate device(s) should be selected and what secondary select signals to use.
//    - Takes first two bits of address [1:0]
//    - Restricts valid values to [0:2]
//    - Outputs one-hot encoding to hselx
//    - Outputs normal binary encoding to mul_sel
//
//////////////////////////////////////////////////////////////////////////////////

module ahb_decoder (
    /* Input ports */
    // Address from manager
    input  logic [31:0] haddr,

    /* Output ports */
    // Slave select signals (one-hot encoded)
    output logic [2:0] hselx,
    
    // Secondary select signals for subordinates (binary encoded)
    output logic [1:0] mul_sel
);

    // Extract the two least significant bits of the address
    logic [1:0] addr_bits;
    assign addr_bits = haddr[31:30];
    
    // Combinational logic for decoding
    always_comb begin
        // Default assignments
        hselx = 3'b000;
        mul_sel = 2'b00;
        
        // Address decoding based on addr_bits
        case (addr_bits)
            2'b00: begin
                hselx = 3'b001;   
                mul_sel = 2'b00;   
            end
            
            2'b01: begin
                hselx = 3'b010;   
                mul_sel = 2'b01;   
            end
            
            2'b10: begin
                hselx = 3'b100;    
                mul_sel = 2'b10;  
            end
            
            default: begin
                // Invalid address - disable all subordinates
                hselx = 3'b000;
                mul_sel = 2'b00;
            end
        endcase
    end

endmodule