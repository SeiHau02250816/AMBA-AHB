//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_multiple_non_consecutive_txns_test
// Module Name: ahb_multiple_non_consecutive_txns_test
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - Multiple Non-Consecutive Transactions Test
//    - Configures environment for a random number of transactions
//    - Creates configuration file with randomized transaction count (10 to 20)
//    - Sets up AHB environment and runs main test sequence
//
// Revision:
//    v1.0 - Initial implementation 
//////////////////////////////////////////////////////////////////////////////////

class ahb_multiple_non_consecutive_txns_test;
    // Virtual interface for AHB signals
    virtual ahb_intf vintf;
    
    // AHB environment instance
    ahb_env ahb_env_h;

    // Class to encapsulate randomizable properties
    class txn_config;
        rand int num_txns;

        function new();
            // Constructor
        endfunction
    endclass

    // Constructor
    function new(virtual ahb_intf vintf);
        // Store the virtual interface
        this.vintf = vintf;
        
        // Write configuration file
        write_config_file();

        // Create AHB environment
        ahb_env_h = new(this.vintf);
    endfunction

    // Write configuration to file
    function void write_config_file();
        int file;
        txn_config ahb_config = new();

        // Randomize number of transactions between 40 and 50
        assert(ahb_config.randomize() with {
            ahb_config.num_txns inside {[40:50]};
        }) else $fatal("Failed to randomize num_txns");

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "NUM_OF_TXN=%0d", ahb_config.num_txns);
            $fclose(file);
            $display("Configuration file written successfully.");
            $display("Number of transactions = %0d.", ahb_config.num_txns);
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction
    
    // Main test execution task
    task main;
        $display("Task main :: ahb_multiple_non_consecutive_txns_test");
        ahb_env_h.main();
    endtask
endclass
