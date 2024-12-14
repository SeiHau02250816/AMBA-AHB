//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 20.11.2024 18:45:00
// Design Name: ahb_transaction_class
// Module Name: ahb_txn
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created AHB transaction class.
// 
// Additional Comments: AHB transaction class for AMBA AHB SV Testbench
//////////////////////////////////////////////////////////////////////////////////

class ahb_txn;
    // Randomized master signals
    rand logic [31:0] haddr;     // Address bus
    rand logic        hwrite;    // Transfer direction (1: write, 0: read)
    rand logic [2:0]  hsize;     // Transfer size
    rand logic [2:0]  hburst;    // Burst type
    rand logic [3:0]  hprot;     // Protection control
    rand logic [1:0]  htrans;    // Transfer type
    rand logic        hmastlock; // Locked transfer
    rand logic [31:0] hwdata;    // Write data bus
    rand logic [3:0]  hwstrb;    // Write strobe

    // Response signals (not randomized)
    logic        hreadyout; // Transfer complete
    logic        hresp;     // Transfer response
    logic [31:0] hrdata;    // Read data bus

    // For 32-bits data bus, hsize must be <= 3'b010
    constraint valid_size {
        hsize inside {3'b000, 3'b001, 3'b010}; // Byte, Halfword, Word
    }

    constraint aligned_and_valid_addr {
        solve hsize before haddr;

        // Alignment based on hsize
        if (hsize == 3'b010) {          // WORD transfer
            haddr[1:0] == 2'b00;        // Ensure word alignment
        } else if (hsize == 3'b001) {   // HALFWORD transfer
            haddr[0] == 1'b0;           // Ensure halfword alignment
        }                               
        // No alignment required for BYTE   

        // Ensure valid address range
        haddr <= 32'hbfff_ffff;
    }

    // With masking capabilities
    constraint valid_hwstrb { 
        solve hwrite before hwstrb;
        solve haddr before hwstrb;

        if (hwrite == 1'b0) hwstrb == 4'b0000; // Read transactions must have hwstrb = 0
        else {
            if (hsize == 3'b000) { // BYTE
                if (haddr[1:0] == 2'b00) hwstrb[3:1] == 3'b000; // Only hwstrb[0] can be randomized
                else if (haddr[1:0] == 2'b01) hwstrb[3:2] == 2'b00 && hwstrb[0] == 1'b0; // hwstrb[1] can be randomized
                else if (haddr[1:0] == 2'b10) hwstrb[3] == 1'b0 && hwstrb[1:0] == 2'b00; // hwstrb[2] can be randomized
                else if (haddr[1:0] == 2'b11) hwstrb[2:0] == 3'b000; // Only hwstrb[3] can be randomized
            } 
            else if (hsize == 3'b001) { // HALFWORD
                if (haddr[1:0] == 2'b00) hwstrb[3:2] == 2'b00; // hwstrb[1:0] can be randomized
                else if (haddr[1:0] == 2'b10) hwstrb[1:0] == 2'b00; // hwstrb[3:2] can be randomized
            }
            // For hsize == 3'b010 (WORD), no constraint is added to hwstrb for fine-grained masking
        }
    }


    // Deep copy method (similar to APB transaction class)
    function ahb_txn clone();
        ahb_txn new_txn = new();
        
        new_txn.haddr     = this.haddr;
        new_txn.hwrite    = this.hwrite;
        new_txn.hsize     = this.hsize;
        new_txn.hburst    = this.hburst;
        new_txn.hprot     = this.hprot;
        new_txn.htrans    = this.htrans;
        new_txn.hmastlock = this.hmastlock;
        new_txn.hwdata    = this.hwdata;
        new_txn.hwstrb    = this.hwstrb;
        
        new_txn.hreadyout = this.hreadyout;
        new_txn.hresp     = this.hresp;
        new_txn.hrdata    = this.hrdata;
        
        return new_txn;
    endfunction

    // Print transaction details for debugging
    function void print(input string tag = "");
        $display("AHB Transaction %s:", tag);
        $display("  Address     : 0x%0h", haddr);
        $display("  Write       : %0b", hwrite);
        $display("  Size        : %0b", hsize);
        $display("  Burst       : %0b", hburst);
        $display("  Protection  : %0b", hprot);
        $display("  Transfer    : %0b", htrans);
        $display("  Locked      : %0b", hmastlock);
        $display("  Write Data  : 0x%0h", hwdata);
        $display("  Write Strobe: %0b", hwstrb);
        $display("  Ready Out   : %0b", hreadyout);
        $display("  Response    : %0b", hresp);
        $display("  Read Data   : 0x%0h", hrdata);
    endfunction
endclass