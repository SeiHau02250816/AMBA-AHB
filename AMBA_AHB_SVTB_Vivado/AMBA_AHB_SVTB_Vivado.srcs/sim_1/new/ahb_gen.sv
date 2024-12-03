//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024
// Design Name: ahb_generator
// Module Name: ahb_gen
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created AHB transaction generator.
// 
// Additional Comments: 
// - Generator for AMBA AHB Testbench 
// - Unlike APB, AHB doesn't have operating states, and thus we don't need to consider
//   transactions for state transfer.
//////////////////////////////////////////////////////////////////////////////////

class ahb_gen;
    // Configuration properties as global class members
    int num_txns;
    int consecutive;
    mailbox g2d_mb;

    // Transaction objects for various transfer types
    ahb_txn write_txn, idle_txn;
    ahb_txn read_setup_txn, read_txn;

    // Class to encapsulate randomizable properties
    class txn_properties;
        rand int unsigned haddr_value;
        rand logic [2:0] hsize_value;

        function new();
            // Constructor
        endfunction
    endclass

    // Constructor
    function new(mailbox g2d_mb);
        this.g2d_mb = g2d_mb;
        load_configurations();  // Load configurations on instantiation
    endfunction

    // Method to load configurations from the config file
    function void load_configurations();
        int file;
        string line;
        num_txns = 0;      // Default value if not specified in the file
        consecutive = 0;   // Default to non-consecutive if not specified

        file = $fopen("ahb_config.cfg", "r");
        if (file) begin
            while (!$feof(file)) begin
                line = "";
                $fgets(line, file);
                if ($sscanf(line, "NUM_OF_TXN=%d", num_txns) == 1) continue;
                if ($sscanf(line, "CONSECUTIVE=%d", consecutive) == 1) continue;
            end
            $fclose(file);
        end else begin
            $display("Error: Could not open configuration file ahb_config.cfg");
        end
    endfunction

    task gen_single();
        txn_properties props = new();
        
        // Randomize properties
        assert(props.randomize() with {
            props.hsize_value inside {3'b000, 3'b001, 3'b010};  // BYTE, HALFWORD, WORD
            props.haddr_value inside {[32'h0000_0000 : 32'h0FFF_FFFF]};  // Address range
        }) else $fatal(1, "Failed to randomize transaction properties");
        
        // Write transaction
        write_txn = new();
        write_txn.randomize() with {
            hwrite == 1'b1;      // Write transfer
            hsize == props.hsize_value; // Use the same randomized hsize
            haddr == props.haddr_value; // Use the same randomized address
        };
        g2d_mb.put(write_txn);
        
        // Read transaction
        read_txn = new();
        read_txn.randomize() with {
            hwrite == 1'b0;      // Read transfer
            haddr  == props.haddr_value; // Read from the same address
            hsize == props.hsize_value; // Use the same randomized hsize
        };
        g2d_mb.put(read_txn);
    endtask: gen_single

    // Task to generate non-consecutive transactions
    task gen_non_consecutive();
        for (int i = 0; i < this.num_txns; i++) begin
            gen_single();
        end
    endtask: gen_non_consecutive
    
    // Main generation task
    task gen;
        #30;
        $display("Task generate :: ahb_txn_gen with %0d transaction(s), CONSECUTIVE=%0d", num_txns, consecutive);
        
        gen_non_consecutive();
    endtask
endclass