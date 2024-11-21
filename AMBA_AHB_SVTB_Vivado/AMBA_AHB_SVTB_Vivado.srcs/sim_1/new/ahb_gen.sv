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

    // Task for generating consecutive transactions
//    task gen_consecutive();
//        int unsigned addr_array[]; // Array to store randomized addresses
        
//        // Step 1: Initialize the size of addr_array
//        addr_array = new[num_txns];

//        // Step 2: Generate consecutive write transactions
//        for (int i = 0; i < num_txns; i++) begin
//            // Write transactions
//            write_setup_txn = new();
//            write_setup_txn.randomize() with {
//                htrans == 2'b10;     // NONSEQ transfer
//                hwrite == 1'b1;      // Write transfer
//                hburst == 3'b000;    // Single burst
//                hsize inside {3'b010}; // Word transfer
//                haddr inside {[32'h0000_0000 : 32'h0FFF_FFFF]};
//            };
//            addr_array[i] = write_setup_txn.haddr; 
//            g2d_mb.put(write_setup_txn);

//            // Complete write transaction
//            write_txn = write_setup_txn.clone();
//            write_txn.htrans = 2'b00; // IDLE after transfer
//            g2d_mb.put(write_txn);

//            // Idle transaction
//            idle_txn = new();
//            idle_txn.randomize() with {
//                htrans == 2'b00;     // IDLE
//                haddr == addr_array[i];
//            };
//            g2d_mb.put(idle_txn);
//        end

//        // Step 3: Generate consecutive read transactions
//        for (int i = 0; i < num_txns; i++) begin
//            // Read transactions
//            read_setup_txn = new();
//            read_setup_txn.randomize() with {
//                htrans == 2'b10;     // NONSEQ transfer
//                hwrite == 1'b0;      // Read transfer
//                hburst == 3'b000;    // Single burst
//                hsize inside {3'b010}; // Word transfer
//                haddr == addr_array[i]; // Use pre-randomized address
//            };
//            g2d_mb.put(read_setup_txn);

//            // Complete read transaction
//            read_txn = read_setup_txn.clone();
//            read_txn.htrans = 2'b00; // IDLE after transfer
//            g2d_mb.put(read_txn);

//            // Idle transaction
//            idle_txn = new();
//            idle_txn.randomize() with {
//                htrans == 2'b00;     // IDLE
//                haddr == addr_array[i];
//            };
//            g2d_mb.put(idle_txn);
//        end
//    endtask

    // Task for generating non-consecutive transactions (alternating)
//    task gen_non_consecutive();
//        int unsigned addr;
//        for (int i = 0; i < num_txns; i++) begin
//            // Write transactions
//            write_setup_txn = new();
//            write_setup_txn.randomize() with {
//                htrans == 2'b10;     // NONSEQ transfer
//                hwrite == 1'b1;      // Write transfer
//                hburst == 3'b000;    // Single burst
//                hsize inside {3'b010}; // Word transfer
//                haddr inside {[32'h0000_0000 : 32'h0FFF_FFFF]};
//            };
//            addr = write_setup_txn.haddr;
//            g2d_mb.put(write_setup_txn);

//            // Complete write transaction
//            write_txn = write_setup_txn.clone();
//            write_txn.htrans = 2'b00; // IDLE after transfer
//            g2d_mb.put(write_txn);

//            // Read transactions
//            read_setup_txn = new();
//            read_setup_txn.randomize() with {
//                htrans == 2'b10;     // NONSEQ transfer
//                hwrite == 1'b0;      // Read transfer
//                hburst == 3'b000;    // Single burst
//                hsize inside {3'b010}; // Word transfer
//                haddr == addr;
//            };
//            g2d_mb.put(read_setup_txn);

//            // Complete read transaction
//            read_txn = read_setup_txn.clone();
//            read_txn.htrans = 2'b00; // IDLE after transfer
//            g2d_mb.put(read_txn);

//            // Idle transaction
//            idle_txn = new();
//            idle_txn.randomize() with {
//                htrans == 2'b00;     // IDLE
//                haddr == addr;
//            };
//            g2d_mb.put(idle_txn);
//        end
//    endtask

    task gen_single();
        int unsigned addr;
        
        // Write transaction
        write_txn = new();
        write_txn.randomize() with {
            hwrite == 1'b1;      // Write transfer
        };
        addr = write_setup_txn.haddr;
        g2d_mb.put(write_txn);
        
        // Read transaction
        read_txn = new();
        read_txn.randomize() with {
            hwrite == 1'b0;      // Read transfer
            haddr  == addr;      // Read from the same address
        };
        g2d_mb.put(read_txn);
    endtask: gen_single

    // Main generation task
    task gen;
        #30;
        $display("Task generate :: ahb_txn_gen with %0d transaction(s), CONSECUTIVE=%0d", num_txns, consecutive);
        
        gen_single();
//        if (consecutive == 1) begin
//            gen_consecutive();
//        end else begin
//            gen_non_consecutive();
//        end
    endtask
endclass