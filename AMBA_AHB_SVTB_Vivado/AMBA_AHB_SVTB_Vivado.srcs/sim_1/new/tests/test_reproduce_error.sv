// Engineer: SeiHau Teo
// 
// Create Date: 13.12.2024 
// Design Name: test_reproduce_error
// Module Name: test_reproduce_error
// Project Name: AHB SVTB
// 
// Description:
//    AHB Testbench - Reproduce Error Test
//    - Configures environment for reproducing the error in the subordinate module
//    - Verifies that the error condition is correctly handled
// 
// Revision:
//    v1.0 - Initial implementation 

class test_reproduce_error;
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
        int transfer_type = 2;  // NONSEQ
        int transfer_size = 32'b0010;  // BYTE
        int write_strobe = 32'b0001;  // Set write strobe to all bytes
        int addr = 32'h04d8df08;
        int data = 32'h05dc94ac;

        file = $fopen("ahb_config.cfg", "w");
        if (file) begin
            $fdisplay(file, "NUM_OF_TXN=%0d", num_txns); // Set number of transactions
            $fdisplay(file, "TRANSFER_TYPE=%0d", transfer_type); // Write transfer
            $fdisplay(file, "TRANSFER_SIZE=%0d", transfer_size); // Set transfer size
            $fdisplay(file, "WRITE_STROBE=%0d", write_strobe); // Set write strobe
            $fdisplay(file, "ADDRESS=%0d", addr);
            $fdisplay(file, "DATA=%0d", data);
            $fclose(file);
            $display("Configuration file written successfully.");
            $display("Number of transactions: %0d", num_txns);
            $display("Transfer Type: Write");
            $display("Transfer Size: WORD");
            $display("Write Strobe: all bytes");
            $display("Address: %0h", addr);
            $display("Data: %0h", data);
        end else begin
            $error("Error: Could not create configuration file.");
        end
    endfunction
    
    // Main test execution task
    task main;
        $display("Task main :: test_reproduce_error");
        ahb_env_h.main();
    endtask
endclass