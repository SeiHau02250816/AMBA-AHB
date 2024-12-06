//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 06.12.2024 
// Design Name: ahb_halfword_strobe_test
// Module Name: ahb_halfword_strobe_test
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - Halfword Strobe Test
//    - Configures environment for a halfword strobe transaction
//    - Sets up AHB environment and runs main test sequence
//    - Tests half-word transfer with specific strobe (HSIZE = HALF_WORD, HWSTRB = 0001)
//
// Revision:
//    v1.0 - Initial implementation 
//////////////////////////////////////////////////////////////////////////////////

class ahb_halfword_strobe_test;
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
        int num_txns = 1;  // Set number of transactions to 1
        int transfer_size = 32'b0001;  // Set transfer size to HALF_WORD
        int write_strobe = 32'b0001;  // Set write strobe to specific byte

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "NUM_OF_TXN=%0d", num_txns);
            $fdisplay(file, "TRANSFER_SIZE=%0d", transfer_size);
            $fdisplay(file, "WRITE_STROBE=%0d", write_strobe);
            $fclose(file);
            $display("Configuration file written successfully.");
            $display("Number of transactions = %0d.", num_txns);
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction

    // Main test execution task
    task main;
        $display("Task main :: ahb_halfword_strobe_test");
        ahb_env_h.main();
    endtask

endclass
