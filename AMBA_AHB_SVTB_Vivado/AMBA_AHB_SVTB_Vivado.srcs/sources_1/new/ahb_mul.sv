//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 17:32:45
// Module Name: ahb_mul
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created initial version with descriptions.
// 
// Description:
//    This module selects and multiplexes three 32-bit data inputs based on a secondary select signal.
//
//////////////////////////////////////////////////////////////////////////////////

module ahb_mul (
    /* Input ports */
    input  logic       hclk,      // Clock signal
    input  logic       hresetn,   // Reset signal
    // Secondary select signals
    input logic [1:0]  mul_sel,
    // Data inputs from subordinates
    input logic [31:0] hrdata1,
    input logic [31:0] hrdata2,
    input logic [31:0] hrdata3,

    /* Output port */
    // Selected data output
    output logic [31:0] hrdata
);
    // Internal registers for output signals
    logic [31:0] rdata, rdata_n;

    always_ff @(!hresetn or posedge hclk) begin
        if (!hresetn) begin
            rdata <= 32'b0;
        end
        else begin
            rdata <= rdata_n;
        end
    end

    always_comb begin
        case (mul_sel)
            2'b00: rdata_n <= hrdata1;
            2'b01: rdata_n <= hrdata2;
            2'b10: rdata_n <= hrdata3;
            default: rdata_n <= 32'b0; // Default to 0 if mul_sel is out of range
        endcase
    end

    assign hrdata = rdata;
endmodule