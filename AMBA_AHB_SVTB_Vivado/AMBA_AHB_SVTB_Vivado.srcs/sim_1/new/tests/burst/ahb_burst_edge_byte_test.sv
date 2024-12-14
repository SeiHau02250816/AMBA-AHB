//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 14.12.2024 
// Design Name: ahb_burst_edge_byte_test
// Module Name: ahb_burst_edge_byte_test
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - Burst Edge Byte Test
//    - Configures environment for burst transactions
//    - Sets up AHB environment and runs main test sequence
//    - Tests burst transfers with edge burst type
//
// Revision:
//    v1.0 - Initial implementation 
//////////////////////////////////////////////////////////////////////////////////

class ahb_burst_edge_byte_test;
    // Virtual interface for AHB signals
    virtual ahb_intf vintf;
    
    // AHB environment instance
    ahb_env ahb_env_b;

    // Constructor
    function new(virtual ahb_intf vintf);
        // Store the virtual interface
        this.vintf = vintf;
        
        // Write configuration file
        write_config_file();

        // Create AHB environment
        ahb_env_b = new(this.vintf);
    endfunction

    // Write configuration to file
    function void write_config_file();
        int file;
        int transfer_size = 32'b0000;  // Set transfer size to BYTE
        int burst_enable = 1; // Enable burst transactions
        int burst_type = 32'b101; // Set burst type to INCR8
        logic[31:0] addr = 32'b0001_0000; // Set addr to 0x10

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "TRANSFER_SIZE=%0d", transfer_size);
            $fdisplay(file, "BURST=%0d", burst_enable);
            $fdisplay(file, "BURST_TYPE=%0d", burst_type);
            $fdisplay(file, "ADDRESS=%0d", addr);
            $fclose(file);
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction

    // Main test execution task
    task main;
        $display("Task main :: ahb_burst_edge_byte_test");
        ahb_env_b.main();
    endtask
endclass