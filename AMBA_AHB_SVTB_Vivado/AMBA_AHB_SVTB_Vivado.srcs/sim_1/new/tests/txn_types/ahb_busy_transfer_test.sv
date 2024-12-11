//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 11.12.2024 
// Design Name: ahb_busy_transfer_test
// Module Name: ahb_busy_transfer_test
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - BUSY Transfer Test
//    - Configures environment for BUSY transfer testing
//    - Verifies that no read/write occurs during BUSY transfer
//    - Checks that subordinate responds with OKAY
// 
// Revision:
//    v1.0 - Initial implementation 
//////////////////////////////////////////////////////////////////////////////////

class ahb_busy_transfer_test;
    // Virtual interface for AHB signals
    virtual ahb_intf vintf;
    
    // AHB environment instance
    ahb_env ahb_env_h;

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
        int num_txns = 1;  // Set number of transactions to 1
        int transfer_type = 1;  // 1 = BUSY transfer
        int transfer_size = 32'b0010;  // Set transfer size to WORD
        int write_strobe = 32'b1111;  // Set write strobe to all bytes

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "NUM_OF_TXN=%0d", num_txns); // Set number of transactions
            $fdisplay(file, "TRANSFER_TYPE=%0d", transfer_type); // BUSY transfer
            $fdisplay(file, "TRANSFER_SIZE=%0d", transfer_size); // Set transfer size
            $fdisplay(file, "WRITE_STROBE=%0d", write_strobe); // Set write strobe
            $fclose(file);
            $display("Configuration file written successfully.");
            $display("Number of transactions: %0d", num_txns);
            $display("Transfer Type: BUSY");
            $display("Transfer Size: WORD");
            $display("Write Strobe: all bytes");
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction
    
    // Main test execution task
    task main;
        $display("Task main :: ahb_busy_transfer_test");
        ahb_env_h.main();
    endtask
endclass
