//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_single_write_single_read_test
// Module Name: ahb_single_write_single_read_test
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - Single Write/Single Read Test
//    - Configures environment for a single write and read transaction
//    - Creates configuration file with transaction count
//    - Sets up AHB environment and runs main test sequence
//
// Revision:
//    v1.0 - Initial implementation 
//////////////////////////////////////////////////////////////////////////////////

class ahb_single_write_single_read_test;
    // Virtual interface for AHB signals
    virtual ahb_intf vintf;
    
    // AHB environment instance
    ahb_env ahb_env_h;

    // Constructor
    function new(virtual ahb_intf vintf);
        // Store the virtual interface
        this.vintf = vintf;
        
        // Create AHB environment
        ahb_env_h = new(this.vintf);
        
        // Write configuration file
        write_config_file();
    endfunction

    // Write configuration to file
    function void write_config_file();
        int file;
        int num_txns = 1;  // Set number of transactions to 1 for single write + single read

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "NUM_OF_TXN=%0d", num_txns);
            $fclose(file);
            $display("Configuration file written successfully.");
            $display("Number of transactions = %0d.", num_txns);
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction
    
    // Main test execution task
    task main;
        $display("Task main :: ahb_single_write_single_read_test");
        ahb_env_h.main();
    endtask
endclass
